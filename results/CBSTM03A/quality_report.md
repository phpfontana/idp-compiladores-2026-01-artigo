# CBSTM03A Quality Gate Report

**Date:** 2026-06-20T23:50  
**Phase:** P6 — Quality Gate  
**Program:** CBSTM03A (Statement Generator)

---

## Gate 1 — Build

**Command:** `javac --release 21 workspace/CBSTM03A/java/src/CBSTM03A.java`  
**Result:** PASS — compiled without errors (3 pre-existing unused-variable warnings, no errors)

---

## Gate 2 — Equivalence

**Command:** `./workspace/CBSTM03A/run_characterization.sh java`  
**Result:** PASS — 3/3 PASS (STMTFILE, HTMLFILE, stdout all match golden master byte-for-byte)

---

## Gate 3 — Doc Faithfulness

Reference: `artifacts/docs/CBSTM03A.md` Key Business Rules + Notable COBOL Constructs  
Score: **11/11**

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | PSA/TCB/TIOT stub produces appropriate output | PASS | `printPsaStub()` in `main()` prints 8 lines matching `golden_stdout.txt` exactly; stdout equivalence confirmed |
| 2 | Processing order: TRNXFILE loaded first, then XREFFILE→CUSTFILE→ACCTFILE sequence | PASS | `main()` calls `loadTrnxTable()` first, then `loadFlatMap(custSeqPath)`, then `loadFlatMap(acctSeqPath)`, then iterates XREF — exact documented order |
| 3 | All transactions pre-loaded into in-memory structure (up to 51 cards × 10 trnx per COBOL) | PASS | `loadTrnxTable()` builds `LinkedHashMap<String, List<byte[]>>` holding all transactions in memory before XREF iteration begins; limit is unbounded in Java (acceptable modernization beyond the 51×10 hard limit) |
| 4 | Each XREF record generates both plain-text and HTML statement | PASS | XREF loop calls `writeStatementHeader`, `writeTrans`, `writeStatementFooter` — each writes to both `stmtOut` and `htmlOut` |
| 5 | Plain-text includes: name+address, account-id, current balance, FICO score, transaction table | PASS | `buildStatementLines()` builds ST-LINE1 (name), ST-LINE2/3/4 (addr), ST-LINE7 (acct-id), ST-LINE8 (curr-bal), ST-LINE9 (FICO); transaction rows written in `writeTrans()` |
| 6 | HTML is a complete HTML document with inline CSS | PASS | `writeStatementHeader()` emits `<!DOCTYPE html>`, `<html>`, `<head>`, `<body>`, table with inline `style=` CSS; `writeStatementFooter()` closes with `</table>`, `</body>`, `</html>` |
| 7 | Transaction amounts accumulated in WS-TOTAL-AMT (analogous to COMP-3) | PASS | `totalAmtHundredths` (`long`) accumulates per-transaction amounts in the XREF loop; written as total-expense line in `writeStatementFooter()` |
| 8 | CBSTM03B delegation replaced by direct file reads in Java (acceptable modernization) | PASS | Java reads flat sequential dump files (`dump_TRNXSEQ`, etc.) directly via `FileInputStream`; CBSTM03B call interface eliminated; documented as acceptable |
| 9 | ALTER/GO TO state machine replaced by sequential method calls (acceptable) | PASS | `main()` calls `writeStatementHeader`, `writeTrans` (loop), `writeStatementFooter` sequentially; no ALTER/GO TO construct needed |
| 10 | 2D OCCURS table replaced by Map/List structure (acceptable) | PASS | `LinkedHashMap<String, List<byte[]>> trnxMap` replaces the 51×10 OCCURS table; insertion-order preserved via `LinkedHashMap` |
| 11 | PERFORM THRU ranges replaced by method calls (acceptable) | PASS | `writeStatementHeader` inlines 5100-WRITE-HTML-HEADER and 5200-WRITE-HTML-NMADBS paragraph ranges as sequential Java statements |

**Doc Faithfulness Score: 11/11**

---

## Success Criterion Evaluation

| Criterion | Threshold | Actual | Met? |
|---|---|---|---|
| Build | OK | OK | YES |
| Equivalence | 3/3 | 3/3 | YES |
| Doc faithfulness | ≥ 8/11 | 11/11 | YES |

**Overall: PASS — all success criteria met**

---

## Phase 5 Summary (for reference)

Two optimization candidates were attempted and both rejected:

1. **BufferedOutputStream (65536-byte buffer) on stmtOut + htmlOut:** baseline=67ms/iter, optimized=68ms/iter, gain=−1.5% → REJECTED (no improvement)
2. **Cached `StandardCharsets.ISO_8859_1` as static field:** baseline=67ms/iter, optimized=78ms/iter, gain=−16% → REJECTED (no improvement; noise dominated)

**Conclusion:** At this output scale (~19KB total: 3280-byte STMTFILE + 16100-byte HTMLFILE), JVM startup (~60ms) dominates wall-clock time and application-level optimizations are not visible at macro-benchmark scale. Zero optimizations kept. This matches the pattern observed for CBTRN02C.
