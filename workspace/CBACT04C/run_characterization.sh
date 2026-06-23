#!/usr/bin/env bash
# run_characterization.sh
# Re-runnable characterization test for CBACT04C.
# Usage:
#   ./run_characterization.sh           -- compare COBOL output against golden master
#   ./run_characterization.sh JAVA_BIN  -- compare Java output against golden master
#
# The script:
# 1. Regenerates all input files (TCATBALF, XREFFILE, DISCGRP, ACCTFILE)
# 2. Runs CBACT04C_DRIVER (or provided Java binary) with date '2026-06-17'
# 3. Dumps ACCTFILE to sequential (ACCTSEQ)
# 4. Masks TRAN-ORIG-TS (bytes 278-303) and TRAN-PROC-TS (bytes 304-329) in TRANSACT
# 5. Compares all 3 outputs against golden master files (byte-for-byte)
# 6. Prints PASS/FAIL for each comparison
#
# Non-determinism:
#   TRAN-ORIG-TS in TRANSACT at offset 278 length 26 per 350-byte record.
#   TRAN-PROC-TS in TRANSACT at offset 304 length 26 per 350-byte record.
#   Both fields are zeroed in both test and golden copies before comparison.
#
# PARM-DATE mechanism:
#   CBACT04C has PROCEDURE DIVISION USING EXTERNAL-PARMS.
#   GnuCOBOL does not allow compiling such a program as executable (-x).
#   Solution: compile CBACT04C as a shared module (.dylib/.so) and use
#   CBACT04C_DRIVER (a standalone executable) that sets PARM-DATE='2026-06-17'
#   and CALLS CBACT04C with USING WS-EXTERNAL-PARMS.
#
# CBACT04C golden behavior (known issue):
#   The last account's interest (ACCT=00000000002, WS-TOTAL-INT=24.50) is
#   written to TRANSACT but is NOT posted to ACCTFILE. This is because
#   CBACT04C's EOF handling is dead code (the UNTIL exits before ELSE runs).
#   Account 1 (BAL=5012.50) IS updated because it triggers on account-change.
#   Account 2 (BAL=8000.00) remains UNCHANGED in ACCTFILE.
#   This is the actual COBOL behavior - Java must replicate it exactly.
#
# Environment: GnuCOBOL 3.2.0 (-std=ibm), COB_LIBRARY_PATH for CBACT04C module.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GOLDEN_DIR="$PROJECT_ROOT/results/CBACT04C"
WORK_DIR="$SCRIPT_DIR"
RUN_DATE="2026-06-17"

echo "=== CBACT04C Characterization Test ==="
echo "Project root: $PROJECT_ROOT"
echo "Working dir:  $WORK_DIR"
echo "Golden dir:   $GOLDEN_DIR"
echo "Run date:     $RUN_DATE"
echo ""

cd "$WORK_DIR"

# Export CBACT04C module path (for COBOL path)
export COB_LIBRARY_PATH="$WORK_DIR"

# ----------------------------------------------------------------
# Step 1: Regenerate all input files
# ----------------------------------------------------------------
echo "[1/4] Regenerating test data..."

export TCATBALF="$WORK_DIR/TCATBALF"
export XREFFILE="$WORK_DIR/XREFFILE"
export DISCGRP="$WORK_DIR/DISCGRP"
export ACCTFILE="$WORK_DIR/ACCTFILE"

# Remove old indexed files (with possible .idx companion)
rm -f "$WORK_DIR/TCATBALF" "$WORK_DIR/TCATBALF.idx"
rm -f "$WORK_DIR/XREFFILE" "$WORK_DIR/XREFFILE.idx"
rm -f "$WORK_DIR/DISCGRP"  "$WORK_DIR/DISCGRP.idx"
rm -f "$WORK_DIR/ACCTFILE" "$WORK_DIR/ACCTFILE.idx"
rm -f "$WORK_DIR/TRANSACT"

"$WORK_DIR/GENTCAT"
if [ $? -ne 0 ]; then echo "FAIL: GENTCAT"; exit 1; fi

"$WORK_DIR/GENXREF"
if [ $? -ne 0 ]; then echo "FAIL: GENXREF"; exit 1; fi

"$WORK_DIR/GENDISCGRP"
if [ $? -ne 0 ]; then echo "FAIL: GENDISCGRP"; exit 1; fi

"$WORK_DIR/GENACCT"
if [ $? -ne 0 ]; then echo "FAIL: GENACCT"; exit 1; fi

echo "      Input files generated."
echo ""

# ----------------------------------------------------------------
# Step 2: Run the program under test
# ----------------------------------------------------------------
export TRANSACT="$WORK_DIR/TRANSACT"

rm -f "$WORK_DIR/test_stdout.txt"
rm -f "$WORK_DIR/test_TRANSACT_masked" "$WORK_DIR/test_ACCTSEQ"

if [ -n "$1" ]; then
    echo "[2/4] Running Java program: $1 with date $RUN_DATE"
    set +e
    "$1" "$RUN_DATE" > "$WORK_DIR/test_stdout.txt" 2>&1
    PROG_EXIT=$?
    set -e
else
    echo "[2/4] Running COBOL CBACT04C_DRIVER (date=$RUN_DATE hardcoded in driver)..."
    set +e
    "$WORK_DIR/CBACT04C_DRIVER" > "$WORK_DIR/test_stdout.txt" 2>&1
    PROG_EXIT=$?
    set -e
