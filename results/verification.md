# Equivalence Verification Results (append-only)

Written by equivalence-verifier. One block per program per run. Final verdict is
ACCEPTED only at 100% case match.

---

## CBACT01C — 2026-06-17T21:03
Verdict: _ACCEPTED_

| Case | Exercises | Result | Diff (if FAIL) |
|---|---|---|---|
| OUTFILE (300B × 3 records = 900B flat) | Fixed-length account records; COMP-3 sign encoding; FD buffer persistence (2525.00 sentinel); COBDATFT date reformat | PASS | — |
| ARRYFILE (110B × 3 records = 330B flat) | OCCURS 5 COMP-3 array; INITIALIZE semantics (FILLER stays 0x00); hardcoded BAL(3)=−1025.00 | PASS | — |
| VBRCFILE (177B variable-block) | VBR records with 4-byte RDW header (big-endian payload length + 2 zero bytes); two payloads per account (12B and 39B) | PASS | — |
| STDOUT (DISPLAY output) | DISPLAY S9(10)V99 overpunch sign; 49-dash separator; raw-byte output | PASS | — |

---

## CBTRN02C — 2026-06-17T21:44
Verdict: _ACCEPTED_

| Case | Exercises | Result | Diff (if FAIL) |
|---|---|---|---|
| DALYREJS (1720B = 4 records × 430B) | Reject record layout (350B DALYTRAN + 4B reason code 9(4) + 76B desc); reason codes 100/101/102/103; reject count; exit code 4 | PASS | — |
| TRNSEQ masked (3 accepted records × 350B, TRAN-PROC-TS zeroed) | Accepted transaction records; INITIALIZE FILLER stays 0x00; TreeMap key ordering for TCATBAL | PASS | — |
| ACCTSEQ (4 accounts × 300B) | Account balance update (ADD signed DISPLAY); CYC-CREDIT/CYC-DEBIT split; REWRITE semantics via LinkedHashMap | PASS | — |
| TCATSEQ (1 existing + 1 new record × 50B) | TCATBAL create (WRITE) vs update (REWRITE); new record FILLER stays 0x00; TreeMap sort order | PASS | — |
| STDOUT (DISPLAY output) | Transaction counts; rejection counts; exact DISPLAY formatting | PASS | — |

Note: TRAN-PROC-TS (bytes 304–329 of each accepted record) masked to 0x00 before comparison because FUNCTION CURRENT-DATE is non-deterministic.

---

## CBACT04C — 2026-06-18T01:47
Verdict: _ACCEPTED_

| Case | Exercises | Result | Diff (if FAIL) |
|---|---|---|---|
| TRANSACT masked (4 records × 350B, both timestamps zeroed) | Interest transaction records; TRAN-ID=PARM-DATE+counter; TRAN-DESC STRING+NUL-pad; interest formula (bal×rate)/120000 integer truncation; DISCGRP DEFAULT fallback; TRAN-CAT-CD='0005' PIC 9(4) | PASS | — |
| ACCTSEQ (2 accounts × 300B) | Account update: ACCT-CURR-BAL += interest, CYC fields zeroed; dead-code EOF bug (last account NOT posted, retains original balance) | PASS | — |
| STDOUT (DISPLAY output) | TCATBALF scan lines; "DISCLOSURE GROUP RECORD MISSING" + "TRY WITH DEFAULT GROUP CODE" messages; START/END banners | PASS | — |

Note: TRAN-ORIG-TS (bytes 278–303) and TRAN-PROC-TS (bytes 304–329) of each TRANSACT record masked to 0x00 before comparison. Dead-code EOF bug documented: account 2 (last account) is never posted — Java replicates this faithfully.

---

## CBSTM03A — 2026-06-20T20:45
Verdict: _ACCEPTED_

| Case | Exercises | Result | Diff (if FAIL) |
|---|---|---|---|
| STMTFILE (3280B = 41 records × 80B, no newlines) | Plain-text statement format; STRING DELIMITED BY ' '; PIC 9(9).99- formatted balance; PIC Z(9).99- leading-zero-suppressed transaction amounts; INITIALIZE STATEMENT-LINES (FILLER keeps VALUE); 2 customers × multi-transaction layout | PASS | — |
| HTMLFILE (16100B = 161 records × 100B, no newlines) | Full HTML document per customer; 88-level VALUE → space-padded 100B records; STRING DELIMITED BY '  ' (double-space) for address/name; HTML-L11 group record (59B content + 41B spaces); inline CSS styling | PASS | — |
| STDOUT (202B, 8 lines) | PSA/TCB/TIOT stub output (fixed lines replacing mainframe null-pointer code path) | PASS | — |

Note: PSA/TCB/TIOT section stubs both COBOL (CBSTM03A_RUNNABLE.cbl) and Java with identical fixed DISPLAY lines. Indexed BDB files read via COBOL dump programs; Java reads flat sequential dumps.

---

## CBSTM03B — 2026-06-21T00:02
Verdict: _ACCEPTED_

| Case | Exercises | Result | Diff (if FAIL) |
|---|---|---|---|
| OUTPUT file (1520B = 19 records × 80B) | CBSTM03B dispatch over all 4 files and all used operations: O/R/C for TRNXFILE (3 records) and XREFFILE (2 records); O/K/C for CUSTFILE and ACCTFILE (2 keyed reads each); RC='00' for OK, RC='10' for EOF; LK-M03B-FLDT first-50-bytes captured per call | PASS | — |
| STDOUT (1539B, 19 lines) | DISPLAY diagnostic lines from driver mirroring each call; CBSTM03B itself produces no DISPLAY output | PASS | — |

Note: CBSTM03B is a subroutine with PROCEDURE DIVISION USING; tested via CBSTM03B_DRIVER.cbl driver that exercises 19 call sequences. Java translation (CBSTM03B.java) replicates the same 19-call sequence using flat sequential dump files from workspace/CBSTM03A/. W (write) and Z (rewrite) operation codes not exercised — consistent with the documented driver scope.
