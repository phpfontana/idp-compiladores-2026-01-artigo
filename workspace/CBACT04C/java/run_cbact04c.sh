#!/usr/bin/env bash
# run_cbact04c.sh
# Java runner for CBACT04C.
# Usage: ./run_cbact04c.sh <PARM-DATE>
# E.g.:  ./run_cbact04c.sh 2026-06-17
#
# Expects the following env vars already set (by run_characterization.sh):
#   TCATBALF  - path to indexed TCATBALF file
#   XREFFILE  - path to indexed XREFFILE
#   DISCGRP   - path to indexed DISCGRP file
#   ACCTFILE  - path to indexed ACCTFILE
#   TRANSACT  - path to output TRANSACT file
#
# This script:
#   1. Dumps indexed files to sequential using COBOL dump utilities
#   2. Runs Java CBACT04C with sequential files + PARM-DATE
#   3. Outputs:  $WORK_DIR/java_TRANSACT  (transaction output)
#                $WORK_DIR/java_ACCTSEQ   (account after-state)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PARM_DATE="${1:-2026-06-17}"

# Sequential dump paths
export TCATBALF_SEQ="$WORK_DIR/java_TCATBALF_SEQ"
export XREFFILE_SEQ="$WORK_DIR/java_XREFFILE_SEQ"
export DISCGRP_SEQ="$WORK_DIR/java_DISCGRP_SEQ"
export ACCTFILE_SEQ="$WORK_DIR/java_ACCTFILE_SEQ"
export TRANSACT="$WORK_DIR/java_TRANSACT"
export ACCTFILE_SEQ_OUT="$WORK_DIR/java_ACCTSEQ"

# Clean up old sequential files
rm -f "$TCATBALF_SEQ" "$XREFFILE_SEQ" "$DISCGRP_SEQ" "$ACCTFILE_SEQ"
rm -f "$TRANSACT" "$ACCTFILE_SEQ_OUT"

# Step 1: Dump indexed files to sequential
export COB_LIBRARY_PATH="$WORK_DIR"

# Dump TCATBALF
"$WORK_DIR/DUMPTCAT" 2>&1 >/dev/null
if [ $? -ne 0 ]; then echo "FAIL: DUMPTCAT"; exit 1; fi

# Dump XREFFILE
"$WORK_DIR/DUMPXREF" 2>&1 >/dev/null
if [ $? -ne 0 ]; then echo "FAIL: DUMPXREF"; exit 1; fi

# Dump DISCGRP
"$WORK_DIR/DUMPDISCGRP" 2>&1 >/dev/null
if [ $? -ne 0 ]; then echo "FAIL: DUMPDISCGRP"; exit 1; fi

# Dump ACCTFILE
export ACCTSEQ="$ACCTFILE_SEQ"
"$WORK_DIR/DUMPACCT" 2>&1 >/dev/null
if [ $? -ne 0 ]; then echo "FAIL: DUMPACCT"; exit 1; fi

# Step 2: Run Java CBACT04C
java -cp "$SCRIPT_DIR/out" CBACT04C "$PARM_DATE"
