# CBACT04C Equivalence Report — Phase 4

**Date:** 2026-06-18  
**Verifier:** equivalence-verifier subagent  
**Java source (read-only):** `workspace/CBACT04C/java/src/CBACT04C.java`  
**Test command:**
```
cd workspace/CBACT04C
bash run_characterization.sh ./java/run_cbact04c.sh
```

---

## Environment

| Item | Value |
|---|---|
| Platform | macOS Darwin 24.6.0 |
| Java | system java (via `java -cp workspace/CBACT04C/java/out CBACT04C`) |
| GnuCOBOL (dump utilities) | 3.2.0 (-std=ibm) |
| PARM-DATE | 2026-06-17 |
| Golden master | `results/CBACT04C/golden_TRANSACT_masked`, `golden_ACCTSEQ`, `golden_stdout.txt` |

---

## Full Test Output

```
=== CBACT04C Characterization Test ===
Project root: /Users/fontana/Desktop/idp-compiladores-2026-01-av02
Working dir:  /Users/fontana/Desktop/idp-compiladores-2026-01-av02/workspace/CBACT04C
Golden dir:   /Users/fontana/Desktop/idp-compiladores-2026-01-av02/results/CBACT04C
Run date:     2026-06-17

[1/4] Regenerating test data...
TCAT1: ACCT=00000000001 CR/0001 BAL=1000.00
TCAT2: ACCT=00000000001 DB/0002 BAL=500.00
TCAT3: ACCT=00000000002 CR/0001 BAL=2000.00
TCAT4: ACCT=2 DR/0003 BAL=300.00 fallback
GENTCAT COMPLETE: 4 records written
XREF1: 4000002000000001 -> 00000000001
XREF2: 4000002000000002 -> 00000000002
GENXREF COMPLETE: 2 records written
DISCGRP1: DEFAULT    DR/0003 RATE=18.00%
DISCGRP2: GRP0000001 CR/0001 RATE=12.00%
DISCGRP3: GRP0000001 DB/0002 RATE=6.00%
GENDISCGRP COMPLETE: 3 records written
GENACCT: wrote ACCT=1 BAL=5000.00 GRP=GRP0000001
GENACCT: wrote ACCT=2 BAL=8000.00 GRP=GRP0000001
GENACCT COMPLETE: 2 records written
      Input files generated.

[2/4] Running Java program: ./java/run_cbact04c.sh with date 2026-06-17
      Exit code: 0
START OF EXECUTION OF PROGRAM CBACT04C
00000000001CR000100000100000                      
00000000001DB000200000050000                      
00000000002CR000100000200000                      
00000000002DR000300000030000                      
DISCLOSURE GROUP RECORD MISSING
TRY WITH DEFAULT GROUP CODE
END OF EXECUTION OF PROGRAM CBACT04C

[3/4] Dumping ACCTFILE to sequential...
      (Java path: using Java output files directly)

[4/4] Masking timestamps in TRANSACT...
  Masked 4 record(s): TRAN-ORIG-TS[278:304] and TRAN-PROC-TS[304:330] zeroed

[5/4] Comparing outputs against golden master...
  PASS  TRANSACT masked (both timestamps zeroed)
  PASS  ACCTSEQ (account after-state)
  PASS  STDOUT   (DISPLAY output)

Results: PASS=3 FAIL=0 / 3

=== OVERALL: PASS ===
```

---

## Construct-Level Fidelity Table

| Construct | Expected | Java handles? |
|---|---|---|
| Sequential TCATBALF read grouped by account | Read 50-byte records, group by ACCT-ID (11 bytes at offset 0) | YES — `loadSequentialFile(path, 50)` reads fixed-width records; grouping done via `wsLastAcctNum` comparison |
| DISCGRP fallback ('DEFAULT' group) | Retry with 'DEFAULT   ' (10 chars) on status 23 (not found) | YES — `perform1200GetInterestRate` retries with `"DEFAULT   " + tranTypeCd + tranCatCd` key; prints exact COBOL messages |
| Interest formula (truncation toward zero) | `(bal_hundredths * rate_hundredths) / (1200 * 100)` — Java integer division truncates toward zero | YES — `(tranCatBalHundredths * disIntRateHundredths) / (1200L * 100L)` — all positive in test data; integer division matches COBOL COMPUTE truncation |
| Dead-code EOF bug (last account not posted) | No ACCTFILE REWRITE after last record; account 2 retains original BAL=8000.00, CYC-CREDIT=200.00, CYC-DEBIT=80.00 | YES — `perform1050UpdateAccount` is never called after EOF; only called on account-change. Account 2 is never updated |
| XREFFILE alternate key lookup | Loaded into map keyed by XREF-ACCT-ID (11 bytes at offset 25) | YES — `xrefMap` keyed by bytes 25-35 of XREFFILE records; looked up by account ID |
| ACCTFILE read+update (REWRITE) | Read account into memory, add interest, zero CYC fields, write back | YES — `perform1100GetAcctData` clones record; `perform1050UpdateAccount` modifies and puts back into `acctMap`; written to `ACCTFILE_SEQ_OUT` at end |
| Both timestamps masked (ORIG-TS + PROC-TS) | Bytes 278-303 and 304-329 zeroed before comparison | YES — `getDb2Timestamp()` writes live timestamp at both offsets; test script masks both ranges to zero before `cmp` |
| TRAN-CAT-CD '05' as PIC 9(4) = '0005' | 4-byte DISPLAY literal '0005' at bytes 18-21 | YES — bytes 18-21 set to `'0','0','0','5'` |
| TRAN-DESC STRING verb + NUL padding | 'Int. for a/c '+ACCT-ID (24 chars) then NUL fill to 100 bytes | YES — `descStr` concatenated and copied into zero-initialized array; remaining bytes stay 0x00 |
| LINKAGE SECTION PARM-DATE as args[0] | Java args[0] passed as `parmDate`, used in TRAN-ID construction | YES — `parmDate = args[0]`; TRAN-ID = `parmDate + String.format("%06d", suffix)` = '2026-06-17000001' etc. |

