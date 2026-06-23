# COTRTUPC

## Purpose
COTRTUPC is a CICS COBOL DB2 program that adds or updates a transaction type record in the DB2 `TRANSACTION_TYPE` table. Called from COTRTLIC with action 'U' (update) or 'D' (delete), it validates the transaction type number and description, then executes the appropriate EXEC SQL statement. Trans-ID is `CTTU`.

## Sub-Application
`app-transaction-type-db2` — not part of the five-program core subset; requires DB2 and CICS.

## Inputs
- BMS map input (COTRTUP mapset, CTRTUPA map): transaction type number (X(2)), description (X(50))
- `DFHCOMMAREA` — CICS commarea with action flag from COTRTLIC
- `TRANSACTION_TYPE` DB2 table

## Outputs
- DB2 `TRANSACTION_TYPE` row inserted, updated, or deleted via EXEC SQL
- BMS map output: success or error message

## Key Business Rules
1. `WS-EDIT-ALPHANUM-ONLY PIC X(256)` — generic alphanumeric validation buffer; validated via INSPECT TALLYING.
2. `WS-EDIT-ALPHANUM-LENGTH PIC S9(4) COMP-3` — length of content to validate.
3. Date edit variables via `COPY CSUTLDWY` — consistent date validation infrastructure.
4. `WS-DATACHANGED-FLAG` (`'0'` = no change, `'1'` = changed) — prevents unnecessary SQL UPDATE when no fields changed.
5. `WS-DISP-SQLCODE PIC ----9` — signed display format for SQLCODE error reporting.
6. `WS-STRING-MID`, `WS-STRING-LEN`, `WS-STRING-OUT` — STRING verb helpers for description formatting.

## Notable COBOL Constructs
- **WS-EDIT-ALPHANUM-ONLY PIC X(256):** Generic validation buffer large enough for any field; reused by INSPECT; Java equivalent: `s.matches("[A-Za-z0-9 ]+")`
- **EXEC SQL UPDATE/INSERT/DELETE:** Embedded SQL in CICS; Java equivalent: JDBC PreparedStatement within a CICS-analogous transaction.
