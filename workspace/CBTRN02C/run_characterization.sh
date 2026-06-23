#!/usr/bin/env bash
# run_characterization.sh
# Re-runnable characterization test for CBTRN02C.
# Usage:
#   ./run_characterization.sh           -- compare COBOL output against golden master
#   ./run_characterization.sh JAVA_BIN  -- compare Java output against golden master
#
# The script:
# 1. Regenerates all input files (XREFFILE, ACCTFILE, TCATBALF, DALYTRAN)
# 2. Runs CBTRN02C (or provided Java binary)
# 3. Dumps TRANFILE, ACCTFILE, TCATBALF to sequential flat files
# 4. Masks TRAN-PROC-TS (bytes 304-329, 0-indexed) in TRNSEQ dump
# 5. Compares all 5 outputs against golden master files (byte-for-byte)
# 6. Prints PASS/FAIL for each comparison
#
# Non-determinism: TRAN-PROC-TS in TRANFILE at offset 304 length 26 per 350-byte record.
# This field is zeroed in both test and golden copies before comparison.
#
# Environment: GnuCOBOL 3.2.0 (-std=ibm), COB_LIBRARY_PATH for CEE3ABD stub.

set -e
# Note: CBTRN02C exits with code 4 when rejections are present (expected).
# We handle that explicitly below; do not let set -e abort the script for it.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GOLDEN_DIR="$PROJECT_ROOT/results/CBTRN02C"
WORK_DIR="$SCRIPT_DIR"

echo "=== CBTRN02C Characterization Test ==="
echo "Project root: $PROJECT_ROOT"
echo "Working dir:  $WORK_DIR"
echo "Golden dir:   $GOLDEN_DIR"
echo ""

cd "$WORK_DIR"

# Export CEE3ABD library path
export COB_LIBRARY_PATH="$WORK_DIR/../CBACT01C"

# ----------------------------------------------------------------
# Step 1: Regenerate all input files
# ----------------------------------------------------------------
echo "[1/5] Regenerating test data..."

export XREFFILE="$WORK_DIR/XREFFILE"
export ACCTFILE="$WORK_DIR/ACCTFILE"
export TCATBALF="$WORK_DIR/TCATBALF"
export DALYTRAN="$WORK_DIR/DALYTRAN"

# Remove old files (isam files may have .idx companion)
rm -f "$WORK_DIR/XREFFILE" "$WORK_DIR/XREFFILE.idx"
rm -f "$WORK_DIR/ACCTFILE" "$WORK_DIR/ACCTFILE.idx"
rm -f "$WORK_DIR/TCATBALF" "$WORK_DIR/TCATBALF.idx"
rm -f "$WORK_DIR/DALYTRAN"

./GENXREF
if [ $? -ne 0 ]; then echo "FAIL: GENXREF"; exit 1; fi

./GENACCT
if [ $? -ne 0 ]; then echo "FAIL: GENACCT"; exit 1; fi

./GENTCAT
if [ $? -ne 0 ]; then echo "FAIL: GENTCAT"; exit 1; fi

./GENDALY
if [ $? -ne 0 ]; then echo "FAIL: GENDALY"; exit 1; fi

echo "      Input files generated."
echo ""

# ----------------------------------------------------------------
# Step 2: Run the program under test
# ----------------------------------------------------------------
export TRANFILE="$WORK_DIR/TRANFILE"
export DALYREJS="$WORK_DIR/DALYREJS"

rm -f "$WORK_DIR/TRANFILE" "$WORK_DIR/TRANFILE.idx"
rm -f "$WORK_DIR/DALYREJS"
rm -f "$WORK_DIR/test_stdout.txt"
rm -f "$WORK_DIR/java_TRNSEQ" "$WORK_DIR/java_ACCTSEQ" "$WORK_DIR/java_TCATSEQ"

if [ -n "$1" ]; then
    echo "[2/5] Running Java program: $1"
    # Java wrapper dumps indexed files to sequential and sets DALYREJS env
    # The Java program writes: java_TRNSEQ, DALYREJS, java_ACCTSEQ, java_TCATSEQ
    set +e
    "$1" > "$WORK_DIR/test_stdout.txt" 2>&1
    PROG_EXIT=$?
    set -e
