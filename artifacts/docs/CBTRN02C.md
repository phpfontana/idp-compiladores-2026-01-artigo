# CBTRN02C

## Purpose
CBTRN02C is a batch COBOL program that posts daily transaction records from a sequential input file (DALYTRAN) into the CardDemo online VSAM files. For each transaction it performs a two-step validation (card cross-reference lookup, then account credit-limit and expiration checks), posts accepted transactions to the transaction master file (TRANFILE) and updates both the account balance and the transaction category balance (TCATBALF), and writes rejected transactions to a daily rejects file (DALYREJS) with a 4-digit reason code. It is the core transaction posting program in the batch pipeline.

## Inputs
- `DALYTRAN` — Sequential daily transaction input file; one record per transaction
- `XREFFILE` — VSAM KSDS card-to-account cross-reference (random access by card number)
- `ACCTFILE` — VSAM KSDS account master (random I/O; read then rewrite on posting)
- `TCATBALF` — VSAM KSDS transaction category balance file (random I/O; read then create or rewrite)

## Outputs
- `TRANFILE` — VSAM KSDS transaction master; one record written per accepted transaction
- `DALYREJS` — Sequential daily rejects file; one record written per rejected transaction (contains original transaction data + 80-byte validation trailer with reason code and description)
- Return code 4 if any transactions were rejected (set via `MOVE 4 TO RETURN-CODE`)

## Key Business Rules
1. Each daily transaction record is read sequentially until EOF.
2. **Card validation (reason code 100):** The card number is looked up in XREFFILE by key. If not found (INVALID KEY), the transaction is rejected with reason code `0100` and description "INVALID CARD NUMBER FOUND".
3. **Account validation (reason code 101):** The account linked to the card is looked up in ACCTFILE. If not found, rejected with `0101` / "ACCOUNT RECORD NOT FOUND".
4. **Over-limit check (reason code 102):** `ACCT-CREDIT-LIMIT >= (ACCT-CURR-CYC-CREDIT - ACCT-CURR-CYC-DEBIT + DALYTRAN-AMT)` must be true; otherwise rejected with `0102` / "OVERLIMIT TRANSACTION".
5. **Expiration check (reason code 103):** `ACCT-EXPIRAION-DATE >= DALYTRAN-ORIG-TS(1:10)` (date-string comparison); if the account has expired the transaction is rejected with `0103` / "TRANSACTION RECEIVED AFTER ACCT EXPIRATION".
6. Validations are sequential: card is checked first; if that fails, account check is skipped.
7. **Account balance update:** `ACCT-CURR-BAL += DALYTRAN-AMT`; if amount >= 0 add to `ACCT-CURR-CYC-CREDIT`, else add to `ACCT-CURR-CYC-DEBIT`.
8. **TCATBAL update:** The transaction category balance keyed by (ACCT-ID + TYPE-CD + CAT-CD) is incremented by DALYTRAN-AMT; if the record doesn't exist it is created (WRITE) with the amount; if it exists it is updated (REWRITE).
9. The processing timestamp on the posted transaction (`TRAN-PROC-TS`) is set to the current system time formatted as a DB2-style timestamp `YYYY-MM-DD-HH.MM.SS.cc0000`.
10. Reject records carry the full 350-byte original transaction data plus the 80-byte validation trailer.
11. At end of run, transaction and reject counts are displayed and return code 4 is set if reject count > 0.

## Notable COBOL Constructs
- **Indexed I/O (random access):** XREFFILE, ACCTFILE, and TCATBALF are all accessed via `READ ... KEY IS ...` with INVALID KEY / NOT INVALID KEY handlers.
- **REDEFINES:** `TWO-BYTES-ALPHA REDEFINES TWO-BYTES-BINARY` and `FILLER REDEFINES DB2-FORMAT-TS` — the DB2 timestamp REDEFINES overlays the string with named sub-fields (DB2-YYYY, DB2-MM, etc.) for field-by-field population.
- **COMP-3 fields:** Not present in CBTRN02C itself, but TCATBALF record (CVTRA01Y) contains `TRAN-CAT-BAL` which may be COMP-3 — translator must verify.
- **Shared WORKING-STORAGE state:** `WS-VALIDATION-FAIL-REASON` and `WS-VALIDATION-FAIL-REASON-DESC` are shared across 1500-A and 1500-B validation paragraphs; ordering is critical.
- **REWRITE:** Both ACCTFILE and TCATBALF are opened I-O and updated via REWRITE after READ; Java must mirror the read-then-update pattern exactly.

## Copybook Dependencies
- `CVTRA06Y` — DALYTRAN-RECORD layout (DALYTRAN-ID, DALYTRAN-CARD-NUM, DALYTRAN-AMT, etc.)
- `CVTRA05Y` — TRAN-RECORD layout for the transaction master file
- `CVACT03Y` — CARD-XREF-RECORD layout (XREF-CARD-NUM, XREF-CUST-ID, XREF-ACCT-ID)
- `CVACT01Y` — ACCOUNT-RECORD layout (ACCT-ID, balances, credit limit, expiration date)
- `CVTRA01Y` — TRAN-CAT-BAL-RECORD layout (TRANCAT-ACCT-ID, TRANCAT-TYPE-CD, TRANCAT-CD, TRAN-CAT-BAL)

## Called Programs
- `CEE3ABD` — LE ABEND routine (abnormal termination on I/O error)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `DALYTRAN-CARD-NUM` | `X(16)` | Card number from daily transaction input |
| `DALYTRAN-AMT` | `S9(9)V99` (inferred) | Transaction amount (positive=credit, negative=debit) |
| `DALYTRAN-ORIG-TS` | `X(26)` (inferred) | Original transaction timestamp; first 10 chars compared to account expiry |
| `ACCT-CREDIT-LIMIT` | `S9(10)V99` | Account credit limit |
| `ACCT-CURR-CYC-CREDIT` | `S9(10)V99` | Current cycle credit accumulator |
| `ACCT-CURR-CYC-DEBIT` | `S9(10)V99` | Current cycle debit accumulator |
| `WS-VALIDATION-FAIL-REASON` | `9(04)` | Reason code: 0=OK, 100=bad card, 101=no account, 102=over-limit, 103=expired |
| `TRAN-CAT-BAL` | inferred | Running balance per account/type/category; keyed (ACCT-ID+TYPE-CD+CAT-CD) |
