# COMEN01C

## Purpose
COMEN01C is the CICS pseudo-conversational main menu program for regular (non-admin) CardDemo users. It presents a numbered list of up to 12 menu options (from `CDEMO-MENU-OPT-*` arrays in COCOM01Y), accepts a numeric selection, and transfers control to the corresponding program via `EXEC CICS XCTL`. Admin-only options are blocked for regular users. It mirrors COADM01C in structure but serves a different user population.

## Inputs
- `COMEN1AI` — BMS map input from COMEN01 mapset: `OPTIONI` (1–2 char numeric option)
- `DFHCOMMAREA` — CICS commarea carrying `CARDDEMO-COMMAREA` (includes CDEMO-MENU-OPT-* arrays and CDEMO-USRTYP-USER flag)

## Outputs
- `COMEN1AO` — BMS map output (COMEN01 mapset) with up to 12 menu options (OPTN001O–OPTN012O)
- `XCTL` to selected option program

## Key Business Rules
1. On first entry (`NOT CDEMO-PGM-REENTER`): menu screen is built from COMMAREA option arrays and sent.
2. On ENTER: option is right-trimmed, spaces replaced with `'0'`, converted to numeric; valid range is 1 to `CDEMO-MENU-OPT-COUNT`.
3. If the selected option has `CDEMO-MENU-OPT-USRTYPE(n) = 'A'` and the current user is a regular user (`CDEMO-USRTYP-USER`), access is denied with "No access - Admin Only option..."
4. If the option program name is `'COPAUS0C'`, availability is first checked with `EXEC CICS INQUIRE PROGRAM ... NOHANDLE`; if not found, "not installed" message is shown.
5. If the option program name starts with `'DUMMY'`, a "coming soon" message is shown instead of XCTL.
6. PF3 returns to the COSGN00C signon screen.
7. Any other AID key shows "Invalid Key" and redisplays the menu.
8. Up to 12 menu options are supported (one more than COADM01C's 10).

## Notable COBOL Constructs
- **EXEC CICS INQUIRE PROGRAM:** Used specifically for COPAUS0C to dynamically check installation; `NOHANDLE` suppresses any CICS condition; result checked via `EIBRESP = DFHRESP(NORMAL)`.
- **CDEMO-MENU-OPT-USRTYPE check:** Compares option metadata `'A'`=admin-only vs. access based on commarea user type — a role-based access control pattern implemented entirely in WORKING-STORAGE.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA` with CDEMO-MENU-OPT-COUNT, CDEMO-MENU-OPT-PGMNAME, CDEMO-MENU-OPT-NAME, CDEMO-MENU-OPT-USRTYPE arrays; CDEMO-USRTYP-USER/ADMIN flags
- `COMEN02Y` — additional menu option constants
- `COMEN01` — BMS mapset definitions (COMEN1AI, COMEN1AO)
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y`, `CSUSR01Y` — standard header/message/user copybooks
- `DFHAID`, `DFHBMSCA` — CICS AID/BMS attribute constants

## Called Programs
None (uses `EXEC CICS XCTL` for navigation)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `WS-OPTION` | `9(02)` | Numeric option selected |
| `CDEMO-MENU-OPT-COUNT` | numeric | Number of available menu options |
| `CDEMO-MENU-OPT-USRTYPE(n)` | `X(01)` | `'A'` = admin-only; blocks regular users |
| `CDEMO-MENU-OPT-PGMNAME(n)` | `X(08)` | XCTL target program; `'DUMMY...'` = coming soon |
