#!/bin/bash
# run_characterization.sh — CBSTM03B Characterization Test
# Re-runnable: sets env vars pointing to indexed files in workspace/CBSTM03A/,
# runs CBSTM03B_DRIVER, compares OUTPUT and stdout against golden master.
# Exit 0 = all pass (2/2), Exit 1 = one or more fail.
#
# Usage:
#   ./run_characterization.sh          # COBOL mode (default)
#   ./run_characterization.sh java     # Java mode
#
# Prerequisites (COBOL mode):
#   - workspace/CBSTM03A/ data files must exist (run CBSTM03A/run_characterization.sh
#     first if they are absent, as it regenerates them)
#   - CBSTM03B_DRIVER and CBSTM03B.dylib must be present in this directory
#
# Prerequisites (java mode):
#   - workspace/CBSTM03A/ dump files (dump_TRNXSEQ, dump_XREFSEQ, dump_CUSTSEQ,
#     dump_ACCTSEQ) must exist
#   - java/src/CBSTM03B.java must be present

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CBSTM03A_DIR="${SCRIPT_DIR}/../CBSTM03A"
RESULTS_DIR="${SCRIPT_DIR}/../../results/CBSTM03B"
JAVA_SRC_DIR="${SCRIPT_DIR}/java/src"
JAVA_CLASS_DIR="${SCRIPT_DIR}/java"

MODE="${1:-cobol}"

echo "=== CBSTM03B Characterization Test (mode: ${MODE}) ==="
echo "Working directory: $SCRIPT_DIR"
echo ""

# ---- Shared comparison function ----
PASS=0
FAIL=0

compare_file() {
    local label="$1"
    local actual="$2"
    local golden="$3"

    if diff -q "$actual" "$golden" > /dev/null 2>&1; then
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $label"
        echo "    diff ${actual} vs ${golden}:"
        diff "$actual" "$golden" | head -20 || true
        FAIL=$((FAIL + 1))
    fi
}

# ==========================================================================
# COBOL mode
# ==========================================================================
if [ "$MODE" = "cobol" ]; then

    # ---- Step 1: Verify prerequisite data files exist ----
    echo "--- Checking prerequisite data files ---"
    for f in data_TRNXFILE data_XREFFILE data_CUSTFILE data_ACCTFILE; do
        if [ ! -f "${CBSTM03A_DIR}/${f}" ]; then
            echo "ERROR: Missing ${CBSTM03A_DIR}/${f}"
            echo "Run workspace/CBSTM03A/run_characterization.sh first to generate test data."
            exit 1
        fi
        echo "  Found: ${CBSTM03A_DIR}/${f}"
    done
    echo ""

    # ---- Step 2: Set environment variables ----
    export TRNXFILE="${CBSTM03A_DIR}/data_TRNXFILE"
    export XREFFILE="${CBSTM03A_DIR}/data_XREFFILE"
    export CUSTFILE="${CBSTM03A_DIR}/data_CUSTFILE"
    export ACCTFILE="${CBSTM03A_DIR}/data_ACCTFILE"
    export DRVOUTPUT="${SCRIPT_DIR}/test_OUTPUT"
    export COB_LIBRARY_PATH="${SCRIPT_DIR}"

    # ---- Step 3: Run driver ----
    echo "--- Running CBSTM03B_DRIVER ---"
    rm -f "${SCRIPT_DIR}/test_OUTPUT" "${SCRIPT_DIR}/test_stdout.txt"

    cd "$SCRIPT_DIR"
    ./CBSTM03B_DRIVER > "${SCRIPT_DIR}/test_stdout.txt" 2>&1
    RUN_RC=$?

    if [ $RUN_RC -ne 0 ]; then
        echo "ERROR: CBSTM03B_DRIVER exited with code $RUN_RC"
        cat "${SCRIPT_DIR}/test_stdout.txt"
        exit 1
    fi

    echo "  CBSTM03B_DRIVER completed (exit 0)"
    echo "  test_OUTPUT:    $(wc -c < "${SCRIPT_DIR}/test_OUTPUT") bytes"
    echo "  test_stdout.txt: $(wc -l < "${SCRIPT_DIR}/test_stdout.txt") lines"
    echo ""

    # ---- Step 4: Compare against golden master ----
    echo "--- Comparing against golden master ---"
    compare_file "test_OUTPUT"     "${SCRIPT_DIR}/test_OUTPUT"     "${RESULTS_DIR}/golden_OUTPUT"
    compare_file "test_stdout.txt" "${SCRIPT_DIR}/test_stdout.txt" "${RESULTS_DIR}/golden_stdout.txt"

