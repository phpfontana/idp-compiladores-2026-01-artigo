# CBCUS01C

## Purpose
CBCUS01C is a minimal batch COBOL program that opens the VSAM KSDS customer file (CUSTFILE), reads every record sequentially, and DISPLAYs each record to SYSOUT. It serves as a diagnostic/dump utility — no data transformation, validation, or output file writing occurs.

## Inputs
- `CUSTFILE` — VSAM KSDS customer master file; sequential read; record key `FD-CUST-ID` (PIC 9(09)); record length 500 bytes (9-byte key + 491-byte data)

## Outputs
- `SYSOUT` — each `CUSTOMER-RECORD` (from CVCUS01Y) is printed via DISPLAY

## Key Business Rules
1. All records are read sequentially until EOF (status `'10'`).
2. Records are displayed as-is with no filtering, formatting, or selection.
3. Any non-EOF, non-OK file status causes an ABEND via `CEE3ABD`.
4. Note: the `1000-CUSTFILE-GET-NEXT` paragraph issues `DISPLAY CUSTOMER-RECORD` for both the successful-read path and again in the outer loop — records are displayed twice on success (same minor pattern as CBACT03C).

## Notable COBOL Constructs
- **Indexed I/O (KSDS sequential):** CUSTFILE declared with `ORGANIZATION IS INDEXED`, `ACCESS MODE IS SEQUENTIAL`.
- **REDEFINES (IO-STATUS decode):** `TWO-BYTES-ALPHA REDEFINES TWO-BYTES-BINARY` — used for displaying extended file-status codes.

## Copybook Dependencies
- `CVCUS01Y` — provides `CUSTOMER-RECORD` layout (CUST-ID, CUST-FIRST-NAME, CUST-LAST-NAME, CUST-ADDR-*, CUST-SSN, CUST-FICO-CREDIT-SCORE, etc.)

## Called Programs
- `CEE3ABD` — LE ABEND routine

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `FD-CUST-ID` | `9(09)` | Customer ID — KSDS primary key |
| `FD-CUST-DATA` | `X(491)` | Remaining customer record data |
