# CBACT03C

## Purpose
CBACT03C is a minimal batch COBOL program that opens the VSAM KSDS cross-reference file (XREFFILE), reads every record sequentially, and DISPLAYs each record to SYSOUT. It serves as a diagnostic/dump utility — no data transformation, validation, or output file writing occurs.

## Inputs
- `XREFFILE` — VSAM KSDS card-to-account cross-reference file; sequential read; record key `FD-XREF-CARD-NUM` (PIC X(16)); record length 50 bytes (16-byte key + 34-byte data)

## Outputs
- `SYSOUT` — each `CARD-XREF-RECORD` (from CVACT03Y) is printed via DISPLAY

## Key Business Rules
1. All records are read sequentially until EOF (status `'10'`).
2. Records are displayed as-is with no filtering, formatting, or selection.
3. Any non-EOF, non-OK file status causes an ABEND via `CEE3ABD`.
4. Note: the `1000-XREFFILE-GET-NEXT` paragraph issues `DISPLAY CARD-XREF-RECORD` for both the successful-read path and the outer loop — records are actually displayed twice on success (a minor bug in the source).

## Notable COBOL Constructs
- **Indexed I/O (KSDS sequential):** XREFFILE declared with `ORGANIZATION IS INDEXED`, `ACCESS MODE IS SEQUENTIAL`.
- **REDEFINES (IO-STATUS decode):** `TWO-BYTES-ALPHA REDEFINES TWO-BYTES-BINARY` — used for displaying extended file-status codes.

## Copybook Dependencies
- `CVACT03Y` — provides `CARD-XREF-RECORD` layout (XREF-CARD-NUM, XREF-CUST-ID, XREF-ACCT-ID)

## Called Programs
- `CEE3ABD` — LE ABEND routine

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `FD-XREF-CARD-NUM` | `X(16)` | Card number — KSDS primary key |
| `FD-XREF-DATA` | `X(34)` | Remaining xref record data (CUST-ID + ACCT-ID) |
