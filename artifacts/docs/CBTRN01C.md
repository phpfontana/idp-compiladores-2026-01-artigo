# CBTRN01C

## Purpose
CBTRN01C is a read-only batch COBOL program that reads daily transactions from DALYTRAN sequentially, then validates each by looking up the card number in XREFFILE and the linked account in ACCTFILE, DISPLAYing the results to SYSOUT. It does not post, update, or write any records — it is a diagnostic validation and audit-log tool that precedes CBTRN02C in the batch pipeline.

## Inputs
- `DALYTRAN` — Sequential daily transaction input file; one record per transaction
- `CUSTFILE` — VSAM KSDS customer master (opened INPUT; not actually read in the processing loop — only opened)
- `XREFFILE` — VSAM KSDS card-to-account cross-reference (random access by card number)
- `CARDFILE` — VSAM KSDS card master (opened INPUT; not actually read in the processing loop — only opened)
- `ACCTFILE` — VSAM KSDS account master (random access by account ID)
- `TRANFILE` — VSAM KSDS transaction master (opened INPUT; not actually read in the processing loop — only opened)

## Outputs
- `SYSOUT` — validation results displayed: XREF lookup result (card number, account ID, customer ID) and account read status; "not found" messages for missing records

## Key Business Rules
1. Each transaction is read sequentially from DALYTRAN until EOF.
2. Each transaction record is DISPLAYed in full before validation.
3. The card number (`DALYTRAN-CARD-NUM`) is looked up in XREFFILE by key; if not found, the transaction is flagged and account lookup is skipped.
4. If the XREF is found, the linked account ID (`XREF-ACCT-ID`) is looked up in ACCTFILE by key; if not found, a "NOT FOUND" message is displayed.
5. No records are written, updated, or rejected — this is a pure reporting/validation pass.
6. CUSTFILE, CARDFILE, and TRANFILE are opened but never read — they appear to be leftover from an earlier implementation or reserved for future use.
7. Any unexpected file status causes an ABEND via `CEE3ABD`.

## Notable COBOL Constructs
- **Multi-file READ loop:** Opens 6 files but only reads 3 (DALYTRAN, XREFFILE, ACCTFILE) — the unused file opens are a design artifact.
- **READ ... KEY IS ... INVALID KEY pattern:** Used for random access of XREFFILE and ACCTFILE; `WS-XREF-READ-STATUS` and `WS-ACCT-READ-STATUS` communicate results between paragraphs.

## Copybook Dependencies
- `CVTRA06Y` — `DALYTRAN-RECORD` layout
- `CVCUS01Y` — `CUSTOMER-RECORD` layout
- `CVACT03Y` — `CARD-XREF-RECORD` layout
- `CVACT02Y` — card record layout
- `CVACT01Y` — `ACCOUNT-RECORD` layout
- `CVTRA05Y` — `TRAN-RECORD` layout

## Called Programs
- `CEE3ABD` — LE ABEND routine

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `DALYTRAN-CARD-NUM` | `X(16)` | Card number from daily transaction input |
| `DALYTRAN-ID` | `X(16)` | Transaction ID displayed on xref failure |
| `XREF-ACCT-ID` | `9(11)` | Account ID looked up via xref |
| `WS-XREF-READ-STATUS` | `9(04)` | 0=found, 4=not found for xref lookup |
| `WS-ACCT-READ-STATUS` | `9(04)` | 0=found, 4=not found for account lookup |
