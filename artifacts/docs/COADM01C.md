# COADM01C

## Purpose
COADM01C is the CICS pseudo-conversational admin menu program for CardDemo. It presents a numbered menu of admin options (up to 10), accepts a numeric option from the user, and transfers control to the corresponding program via `EXEC CICS XCTL`. Menu items and target program names come from `CDEMO-ADMIN-OPT-*` arrays in COCOM01Y. Admin users are routed here from COSGN00C after successful authentication.

## Inputs
- `COADM1AI` — BMS map input from COADM01 mapset: `OPTIONI` (1–2 char numeric option number)
- `DFHCOMMAREA` — CICS commarea carrying `CARDDEMO-COMMAREA` (includes CDEMO-ADMIN-OPT-* menu table)

## Outputs
- `COADM1AO` — BMS map output (COADM01 mapset) with menu options built dynamically
- `XCTL` to option program — `CDEMO-ADMIN-OPT-PGMNAME(WS-OPTION)` — transfers to the selected program

## Key Business Rules
1. On first entry (`NOT CDEMO-PGM-REENTER`): the screen is sent with menu options populated.
2. On ENTER: the option number is right-justified, spaces replaced with `'0'`, and converted to numeric `WS-OPTION`.
3. Valid option range: 1 to `CDEMO-ADMIN-OPT-COUNT` and non-zero; any other input shows "Please enter a valid option number..."
4. If the selected option's program name does not start with `'DUMMY'`, XCTL transfers to that program; otherwise a "not installed" message is shown and the menu is redisplayed.
5. A `HANDLE CONDITION PGMIDERR` is set at entry: if the XCTL target program is not installed, PGMIDERR-ERR-PARA catches the error and shows the "not installed" message instead of ABENDing.
6. PF3 returns to COSGN00C (the signon screen) via XCTL.
7. Any other AID key shows "Invalid Key" and redisplays the menu.
8. Menu options are built dynamically in `BUILD-MENU-OPTIONS`: up to 10 options using `CDEMO-ADMIN-OPT-NUM(i)` and `CDEMO-ADMIN-OPT-NAME(i)` STRING'd together.

## Notable COBOL Constructs
- **EXEC CICS HANDLE CONDITION PGMIDERR:** Sets a condition handler so that if the target program is not found during XCTL, control falls to `PGMIDERR-ERR-PARA` instead of causing an ABEND — a CICS exception-handling mechanism.
- **Pseudo-conversational pattern:** `RETURN TRANSID('CA00') COMMAREA(CARDDEMO-COMMAREA)` — returns to CICS after every send; state is preserved in COMMAREA.
- **Right-justified option parsing:** `PERFORM VARYING WS-IDX FROM LENGTH ... BY -1 UNTIL NOT SPACES` finds the rightmost non-space character; then INSPECT replaces spaces with `'0'` for numeric conversion.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA` with CDEMO-ADMIN-OPT-COUNT, CDEMO-ADMIN-OPT-PGMNAME, CDEMO-ADMIN-OPT-NUM, CDEMO-ADMIN-OPT-NAME arrays
- `COADM02Y` — additional admin option metadata
- `COADM01` — BMS mapset definitions (COADM1AI, COADM1AO, OPTN001O–OPTN010O)
- `COTTL01Y` — screen title constants
- `CSDAT01Y` — current date/time working storage
- `CSMSG01Y` — standard message constants
- `CSUSR01Y` — user record layout
- `DFHAID` — AID key constants (DFHENTER, DFHPF3)
- `DFHBMSCA` — BMS attribute constants (DFHGREEN)

## Called Programs
None (uses `EXEC CICS XCTL` for navigation)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `WS-OPTION-X` | `X(02)` | Right-justified input option before numeric conversion |
| `WS-OPTION` | `9(02)` | Numeric option selected |
| `CDEMO-ADMIN-OPT-COUNT` | numeric | Number of menu options in commarea |
| `CDEMO-ADMIN-OPT-PGMNAME(n)` | `X(08)` | Target program for option n; `'DUMMY...'` = not implemented |
