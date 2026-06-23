#!/usr/bin/env bash
# run_cbtrn02c.sh
# Wrapper: dumps indexed files to sequential then runs Java CBTRN02C.
# Called by run_characterization.sh when a Java path is provided.
# Usage: ./java/run_cbtrn02c.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$WORK_DIR/../.." && pwd)"

cd "$WORK_DIR"

export COB_LIBRARY_PATH="$WORK_DIR/../CBACT01C"

# ---- Dump indexed input files to sequential for Java ----

# Dump XREFFILE -> XREFFILE_SEQ
export XREFFILE="$WORK_DIR/XREFFILE"
export XREFSEQ="$WORK_DIR/XREFFILE_SEQ"
"$WORK_DIR/DUMPXREF" > /dev/null 2>&1
# DUMPXREF uses XREFSEQ env var for output path

# Dump ACCTFILE -> ACCTFILE_SEQ (reuse DUMPACCT, output env = ACCTSEQ)
export ACCTFILE="$WORK_DIR/ACCTFILE"
export ACCTSEQ="$WORK_DIR/ACCTFILE_SEQ"
"$WORK_DIR/DUMPACCT" > /dev/null 2>&1

# Dump TCATBALF -> TCATBALF_SEQ (reuse DUMPTCAT, output env = TCATSEQ)
export TCATBALF="$WORK_DIR/TCATBALF"
export TCATSEQ="$WORK_DIR/TCATBALF_SEQ"
"$WORK_DIR/DUMPTCAT" > /dev/null 2>&1

# ---- Set environment for Java ----
export DALYTRAN="$WORK_DIR/DALYTRAN"
export XREFFILE_SEQ="$WORK_DIR/XREFFILE_SEQ"
export ACCTFILE_SEQ="$WORK_DIR/ACCTFILE_SEQ"
export TCATBALF_SEQ="$WORK_DIR/TCATBALF_SEQ"
export TRANFILE_SEQ="$WORK_DIR/java_TRNSEQ"
export DALYREJS="$WORK_DIR/DALYREJS"
export ACCTFILE_SEQ_OUT="$WORK_DIR/java_ACCTSEQ"
export TCATBALF_SEQ_OUT="$WORK_DIR/java_TCATSEQ"

# ---- Run Java CBTRN02C ----
java -cp "$SCRIPT_DIR/out" CBTRN02C "$@"