# ==========================================================================
# Java mode
# ==========================================================================
elif [ "$MODE" = "java" ]; then

    # ---- Step 1: Verify prerequisite dump files exist ----
    echo "--- Checking prerequisite dump files ---"
    for f in dump_TRNXSEQ dump_XREFSEQ dump_CUSTSEQ dump_ACCTSEQ; do
        if [ ! -f "${CBSTM03A_DIR}/${f}" ]; then
            echo "ERROR: Missing ${CBSTM03A_DIR}/${f}"
            echo "Run workspace/CBSTM03A/run_characterization.sh first to generate dump files."
            exit 1
        fi
        echo "  Found: ${CBSTM03A_DIR}/${f}"
    done
    echo ""

    # ---- Step 2: Compile Java if needed ----
    JAVA_CLASS="${JAVA_CLASS_DIR}/CBSTM03B.class"
    if [ ! -f "$JAVA_CLASS" ] || [ "${JAVA_SRC_DIR}/CBSTM03B.java" -nt "$JAVA_CLASS" ]; then
        echo "--- Compiling CBSTM03B.java ---"
        javac -source 21 -target 21 "${JAVA_SRC_DIR}/CBSTM03B.java" -d "${JAVA_CLASS_DIR}"
        echo "  Compilation OK"
        echo ""
    else
        echo "--- CBSTM03B.class is up to date ---"
        echo ""
    fi

    # ---- Step 3: Run Java driver ----
    echo "--- Running CBSTM03B (Java) ---"
    TEST_OUTPUT="${SCRIPT_DIR}/test_OUTPUT_java"
    TEST_STDOUT="${SCRIPT_DIR}/test_stdout_java.txt"
    rm -f "$TEST_OUTPUT" "$TEST_STDOUT"

    java -cp "${JAVA_CLASS_DIR}" CBSTM03B \
        "${CBSTM03A_DIR}/dump_TRNXSEQ" \
        "${CBSTM03A_DIR}/dump_XREFSEQ" \
        "${CBSTM03A_DIR}/dump_CUSTSEQ" \
        "${CBSTM03A_DIR}/dump_ACCTSEQ" \
        "$TEST_OUTPUT" > "$TEST_STDOUT" 2>&1
    RUN_RC=$?

    if [ $RUN_RC -ne 0 ]; then
        echo "ERROR: CBSTM03B (Java) exited with code $RUN_RC"
        cat "$TEST_STDOUT"
        exit 1
    fi

    echo "  CBSTM03B (Java) completed (exit 0)"
    echo "  test_OUTPUT_java:    $(wc -c < "${TEST_OUTPUT}") bytes"
    echo "  test_stdout_java.txt: $(wc -l < "${TEST_STDOUT}") lines"
    echo ""

    # ---- Step 4: Compare against golden master ----
    echo "--- Comparing against golden master ---"
    compare_file "test_OUTPUT_java"     "$TEST_OUTPUT" "${RESULTS_DIR}/golden_OUTPUT"
    compare_file "test_stdout_java.txt" "$TEST_STDOUT" "${RESULTS_DIR}/golden_stdout.txt"

else
    echo "ERROR: Unknown mode '$MODE'. Use 'cobol' or 'java'."
    exit 1
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
