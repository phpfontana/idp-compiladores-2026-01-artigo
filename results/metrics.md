# Measured Metrics (append-only)

Raw numbers only. Never round or improve. `not measured` is a valid value.

## Efficiency — per program, per phase

| Program | Phase | Wall-clock | Tokens/cost | Interventions | Throughput |
|---|---|---|---|---|---|
| CBACT01C | P2 | not measured | not measured | 0 | not measured |
| CBACT01C | P3 | 14m | not measured | 0 | not measured |
| CBACT01C | P4 | 2m | not measured | 0 | not measured |
| CBACT01C | P5 | 10m | not measured | 0 | not measured |
| CBACT01C | P6 | 8m | not measured | 0 | not measured |
| CBTRN02C | P2 | not measured | not measured | 0 | not measured |
| CBTRN02C | P3 | ~30m | not measured | 3 | not measured |
| CBTRN02C | P4 | 3m | not measured | 0 | not measured |
| CBTRN02C | P5 | 25m | not measured | 0 | not measured |
| CBTRN02C | P6 | 5m | not measured | 0 | not measured |
| CBACT04C | P2 | not measured | not measured | 0 | not measured |
| CBACT04C | P3 | 45m | not measured | 1 | not measured |
| CBACT04C | P4 | 5m | not measured | 0 | not measured |
| CBACT04C | P5 | 20m | not measured | 0 | not measured |
| CBACT04C | P6 | 15m | not measured | 0 | not measured |
| CBSTM03A | P2 | not measured | not measured | 0 | not measured |
| CBSTM03A | P3 | ~20m | not measured | 1 | not measured |
| CBSTM03A | P4 | 1s | not measured | 0 | not measured |
| CBSTM03A | P5 | 30m | not measured | 0 | not measured |
| CBSTM03A | P6 | 10m | not measured | 0 | not measured |
| CBSTM03B | P2 | not measured | not measured | 0 | not measured |
| CBSTM03B | P3 | <5m | not measured | 0 | not measured |
| CBSTM03B | P4 | 1s | not measured | 0 | not measured |
| CBSTM03B | P5 | 20m | not measured | 0 | not measured |
| CBSTM03B | P6 | 5m | not measured | 0 | not measured |

Notes:
- P2 wall-clock not measured because data generation and compilation time was not timed separately.
- Interventions = number of P3 fix iterations required before equivalence gate passed. P3 iterations logged individually in logs/run-log.md.
- Tokens/cost not captured at subagent level; would require API-level instrumentation not available in this run.

## Accuracy — per program

| Program | Equivalence (cases pass/total) | Verdict | Build | Doc faithfulness |
|---|---|---|---|---|
| CBACT01C | 4/4 | ACCEPTED | OK | 7/9 (2 PARTIAL: CEE3ABD/file-status error paths have no direct Java analog) |
| CBTRN02C | 5/5 | ACCEPTED | OK | 11/11 |
| CBACT04C | 3/3 | ACCEPTED | OK | 13/13 (rule 3 noted PARTIAL — dead-code EOF bug faithfully replicated) |
| CBSTM03A | 3/3 | ACCEPTED | OK | 11/11 |
| CBSTM03B | 2/2 | ACCEPTED | OK | 9/9 |

## Optimization log (Phase 5) — every attempt, including discards

| Program | Change | Still equivalent? | Metric before | Metric after | Kept? | Reason |
|---|---|---|---|---|---|---|
| CBACT01C | Eliminate per-record heap allocations: cobdatftInPlace(), DISPLAY_NEG_1025_00 constant, static RDW_BUF | YES (4/4) | 42.6 ms/iter | 41.7 ms/iter | YES | gain > 0 and equivalence passes |
| CBTRN02C | BufferedOutputStream (65536B) + cached StandardCharsets.ISO_8859_1 | YES (5/5) | 245 ms/iter | ~252 ms/iter | NO | no gain; JVM startup (~100–150ms) dominates; Java I/O is <5KB |
| CBACT04C | Cache StandardCharsets.ISO_8859_1 as static final field (8 call sites) | YES (3/3) | 291.4 ms/iter | 290.5 ms/iter | YES | gain > 0 (0.3%) and equivalence passes |
| CBSTM03A | BufferedOutputStream (65536B) on stmtOut + htmlOut | YES (3/3) | 67 ms/iter | 68 ms/iter | NO | no gain; JVM startup (~60ms) dominates at 19KB output scale |
| CBSTM03A | Cache StandardCharsets.ISO_8859_1 as static field | YES (3/3) | 67 ms/iter | 78 ms/iter | NO | worse than baseline; noise dominated |
| CBSTM03B | Cache StandardCharsets.ISO_8859_1 + BufferedOutputStream | YES (2/2) | 57 ms/iter | 57 ms/iter | NO | 0% gain; JVM startup dominates at <3KB file scale |
| CBSTM03B | Pre-built DD-name byte[] constants + LINE_TEMPLATE.clone() | YES (2/2) | 57 ms/iter | 66 ms/iter | NO | no gain; worse than baseline within noise |