else
    echo "[2/5] Running COBOL CBTRN02C..."
    set +e
    ./CBTRN02C > "$WORK_DIR/test_stdout.txt" 2>&1
    PROG_EXIT=$?
    set -e
fi
# Exit code 4 = normal: rejections present (per CBTRN02C spec)
# Exit code 0 = normal: no rejections
# Any other exit code = error
if [ "$PROG_EXIT" -ne 0 ] && [ "$PROG_EXIT" -ne 4 ]; then
    echo "FAIL: program exited with unexpected code $PROG_EXIT"
    cat "$WORK_DIR/test_stdout.txt"
    exit 1
fi

echo "      Exit code: $PROG_EXIT"
cat "$WORK_DIR/test_stdout.txt"
echo ""

# ----------------------------------------------------------------
# Step 3: Dump indexed output files to sequential
# ----------------------------------------------------------------
echo "[3/5] Dumping indexed files to sequential..."

if [ -n "$1" ]; then
    # Java path: Java already wrote sequential output files directly.
    # Point the test variables at Java's output files.
    TRNSEQ="$WORK_DIR/java_TRNSEQ"
    ACCTSEQ="$WORK_DIR/java_ACCTSEQ"
    TCATSEQ="$WORK_DIR/java_TCATSEQ"
    echo "      (Java path: using Java output files directly)"
else
    # COBOL path: dump indexed output files to sequential
    export TRNSEQ="$WORK_DIR/test_TRNSEQ"
    export ACCTSEQ="$WORK_DIR/test_ACCTSEQ"
    export TCATSEQ="$WORK_DIR/test_TCATSEQ"

    rm -f "$TRNSEQ" "$ACCTSEQ" "$TCATSEQ"

    export TRANFILE="$WORK_DIR/TRANFILE"
    ./DUMPTRN
    if [ $? -ne 0 ]; then echo "FAIL: DUMPTRN"; exit 1; fi

    export ACCTFILE="$WORK_DIR/ACCTFILE"
    ./DUMPACCT
    if [ $? -ne 0 ]; then echo "FAIL: DUMPACCT"; exit 1; fi

    export TCATBALF="$WORK_DIR/TCATBALF"
    ./DUMPTCAT
    if [ $? -ne 0 ]; then echo "FAIL: DUMPTCAT"; exit 1; fi
fi

echo ""

# ----------------------------------------------------------------
# Step 4: Mask TRAN-PROC-TS in TRNSEQ (bytes 304-329 per 350-byte record)
# ----------------------------------------------------------------
echo "[4/5] Masking TRAN-PROC-TS in TRANFILE dump..."
python3 -c "
import sys
data = open('$TRNSEQ','rb').read()
out = bytearray(data)
for i in range(0, len(out), 350):
    for j in range(304, 330):
        if i+j < len(out):
            out[i+j] = 0
open('${TRNSEQ}_masked','wb').write(bytes(out))
print(f'  Masked {len(out)//350} record(s) in TRNSEQ')
"
echo ""

# ----------------------------------------------------------------
# Step 5: Compare outputs against golden master
# ----------------------------------------------------------------
echo "[5/5] Comparing outputs against golden master..."
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
for i,(a,b) in enumerate(zip(t,g)):
    if a != b:
        print(f'First diff at byte {i}: test=0x{a:02x} golden=0x{b:02x}')
        break
" 2>/dev/null || true
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

compare_file "DALYREJS (reject file, deterministic)" \
    "$WORK_DIR/DALYREJS" \
    "$GOLDEN_DIR/golden_DALYREJS"

compare_file "TRNSEQ masked (accepted txns, PROC-TS zeroed)" \
    "${TRNSEQ}_masked" \
    "$GOLDEN_DIR/golden_TRNSEQ_masked"

compare_file "ACCTSEQ (account after-state)" \
    "$ACCTSEQ" \
    "$GOLDEN_DIR/golden_ACCTSEQ"

compare_file "TCATSEQ (tcatbal after-state)" \
    "$TCATSEQ" \
    "$GOLDEN_DIR/golden_TCATSEQ"

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
