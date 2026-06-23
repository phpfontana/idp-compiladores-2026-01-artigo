#!/usr/bin/env bash
# run_characterization.sh
# Re-runnable characterization test for CBACT01C.
# Usage:
#   ./run_characterization.sh           -- compare COBOL output against golden master
#   ./run_characterization.sh JAVA_BIN  -- compare Java output against golden master
#
# The script:
# 1. Regenerates the test data (ACCTFILE)
# 2. Runs CBACT01C (or provided Java binary) with golden env vars set
# 3. Compares outputs byte-for-byte against results/CBACT01C/golden_*
# 4. Prints PASS or FAIL for each file
#
# Environment: GnuCOBOL 3.2.0, COB_LIBRARY_PATH must include the stub .dylib files
# Run from: workspace/CBACT01C/ (script is designed to be run from that directory)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GOLDEN_DIR="$PROJECT_ROOT/results/CBACT01C"
WORK_DIR="$SCRIPT_DIR"

echo "=== CBACT01C Characterization Test ==="
echo "Project root: $PROJECT_ROOT"
echo "Working dir:  $WORK_DIR"
echo "Golden dir:   $GOLDEN_DIR"
echo ""

cd "$WORK_DIR"

# ----------------------------------------------------------------
# Step 1: Regenerate test data
# ----------------------------------------------------------------
echo "[1/4] Regenerating test data..."
export ACCTFILE="$WORK_DIR/ACCTFILE"
rm -f "$ACCTFILE"
./GENMKDAT
if [ $? -ne 0 ]; then
    echo "FAIL: GENMKDAT failed to generate test data"
    exit 1
fi
echo "      ACCTFILE generated: $ACCTFILE"
echo ""

# ----------------------------------------------------------------
# Step 2: Run the program under test
# ----------------------------------------------------------------
export OUTFILE="$WORK_DIR/test_OUTFILE"
export ARRYFILE="$WORK_DIR/test_ARRYFILE"
export VBRCFILE="$WORK_DIR/test_VBRCFILE"
export COB_LIBRARY_PATH="$WORK_DIR"

rm -f "$OUTFILE" "$ARRYFILE" "$VBRCFILE" "$WORK_DIR/test_stdout.txt"

if [ -n "$1" ]; then
    echo "[2/4] Running Java program: $1"
    "$1" > "$WORK_DIR/test_stdout.txt" 2>&1
    PROG_EXIT=$?
else
    echo "[2/4] Running COBOL CBACT01C..."
    ./CBACT01C > "$WORK_DIR/test_stdout.txt" 2>&1
    PROG_EXIT=$?
fi

echo "      Exit code: $PROG_EXIT"
echo ""

# ----------------------------------------------------------------
# Step 3: Compare outputs
# ----------------------------------------------------------------
echo "[3/4] Comparing outputs against golden master..."
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
        # Show first difference
        diff <(xxd "$test_file") <(xxd "$golden_file") | head -20 || true
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# Compare binary output files
compare_file "OUTFILE  (flat account records)" \
    "$WORK_DIR/test_OUTFILE" \
    "$GOLDEN_DIR/golden_OUTFILE"

compare_file "ARRYFILE (array records)" \
    "$WORK_DIR/test_ARRYFILE" \
    "$GOLDEN_DIR/golden_ARRYFILE"

compare_file "VBRCFILE (variable-length records)" \
    "$WORK_DIR/test_VBRCFILE" \
    "$GOLDEN_DIR/golden_VBRCFILE"

# Compare stdout (strip trailing whitespace for cross-platform robustness,
# but compare the semantic content line-by-line)
# For the equivalence gate, we strip the libcob runtime warnings (stderr artifacts)
# and compare only DISPLAY output lines.
echo ""
echo "  [stdout comparison: semantic lines only, excluding libcob warnings]"
grep -v "^libcob:" "$WORK_DIR/test_stdout.txt" > "$WORK_DIR/test_stdout_clean.txt" 2>/dev/null || true
grep -v "^libcob:" "$GOLDEN_DIR/golden_stdout.txt" > "$WORK_DIR/golden_stdout_clean.txt" 2>/dev/null || true

if cmp -s "$WORK_DIR/test_stdout_clean.txt" "$WORK_DIR/golden_stdout_clean.txt"; then
    echo "  PASS  STDOUT   (DISPLAY output)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  FAIL  STDOUT   (DISPLAY output mismatch)"
    diff "$WORK_DIR/golden_stdout_clean.txt" "$WORK_DIR/test_stdout_clean.txt" | head -40 || true
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

# ----------------------------------------------------------------
# Step 4: Summary
# ----------------------------------------------------------------
echo "[4/4] Results:"
echo "      PASS: $PASS_COUNT / $((PASS_COUNT + FAIL_COUNT))"
echo "      FAIL: $FAIL_COUNT / $((PASS_COUNT + FAIL_COUNT))"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "=== OVERALL: PASS ==="
    exit 0
else
    echo "=== OVERALL: FAIL ==="
    exit 1
fi
