# COCRDLIC

## Purpose
COCRDLIC is the CICS pseudo-conversational credit card list program for CardDemo. It displays up to 7 credit card records per page, supports forward/backward pagination (PF8/PF7), and lets the user select a card for view (`S` → COCRDSLC) or update (`U` → COCRDUPC). Admin users see all cards in CARDDAT; regular users see only the cards whose account ID matches the account in COMMAREA. The program uses CICS STARTBR/READNEXT for browsing and maintains page state (first/last card keys, page number) in the COMMAREA.

## Inputs
- `CCRDLIAI` — BMS map input from COCRDLI mapset: `ACCTIDNI`/`CARDNINI` (account/card filter), `SEL0001I`–`SEL0007I` (row action codes `S`/`U`)
- `DFHCOMMAREA` — carries `CARDDEMO-COMMAREA` plus `WS-THIS-PROGCOMMAREA` (WS-CA-LAST-CARDKEY, WS-CA-FIRST-CARDKEY, WS-CA-SCREEN-NUM, WS-CA-LAST-PAGE-DISPLAYED, WS-CA-NEXT-PAGE-IND)
- `CARDDAT` CICS VSAM KSDS — card master; browsed sequentially (all cards, admin) or filtered by account (regular user)
- `CARDAIX` CICS VSAM AIX — alternate index by account ID; used when filtering by account

## Outputs
- `CCRDLIAO` — BMS map output (COCRDLI mapset) with up to 7 rows of (ACCTNO, CARD-NUM, CARD-STATUS)
- `XCTL` to `COCRDSLC` — when user selects `S` on a row
- `XCTL` to `COCRDUPC` — when user selects `U` on a row
- `XCTL` to `COMEN01C` — PF3 exit

## Key Business Rules
1. On first entry from menu (`CDEMO-PGM-ENTER` from different program): page state is reset; card list is read forward from the beginning.
2. ENTER: processes any row selections (`S`/`U`); only one selection at a time is valid (multiple selections show "PLEASE SELECT ONLY ONE RECORD").
3. Selection `S` → XCTL to COCRDSLC with selected card key in commarea.
4. Selection `U` → XCTL to COCRDUPC with selected card key in commarea.
5. PF8 (page down): advances using last card key from current page; only if `CA-NEXT-PAGE-EXISTS`.
6. PF7 (page up): backs up using first card key from current page; only if not already on `CA-FIRST-PAGE`.
7. `9000-READ-FORWARD` performs STARTBR/READNEXT loop of up to 7 records; stores first key before loop and last key after; sets `CA-NEXT-PAGE-EXISTS` if an 8th record exists.
8. "No records found" error is set if the browse returns no records for the given filter.
9. Admin users can view all cards (browse from beginning); regular users are filtered by account ID (browse CARDAIX by account ID path).

## Notable COBOL Constructs
- **WS-SCREEN-DATA (7×28-byte):** In-memory screen buffer; `WS-ALL-ROWS PIC X(196)` with REDEFINES as `WS-SCREEN-ROWS OCCURS 7 TIMES` each containing WS-ROW-ACCTNO (X(11)), WS-ROW-CARD-NUM (X(16)), WS-ROW-CARD-STATUS (X(1)).
- **WS-EDIT-SELECT-ARRAY OCCURS 7:** Parallel array to screen rows; `SELECT-OK` accepts values `'S'` or `'U'`; `WS-EDIT-SELECT-COUNTER` counts non-blank to enforce single-selection rule.
- **Pagination state in commarea:** WS-CA-LAST-CARDKEY and WS-CA-FIRST-CARDKEY stored in commarea across RETURN — CICS pseudo-conversational state persistence pattern.
- **STARTBR / READNEXT:** Standard CICS browse pattern for paginated display; browse started at the resume key; read loop exits at EOF or after 7 records plus one lookahead for next-page flag.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA`
- `CVCRD01Y` — `CC-WORK-AREA`
- `COCRDLI` — BMS mapset (CCRDLIAI, CCRDLIAO)
- `CVACT02Y` — `CARD-RECORD`
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y`, `CSUSR01Y` — standard copybooks
- `DFHBMSCA`, `DFHAID` — CICS constants

## Called Programs
None (XCTL only)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `WS-CA-LAST-CARD-NUM` | `X(16)` | Card num of last displayed row; used for PF8 |
| `WS-CA-FIRST-CARD-NUM` | `X(16)` | Card num of first displayed row; used for PF7 |
| `WS-CA-SCREEN-NUM` | `9(1)` | Current page number |
| `CA-NEXT-PAGE-EXISTS` | 88-level | Set when 8th record found during browse |
| `WS-MAX-SCREEN-LINES` | `S9(4) COMP VALUE 7` | Max rows per screen |
