# COTRTLIC

## Purpose
COTRTLIC is a CICS COBOL DB2 program that lists transaction types from the DB2 `TRANSACTION_TYPE` table with cursor-based paging. The user can select a type for update (`U`) or delete (`D`) — both route to COTRTUPC. It demonstrates DB2 cursor-based pagination within CICS pseudo-conversational programs. Trans-ID is `CTLI`.

## Sub-Application
`app-transaction-type-db2` — not part of the five-program core subset; requires DB2 and CICS.

## Inputs
- BMS map input (COTRTLI mapset, CTRTLIA map): selection flags for up to 7 rows
- `TRANSACTION_TYPE` DB2 table (via cursor OPEN/FETCH)
- `DFHCOMMAREA` — CICS commarea with `CARDDEMO-COMMAREA`

## Outputs
- BMS map output: up to 7 rows of transaction type data
- `XCTL` to `COTRTUPC` (Trans-ID CTTU) — for U and D selections
- `XCTL` to `COADM01C` — PF3 exit to admin menu

## Key Business Rules
1. `WS-MAX-SCREEN-LINES = 7` — 7 rows per page (same as COCRDLIC).
2. DB2 cursor opened with ORDER BY clause; FETCH used for pagination.
3. `LIT-TRANTYPE-TABLE = 'TRANSACTION_TYPE '` — exact table name used in SQL.
4. `LIT-DSNTIAC = 'DSNTIAC'` — IBM DB2 error handler CALLed on SQL errors.
5. `LIT-DELETE-FLAG = 'D'`, `LIT-UPDATE-FLAG = 'U'` — action codes.
6. Both D and U route to COTRTUPC; the action flag is passed in COMMAREA.
7. PF3 → COADM01C (admin-only screen).

## Notable COBOL Constructs
- **DB2 cursor paging:** `EXEC SQL DECLARE ... CURSOR FOR SELECT ... FROM TRANSACTION_TYPE END-EXEC` followed by OPEN/FETCH — Java equivalent: JDBC ResultSet with `setFetchSize`.
- **DSNTIAC error handler:** IBM-supplied DB2 COBOL error handler called via CALL 'DSNTIAC' on non-zero SQLCODE.
