# CBACT02C

## Purpose
CBACT02C is a minimal batch COBOL program that opens the VSAM KSDS card file (CARDFILE), reads every record sequentially, and DISPLAYs each record to SYSOUT. It serves as a diagnostic/dump utility — no data transformation, validation, or output file writing occurs.

## Inputs
- `CARDFILE` — VSAM KSDS card master file; sequential read; record key `FD-CARD-NUM` (PIC X(16)); record length 150 bytes (16-byte key + 134-byte data)

## Outputs
- `SYSOUT` — each `CARD-RECORD` (from CVACT02Y) is printed via DISPLAY

## Key Business Rules
1. All records are read sequentially until EOF (status `'10'`).
2. Records are displayed as-is with no filtering, formatting, or selection.
3. Any non-EOF, non-OK file status causes an ABEND via `CEE3ABD`.

## Notable COBOL Constructs
- **Indexed I/O (KSDS sequential):** CARDFILE declared with `ORGANIZATION IS INDEXED`, `ACCESS MODE IS SEQUENTIAL`; the key field `FD-CARD-NUM` orders the reads.
- **REDEFINES (IO-STATUS decode):** `TWO-BYTES-ALPHA REDEFINES TWO-BYTES-BINARY` — used in `9910-DISPLAY-IO-STATUS` to decode 2-byte binary file-status codes for display.

## Copybook Dependencies
- `CVACT02Y` — provides `CARD-RECORD` layout (CARD-NUM, CARD-ACCT-ID, CARD-CVV-CD, CARD-EMBOSSED-NAME, CARD-EXPIRAION-DATE, CARD-ACTIVE-STATUS)

## Called Programs
- `CEE3ABD` — LE ABEND routine

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `FD-CARD-NUM` | `X(16)` | Card number — KSDS primary key |
| `FD-CARD-DATA` | `X(134)` | Remaining card record data |
