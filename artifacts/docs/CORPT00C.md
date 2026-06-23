# CORPT00C

## Purpose
CORPT00C is a CICS pseudo-conversational COBOL program that presents a report-request screen to the user. The user selects Monthly, Yearly, or Custom date range; CORPT00C validates the dates (calling CSUTLDTC), then submits an 80-character-record JCL job to JES via the CICS extrapartition TDQ queue named `'JOBS'`. The batch job runs the TRANREPT procedure which executes CBTRN03C to produce a printed transaction report. This is the online-to-batch bridge in CardDemo.

## Inputs
- `CORPT0AI` — BMS map input from the CORPT00 mapset: `MONTHLYI`, `YEARLYI`, `CUSTOMI` (radio select), `SDTMMI`/`SDTDDI`/`SDTYYYYI` (start date), `EDTMMI`/`EDTDDI`/`EDTYYYYI` (end date), `CONFIRMI` (Y/N confirmation)
- `DFHCOMMAREA` — 32767-byte variable-length CICS commarea carrying `CARDDEMO-COMMAREA`

## Outputs
- `CORPT0AO` — BMS map output (CORPT00 mapset) with error messages, report confirmation
- `JOBS` TDQ — 80-character JCL records written to JES internal reader via `EXEC CICS WRITEQ TD QUEUE('JOBS')`
- JCL submitted job runs proc `TRANREPT` which calls CBTRN03C

## Key Business Rules
1. On first entry (`EIBCALEN = 0`), the program redirects to COSGN00C (the signon screen) — authentication required before report submission.
2. On re-entry (`CDEMO-PGM-REENTER = TRUE`), the user's EIBAID key determines action: ENTER processes input, PF3 exits to COMEN01C.
3. **Monthly report:** Start date = first day of current month; end date = last day of current month, computed using `FUNCTION INTEGER-OF-DATE` and `FUNCTION DATE-OF-INTEGER` intrinsics.
4. **Yearly report:** Start date = YYYY-01-01; end date = YYYY-12-31, where YYYY is the current year.
5. **Custom report:** All six date fields (start MM, DD, YYYY; end MM, DD, YYYY) must be non-empty and numeric; month ≤ 12, day ≤ 31; each date is then validated via CSUTLDTC CALL.
6. After date computation/validation, `PARM-START-DATE-1`/`PARM-START-DATE-2` and `PARM-END-DATE-1`/`PARM-END-DATE-2` are populated in the inline JCL WORKING-STORAGE area before submission.
7. Confirmation is required: if `CONFIRMI` is blank, user is prompted; `'N'` resets the screen; `'Y'` proceeds with submission.
8. JCL is stored in `JOB-DATA-1` as 80-byte VALUE literals; `JOB-DATA-2 REDEFINES JOB-DATA-1` provides a `JOB-LINES OCCURS 1000 TIMES` table for the write loop.
9. JCL records are written one at a time with `EXEC CICS WRITEQ TD QUEUE('JOBS')` until a `'/*EOF'` sentinel or spaces/LOW-VALUES record is encountered.
10. CSUTLDTC date validation uses result code `'0000'` for valid; message number `'2513'` is allowed (it is actually the "valid date" code from CEEDAYS feedback — a quirk preserved from the API design).

## Notable COBOL Constructs
- **JCL in WORKING-STORAGE:** `JOB-DATA-1` stores complete JCL as VALUE clauses on 80-byte FILLER fields; `JOB-DATA-2 REDEFINES JOB-DATA-1` makes it indexable as `JOB-LINES(idx)` — a mainframe anti-pattern that hardcodes JCL into the COBOL source.
- **DATE-OF-INTEGER / INTEGER-OF-DATE:** COBOL intrinsic functions used to compute end-of-month by adding 1 to the month and subtracting 1 from the resulting Gregorian day count.
- **EXEC CICS WRITEQ TD:** Writes to an extra-partition TDQ (JES internal reader); Java has no direct equivalent — this must be replaced with file write or a job submission API.
- **Pseudo-conversational pattern:** Program returns to CICS after every screen send (`RETURN TRANSID('CR00') COMMAREA(...)`); state is maintained in COMMAREA via `CDEMO-PGM-REENTER`.

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA` (CDEMO-* fields including CDEMO-PGM-REENTER, CDEMO-TO-PROGRAM)
- `CORPT00` — BMS mapset definitions (CORPT0AI, CORPT0AO)
- `COTTL01Y` — screen title constants
- `CSDAT01Y` — current date/time working storage
- `CSMSG01Y` — standard message constants (CCDA-MSG-INVALID-KEY)
- `CVTRA05Y` — transaction record layout (not used in the logic but copied)
- `DFHAID` — AID key constants (DFHENTER, DFHPF3)
- `DFHBMSCA` — BMS color/attribute constants (DFHGREEN)

## Called Programs
- `CSUTLDTC` — date validation subroutine (called for custom date range only)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `JOB-LINES OCCURS 1000` | `X(80)` | JCL text via REDEFINES of JOB-DATA-1 |
| `PARM-START-DATE-1` / `-2` | `X(10)` | Start date populated in two JCL places |
| `PARM-END-DATE-1` / `-2` | `X(10)` | End date populated in two JCL places |
| `WS-REPORT-NAME` | `X(10)` | `'Monthly'`, `'Yearly'`, or `'Custom'` |
| `WS-START-DATE` / `WS-END-DATE` | `X(10)` | Computed or user-entered date range |
