# COCRDUPC

## Purpose
COCRDUPC is the CICS pseudo-conversational credit card update program for CardDemo. The user enters an account ID and card number to look up a card record, views the current values, edits them (embossed name, card status, expiry date), and saves via PF5. The program validates inputs, acquires an UPDATE lock on CARDDAT, checks for concurrent modifications (optimistic conflict detection), and writes the updated record. Trans-ID is `CCUP`.

## Inputs
- `CCRDUIAI` — BMS map input from COCRDUP mapset: `ACCTIDNI` (account), `CARDNINI` (card number), `CNAMEI` (embossed name), `CSTATI` (card status Y/N), `CEXPYRI`/`CEXPMI` (expiry year/month)
- `DFHCOMMAREA` — CICS commarea; carries `CARDDEMO-COMMAREA` plus `WS-THIS-PROGCOMMAREA` (from-program, from-tranid)
- `CARDDAT` CICS VSAM KSDS — card master; read with UPDATE lock, then REWRITE on confirmation
- `CARDAIX` CICS VSAM AIX — alternate index by account; used for lookup when only account ID is supplied

## Outputs
- Updated record in `CARDDAT` — changed name, status, and/or expiry date
- `CCRDUIAO` — BMS map output with current card values and messages
- `XCTL` to `COCRDLIC` (PF3, back to list) or `COMEN01C` (PF3, no context)

## Key Business Rules
1. Account ID must be non-zero 11-digit numeric; card number must be 16-digit numeric.
2. Embossed name must be non-empty and alpha-only (INSPECT TALLYING non-alpha chars; `CARD-NAME-CHECK` used for validation).
3. Card status must be `'Y'` or `'N'`; any other value fails with "Card Active Status must be Y or N".
4. Expiry month must be 1–12 (`VALID-MONTH` 88-level on `CARD-MONTH-CHECK-N PIC 9(2)`).
5. Expiry year must be 1950–2099 (`VALID-YEAR` 88-level on `CARD-YEAR-CHECK-N PIC 9(4)`).
6. Optimistic locking: card data read during lookup is saved in WS; on PF5 save, the current DB record is re-read (with UPDATE lock) and compared to saved values — if changed, "Record changed by some one else" error.
7. PF5 (save/confirm): after all edits pass validation, the record is REWRITTEN; "Changes committed to database" message on success.
8. `NO-CHANGES-DETECTED`: if user does not change any field from the read values, save is skipped with a no-change message.
9. PF3 returns to COCRDLIC (or COMEN01C if no calling context).

## Notable COBOL Constructs
- **EXEC CICS READ ... UPDATE:** Locks the CARDDAT record; CICS releases the lock on REWRITE or UNLOCK; Java equivalent is SELECT FOR UPDATE in JDBC or optimistic version fields.
- **Optimistic concurrency check:** Compare saved WS copy of record with re-read values before REWRITE — a pattern that CICS requires because UPDATE locks are released between pseudo-conversational turns; Java avoids this if using DB transactions.
- **CARD-NAME-CHECK PIC X(50):** Used with INSPECT TALLYING COUNT WHEN NOT ALPHABETIC-UPPER/-LOWER/-SPACE to detect non-alpha characters; Java equivalent is `String.matches("[A-Za-z ]+")`.
- **CARD-MONTH-CHECK-N REDEFINES CARD-MONTH-CHECK:** Numeric overlay of alphanumeric input for range validation — Java: `Integer.parseInt` + bounds check.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA`
- `CVCRD01Y` — `CC-WORK-AREA`
- `COCRDUP` — BMS mapset (CCRDUIAI, CCRDUIAO)
- `CVACT02Y` — `CARD-RECORD` (CARD-NUM, CARD-ACCT-ID, CARD-CVV-CD, CARD-NAME-EMBOSSED, CARD-STATUS, CARD-EXPIRAION-DATE)
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y`, `CSMSG02Y`, `CSUSR01Y` — standard copybooks
- `DFHBMSCA`, `DFHAID` — CICS constants

## Called Programs
None (XCTL only)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `WS-CARD-RID-CARDNUM` | `X(16)` | Card number; CARDDAT KSDS key component |
| `CARD-MONTH-CHECK-N` | `9(02)` REDEFINES | Month as numeric; 88 VALID-MONTH = 1 THRU 12 |
| `CARD-YEAR-CHECK-N` | `9(04)` REDEFINES | Year as numeric; 88 VALID-YEAR = 1950 THRU 2099 |
| `FLG-YES-NO-CHECK` | `X(01)` | Validates `'Y'`/`'N'` for status field |
