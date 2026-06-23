# CBSTM03B Quality Report

**Date:** 2026-06-20  
**Phase 5 (Optimization) + Phase 6 (Quality Gate)**

---

## Phase 5 — Optimization

### Baseline
- 10-run measurement: 572ms total, **57ms/run average**
- Equivalence: 2/2 PASS (confirmed before optimization attempts)

### Candidate 1: cached charset constant + BufferedOutputStream
- Change: extracted `StandardCharsets.ISO_8859_1` into a `static final LATIN1` field; wrapped `FileOutputStream` in `BufferedOutputStream`
- Measured: 579ms total, **57ms/run average**
- Equivalence: 2/2 PASS
- Performance gate: FAIL (0% gain, within noise)
- Decision: REVERTED

### Candidate 2: pre-built DD-name byte[] constants + LINE_TEMPLATE clone
- Change: replaced per-call `paddedAscii(String, int)` with static `byte[]` fields for each DD name; replaced `new byte[80] + Arrays.fill` with `LINE_TEMPLATE.clone()`
- Measured: 665ms total, **66ms/run average**
- Equivalence: 2/2 PASS
- Performance gate: FAIL (no gain; +9ms vs baseline, within JVM startup noise)
- Decision: REVERTED

### P5 Conclusion
Both candidates passed equivalence but failed the performance gate. The program is JVM-startup-dominated (~50-55ms of the ~57ms wall-clock is JVM initialization). The actual computation — 19 I/O calls over files totalling ~2.75KB — completes in microseconds. No source-level optimization can overcome JVM startup cost at this scale. No optimizations kept. Source restored to baseline.

**P5 result:** baseline=57ms/iter, optimized=not measured (no candidate kept), gain=0%, kept=none

---

## Phase 6 — Quality Gate

### Build
```
javac --release 21 workspace/CBSTM03B/java/src/CBSTM03B.java
```
Result: **OK** (no errors, no warnings)

### Equivalence
```
./workspace/CBSTM03B/run_characterization.sh java
```
Result: **2/2 PASS**
- test_OUTPUT_java: PASS (1520 bytes matches golden_OUTPUT)
- test_stdout_java.txt: PASS (19 lines matches golden_stdout.txt)

### Doc Faithfulness (9 items scored against artifacts/docs/CBSTM03B.md)

| # | Item | Result | Notes |
|---|---|---|---|
| 1 | Operation codes O/C/R/K handled; W/Z noted as not exercised | PASS | trnxOpen/Close/Read, xrefOpen/Close/Read, custOpen/Close/Key, acctOpen/Close/Key all present |
| 2 | All 4 files dispatched correctly (TRNXFILE, XREFFILE, CUSTFILE, ACCTFILE) | PASS | Each file has dedicated methods |
| 3 | Return codes '00', '10', '04' produced correctly | PASS | RC_OK="00", RC_EOF="10" used; '04' open-warning is COBOL/VSAM-only and correctly omitted (normal-path opens return '00') |
| 4 | Sequential read behavior for TRNXFILE and XREFFILE | PASS | trnxData/trnxPos and xrefData/xrefPos implement sequential scan |
| 5 | Random (key) read behavior for CUSTFILE and ACCTFILE | PASS | custMap (9-byte key) and acctMap (11-byte key) implement keyed lookup |
| 6 | Control area structure mirrored (DD name, oper, RC, key, key-len, data area) | PASS | writeLine(dd, oper, rc, fldt, showFldt) covers all fields; key/key-len collapsed into direct string args (acceptable modernization) |
| 7 | LINKAGE SECTION pattern replaced by method/class interface | PASS | LK-M03B-AREA group item replaced by method parameters + instance fields |
| 8 | File status propagation to RC field (TRNXFILE-STATUS → LK-M03B-RC) | PASS | RC strings "00", "10", "23" passed directly to writeLine and written to output |
| 9 | No write operations exercised in test (W/Z) | PASS | 19-call driver sequence uses only O/C/R/K; W/Z absent, consistent with doc |

**Doc faithfulness score: 9/9**

### Success Criterion Evaluation
- Build: OK
- Equivalence: 2/2 PASS
- Doc faithfulness: 9/9 (threshold: 7/9)

**Overall: PASS — all gates MET**
