# COUSR01C

## Purpose
COUSR01C is the CICS pseudo-conversational user add program for CardDemo (admin function). It presents a blank form where the admin enters first name, last name, user ID, password, and user type, then writes the new user record to the USRSEC VSAM KSDS. No duplicate-key check is documented; CICS WRITE with a duplicate key will generate a DUPKEY condition. Trans-ID is `CU01`.

## Inputs
- `COUSR1AI` — BMS map input from COUSR01 mapset: `FNAMEI` (first name), `LNAMEI` (last name), `USERIDI` (user ID, 8 chars), `PASSWDI` (password, 8 chars), `USRTYPEI` (user type)
- `DFHCOMMAREA` — CICS commarea with `CARDDEMO-COMMAREA`
- `USRSEC` CICS VSAM KSDS — user security file; written via EXEC CICS WRITE

## Outputs
- New record in `USRSEC` with SEC-USR-ID, SEC-USR-FNAME, SEC-USR-LNAME, SEC-USR-PWD, SEC-USR-TYPE
- `COUSR1AO` — BMS map output with success or error message
- `XCTL` to `COADM01C` — PF3 exit

## Key Business Rules
1. `EIBCALEN = 0` → XCTL to COSGN00C.
2. All five fields are mandatory. Validation is sequential (first blank field encountered triggers error):
   - FNAMEI empty → "First Name can NOT be empty..."
   - LNAMEI empty → "Last Name can NOT be empty..."
   - USERIDI empty → "User ID can NOT be empty..."
   - PASSWDI empty → "Password can NOT be empty..."
   - USRTYPEI empty → "User Type can NOT be empty..."
3. If all pass, all fields are moved to `SEC-USER-DATA` (from CSUSR01Y) and `WRITE-USER-SEC-FILE` is called.
4. PF3 → XCTL to COADM01C; no save on PF3 (just exit).
5. PF4 clears the form.
6. No explicit duplicate-key handling visible in the read portion — CICS WRITE DUPKEY would cause ABEND unless HANDLE CONDITION or NOHANDLE is used.
7. Password is stored in plain text (SEC-USR-PWD PIC X(08)) — a security weakness to document for migration.

## Notable COBOL Constructs
- **Sequential validation chain:** EVALUATE TRUE with WHEN-chain stops at the first blank field and immediately does PERFORM SEND-USRADD-SCREEN — no full multi-field validation pass.
- **SEC-USER-DATA (CSUSR01Y):** Reused across all user management programs; contains SEC-USR-ID/FNAME/LNAME/PWD/TYPE — a common data-structure pattern in this application.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA`
- `COUSR01` — BMS mapset (COUSR1AI, COUSR1AO)
- `CSUSR01Y` — `SEC-USER-DATA`
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y` — standard copybooks
- `DFHAID`, `DFHBMSCA` — CICS constants

## Called Programs
None (EXEC CICS WRITE for file I/O; XCTL for navigation)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `SEC-USR-ID` | `X(08)` | Primary key of USRSEC record |
| `SEC-USR-PWD` | `X(08)` | Password stored in plain text |
| `SEC-USR-TYPE` | `X(01)` | User type: `'A'` = admin, `'U'` = regular (from COSGN00C) |
