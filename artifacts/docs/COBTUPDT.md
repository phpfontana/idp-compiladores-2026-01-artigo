# COBTUPDT

## Purpose
COBTUPDT is a batch COBOL program that reads a sequential input file and applies insert/update/delete operations to the DB2 `TRANSACTION_TYPE` table (`DCLTRTYP`). Each input record specifies a record type (I/U/D), transaction type number (2 chars), and description (50 chars). It serves as a bulk-maintenance utility for the transaction type reference table used by COTRTLIC/COTRTUPC.

## Sub-Application
`app-transaction-type-db2` — not part of the five-program core subset; requires DB2.

## Inputs
- `INPFILE` — sequential file (`TR-RECORD`), records: `INPUT-TYPE PIC X(1)` + `INPUT-TR-NUMBER PIC X(2)` + `INPUT-TR-DESC PIC X(50)` (53 bytes, RECORDING MODE F)
- DB2 `TRANSACTION_TYPE` table (via EXEC SQL INCLUDE DCLTRTYP)
- `SQLCA` (EXEC SQL INCLUDE SQLCA) for error handling

## Outputs
- DB2 `TRANSACTION_TYPE` table rows inserted/updated/deleted
- `WS-RETURN-MSG PIC X(80)` — diagnostic messages

## Key Business Rules
1. `INPUT-TYPE = 'I'` → INSERT; `'U'` → UPDATE; `'D'` → DELETE.
2. SQLCODE checked after each EXEC SQL; non-zero causes error message and STOP RUN.
3. `WS-VAR-SQLCODE PIC ----9` (5-digit signed display) used for formatted SQLCODE display.
4. `LASTREC PIC X(1)` flag tracks end-of-file from AT END clause.

## Notable COBOL Constructs
- **Embedded SQL:** `EXEC SQL INSERT/UPDATE/DELETE ... END-EXEC` — standard COBOL/DB2 precompiler pattern; Java equivalent: JDBC PreparedStatement.
- **EXEC SQL INCLUDE DCLTRTYP:** DB2-generated host variable declarations for the TRANSACTION_TYPE table.
