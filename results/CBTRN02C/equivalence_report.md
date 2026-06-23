# CBTRN02C Equivalence Verification Report

**Date:** 2026-06-17T21:44  
**Phase:** P4 – Equivalence Verification  
**Verifier:** equivalence-verifier (read-only; no Java edits made)

---

## Environment

| Item | Value |
|---|---|
| OS | Darwin 24.6.0 (macOS, ARM64) |
| Java | OpenJDK 21.0.11 LTS (HotSpot 64-Bit Server VM) |
| GnuCOBOL | 3.2.0 (-std=ibm) |
| Shell | zsh / bash |
| Python | system python3 (mask script) |

---

## Test Command

```bash
cd /Users/fontana/Desktop/idp-compiladores-2026-01-av02/workspace/CBTRN02C
bash run_characterization.sh ./java/run_cbtrn02c.sh
```

---

## Full Test Output

```
=== CBTRN02C Characterization Test ===
Project root: /Users/fontana/Desktop/idp-compiladores-2026-01-av02
Working dir:  /Users/fontana/Desktop/idp-compiladores-2026-01-av02/workspace/CBTRN02C
Golden dir:   /Users/fontana/Desktop/idp-compiladores-2026-01-av02/results/CBTRN02C

[1/5] Regenerating test data...
XREF1: 4000002000000000 -> 00000000001
XREF2: 4000002000000001 -> 00000000002
XREF3: 4000002000000002 -> 00000000003
XREF4: 4000002000000003 -> 00000000004
XREF5: 4000002000000099 -> 00000000099 (missing)
GENXREF COMPLETE: 5 records written
ACCT1: id=00000000001 limit=1000 cr=200
ACCT2: id=00000000002 limit=2000 cr=0
ACCT3: id=00000000003 limit=1000 cr=990 (overlimit)
ACCT4: id=00000000004 expiry=2020-01-01 (expired)
GENACCT COMPLETE: 4 records written
TCAT1: ACCT=00000000002 CR/0001 BAL=100.00
GENTCAT COMPLETE: 1 record written
TRN01: ACCEPT card=4000002000000000 +50.00
TRN02: ACCEPT card=4000002000000001 +75.00
TRN03: REJECT100 card=9999999999999999
TRN04: REJECT101 card=4000002000000099
TRN05: REJECT102 card=4000002000000002 overlimit
TRN06: REJECT103 card=4000002000000003 expired
TRN07: ACCEPT card=4000002000000001 +100.00
GENDALY COMPLETE: 7 records written
      Input files generated.

[2/5] Running Java program: ./java/run_cbtrn02c.sh
      Exit code: 4
START OF EXECUTION OF PROGRAM CBTRN02C
TCATBAL record not found for key : 00000000001CR0001.. Creating.
TRANSACTIONS PROCESSED :000000007
TRANSACTIONS REJECTED  :000000004
END OF EXECUTION OF PROGRAM CBTRN02C

[3/5] Dumping indexed files to sequential...
      (Java path: using Java output files directly)

[4/5] Masking TRAN-PROC-TS in TRANFILE dump...
  Masked 3 record(s) in TRNSEQ

[5/5] Comparing outputs against golden master...
  PASS  DALYREJS (reject file, deterministic)
  PASS  TRNSEQ masked (accepted txns, PROC-TS zeroed)
  PASS  ACCTSEQ (account after-state)
  PASS  TCATSEQ (tcatbal after-state)
  PASS  STDOUT   (DISPLAY output)

Results: PASS=5 FAIL=0 / 5

=== OVERALL: PASS ===
```

**Program exit code:** 4 (expected — rejections present per CBTRN02C spec)

---

## Construct-Level Fidelity Table

