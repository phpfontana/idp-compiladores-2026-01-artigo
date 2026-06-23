# COTRN00C

## Purpose
COTRN00C is the CICS pseudo-conversational transaction list program for CardDemo. It displays up to 10 transaction records per page from the TRANSACT VSAM KSDS file, supports forward/backward pagination (PF7/PF8), accepts a transaction ID prefix as filter, and lets the user select a transaction for detail view. Selection `S` → XCTL to COTRN01C. Trans-ID is `CT00`.

## Inputs
- `COTRN0AI` — BMS map input from COTRN00 mapset: `TRNIDINI` (starting transaction ID for browse), `SEL0001I`–`SEL0010I` (selection flags), `TRNID01I`–`TRNID10I` (transaction IDs of displayed rows)
- `DFHCOMMAREA` — CICS commarea with `CARDDEMO-COMMAREA` plus `CDEMO-CT00-INFO` (CDEMO-CT00-TRNID-FIRST, CDEMO-CT00-TRNID-LAST, CDEMO-CT00-PAGE-NUM, CDEMO-CT00-NEXT-PAGE-FLG, CDEMO-CT00-TRN-SEL-FLG, CDEMO-CT00-TRN-SELECTED)
- `TRANSACT` CICS VSAM KSDS — transaction master; browsed with STARTBR/READNEXT (forward) or STARTBR/READPREV (backward)

## Outputs
- `COTRN0AO` — BMS map output (COTRN00 mapset) with up to 10 transaction rows; each row shows TRAN-ID, TRAN-TYPE-CD, TRAN-AMT (formatted +99999999.99), TRAN-ORIG-TS
- `XCTL` to `COTRN01C` — when user selects `S` on a row
- `XCTL` to `COMEN01C` — PF3

## Key Business Rules
1. On first entry (`NOT CDEMO-PGM-REENTER`, `EIBCALEN > 0`): immediately reads forward from beginning of TRANSACT and displays first page.
2. `EIBCALEN = 0` → XCTL to COSGN00C (authentication required).
3. ENTER: if a row selection is active (first non-blank `SEL000nI`), stores the flag and transaction ID in COMMAREA then XCTLs to COTRN01C; only action `S` is valid (other values show "Invalid selection. Valid value is S").
4. If `TRNIDINI` is non-empty and numeric, it is used as the STARTBR key for the next forward read; non-numeric shows "Tran ID must be Numeric..." error.
5. PF7 (backward): `PROCESS-PAGE-BACKWARD` — STARTBR/READPREV from saved `CDEMO-CT00-TRNID-FIRST`; page number decremented; "already at top" message on page 1.
6. PF8 (forward): `PROCESS-PAGE-FORWARD` — STARTBR/READNEXT from saved `CDEMO-CT00-TRNID-LAST`; page number incremented; `NEXT-PAGE-FLG` set if 11th record exists.
7. `TRAN-AMT` is moved to `WS-TRAN-AMT PIC +99999999.99` for display formatting.
8. `WS-PAGE-NUM` and `CDEMO-CT00-PAGE-NUM` track the current page across pseudo-conversational turns.

## Notable COBOL Constructs
- **STARTBR / READNEXT / READPREV:** CICS browse control commands for sequential and reverse scan of TRANSACT. Java equivalent: keyset-based pagination with an indexed column.
- **CDEMO-CT00-INFO in commarea:** Custom commarea extension appended after CARDDEMO-COMMAREA for page state — Java would use session attributes or hidden form fields.
- **10-row select array:** `SEL0001I`–`SEL0010I` and `TRNID01I`–`TRNID10I` are parallel BMS map fields evaluated in a single EVALUATE TRUE with WHEN-chain — no loop; hand-coded for exactly 10 rows.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA` (base); `CDEMO-CT00-INFO` appended inline
- `COTRN00` — BMS mapset (COTRN0AI, COTRN0AO)
- `CVTRA05Y` — `TRAN-RECORD` (TRAN-ID, TRAN-TYPE-CD, TRAN-AMT, etc.)
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y` — standard copybooks
- `DFHAID`, `DFHBMSCA` — CICS constants

## Called Programs
None (XCTL only for navigation)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `WS-TRAN-AMT` | `+99999999.99` | Formatted amount for display |
| `CDEMO-CT00-TRNID-FIRST` | `X(16)` | First TRAN-ID on current page; used for PF7 |
| `CDEMO-CT00-TRNID-LAST` | `X(16)` | Last TRAN-ID on current page; used for PF8 |
| `CDEMO-CT00-PAGE-NUM` | `9(08)` | Current page number |
| `CDEMO-CT00-NEXT-PAGE-FLG` | `X(01)` | `'Y'` = next page exists |
