# COSGN00C

## Purpose
COSGN00C is the CICS pseudo-conversational signon program for CardDemo. It presents a signon screen (COSGN0A) where users enter a user ID and password, reads the USRSEC VSAM dataset to authenticate, then transfers control to COADM01C (admin users) or COMEN01C (regular users) via XCTL. It is the entry point for the online CardDemo application.

## Inputs
- `COSGN0AI` — BMS map input from COSGN00 mapset: `USERIDI` (user ID, 8 chars), `PASSWDI` (password, 8 chars)
- `DFHCOMMAREA` — CICS commarea carrying `CARDDEMO-COMMAREA`
- `USRSEC` — CICS-managed VSAM KSDS security file; read by key = upper-cased user ID; contains `SEC-USR-PWD` and `SEC-USR-TYPE`

## Outputs
- `COSGN0AO` — BMS map output (COSGN00 mapset) with error messages and screen header
- `XCTL` to `COADM01C` — if authenticated user has admin type
- `XCTL` to `COMEN01C` — if authenticated user is a regular user

## Key Business Rules
1. On first entry (`EIBCALEN = 0`), the signon screen is presented with cursor on USERID field.
2. On ENTER: both USER ID and PASSWORD must be non-empty; otherwise a field-specific error message is shown.
3. User ID and password are converted to uppercase via `FUNCTION UPPER-CASE` before lookup.
4. The USRSEC file is read via `EXEC CICS READ DATASET('USRSEC') RIDFLD(WS-USER-ID)`; RESP=0 means found, RESP=13 means not found.
5. On successful read, `SEC-USR-PWD` must exactly equal the uppercase `WS-USER-PWD`; mismatch returns "Wrong Password. Try again..." and re-prompts.
6. On successful authentication, `CDEMO-USER-ID` and `CDEMO-USER-TYPE` are set in COMMAREA, then XCTL transfers to COADM01C or COMEN01C based on `CDEMO-USRTYP-ADMIN`.
7. PF3 sends a "Thank you" plain text message and terminates via `EXEC CICS RETURN` (no TRANSID — terminates the task).
8. Any other AID key results in an "Invalid Key" error message on the signon screen.
9. EIBCALEN > 0 but no COMMAREA processing — `EVALUATE EIBAID` fires immediately (no state saved between pseudo-conversational returns for signon).

## Notable COBOL Constructs
- **EXEC CICS READ (VSAM direct):** Uses CICS file control for USRSEC — not sequential VSAM, but a CICS-managed KSDS random read; Java equivalent is a JDBC or direct key-value store lookup.
- **EXEC CICS ASSIGN APPLID / SYSID:** Retrieves the CICS region APPLID and SYSID for display in the screen header — no Java equivalent; mock with environment variable.
- **XCTL for authenticated navigation:** `EXEC CICS XCTL PROGRAM('COADM01C')` — transfers control and clears the current program stack; Java equivalent is method dispatch or servlet forward.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA` (CDEMO-USER-ID, CDEMO-USER-TYPE, CDEMO-USRTYP-ADMIN)
- `COSGN00` — BMS mapset definitions (COSGN0AI, COSGN0AO)
- `COTTL01Y` — screen title constants
- `CSDAT01Y` — current date/time working storage
- `CSMSG01Y` — standard message constants
- `CSUSR01Y` — `SEC-USER-DATA` layout (SEC-USR-PWD, SEC-USR-TYPE)
- `DFHAID` — AID key constants (DFHENTER, DFHPF3)
- `DFHBMSCA` — BMS attribute constants

## Called Programs
None (uses `EXEC CICS XCTL` for navigation, not CALL)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `WS-USER-ID` | `X(08)` | Upper-cased user ID used as USRSEC lookup key |
| `WS-USER-PWD` | `X(08)` | Upper-cased password compared to SEC-USR-PWD |
| `SEC-USR-PWD` | `X(08)` | Stored password from USRSEC (from CSUSR01Y) |
| `SEC-USR-TYPE` | `X(01)` | User type: drives admin vs. regular menu routing |
| `CDEMO-USER-TYPE` | `X(01)` | Copied to COMMAREA; `CDEMO-USRTYP-ADMIN` 88-level checks admin |
