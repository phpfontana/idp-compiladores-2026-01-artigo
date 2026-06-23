#!/usr/bin/env bash
# benchmark.sh - measure wall-clock time for N-iteration CBACT04C loop
WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$WORK_DIR"
export COB_LIBRARY_PATH="$WORK_DIR"

ITERS=${1:-100}

START=$(python3 -c "import time; print(int(time.time()*1000))")
for i in $(seq 1 "$ITERS"); do
  "$WORK_DIR/GENTCAT"    > /dev/null 2>&1
  "$WORK_DIR/GENXREF"    > /dev/null 2>&1
  "$WORK_DIR/GENDISCGRP" > /dev/null 2>&1
  "$WORK_DIR/GENACCT"    > /dev/null 2>&1
  bash "$WORK_DIR/run_characterization.sh" "$WORK_DIR/java/run_cbact04c.sh" > /dev/null 2>&1
done
END=$(python3 -c "import time; print(int(time.time()*1000))")

TOTAL=$((END - START))
python3 -c "print(f'iters=$ITERS total_ms=$TOTAL ms_per_iter={$TOTAL/$ITERS:.1f}')"
