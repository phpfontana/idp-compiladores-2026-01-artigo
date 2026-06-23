#!/usr/bin/env bash
# benchmark.sh - time N iterations of CBTRN02C Java run
# Usage: bash benchmark.sh [N] [java_runner]
# Defaults: N=100, java_runner=./java/run_cbtrn02c.sh

set -e

WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$WORK_DIR"

N="${1:-100}"
RUNNER="${2:-./java/run_cbtrn02c.sh}"

export COB_LIBRARY_PATH="$WORK_DIR/../CBACT01C"

echo "Benchmarking $N iterations of: bash run_characterization.sh $RUNNER"
echo "Start: $(date)"

START_MS=$(($(date +%s) * 1000 + $(date +%N | cut -c1-3)))

for i in $(seq 1 "$N"); do
    ./GENXREF > /dev/null 2>&1
    ./GENACCT > /dev/null 2>&1
    ./GENTCAT > /dev/null 2>&1
    ./GENDALY > /dev/null 2>&1
    bash run_characterization.sh "$RUNNER" > /dev/null 2>&1 || true
done

END_MS=$(($(date +%s) * 1000 + $(date +%N | cut -c1-3)))
TOTAL_MS=$((END_MS - START_MS))
PER_ITER_MS=$((TOTAL_MS / N))

echo "End: $(date)"
echo "Total: ${TOTAL_MS} ms"
echo "Per iteration: ${PER_ITER_MS} ms"
echo "N=$N"
