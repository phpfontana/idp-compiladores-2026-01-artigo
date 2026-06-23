#!/usr/bin/env bash
# run_cbact01c.sh – wrapper for CBACT01C Java translation.
#
# Decision: use DUMPSEQ.cbl to export the BDB-indexed ACCTFILE to a flat
# 300-byte-per-record sequential file (ACCTSEQ), then feed that to Java.
# This avoids any BDB/JNI dependency in the Java program.
#
# Environment variables used by run_characterization.sh:
#   ACCTFILE  – path to the BDB indexed file (set by the harness)
#   OUTFILE   – destination flat file
#   ARRYFILE  – destination array file
#   VBRCFILE  – destination variable-length file
#
# This script runs from workspace/CBACT01C/ (set by run_characterization.sh).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Step 1: dump BDB ACCTFILE -> flat ACCTSEQ
ACCTSEQ="$WORK_DIR/ACCTSEQ"
export ACCTSEQ
(cd "$WORK_DIR" && ./DUMPSEQ) >/dev/null 2>&1

# Step 2: run Java, using the sequential dump as input
export ACCTFILE_SEQ="$ACCTSEQ"
java -cp "$SCRIPT_DIR/out" CBACT01C "$@"
