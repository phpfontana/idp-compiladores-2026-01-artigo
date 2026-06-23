# CBPAUP0C

## Purpose
CBPAUP0C is a batch COBOL IMS program in the CardDemo Authorization sub-application. It scans the IMS authorization database and deletes expired pending authorization messages — records whose authorization date (WS-AUTH-DATE) plus an expiry threshold (WS-EXPIRY-DAYS) is earlier than the current Julian date (CURRENT-YYDDD). It uses IMS DL/I calls via PSB PSBPAUTB to access the authorization database hierarchically.

## Sub-Application
`app-authorization-ims-db2-mq` — not part of the five-program core subset; uses IMS DB which is not present in the GnuCOBOL test environment.

## Inputs
- IMS PCB `PSBPAUTB` (PSB-NAME) — authorization database accessed via DL/I GU/GN/DLET calls
- `CURRENT-DATE` / `CURRENT-YYDDD` — system date (Julian format) obtained via ACCEPT FROM DATE or similar
- `WS-EXPIRY-DAYS` — configurable expiry threshold (S9(4) COMP)

## Outputs
- Expired records deleted from IMS authorization DB via DLET DL/I calls
- Counters: `WS-NO-SUMRY-READ`, `WS-NO-SUMRY-DELETED`, `WS-NO-DTL-READ`, `WS-NO-DTL-DELETED`, `WS-TOT-REC-WRITTEN`
- Checkpoint records written every `WS-NO-CHKP` records (IMS CHKP facility)

## Key Business Rules
1. Reads IMS authorization summary segments (GET NEXT/GET UNIQUE DL/I calls).
2. For each summary, reads child detail segments (hierarchical).
3. If `WS-DAY-DIFF = CURRENT-YYDDD - WS-AUTH-DATE >= WS-EXPIRY-DAYS`, sets `QUALIFIED-FOR-DELETE`.
4. `QUALIFIED-FOR-DELETE` → IMS DLET call deletes the segment.
5. IMS checkpoint written periodically using `WK-CHKPT-ID` = `'RMAD' || WK-CHKPT-ID-CTR`.
6. `WS-AUTH-SMRY-PROC-CNT` tracks total summaries processed.

## Notable COBOL Constructs
- **IMS DL/I calls:** Replaces native VSAM with hierarchical database; DL/I GU/GN/DLET via CALL 'CBLTDLI' pattern — no CICS, no VSAM file-control.
- **Julian date arithmetic:** `WS-YYDDD PIC 9(05)` for date comparison — Julian YYDDD is typical in IMS batch programs.

## Copybook Dependencies
IMS-specific (PSB/PCB structures not shown in first 80 lines); no standard CardDemo copybooks used.
