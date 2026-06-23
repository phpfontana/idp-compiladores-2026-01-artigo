# COUSR02C

## Purpose
COUSR02C is the CICS pseudo-conversational user update program for CardDemo (admin function). Given a user ID (entered directly or passed from COUSR00C via `CDEMO-CU02-USR-SELECTED`), it reads the USRSEC VSAM KSDS, displays the current user data, allows editing of first name, last name, password, and user type, and rewrites the record on PF5 or PF3. Trans-ID is `CU02`.

## Inputs
- `COUSR2AI` — BMS map input from COUSR02 mapset: `USRIDINI` (user ID, 8 chars), `FNAMEI`, `LNAMEI`, `PASSWDI`, `USRTYPEI`
- `DFHCOMMAREA` — CICS commarea; `CDEMO-CU02-USR-SELECTED` pre-populates user ID on first entry from COUSR00C
- `USRSEC` CICS VSAM KSDS — user security file; read and rewritten

## Outputs
- Updated record in `USRSEC` with new first name, last name, password, and/or user type
- `COUSR2AO` — BMS map output with confirmation or error message
- `XCTL` to `COADM01C` or `CDEMO-FROM-PROGRAM` (PF3/PF12)

## Key Business Rules
1. `EIBCALEN = 0` → XCTL to COSGN00C.
2. On first entry with `CDEMO-CU02-USR-SELECTED` non-empty: user ID is pre-populated and record is immediately read and displayed.
3. ENTER: reads USRSEC by user ID; displays all current field values on screen.
4. PF5: `UPDATE-USER-INFO` validates and rewrites. Validation:
   - USER-ID non-empty
   - FNAME non-empty
   - LNAME non-empty
   - PASSWORD non-empty
   - USER-TYPE non-empty (validation continues at line 200+, not shown but consistent with add pattern)
5. PF3: also calls `UPDATE-USER-INFO` before returning to the calling program — saves on exit.
6. PF4: clears the form without saving.
7. PF12: returns to COADM01C without saving.
8. `EXEC CICS READ ... UPDATE` is used for USRSEC read (locks the record for update); followed by REWRITE.

## Notable COBOL Constructs
- **PF3 triggers save before exit:** Unusual pattern — most programs exit without saving on PF3; here `UPDATE-USER-INFO` fires on PF3. Migration must preserve this behavior.
- **Pre-population from COUSR00C:** `CDEMO-CU02-USR-SELECTED` carries the user ID from the list screen, enabling a drill-down without the user retyping the key.
- **`WS-USR-MODIFIED` flag:** Present but evaluating its usage is incomplete in the first 200 lines; likely tracks whether edits were made before the save.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA`; `CDEMO-CU02-INFO` appended inline
- `COUSR02` — BMS mapset (COUSR2AI, COUSR2AO)
- `CSUSR01Y` — `SEC-USER-DATA` (SEC-USR-FNAME, SEC-USR-LNAME, SEC-USR-PWD, SEC-USR-TYPE)
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y` — standard copybooks
- `DFHAID`, `DFHBMSCA` — CICS constants

## Called Programs
None (EXEC CICS READ/REWRITE for file I/O; XCTL for navigation)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `CDEMO-CU02-USR-SELECTED` | `X(08)` | Pre-selected user ID from COUSR00C |
| `SEC-USR-FNAME` / `SEC-USR-LNAME` | `X(n)` | First/last name from CSUSR01Y |
| `SEC-USR-PWD` | `X(08)` | Password (plain text) |
| `WS-USR-MODIFIED` | `X(01)` | Edit tracking flag |