---

## Numeric Verification

| Calculation | Expected | Observed in TRANSACT |
|---|---|---|
| Acct 1, CR/0001: (100000 * 1200) / 120000 | 1000 hundredths = 10.00 | `00000001000` at bytes 132-142 of record 1 |
| Acct 1, DB/0002: (50000 * 600) / 120000 | 250 hundredths = 2.50 | `00000000250` at bytes 132-142 of record 2 |
| Acct 2, CR/0001: (200000 * 1200) / 120000 | 2000 hundredths = 20.00 | `00000002000` at bytes 132-142 of record 3 |
| Acct 2, DR/0003 (fallback DEFAULT+18%): (30000 * 1800) / 120000 | 450 hundredths = 4.50 | `00000000450` at bytes 132-142 of record 4 |
| Acct 1 BAL after: 500000 + (1000+250) | 501250 hundredths = 5012.50 | Confirmed by ACCTSEQ PASS |
| Acct 2 BAL after: 800000 (unchanged, dead-code bug) | 800000 hundredths = 8000.00 | Confirmed by ACCTSEQ PASS |

---

## TRANSACT Record Layout Spot-Check (Record 1, xxd)

From binary output (before masking):
- Bytes 0-15: `2026-06-17000001` — TRAN-ID correct
- Bytes 16-17: `01` — TRAN-TYPE-CD correct
- Bytes 18-21: `0005` — TRAN-CAT-CD correct (PIC 9(4) = '0005')
- Bytes 22-31: `System    ` — TRAN-SOURCE correct (space-padded)
- Bytes 32-55: `Int. for a/c 00000000001` — TRAN-DESC correct
- Bytes 56-131: NUL bytes — STRING remainder zero-filled correct
- Bytes 132-142: `00000001000` — TRAN-AMT = 10.00 correct
- Bytes 143-151: `000000000` — TRAN-MERCHANT-ID zeros correct
- Bytes 152-261: spaces — MERCHANT-NAME/CITY/ZIP correct
- Bytes 262-277: `4000002000000001` — TRAN-CARD-NUM correct
- Bytes 278-303: timestamp (masked to zeros before compare)
- Bytes 304-329: timestamp (masked to zeros before compare)
- Bytes 330-349: NUL bytes — FILLER correct

---

## Final Verdict

**ACCEPTED**

All 3 characterization comparisons passed (3/3):
1. PASS — TRANSACT masked (both timestamps zeroed): byte-for-byte match against `golden_TRANSACT_masked` (1400 bytes, 4 records)
2. PASS — ACCTSEQ (account after-state): byte-for-byte match against `golden_ACCTSEQ` (600 bytes, 2 records)
3. PASS — STDOUT (DISPLAY output): byte-for-byte match against `golden_stdout.txt`

The Java translation replicates all documented COBOL behaviors including the dead-code EOF bug (last account not posted), the DISCGRP DEFAULT fallback, the interest formula using integer truncation, correct numeric DISPLAY encoding, and the TRAN-DESC STRING+NUL pattern.

---

## Phase 5 — Optimization

**Date:** 2026-06-18  
**Optimizer:** optimizer subagent

### Benchmark Method

100-iteration shell loop (macOS `python3` millisecond timing):
```
for i in 1..100:
  ./GENTCAT; ./GENXREF; ./GENDISCGRP; ./GENACCT
  bash run_characterization.sh ./java/run_cbact04c.sh
```

### Baseline Measurement

| Run | ms/iter |
|-----|---------|
| Baseline (unoptimized) | 291.4 |

### Optimization Candidate: Cache `LATIN1` Charset

**Change:** Added `static final Charset LATIN1 = java.nio.charset.StandardCharsets.ISO_8859_1` field; replaced all inline `java.nio.charset.StandardCharsets.ISO_8859_1` references (8 occurrences) with the cached field. Eliminates repeated static field chain dereference on each `new String(...)` call in the hot path.

**Equivalence after change:** 3/3 PASS (verified)

| Run | ms/iter |
|-----|---------|
| Optimized | 290.5 |

**Gain:** 0.9 ms (0.3%) — positive but within measurement noise. Consistent with CBTRN02C finding: JVM cold-start (~200 ms/iter) dominates at this macro benchmark scale; micro-optimizations to Java logic are largely invisible.

**Decision:** KEPT (gain > 0 per rule; change is behaviorally neutral).

**Note:** As with CBTRN02C, further optimization would require eliminating per-iteration JVM startup (e.g., GraalVM native image or persistent daemon), which is outside the scope of source-level optimization for this experiment.
