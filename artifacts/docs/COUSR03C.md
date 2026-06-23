# COUSR03C

## Purpose
COUSR03C is the CICS pseudo-conversational user delete program for CardDemo (admin function). Given a user ID (entered directly or passed from COUSR00C via `CDEMO-CU03-USR-SELECTED`), it reads the USRSEC VSAM KSDS record, displays the user for review, and deletes it on PF5 via `EXEC CICS DELETE`. Trans-ID is `CU03`.

## Inputs
- `COUSR3AI` — BMS map input from COUSR03 mapset: `USRIDINI` (user ID, 8 chars)
- `DFHCOMMAREA` — CICS commarea; `CDEMO-CU03-USR-SELECTED` pre-populates user ID on first entry from COUSR00C
- `USRSEC` CICS VSAM KSDS — user security file; read then deleted

## Outputs
- Record deleted from `USRSEC` for the entered user ID
- `COUSR3AO` — BMS map output with confirmation or error message
- `XCTL` to `COADM01C` or `CDEMO-FROM-PROGRAM` (PF3/PF12)

## Key Business Rules
1. `EIBCALEN = 0` → XCTL to COSGN00C.
2. On first entry with `CDEMO-CU03-USR-SELECTED` non-empty: user ID is pre-populated; record is read and displayed for review.
3. ENTER: `PROCESS-ENTER-KEY` reads USRSEC by user ID and shows the record; first name, last name, and user type are displayed (password is NOT displayed — it is not moved to the screen in `PROCESS-ENTER-KEY`).
4. PF5: `DELETE-USER-INFO` reads the record again (to confirm it exists) then calls `DELETE-USER-SEC-FILE` (`EXEC CICS DELETE DATASET('USRSEC')`).
5. PF3: exits to calling program or COADM01C; no delete occurs.
6. PF12: exits to COADM01C unconditionally; no delete.
7. PF4: clears the form.
8. No "are you sure?" confirmation step — PF5 immediately deletes with no second confirmation.

## Notable COBOL Constructs
- **No confirmation prompt:** Unlike COBIL00C (which requires `CONFIRMI = 'Y'`) or COTRN02C, this program deletes on a single PF5 press — a UX risk.
- **Password hidden from delete screen:** `PROCESS-ENTER-KEY` moves FNAME/LNAME/USRTYPE to screen but not PWD — unlike COUSR02C which shows the password. This is the only screen where the password field is intentionally withheld.
- **Read-before-delete:** `DELETE-USER-INFO` reads the record first (`PERFORM READ-USER-SEC-FILE`) before deleting — validates existence before issuing EXEC CICS DELETE.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA`; `CDEMO-CU03-INFO` appended inline
- `COUSR03` — BMS mapset (COUSR3AI, COUSR3AO)
- `CSUSR01Y` — `SEC-USER-DATA`
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y` — standard copybooks
- `DFHAID`, `DFHBMSCA` — CICS constants

## Called Programs
None (EXEC CICS READ/DELETE for file I/O; XCTL for navigation)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `CDEMO-CU03-USR-SELECTED` | `X(08)` | Pre-selected user ID from COUSR00C |
| `SEC-USR-ID` | `X(08)` | Primary key for USRSEC DELETE |
| `SEC-USR-FNAME` / `SEC-USR-LNAME` | (from CSUSR01Y) | Displayed for review before delete |
