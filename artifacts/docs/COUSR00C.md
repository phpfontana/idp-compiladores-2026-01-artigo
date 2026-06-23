# COUSR00C

## Purpose
COUSR00C is the CICS pseudo-conversational user list program for CardDemo (admin function). It displays up to 10 user records per page from the USRSEC VSAM KSDS, supports forward/backward pagination (PF7/PF8), accepts a user ID prefix as filter, and lets the admin select a user for update (`U` → COUSR02C) or delete (`D` → COUSR03C). This is an admin-only screen; Trans-ID is `CU00`.

## Inputs
- `COUSR0AI` — BMS map input from COUSR00 mapset: `USRIDINI` (starting user ID for browse), `SEL0001I`–`SEL0010I` (action flags), `USRID01I`–`USRID10I` (user IDs of displayed rows)
- `DFHCOMMAREA` — CICS commarea with `CARDDEMO-COMMAREA` plus `CDEMO-CU00-INFO` (CDEMO-CU00-USRID-FIRST, CDEMO-CU00-USRID-LAST, CDEMO-CU00-PAGE-NUM, CDEMO-CU00-NEXT-PAGE-FLG, CDEMO-CU00-USR-SEL-FLG, CDEMO-CU00-USR-SELECTED)
- `USRSEC` CICS VSAM KSDS — user security file; browsed with STARTBR/READNEXT (forward) or STARTBR/READPREV (backward)

## Outputs
- `COUSR0AO` — BMS map output (COUSR00 mapset) with up to 10 rows of (USER-SEL, USER-ID, USER-NAME, USER-TYPE)
- `XCTL` to `COUSR02C` — when user selects `U` on a row (update)
- `XCTL` to `COUSR03C` — when user selects `D` on a row (delete)
- `XCTL` to `COADM01C` — PF3 exit (admin menu)

## Key Business Rules
1. `EIBCALEN = 0` → XCTL to COSGN00C (must be authenticated).
2. On first entry (`NOT CDEMO-PGM-REENTER`): reads forward from beginning and displays first page.
3. ENTER: if a row has `SEL = 'U'`/`'u'` → XCTL to COUSR02C; if `'D'`/`'d'` → XCTL to COUSR03C; any other non-blank value shows "Invalid selection. Valid values are U and D".
4. If `USRIDINI` is non-empty, it becomes the STARTBR key for the next forward browse.
5. PF7/PF8: same forward/backward pattern as COTRN00C; page number tracked in `CDEMO-CU00-PAGE-NUM`; "already at top" on page 1.
6. PF3 → XCTL to COADM01C unconditionally.
7. `WS-USER-DATA` — in-memory array of 10 rows (`USER-REC OCCURS 10 TIMES`) for screen population, each containing USER-SEL, USER-ID (X(8)), USER-NAME (X(25)), USER-TYPE (X(8)).
8. "No records found" if browse returns empty.

## Notable COBOL Constructs
- **OCCURS 10 TIMES (WS-USER-DATA):** Explicit 10-element array for screen rows — same hand-coded 10-row pattern as COTRN00C.
- **PF3 goes to COADM01C (not COMEN01C):** Signals this is an admin-only function; contrast with transaction programs which return to COMEN01C.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA`; `CDEMO-CU00-INFO` appended inline
- `COUSR00` — BMS mapset (COUSR0AI, COUSR0AO)
- `CSUSR01Y` — `SEC-USER-DATA` (SEC-USR-ID, SEC-USR-FNAME, SEC-USR-LNAME, SEC-USR-TYPE)
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y` — standard copybooks
- `DFHAID`, `DFHBMSCA` — CICS constants

## Called Programs
None (XCTL only)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `CDEMO-CU00-USRID-FIRST` | `X(08)` | First USER-ID on page; used for PF7 |
| `CDEMO-CU00-USRID-LAST` | `X(08)` | Last USER-ID on page; used for PF8 |
| `CDEMO-CU00-USR-SELECTED` | `X(08)` | USER-ID passed to COUSR02C/COUSR03C |
| `USER-REC OCCURS 10` | — | In-memory display buffer (10 rows) |
