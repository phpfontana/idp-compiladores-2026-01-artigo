# COACTUPC

## Purpose
COACTUPC is the CICS pseudo-conversational account and customer update program for CardDemo — the most complex CICS program in the application. Given an account ID, it reads ACCTDAT (account) and CUSTDAT (customer) via CXACAIX cross-reference, displays both records for editing, performs exhaustive field-by-field validation (including phone NANP validation, SSN part validation, FICO score range check, dates via CSUTLDTC, alphanumeric name/address checks), and rewrites both ACCTDAT and CUSTDAT on PF5 confirmation. Trans-ID is `CAUP`.

## Inputs
- `CACTUPAI` — BMS map input from COACTUP mapset: account ID plus all editable account and customer fields
- `DFHCOMMAREA` — CICS commarea carrying `CARDDEMO-COMMAREA` plus `WS-THIS-PROGCOMMAREA` (large: ACUP-CHANGE-ACTION state, ACUP-OLD-DETAILS snapshot, ACUP-NEW-DETAILS snapshot)
- `ACCTDAT` CICS VSAM KSDS — account master; READ with UPDATE lock for edit
- `CUSTDAT` CICS VSAM KSDS — customer master; READ with UPDATE lock for edit
- `CXACAIX` CICS VSAM AIX — account→card cross-reference; used to resolve customer ID from account

## Outputs
- Updated record in `ACCTDAT` (account status, balances, limits, dates, group ID)
- Updated record in `CUSTDAT` (name, address, phone numbers, SSN, DOB, FICO score, EFT account ID, primary holder indicator)
- `CACTUPAО` — BMS map output with current values, validation errors (field-level highlighting), and state messages
- `XCTL` to `COCRDLIC` — card list access (PF key)
- `XCTL` to `COCRDUPC` — card update (PF key)
- `XCTL` to `COMEN01C` — menu (PF3 exit)

## Key Business Rules

### State Machine (ACUP-CHANGE-ACTION in commarea)
| Value | 88-Level | Meaning |
|---|---|---|
| LOW-VALUES/SPACES | `ACUP-DETAILS-NOT-FETCHED` | No data fetched yet; initial state |
| `'S'` | `ACUP-SHOW-DETAILS` | Data fetched, displayed |
| `'E'` | `ACUP-CHANGES-NOT-OK` | Validation errors; re-display with errors |
| `'N'` | `ACUP-CHANGES-OK-NOT-CONFIRMED` | Edits valid; awaiting PF5 confirm |
| `'C'` | `ACUP-CHANGES-OKAYED-AND-DONE` | Saved successfully |
| `'L'` | `ACUP-CHANGES-OKAYED-LOCK-ERROR` | Could not lock for update |
| `'F'` | `ACUP-CHANGES-OKAYED-BUT-FAILED` | Update failed after lock |

### Input/Validation
1. Account ID must be non-zero 11-digit numeric; zero or non-numeric → error.
2. CXACAIX read by account ID to get card xref; then CUSTDAT read by CUST-ID derived from xref.
3. If account not found in ACCTDAT → "Did not find this account in account master file".
4. If customer not found in CUSTDAT → "Did not find associated customer in master file".
5. **Account fields validated:**
   - `ACCT-ACTIVE-STATUS`: must be `'Y'` or `'N'`
   - Credit Limit, Cash Credit Limit: must be numeric and non-blank; validated via `WS-EDIT-CREDIT-LIMIT`, `WS-EDIT-CASH-CREDIT-LIMIT`
   - Open date, Expiry date, Reissue date: each split into year/month/day sub-fields; validated via CSUTLDTC CALL
6. **Customer fields validated:**
   - Names (first, middle, last): must be alpha only (INSPECT with LIT-UPPER/LIT-LOWER against ALPHANUM charset; `FLG-x-NOT-OK` flags set); blank middle name is allowed
   - Address fields: non-blank required for line 1, city, state, ZIP, country; line 2 optional
   - Phone numbers (1 and 2): validated as NANP 3+3+4 format; area code looked up in `CSLKPCDY` area code table; invalid area codes set `FLG-PHONE-NUM-1A-NOT-OK`/`1B-NOT-OK`/`1C-NOT-OK`
   - SSN: validated by parts — part1 (3 digits) must NOT be 0, 666, or 900–999 (`INVALID-SSN-PART1` 88-level values)
   - DOB: year/month/day sub-fields; date validated via CSUTLDTC
   - FICO score: range 300–850 (`FICO-RANGE-IS-VALID` 88-level on `ACUP-NEW-CUST-FICO-SCORE`)
   - EFT account ID: non-blank required
   - Primary cardholder indicator: must be `'Y'` or `'N'` (`FLG-PRI-CARDHOLDER-ISVALID`)
