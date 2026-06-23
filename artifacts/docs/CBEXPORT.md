# CBEXPORT

## Purpose
CBEXPORT is a batch COBOL program designed for branch migration. It reads five CardDemo master files (CUSTFILE, ACCTFILE, XREFFILE, TRANSACT, CARDFILE) sequentially and writes every record into a single VSAM KSDS export file (EXPFILE) using a 500-byte tagged-record layout. Each output record has a 1-character type tag: `'C'`=customer, `'A'`=account, `'X'`=xref, `'T'`=transaction, `'D'`=card. A monotonically incrementing 9-digit sequence number (`EXPORT-SEQUENCE-NUM`) is the KSDS primary key for EXPFILE.

## Inputs
- `CUSTFILE` — VSAM KSDS customer master; sequential read
- `ACCTFILE` — VSAM KSDS account master; sequential read
- `XREFFILE` — VSAM KSDS card cross-reference; sequential read
- `TRANSACT` — VSAM KSDS transaction master; sequential read
- `CARDFILE` — VSAM KSDS card master; sequential read

## Outputs
- `EXPFILE` — VSAM KSDS export file; 500-byte fixed records; one record per input record from all five input files; tagged by type; keyed by sequence number

## Key Business Rules
1. Files are processed in a fixed sequence: customers first, then accounts, xrefs, transactions, and cards.
2. Each exported record has common header fields: `EXPORT-REC-TYPE`, `EXPORT-TIMESTAMP` (current date/time), `EXPORT-SEQUENCE-NUM` (1-based counter), `EXPORT-BRANCH-ID` (hardcoded `'0001'`), `EXPORT-REGION-CODE` (hardcoded `'NORTH'`).
3. The sequence counter is incremented before every write; the counter starts at 0 and reaches total-records-exported at end.
4. All five input files are read until EOF; any non-EOF, non-OK status ABENDs the program.
5. Any EXPFILE write error ABENDs the program — no partial exports.
6. At end, summary counts are DISPLAYed: per-type counts and total count.
7. The `3000-VALIDATE-IMPORT` placeholder (in CBIMPORT) is the corresponding validation step; CBEXPORT itself has no checksum or integrity metadata in the export header.

## Notable COBOL Constructs
- **CVEXPORT copybook:** Provides the 500-byte `EXPORT-RECORD` group layout with type-specific field overlays (EXP-CUST-*, EXP-ACCT-*, EXP-XREF-*, EXP-TRAN-*, EXP-CARD-*).
- **88-level file-status conditions:** `WS-CUSTOMER-EOF VALUE '10'`, `WS-CUSTOMER-OK VALUE '00'` — used in `PERFORM UNTIL WS-CUSTOMER-EOF` loops and `IF NOT WS-xxx-OK` error checks; cleaner than string comparison.
- **ACCEPT FROM DATE/TIME:** `ACCEPT WS-CURRENT-DATE FROM DATE YYYYMMDD` and `FROM TIME` — standard COBOL intrinsic date/time; Java equivalent is `LocalDate.now()`.

## Copybook Dependencies
- `CVCUS01Y` — `CUSTOMER-RECORD` (and its field names used in MOVE statements)
- `CVACT01Y` — `ACCOUNT-RECORD`
- `CVACT03Y` — `CARD-XREF-RECORD`
- `CVTRA05Y` — `TRAN-RECORD`
- `CVACT02Y` — card record
- `CVEXPORT` — `EXPORT-RECORD` layout with all type-specific sub-fields

## Called Programs
- `CEE3ABD` — LE ABEND routine

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `EXPORT-REC-TYPE` | `X(01)` | Record type tag: C/A/X/T/D |
| `EXPORT-SEQUENCE-NUM` | `9(09)` | KSDS primary key; monotone counter |
| `EXPORT-TIMESTAMP` | `X(26)` | Export run timestamp |
| `EXPORT-BRANCH-ID` | `X(04)` | Hardcoded `'0001'` |
| `EXPORT-REGION-CODE` | `X(05)` | Hardcoded `'NORTH'` |
| `WS-TOTAL-RECORDS-EXPORTED` | `9(09)` | Total records written across all types |
