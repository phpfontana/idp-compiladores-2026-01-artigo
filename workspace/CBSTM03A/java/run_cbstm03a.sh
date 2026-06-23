#!/bin/bash
# run_cbstm03a.sh — compile and run CBSTM03A Java translation
#
# Usage: run_cbstm03a.sh <STMTFILE_OUT> <HTMLFILE_OUT>
#
# Environment variables required (set by caller):
#   TRNXFILE  — path to indexed TRNXFILE (BDB)
#   XREFFILE  — path to indexed XREFFILE (BDB)
#   CUSTFILE  — path to indexed CUSTFILE (BDB)
#   ACCTFILE  — path to indexed ACCTFILE (BDB)
#
# The script will run dump programs to create flat sequential files,
# then compile and run the Java translation.

set -euo pipefail

JAVA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(cd "$JAVA_DIR/.." && pwd)"

STMTFILE_OUT="${1:-${WORK_DIR}/test_STMTFILE_java}"
HTMLFILE_OUT="${2:-${WORK_DIR}/test_HTMLFILE_java}"

# Flat sequential dump files
TRNXSEQ="${WORK_DIR}/dump_TRNXSEQ"
XREFSEQ="${WORK_DIR}/dump_XREFSEQ"
CUSTSEQ="${WORK_DIR}/dump_CUSTSEQ"
ACCTSEQ="${WORK_DIR}/dump_ACCTSEQ"

# Export for dump programs
export TRNXSEQ XREFSEQ CUSTSEQ ACCTSEQ

echo "--- Running dump programs ---"
cd "$WORK_DIR"
"${WORK_DIR}/DUMPTRNX"
echo "  TRNXSEQ written: $(wc -c < "$TRNXSEQ") bytes"
"${WORK_DIR}/DUMPXREF"
echo "  XREFSEQ written: $(wc -c < "$XREFSEQ") bytes"
"${WORK_DIR}/DUMPCUST"
echo "  CUSTSEQ written: $(wc -c < "$CUSTSEQ") bytes"
"${WORK_DIR}/DUMPACCT"
echo "  ACCTSEQ written: $(wc -c < "$ACCTSEQ") bytes"

echo "--- Compiling Java ---"
javac --release 21 -d "${JAVA_DIR}" "${JAVA_DIR}/src/CBSTM03A.java"
echo "  Compilation OK"

echo "--- Running Java CBSTM03A ---"
java -cp "${JAVA_DIR}" CBSTM03A \
    "$TRNXSEQ" "$XREFSEQ" "$CUSTSEQ" "$ACCTSEQ" \
    "$STMTFILE_OUT" "$HTMLFILE_OUT"

echo "  STMTFILE: $(wc -c < "$STMTFILE_OUT") bytes -> $STMTFILE_OUT"
echo "  HTMLFILE: $(wc -c < "$HTMLFILE_OUT") bytes -> $HTMLFILE_OUT"