fi

if [ "$PROG_EXIT" -ne 0 ]; then
    echo "FAIL: program exited with unexpected code $PROG_EXIT"
    cat "$WORK_DIR/test_stdout.txt"
    exit 1
fi

echo "      Exit code: $PROG_EXIT"
cat "$WORK_DIR/test_stdout.txt"
echo ""

# ----------------------------------------------------------------
# Step 3: Dump ACCTFILE to sequential
# ----------------------------------------------------------------
echo "[3/4] Dumping ACCTFILE to sequential..."

if [ -n "$1" ]; then
    # Java path: Java program should write sequential ACCTSEQ directly
    ACCTSEQ_FILE="$WORK_DIR/java_ACCTSEQ"
    TRANSACT_SEQ="$WORK_DIR/java_TRANSACT"
    echo "      (Java path: using Java output files directly)"
else
    # COBOL path: dump ACCTFILE indexed to sequential flat file
    export ACCTSEQ="$WORK_DIR/test_ACCTSEQ"
    rm -f "$WORK_DIR/test_ACCTSEQ"
    export ACCTFILE="$WORK_DIR/ACCTFILE"
    "$WORK_DIR/DUMPACCT"
    if [ $? -ne 0 ]; then echo "FAIL: DUMPACCT"; exit 1; fi
    ACCTSEQ_FILE="$WORK_DIR/test_ACCTSEQ"
    TRANSACT_SEQ="$WORK_DIR/TRANSACT"
fi

echo ""

# ----------------------------------------------------------------
# Step 4: Mask TRAN-ORIG-TS and TRAN-PROC-TS in TRANSACT
#   TRAN-ORIG-TS: bytes 278-303 (26 bytes) per 350-byte record
#   TRAN-PROC-TS: bytes 304-329 (26 bytes) per 350-byte record
# ----------------------------------------------------------------
echo "[4/4] Masking timestamps in TRANSACT..."
python3 -c "
import sys
transact_file = '$TRANSACT_SEQ'
masked_file = '$WORK_DIR/test_TRANSACT_masked'
data = open(transact_file,'rb').read()
out = bytearray(data)
rec_len = 350
count = len(out) // rec_len
for i in range(0, len(out), rec_len):
    for j in list(range(278, 304)) + list(range(304, 330)):
        if i+j < len(out):
            out[i+j] = 0
open(masked_file,'wb').write(bytes(out))
print(f'  Masked {count} record(s): TRAN-ORIG-TS[278:304] and TRAN-PROC-TS[304:330] zeroed')
"
echo ""

# ----------------------------------------------------------------
# Step 5: Compare outputs against golden master
# ----------------------------------------------------------------
echo "[5/4] Comparing outputs against golden master..."
PASS_COUNT=0
FAIL_COUNT=0

compare_file() {
    local label="$1"
    local test_file="$2"
    local golden_file="$3"

    if [ ! -f "$test_file" ]; then
        echo "  FAIL  $label: test file not found: $test_file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi
    if [ ! -f "$golden_file" ]; then
        echo "  FAIL  $label: golden file not found: $golden_file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return
    fi
    if cmp -s "$test_file" "$golden_file"; then
        echo "  PASS  $label"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL  $label: byte-for-byte mismatch"
        echo "        Test:   $(wc -c < "$test_file") bytes"
        echo "        Golden: $(wc -c < "$golden_file") bytes"
        python3 -c "
t = open('$test_file','rb').read()
g = open('$golden_file','rb').read()
diffs = 0
for i,(a,b) in enumerate(zip(t,g)):
    if a != b:
        if diffs == 0:
            print(f'First diff at byte {i}: test=0x{a:02x} golden=0x{b:02x}')
        diffs += 1
if diffs > 0:
    print(f'Total differing bytes: {diffs}')
if len(t) != len(g):
    print(f'Size mismatch: test={len(t)} golden={len(g)}')
" 2>/dev/null || true
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

compare_file "TRANSACT masked (both timestamps zeroed)" \
    "$WORK_DIR/test_TRANSACT_masked" \
    "$GOLDEN_DIR/golden_TRANSACT_masked"

compare_file "ACCTSEQ (account after-state)" \
    "$ACCTSEQ_FILE" \
    "$GOLDEN_DIR/golden_ACCTSEQ"

# Compare stdout (strip libcob runtime warnings)
grep -v "^libcob:" "$WORK_DIR/test_stdout.txt" \
    > "$WORK_DIR/test_stdout_clean.txt" 2>/dev/null || true
grep -v "^libcob:" "$GOLDEN_DIR/golden_stdout.txt" \
    > "$WORK_DIR/golden_stdout_clean.txt" 2>/dev/null || true

if cmp -s "$WORK_DIR/test_stdout_clean.txt" \
        "$WORK_DIR/golden_stdout_clean.txt"; then
    echo "  PASS  STDOUT   (DISPLAY output)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  FAIL  STDOUT   (DISPLAY output mismatch)"
    diff "$WORK_DIR/golden_stdout_clean.txt" \
         "$WORK_DIR/test_stdout_clean.txt" | head -30 || true
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""
echo "Results: PASS=$PASS_COUNT FAIL=$FAIL_COUNT / $((PASS_COUNT + FAIL_COUNT))"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "=== OVERALL: PASS ==="
    exit 0
else
    echo "=== OVERALL: FAIL ==="
    exit 1
fi