7. **Optimistic locking:** ACUP-OLD-DETAILS in commarea stores the snapshot read from files. On PF5 confirm: files are re-read (with UPDATE lock) and compared byte-by-byte against ACUP-OLD-DETAILS — if changed, "Record changed by some one else. Please review" error.
8. **No changes:** If ACUP-NEW-DETAILS equals ACUP-OLD-DETAILS after edit, "No change detected..." message; no write.
9. Both ACCTDAT and CUSTDAT are rewritten together; if ACCTDAT REWRITE succeeds but CUSTDAT fails, the state is `ACUP-CHANGES-OKAYED-BUT-FAILED`.

## Notable COBOL Constructs
- **Dual old/new snapshot:** `ACUP-OLD-DETAILS` and `ACUP-NEW-DETAILS` in WS-THIS-PROGCOMMAREA carry complete copies of both account and customer records across pseudo-conversational turns — the classic CICS optimistic locking pattern. Java equivalent: entity version fields or HTTP ETags.
- **CSLKPCDY phone area code table:** `COPY CSLKPCDY` provides a lookup table of valid NANP area codes for phone number validation — a mainframe-specific data validation technique using a 88-level OCCURS table.
- **SSN invalidation pattern:** 88-levels `INVALID-SSN-PART1` with VALUES 0, 666, 900-999 reflect IANA/SSA reserved SSN ranges — business rule encoded as 88-levels rather than code.
- **State machine via COMMAREA:** The single `ACUP-CHANGE-ACTION PIC X(01)` field with 8 distinct 88-levels controls all branch logic across multiple pseudo-conversational turns — Java equivalent: session-scoped enum or state enum in HTTP session.
- **Date sub-fields via REDEFINES:** Dates stored as 8-char fields (YYYYMMDD); REDEFINES overlays year(4)/month(2)/day(2) sub-fields for per-component validation before CSUTLDTC call.
- **FICO-RANGE-IS-VALID 88-level:** Range value check `VALUES 300 THROUGH 850` — cleaner than a numeric range IF in Java; direct equivalent: `fico >= 300 && fico <= 850`.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA`
- `CVCRD01Y` — `CC-WORK-AREA` with CCARD-* AID fields
- `CVACT01Y` — `ACCOUNT-RECORD`
- `CVACT03Y` — `CARD-XREF-RECORD`
- `CVCUS01Y` — `CUSTOMER-RECORD`
- `COACTUP` — BMS mapset (CACTUPAI, CACTUPAО)
- `CSUTLDWY` — date edit working-storage variables (date validation support)
- `CSLKPCDY` — North American phone area code lookup table
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y`, `CSMSG02Y`, `CSUSR01Y` — standard copybooks
- `DFHBMSCA`, `DFHAID` — CICS constants

## Called Programs
- `CSUTLDTC` — date validation (via CALL, not XCTL); used for open date, expiry date, reissue date, DOB
- `COCRDUPC` — card update (XCTL)
- `COCRDLIC` — card list (XCTL)

## Data Structures
| Field | PIC / Notes | Description |
|---|---|---|
| `ACUP-CHANGE-ACTION` | `X(01)` | State machine: LOW-VALUES/S/E/N/C/L/F |
| `ACUP-OLD-DETAILS` | large group | Snapshot of DB values for concurrency check |
| `ACUP-NEW-DETAILS` | large group | User-entered values to be validated and saved |
| `FICO-RANGE-IS-VALID` | 88-level on `9(03)` | `VALUES 300 THROUGH 850` |
| `INVALID-SSN-PART1` | 88-level on `9(03)` | Excludes 0, 666, 900–999 |
| Phone REDEFINES | 3-part X(3)/X(3)/X(4) | NANP area-code/exchange/number split |
