#!/bin/bash
# run_characterization.sh — CBSTM03A Characterization Test
# Re-runnable: regenerates test data, runs CBSTM03A (COBOL or Java), compares against golden master
# Exit 0 = all pass, Exit 1 = one or more fail
#
# Usage:
#   ./run_characterization.sh          — run COBOL version (default)
#   ./run_characterization.sh cobol    — run COBOL version
#   ./run_characterization.sh java     — run Java version

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/../../results/CBSTM03A"

cd "$SCRIPT_DIR"

MODE="${1:-cobol}"

echo "=== CBSTM03A Characterization Test (mode: $MODE) ==="
echo "Working directory: $SCRIPT_DIR"
echo ""

# ---- Step 1: Generate indexed data files ----
echo "--- Generating test data ---"

export TRNXFILE="${SCRIPT_DIR}/data_TRNXFILE"
export XREFFILE="${SCRIPT_DIR}/data_XREFFILE"
export CUSTFILE="${SCRIPT_DIR}/data_CUSTFILE"
export ACCTFILE="${SCRIPT_DIR}/data_ACCTFILE"

# Remove old data files if present
rm -f "$TRNXFILE" "$XREFFILE" "$CUSTFILE" "$ACCTFILE"

./GENTRNX
echo "  TRNX data generated: $TRNXFILE"
./GENXREF
echo "  XREF data generated: $XREFFILE"
./GENCUST
echo "  CUST data generated: $CUSTFILE"
./GENACCT
echo "  ACCT data generated: $ACCTFILE"

echo ""

# ---- Step 2: Run CBSTM03A (COBOL or Java) ----
PASS=0
FAIL=0

compare_file() {
    local label="$1"
    local test_file="$2"
    local golden_file="$3"

    if [ ! -f "$golden_file" ]; then
        echo "  SKIP: $label — no golden master at $golden_file"
        return
    fi
    if [ ! -f "$test_file" ]; then
        echo "  FAIL: $label — test file not found: $test_file"
        FAIL=$((FAIL + 1))
        return
    fi

    if cmp -s "$test_file" "$golden_file"; then
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $label"
        echo "        Test:   $(wc -c < "$test_file") bytes  sha256=$(sha256sum "$test_file" | cut -d' ' -f1)"
        echo "        Golden: $(wc -c < "$golden_file") bytes  sha256=$(sha256sum "$golden_file" | cut -d' ' -f1)"
        # Show first difference
        diff <(xxd "$test_file" | head -20) <(xxd "$golden_file" | head -20) | head -20 || true
        FAIL=$((FAIL + 1))
    fi
}

if [ "$MODE" = "java" ]; then
    echo "--- Running Java CBSTM03A ---"

    TEST_STMTFILE="${SCRIPT_DIR}/test_STMTFILE_java"
    TEST_HTMLFILE="${SCRIPT_DIR}/test_HTMLFILE_java"
    TEST_STDOUT="${SCRIPT_DIR}/test_stdout_java.txt"

    rm -f "$TEST_STMTFILE" "$TEST_HTMLFILE" "$TEST_STDOUT"

    # run_cbstm03a.sh uses TRNXFILE/XREFFILE/CUSTFILE/ACCTFILE already exported above
    bash "${SCRIPT_DIR}/java/run_cbstm03a.sh" "$TEST_STMTFILE" "$TEST_HTMLFILE" \
        > "$TEST_STDOUT" 2>&1
    RC=$?

    if [ $RC -ne 0 ]; then
        echo "ERROR: Java CBSTM03A exited with code $RC"
        cat "$TEST_STDOUT"
        exit 1
    fi

    echo "  Java CBSTM03A completed (exit 0)"
    echo "  stdout: $(wc -c < "$TEST_STDOUT") bytes"
    echo "  STMTFILE: $(wc -c < "$TEST_STMTFILE") bytes"
    echo "  HTMLFILE: $(wc -c < "$TEST_HTMLFILE") bytes"

    # The Java program prints its PSA stub to stdout itself; the run script wraps it.
    # Extract just the CBSTM03A stdout (lines printed by the Java program).
    # run_cbstm03a.sh also emits "--- Running dump ---" etc. lines.
    # We need only the lines from the Java program itself.
    # Strategy: run Java directly to capture clean stdout.
    rm -f "$TEST_STDOUT"
    java -cp "${SCRIPT_DIR}/java" CBSTM03A \
        "${SCRIPT_DIR}/dump_TRNXSEQ" \
        "${SCRIPT_DIR}/dump_XREFSEQ" \
        "${SCRIPT_DIR}/dump_CUSTSEQ" \
        "${SCRIPT_DIR}/dump_ACCTSEQ" \
        "$TEST_STMTFILE" "$TEST_HTMLFILE" \
        > "$TEST_STDOUT" 2>&1

    echo ""
    echo "--- Comparing against golden master ---"
    compare_file "STMTFILE" "$TEST_STMTFILE"  "${RESULTS_DIR}/golden_STMTFILE"
    compare_file "HTMLFILE" "$TEST_HTMLFILE"  "${RESULTS_DIR}/golden_HTMLFILE"
    compare_file "stdout"   "$TEST_STDOUT"    "${RESULTS_DIR}/golden_stdout.txt"

else
    # COBOL mode (default)
    echo "--- Running COBOL CBSTM03A ---"

    export COB_LIBRARY_PATH="${SCRIPT_DIR}"
    export STMTFILE="${SCRIPT_DIR}/test_STMTFILE"
    export HTMLFILE="${SCRIPT_DIR}/test_HTMLFILE"

    rm -f "$STMTFILE" "$HTMLFILE" "${SCRIPT_DIR}/test_stdout.txt"

    ./CBSTM03A > "${SCRIPT_DIR}/test_stdout.txt" 2>&1
    RC=$?

    if [ $RC -ne 0 ]; then
        echo "ERROR: CBSTM03A exited with code $RC"
        cat "${SCRIPT_DIR}/test_stdout.txt"
        exit 1
    fi

    echo "  CBSTM03A completed (exit 0)"
    echo "  stdout: $(wc -c < "${SCRIPT_DIR}/test_stdout.txt") bytes"
    echo "  STMTFILE: $(wc -c < "$STMTFILE") bytes"
    echo "  HTMLFILE: $(wc -c < "$HTMLFILE") bytes"

    echo ""
    echo "--- Comparing against golden master ---"
    compare_file "STMTFILE" "${SCRIPT_DIR}/test_STMTFILE"    "${RESULTS_DIR}/golden_STMTFILE"
    compare_file "HTMLFILE" "${SCRIPT_DIR}/test_HTMLFILE"    "${RESULTS_DIR}/golden_HTMLFILE"
    compare_file "stdout"   "${SCRIPT_DIR}/test_stdout.txt"  "${RESULTS_DIR}/golden_stdout.txt"
fi

# ---- Summary ----
echo ""
TOTAL=$((PASS + FAIL))
echo "=== Result: ${PASS}/${TOTAL} PASS ==="

if [ $FAIL -eq 0 ]; then
    echo "ALL PASS"
    exit 0
else
    echo "FAIL (${FAIL} comparison(s) failed)"
    exit 1
fi
