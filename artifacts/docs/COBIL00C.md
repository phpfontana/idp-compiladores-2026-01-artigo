# COBIL00C

## Purpose
COBIL00C is the CICS pseudo-conversational online bill payment program for CardDemo. The user enters an account ID; the program reads the account balance, shows it, and — after the user confirms with `'Y'` — creates a payment transaction and clears the account balance to zero. It uses CICS file control (not native VSAM) to access three datasets: ACCTDAT (account master), CXACAIX (card cross-reference alternate index by account), and TRANSACT (transaction master).

## Inputs
- `COBIL0AI` — BMS map input from COBIL00 mapset: `ACTIDINI` (account ID), `CONFIRMI` (Y/N/blank)
- `DFHCOMMAREA` — CICS commarea; may carry `CDEMO-CB00-TRN-SELECTED` (a pre-selected transaction ID from a calling screen)
- `ACCTDAT` VSAM KSDS — account master (keyed by ACCT-ID); read with UPDATE lock
- `CXACAIX` VSAM AIX — card xref alternate index keyed by account ID; used to find the card number for the transaction record
- `TRANSACT` VSAM KSDS — transaction master; browsed backward from HIGH-VALUES to find the last transaction ID, then a new record is written

## Outputs
- Updated `ACCTDAT` — `ACCT-CURR-BAL` is set to `ACCT-CURR-BAL - TRAN-AMT` (net zero after full payment)
- New record in `TRANSACT` — TRAN-TYPE-CD=`'02'`, TRAN-CAT-CD=2, TRAN-SOURCE=`'POS TERM'`, TRAN-DESC=`'BILL PAYMENT - ONLINE'`, amount = prior balance, merchant ID = 999999999
- `COBIL0AO` — updated screen showing confirmation message with new transaction ID

## Key Business Rules
1. Account ID must be non-empty; empty input shows "Acct ID can NOT be empty..." error.
2. On first display (CONFIRM blank): account is read (with UPDATE lock), current balance is shown; user is prompted to confirm.
3. If `CONFIRMI = 'Y'` or `'y'`: payment proceeds; if `'N'` or `'n'`: screen is cleared (no action); any other value shows "Invalid value..." error.
4. If `ACCT-CURR-BAL <= 0`: no payment needed; "You have nothing to pay..." error is shown.
5. The new transaction ID is derived by browsing TRANSACT backward from HIGH-VALUES (`EXEC CICS STARTBR ... READPREV ... ENDBR`) to find the maximum existing TRAN-ID, then adding 1.
6. The current timestamp for the transaction is obtained via `EXEC CICS ASKTIME ABSTIME` + `EXEC CICS FORMATTIME`.
7. After successful WRITE to TRANSACT and REWRITE to ACCTDAT, screen shows "Payment successful. Your Transaction ID is ..." in green.
8. On successful confirmation, the account balance is updated: `ACCT-CURR-BAL = ACCT-CURR-BAL - TRAN-AMT` where TRAN-AMT = the old balance (full payment).

## Notable COBOL Constructs
- **EXEC CICS READ ... UPDATE:** Acquires an exclusive update lock on the ACCTDAT record before modification — prevents concurrent updates; Java equivalent is a database row lock or optimistic locking.
- **EXEC CICS STARTBR / READPREV / ENDBR:** Browse pattern to find the maximum key (last transaction ID) in TRANSACT; Java equivalent is a MAX query or reverse-ordered scan.
- **EXEC CICS ASKTIME / FORMATTIME:** CICS services for getting and formatting the current timestamp; Java equivalent is `LocalDateTime.now()`.
- **CXACAIX (Alternate Index):** CICS-managed alternate index on XREFFILE, keyed by account ID (`XREF-ACCT-ID`); used to resolve account-to-card; Java must handle the AIX lookup via secondary index or JOIN.
- **WS-ABS-TIME COMP-3:** `PIC S9(15) COMP-3` — CICS absolute time counter; 15-digit packed decimal.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA` with CDEMO-CB00-TRN-SELECTED
- `COBIL00` — BMS mapset definitions (COBIL0AI, COBIL0AO)
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y` — standard header/message copybooks
- `CVACT01Y` — `ACCOUNT-RECORD` (ACCT-ID, ACCT-CURR-BAL)
- `CVACT03Y` — `CARD-XREF-RECORD` (XREF-ACCT-ID, XREF-CARD-NUM)
- `CVTRA05Y` — `TRAN-RECORD` (TRAN-ID, TRAN-TYPE-CD, TRAN-AMT, etc.)
- `DFHAID`, `DFHBMSCA` — CICS AID/BMS constants

## Called Programs
None (uses EXEC CICS commands for all I/O)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `ACCT-ID` | `9(11)` | Account ID from screen input |
| `ACCT-CURR-BAL` | (from CVACT01Y) | Current balance; read and updated |
| `WS-TRAN-ID-NUM` | `9(16)` | New transaction ID = last ID + 1 |
| `WS-ABS-TIME` | `S9(15) COMP-3` | CICS absolute time for timestamp |
| `TRAN-AMT` | (from CVTRA05Y) | Payment amount = full prior balance |
