# COTRN01C

## Purpose
COTRN01C is the CICS pseudo-conversational transaction detail view program for CardDemo. Given a transaction ID (entered directly or passed from COTRN00C via commarea), it reads the TRANSACT VSAM KSDS and displays all fields of the transaction record including card number, type, category, source, amount, description, timestamps, and merchant information. It is a read-only view — no updates are made. Trans-ID is `CT01`.

## Inputs
- `COTRN1AI` — BMS map input from COTRN01 mapset: `TRNIDINI` (transaction ID, 16 chars)
- `DFHCOMMAREA` — CICS commarea with `CARDDEMO-COMMAREA`; `CDEMO-CT01-TRN-SELECTED` carries the pre-selected transaction ID passed from COTRN00C
- `TRANSACT` CICS VSAM KSDS — transaction master; read by key `TRAN-ID`

## Outputs
- `COTRN1AO` — BMS map output (COTRN01 mapset) displaying: TRAN-ID, TRAN-CARD-NUM, TRAN-TYPE-CD, TRAN-CAT-CD, TRAN-SOURCE, TRAN-AMT (formatted +99999999.99), TRAN-DESC, TRAN-ORIG-TS, TRAN-PROC-TS, TRAN-MERCHANT-ID, TRAN-MERCHANT-NAME, TRAN-MERCHANT-CITY, TRAN-MERCHANT-ZIP
- `XCTL` to `COTRN00C` — PF5 returns to transaction list
- `XCTL` to caller (`CDEMO-FROM-PROGRAM`) or `COMEN01C` — PF3

## Key Business Rules
1. `EIBCALEN = 0` → XCTL to COSGN00C (authentication required; cannot enter directly).
2. On first entry (`NOT CDEMO-PGM-REENTER`): if `CDEMO-CT01-TRN-SELECTED` is non-empty, it is pre-populated into `TRNIDINI` and the record is immediately read and displayed.
3. ENTER: `TRNIDINI` must be non-empty; if blank, "Tran ID can NOT be empty..." error.
4. TRANSACT is read by `TRAN-ID`; RESP checked — NOTFND is handled with an error message; unexpected RESPs ABENDs.
5. PF3: returns to `CDEMO-FROM-PROGRAM` (usually COTRN00C); falls back to COMEN01C if not set.
6. PF4: clears all displayed transaction fields (screen reset, no file I/O).
7. PF5: XCTL to COTRN00C unconditionally.
8. `WS-USR-MODIFIED` flag tracks whether the user has changed any field (currently read-only but infrastructure for a future edit mode).
9. `TRAN-AMT` is moved to `WS-TRAN-AMT PIC +99999999.99` for formatted display.

## Notable COBOL Constructs
- **`CDEMO-CT01-TRN-SELECTED` pre-population:** If a calling program (COTRN00C) pre-selected a transaction, this program auto-fires the read on first entry without requiring the user to type the ID — a commarea-based drill-down pattern.
- **`WS-USR-MODIFIED PIC X(01)`:** A read/write intent flag (`USR-MODIFIED-YES/NO`) suggesting this was designed for a future update mode; currently always stays `NO`.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA`; `CDEMO-CT01-INFO` appended inline (CDEMO-CT01-TRN-SELECTED)
- `COTRN01` — BMS mapset (COTRN1AI, COTRN1AO)
- `CVTRA05Y` — `TRAN-RECORD`
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y` — standard copybooks
- `DFHAID`, `DFHBMSCA` — CICS constants

## Called Programs
None (XCTL only for navigation)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `TRAN-ID` | (from CVTRA05Y) | 16-char transaction ID; TRANSACT KSDS primary key |
| `WS-TRAN-AMT` | `+99999999.99` | Formatted signed decimal amount |
| `CDEMO-CT01-TRN-SELECTED` | `X(16)` | Pre-selected TRAN-ID from calling screen |
| `WS-USR-MODIFIED` | `X(01)` | `'Y'`/`'N'`; future edit mode hook |
