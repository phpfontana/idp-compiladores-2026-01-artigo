# CBIMPORT

## Purpose
CBIMPORT is the inverse of CBEXPORT. It is a batch COBOL program that reads the EXPFILE export file (500-byte KSDS records tagged by type) and routes each record to one of five normalized sequential output files (CUSTOUT, ACCTOUT, XREFOUT, TRNXOUT, CARDOUT). Unknown record types are written to an error file (ERROUT) with a diagnostic message. The program is designed for branch migration import.

## Inputs
- `EXPFILE` — VSAM KSDS export file; 500-byte fixed records; keyed by sequence number (produced by CBEXPORT)

## Outputs
- `CUSTOUT` — Sequential customer records (500 bytes); one per type-`'C'` input record
- `ACCTOUT` — Sequential account records (300 bytes); one per type-`'A'` input record
- `XREFOUT` — Sequential xref records (50 bytes); one per type-`'X'` input record
- `TRNXOUT` — Sequential transaction records (350 bytes); one per type-`'T'` input record
- `CARDOUT` — Sequential card records (150 bytes); one per type-`'D'` input record
- `ERROUT` — Sequential error records (132 bytes); one per unknown-type input record

## Key Business Rules
1. Records are read from EXPFILE sequentially until EOF; a running total count `WS-TOTAL-RECORDS-READ` is maintained.
2. For each record, `EXPORT-REC-TYPE` is evaluated: `'C'`→customer, `'A'`→account, `'X'`→xref, `'T'`→transaction, `'D'`→card, `OTHER`→error.
3. For known types, export sub-fields (EXP-*) are mapped one-to-one to the appropriate native record layout and written.
4. For unknown types, a 132-byte error record is written to ERROUT containing: current timestamp, record type, sequence number, and a `'Unknown record type encountered'` message.
5. `3000-VALIDATE-IMPORT` is a stub: it DISPLAYs a success message but performs no actual validation — no checksums, duplicate detection, or referential integrity checks.
6. Any file I/O error ABENDs the program immediately; the error output write error is logged but does not ABEND.
7. Final statistics are DISPLAYed: total read, per-type imported counts, error count, and unknown-type count.

## Notable COBOL Constructs
- **EVALUATE EXPORT-REC-TYPE:** Single EVALUATE dispatches all five type paths plus error path — cleaner than a chain of IF/ELSE IF.
- **FUNCTION CURRENT-DATE:** Used in the timestamp assembly for the date/time fields in the WS-IMPORT-CONTROL area and in error records.
- **Stub validation:** `3000-VALIDATE-IMPORT` contains only DISPLAY statements — no actual checks; the Java translator should preserve this as a placeholder or note it as a known gap.

## Copybook Dependencies
- `CVCUS01Y` — `CUSTOMER-RECORD` layout (output for type `'C'`)
- `CVACT01Y` — `ACCOUNT-RECORD` layout (output for type `'A'`)
- `CVACT03Y` — `CARD-XREF-RECORD` layout (output for type `'X'`)
- `CVTRA05Y` — `TRAN-RECORD` layout (output for type `'T'`)
- `CVACT02Y` — card record layout (output for type `'D'`)
- `CVEXPORT` — `EXPORT-RECORD` layout with EXP-* sub-fields (input)

## Called Programs
- `CEE3ABD` — LE ABEND routine

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `EXPORT-REC-TYPE` | `X(01)` | Type discriminator from EXPFILE: C/A/X/T/D |
| `EXPORT-SEQUENCE-NUM` | `9(09)` | Sequence number from EXPFILE record |
| `WS-TOTAL-RECORDS-READ` | `9(09)` | Total records read from EXPFILE |
| `WS-UNKNOWN-RECORD-TYPE-COUNT` | `9(09)` | Count of unrecognized record types |
| `ERR-MESSAGE` | `X(50)` | Fixed message `'Unknown record type encountered'` |
