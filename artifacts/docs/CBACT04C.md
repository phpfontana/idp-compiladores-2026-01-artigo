# CBACT04C

## Purpose
CBACT04C is a batch interest calculator that reads the transaction category balance file (TCATBALF) sequentially by account, looks up each account's group code and interest rate from the disclosure group file (DISCGRP), computes monthly interest as `(TRAN-CAT-BAL × DIS-INT-RATE) / 1200`, and posts the accumulated interest for each account as a new transaction record to TRANSACT and as a balance update (REWRITE) to the account master (ACCTFILE). The program accepts one parameter — the processing date — through a LINKAGE SECTION, used as a prefix for the generated transaction IDs.

## Inputs
- `TCATBALF` — VSAM KSDS transaction category balance file; sequential read; keyed by (ACCT-ID + TYPE-CD + CAT-CD)
- `XREFFILE` — VSAM KSDS card cross-reference; random access by ACCT-ID (alternate key `FD-XREF-ACCT-ID`)
- `DISCGRP` — VSAM KSDS disclosure group (interest rate table); random access by (ACCT-GROUP-ID + TYPE-CD + CAT-CD)
- `ACCTFILE` — VSAM KSDS account master; random I/O (read + rewrite)
- `PARM-DATE` — Run-date parameter from LINKAGE SECTION; used as prefix in generated TRAN-ID

## Outputs
- `TRANSACT` — Sequential transaction output file; one interest transaction per category per account
- Updates to `ACCTFILE` — `ACCT-CURR-BAL` is incremented by total interest; `ACCT-CURR-CYC-CREDIT` and `ACCT-CURR-CYC-DEBIT` are reset to zero after posting

## Key Business Rules
1. TCATBALF is read sequentially. Records are grouped by account (WS-LAST-ACCT-NUM).
2. When the account number changes, the previous account's total interest is posted (1050-UPDATE-ACCOUNT) before starting the new account.
3. The last account is posted at EOF (the ELSE branch on END-OF-FILE).
4. For each TCATBALF record, the interest rate is looked up in DISCGRP using (ACCT-GROUP-ID + TYPE-CD + CAT-CD).
5. **Rate fallback:** If the specific disclosure group key is not found (status `23`), the key is overridden to `'DEFAULT'` and DISCGRP is re-read with just the default group, using the same TYPE-CD and CAT-CD. If that still fails, the program ABENDs.
6. **Zero-rate skip:** If `DIS-INT-RATE = 0`, no interest is computed and no transaction is written for that category row.
7. **Interest formula:** `WS-MONTHLY-INT = (TRAN-CAT-BAL × DIS-INT-RATE) / 1200` — annual rate divided by 12 months, computed as integer arithmetic on COMP-3 fields.
8. `WS-TOTAL-INT` accumulates all category interests for the current account; this total is added to `ACCT-CURR-BAL` on account update.
9. On account update: `ACCT-CURR-CYC-CREDIT` and `ACCT-CURR-CYC-DEBIT` are both reset to zero.
10. Each interest transaction record has: `TRAN-TYPE-CD='01'`, `TRAN-CAT-CD='05'`, `TRAN-SOURCE='System'`, description = "Int. for a/c " + ACCT-ID, amount = `WS-MONTHLY-INT`, merchant fields blank, card number from XREF.
11. Transaction ID is built by STRING of `PARM-DATE` + `WS-TRANID-SUFFIX` (a 6-digit counter incremented per transaction written).
12. The processing timestamp is a current-date DB2 timestamp built from `FUNCTION CURRENT-DATE`.
13. `1400-COMPUTE-FEES` is a stub — "To be implemented" — no fees are actually posted.

## Notable COBOL Constructs
- **COMP-3 arithmetic:** `WS-MONTHLY-INT PIC S9(09)V99` and `WS-TOTAL-INT PIC S9(09)V99` accumulate interest; `TRAN-CAT-BAL` (from CVTRA01Y) is likely COMP-3; the COMPUTE statement divides by 1200 — exact decimal scale must be preserved in Java (use `BigDecimal` with HALF_EVEN or same rounding as mainframe).
- **Alternate record key:** XREFFILE has `ALTERNATE RECORD KEY IS FD-XREF-ACCT-ID` used in `READ XREF-FILE INTO CARD-XREF-RECORD KEY IS FD-XREF-ACCT-ID` — Java must handle both primary and alternate key lookups.
- **Rate fallback pattern:** The `1200-GET-INTEREST-RATE` paragraph modifies `FD-DIS-ACCT-GROUP-ID` to `'DEFAULT'` and re-issues a READ — this mutates the key structure in place; the Java translation must replicate this two-read pattern faithfully.
- **PERFORM THRU pattern:** Not present in this program; flow uses simple PERFORM and GO TO via paragraph names.
- **LINKAGE SECTION:** `EXTERNAL-PARMS` with `PARM-DATE PIC X(10)` is passed from the calling JCL as a run-parameter; in Java this becomes a command-line argument.
- **REDEFINES:** `TWO-BYTES-ALPHA REDEFINES TWO-BYTES-BINARY` and `FILLER REDEFINES DB2-FORMAT-TS` for DB2 timestamp assembly.

## Copybook Dependencies
- `CVTRA01Y` — TRAN-CAT-BAL-RECORD (TRANCAT-ACCT-ID, TRANCAT-TYPE-CD, TRANCAT-CD, TRAN-CAT-BAL)
- `CVACT03Y` — CARD-XREF-RECORD (XREF-CARD-NUM, XREF-CUST-ID, XREF-ACCT-ID)
- `CVTRA02Y` — DIS-GROUP-RECORD (FD-DISCGRP-KEY: DIS-ACCT-GROUP-ID + DIS-TRAN-TYPE-CD + DIS-TRAN-CAT-CD; DIS-INT-RATE)
- `CVACT01Y` — ACCOUNT-RECORD (ACCT-ID, ACCT-CURR-BAL, ACCT-CURR-CYC-CREDIT, ACCT-CURR-CYC-DEBIT, ACCT-GROUP-ID)
- `CVTRA05Y` — TRAN-RECORD (TRAN-ID, TRAN-TYPE-CD, TRAN-CAT-CD, TRAN-SOURCE, TRAN-DESC, TRAN-AMT, TRAN-CARD-NUM, TRAN-ORIG-TS, TRAN-PROC-TS)

## Called Programs
- `CEE3ABD` — LE ABEND routine

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `FD-TRAN-CAT-KEY` | group | Composite key: ACCT-ID(11) + TYPE-CD(2) + CAT-CD(4) |
| `DIS-INT-RATE` | inferred (packed) | Annual interest rate from disclosure group table |
| `WS-MONTHLY-INT` | `S9(09)V99` | Computed monthly interest for one category row |
| `WS-TOTAL-INT` | `S9(09)V99` | Accumulated total interest for current account |
| `PARM-DATE` | `X(10)` | Run date from JCL PARM, used as TRAN-ID prefix |
| `WS-TRANID-SUFFIX` | `9(06)` | Incrementing 6-digit counter for TRAN-ID uniqueness |
| `FD-XREF-ACCT-ID` | `9(11)` | Alternate key on XREFFILE for account-based lookup |
