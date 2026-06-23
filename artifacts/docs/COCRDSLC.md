# COCRDSLC

## Purpose
COCRDSLC is the CICS pseudo-conversational credit card detail view program for CardDemo. Given an account ID and card number, it reads the CARDDAT CICS dataset and displays the full card record including card number, embossed name, status, expiry date, and CVV. It is a read-only inquiry screen — no updates are made.

## Inputs
- `CCRDSIAI` — BMS map input from COCRDSL mapset: `ACCTIDNI` (account ID), `CARDNINI` (card number)
- `DFHCOMMAREA` — CICS commarea carrying `CARDDEMO-COMMAREA` (includes CDEMO-CT00-TRN-SELECTED from COCRDLIC if pre-selected)
- `CARDDAT` CICS VSAM KSDS — card master; read by composite key (card number + account ID via `WS-CARD-RID`)

## Outputs
- `CCRDSLAO` — BMS map output (COCRDSL mapset) with: account ID, card number (CARD-CARD-NUM-X), embossed name (CARD-NAME-EMBOSSED-X), card status (CARD-STATUS-X), expiry date (YYYY-MM-DD split into CARD-EXPIRY-YEAR/MONTH/DAY via REDEFINES), CVV (CARD-CVV-CD-X)
- `XCTL` to `COCRDLIC` — PF3 returns to card list
- `XCTL` to `COMEN01C` — PF3 when no calling context

## Key Business Rules
1. Account ID and card number must both be non-empty and numeric; blanks or non-numerics show respective error messages.
2. Account ID must be non-zero 11-digit; card number must be 16-digit (or blank, in which case any card for the account may be shown).
3. CARDDAT is read with composite key `WS-CARD-RID` = CARD-NUM(16) + ACCT-ID(11); RESP checked; RESP=13 = not found.
4. Card expiry date is split for display via REDEFINES: `CARD-EXPIRAION-DATE-X` overlaid with year/separator/month/separator/day sub-fields.
5. CVV is stored as `9(03)` but displayed via `CARD-CVV-CD-X` (X(03) REDEFINES) — masked as alphanumeric.
6. PF3 returns to COCRDLIC (or COMEN01C if no calling context in commarea).
7. Any invalid PF key is treated silently (no error message in this program — AID is remapped to ENTER).

## Notable COBOL Constructs
- **REDEFINES for expiry date parsing:** `CARD-EXPIRAION-DATE-X PIC X(10)` redefined with year/month/day sub-fields — Java equivalent: `LocalDate.parse` with formatter.
- **REDEFINES for numeric/alphanumeric duality:** CVV and account ID each have `X(n)` and `9(n)` REDEFINES for validation vs. display purposes.
- **Variable-length DFHCOMMAREA:** `OCCURS 1 TO 32767 TIMES DEPENDING ON EIBCALEN` — standard CICS pattern for handling both initial and re-entry calls.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA`
- `CVCRD01Y` — `CC-WORK-AREA`
- `COCRDSL` — BMS mapset (CCRDSIAI, CCRDSLAO)
- `CVACT02Y` — `CARD-RECORD` (CARD-NUM, CARD-ACCT-ID, CARD-CVV-CD, CARD-NAME-EMBOSSED, CARD-STATUS, CARD-EXPIRAION-DATE)
- `CVCUS01Y` — customer record layout (referenced but not used for display in this program)
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y`, `CSMSG02Y`, `CSUSR01Y` — standard copybooks
- `DFHBMSCA`, `DFHAID` — CICS constants

## Called Programs
None (XCTL only)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `WS-CARD-RID-CARDNUM` | `X(16)` | Card number part of CARDDAT KSDS key |
| `WS-CARD-RID-ACCT-ID` | `9(11)` | Account ID part of CARDDAT KSDS key |
| `CARD-CVV-CD-X` | `X(03)` | CVV code (alphanumeric display view) |
| `CARD-EXPIRY-YEAR` | `X(04)` | Year sub-field of expiry via REDEFINES |
| `CARD-EXPIRY-MONTH` | `X(02)` | Month sub-field of expiry via REDEFINES |