| Construct | Expected | Java handles? |
|---|---|---|
| Sequential file read (DALYTRAN) | 350-byte records, read to EOF | YES — `FileInputStream.readNBytes(rec, 0, 350)` loop terminates on short read |
| Indexed random access (XREFFILE) | load → Map, key lookup by card-num | YES — `LinkedHashMap<String, byte[]>` keyed on 16-char card number |
| Indexed I/O (ACCOUNT-FILE REWRITE) | read-modify-write in place | YES — `LinkedHashMap` holds mutable byte arrays; modified in-place, written out in original insertion order |
| Indexed I/O (TCATBAL-FILE create/rewrite) | TreeMap, write-on-exit | YES — `TreeMap<String, byte[]>` keyed on 17-char composite (acctId+type+cat); new records inserted on create-path; all written on exit |
| Validation reason codes 100–103 | sequential checks, last wins | YES — card-not-found (100) and acct-not-found (101) short-circuit; within-account, credit-limit (102) and expiry (103) both run in sequence with last failure taking precedence |
| Credit-limit check (COMPUTE signed) | `cycCredit - cycDebit + dalytranAmt <= creditLimit` | YES — long arithmetic in hundredths (cents); mirrors COBOL COMPUTE exactly |
| Account balance update | ADD amt to CURR-BAL; ADD to CYC-CREDIT or CYC-DEBIT depending on sign | YES — `currBal += dalytranAmt`; positive → CYC-CREDIT, negative → CYC-DEBIT |
| DB2 timestamp (FUNCTION CURRENT-DATE) | LocalDateTime, masked in test | YES — `getDb2Timestamp()` uses `LocalDateTime.now()`; TRAN-PROC-TS field (bytes 304–329) zeroed in both test and golden before comparison |
| INITIALIZE semantics (FILLER stays 0x00) | byte[] default zero; alphanumeric fields initialized to spaces only for named fields | YES — `new byte[TCAT_LEN]` is all 0x00; only named fields written; FILLER X(22) remains 0x00 |
| Reject record (350+80 bytes) | DALYTRAN copy (350) + reason-code 9(4) + desc X(76) = 430 bytes | YES — `REJS_LEN=430`; full DALYTRAN copied to `RJ_TRAN_DATA`; reason at offset 350 (4 bytes), desc at 354 (76 bytes) |
| Exit code 4 on rejections | `System.exit(4)` when `wsRejectCount > 0` | YES — confirmed: exit code 4 observed; characterization test accepts 0 or 4 |

---

## Test Result Summary

| Output file | Golden comparison | Result |
|---|---|---|
| DALYREJS (reject file) | byte-for-byte | PASS |
| TRNSEQ masked (accepted txns, PROC-TS zeroed) | byte-for-byte | PASS |
| ACCTSEQ (account after-state) | byte-for-byte | PASS |
| TCATSEQ (tcatbal after-state) | byte-for-byte | PASS |
| STDOUT (DISPLAY output) | text match (libcob lines stripped) | PASS |

**Score: 5/5**

---

## Verdict

**ACCEPTED**

All 5 output comparisons pass byte-for-byte against the COBOL golden master.
The Java translation of CBTRN02C faithfully reproduces the behavior of the
original COBOL program across all tested constructs and data scenarios.

---

## Phase 5 – Optimization

**Date:** 2026-06-17T21:52  
**Agent:** optimizer

### Benchmark methodology

100-iteration shell loop timing full Java run per iteration (includes regenerating
all input files via GENXREF/GENACCT/GENTCAT/GENDALY + COBOL DUMP programs + Java
`CBTRN02C` + masking + file comparison). Run on Darwin 24.6.0 (Apple ARM64).

### Baseline measurement

| Run | Total (ms) | Per iteration (ms) |
|---|---|---|
| Run 1 | 24517 | 245 |

Baseline: **245 ms/iter**

### Candidate optimization: BufferedOutputStream + cached Charset

**Rationale:** `FileOutputStream.write(byte[])` issues one `write(2)` syscall per
invocation. Wrapping with `BufferedOutputStream(65536)` coalesces writes. Also
cached `StandardCharsets.ISO_8859_1` as a static field to eliminate repeated
charset lookups in `putString` / `getString`.

**Result after applying:**

| Run | Total (ms) | Per iteration (ms) |
|---|---|---|
| Run 1 | 24792 | 247 |
| Run 2 | 26046 | 260 |
| Run 3 | 24993 | 249 |

Optimized average: ~252 ms/iter

**Equivalence:** 5/5 PASS (confirmed while optimization was applied)

**Gain:** 0% (within measurement noise of ±10%). No statistically meaningful
improvement. Root cause: the dominant cost per iteration is JVM startup (~100–150 ms
per `java` invocation) plus COBOL GEN/DUMP program overhead. The Java I/O path
processes only 7 transactions and writes files totalling < 5 KB — buffering
provides no measurable benefit at this scale.

**Decision: REVERTED.** Gain ≤ 0 per the equivalence-gate rule. Java source
restored to pre-optimization state and recompiled. Post-revert equivalence: 5/5 PASS.

### Phase 5 summary

| Metric | Value |
|---|---|
| Baseline | 245 ms/iter (100 iterations) |
| Candidates attempted | 1 (BufferedOutputStream + cached charset) |
| Candidates kept | 0 |
| Final optimized time | not measured (no candidate kept) |
| Net gain | 0% |
| Equivalence after P5 | 5/5 PASS |
