# CBTRN03C

## Purpose
CBTRN03C is a batch COBOL report program that generates a formatted transaction detail report filtered by a date range. It reads transaction records from TRANFILE sequentially, filters by processing date against a start/end range read from DATEPARM, looks up card-to-account cross-reference, transaction type description, and transaction category description from VSAM lookup tables, then writes formatted 133-character report lines to TRANREPT. The report groups transactions by card number and accumulates page, account, and grand totals.

## Inputs
- `TRANFILE` — Sequential transaction master file (assigned to TRANFILE); one 350-byte record per transaction; includes `TRAN-PROC-TS` for date filtering
- `CARDXREF` — VSAM KSDS card cross-reference (random access by card number)
- `TRANTYPE` — VSAM KSDS transaction type lookup table (random access by 2-char type code)
- `TRANCATG` — VSAM KSDS transaction category lookup table (random access by composite key: TYPE-CD + CAT-CD)
- `DATEPARM` — Sequential date parameter file; one record: start date (10) + space + end date (10)

## Outputs
- `TRANREPT` — Sequential 133-character formatted report file with: page headers, transaction detail lines, per-card account totals, per-page totals, and grand total

## Key Business Rules
1. Before processing begins, one record is read from DATEPARM to establish `WS-START-DATE` and `WS-END-DATE`.
2. Each transaction is included in the report only if `TRAN-PROC-TS(1:10) >= WS-START-DATE AND <= WS-END-DATE`; otherwise it is silently skipped.
3. When the card number changes (detected by comparing `TRAN-CARD-NUM` to `WS-CURR-CARD-NUM`), account totals are written for the previous card group (except on the very first record where `WS-FIRST-TIME = 'Y'`).
4. On the first qualifying record, the page header is written and `WS-FIRST-TIME` is set to `'N'`.
5. A new page header is written every `WS-PAGE-SIZE` (20) detail lines, preceded by a page-total line.
6. `TRAN-AMT` is accumulated into `WS-PAGE-TOTAL` and `WS-ACCOUNT-TOTAL`; at page boundary, `WS-PAGE-TOTAL` is added to `WS-GRAND-TOTAL` and reset.
7. At EOF, the final page total and grand total are written.
8. Any XREF, TRANTYPE, or TRANCATG key-not-found condition causes an ABEND — they are treated as data integrity errors, not soft errors.

## Notable COBOL Constructs
- **Date-string comparison:** `TRAN-PROC-TS(1:10) >= WS-START-DATE` — uses alphanumeric reference modification for date filtering; Java must replicate the same lexicographic ordering on ISO-format date strings.
- **COMP-3 counters:** `WS-LINE-COUNTER PIC 9(09) COMP-3` and `WS-PAGE-SIZE PIC 9(03) COMP-3` — used with `FUNCTION MOD` for page-break detection.
- **EVALUATE for file-status:** `EVALUATE TRANFILE-STATUS WHEN '00' ... WHEN '10' ... WHEN OTHER` — cleaner than nested IF chains; used in read paragraphs.

## Copybook Dependencies
- `CVTRA05Y` — `TRAN-RECORD` layout (TRAN-ID, TRAN-TYPE-CD, TRAN-CAT-CD, TRAN-SOURCE, TRAN-AMT, TRAN-CARD-NUM, TRAN-PROC-TS)
- `CVACT03Y` — `CARD-XREF-RECORD` layout
- `CVTRA03Y` — `TRAN-TYPE-RECORD` layout (TRAN-TYPE-DESC)
- `CVTRA04Y` — `TRAN-CAT-RECORD` layout (TRAN-CAT-TYPE-DESC)
- `CVTRA07Y` — report layout (TRANSACTION-HEADER-*, TRANSACTION-DETAIL-REPORT, REPORT-*-TOTALS)

## Called Programs
- `CEE3ABD` — LE ABEND routine

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `WS-START-DATE` | `X(10)` | Report start date from DATEPARM |
| `WS-END-DATE` | `X(10)` | Report end date from DATEPARM |
| `WS-LINE-COUNTER` | `9(09) COMP-3` | Lines written on current page |
| `WS-PAGE-SIZE` | `9(03) COMP-3` | Lines per page (hardcoded 20) |
| `WS-PAGE-TOTAL` | `S9(09)V99` | Running total for current page |
| `WS-ACCOUNT-TOTAL` | `S9(09)V99` | Running total for current card group |
| `WS-GRAND-TOTAL` | `S9(09)V99` | Accumulated total for entire report |
| `WS-CURR-CARD-NUM` | `X(16)` | Tracks card number change for group breaks |
