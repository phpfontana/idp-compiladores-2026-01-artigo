# COACTVWC

## Purpose
COACTVWC is the CICS pseudo-conversational account view program for CardDemo. The user enters an account ID and the program reads three CICS datasets (ACCTDAT for account data, CUSTDAT for customer data, and CXACAIX for card cross-reference) and presents a read-only composite view of account and customer information on a single screen. It is a read-only inquiry screen — it writes no data.

## Inputs
- `CACTVWAI` — BMS map input from COACTVW mapset: `ACCTSIDI` (11-digit account ID)
- `DFHCOMMAREA` — CICS commarea carrying `CARDDEMO-COMMAREA` plus `WS-THIS-PROGCOMMAREA` (CA-FROM-PROGRAM, CA-FROM-TRANID)
- `ACCTDAT` CICS VSAM KSDS — account master; read by key = account ID
- `CUSTDAT` CICS VSAM KSDS — customer master; read after resolving customer ID via CXACAIX
- `CXACAIX` CICS VSAM AIX — card cross-reference alternate index by account ID; used to obtain XREF-CARD-NUM and linked CUST-ID

## Outputs
- `CACTVWAO` — BMS map output (COACTVW mapset) with account fields (ACSTTUSO, ACURBALO, ACRDLIMO, ACSHLIMO, ACRCYCRO, ACRCYDBO, ADTOPENO, AEXPDTO, AREISDTO, AADDGRPO) and customer fields (ACSTNUMO, ACSTSSNO formatted NNN-NN-NNNN, ACSTFCOO, ACSTDOBO, ACSFNAMO-ACSLNAMO, ACSADL1O-ACSZIPCO, ACSPHN1O-ACSPHN2O, ACSGOVTO, ACSEFTCO, ACSPFLGO)
- `XCTL` to calling program (PF3 → `CDEMO-FROM-PROGRAM` or COMEN01C if not set)
- `XCTL` to `COCRDLIC` (card list, PF5)
- `XCTL` to `COCRDUPC` (card update, PF6)

## Key Business Rules
1. On first entry (`CDEMO-PGM-ENTER` from menu): blank screen is shown prompting for account ID.
2. On ENTER with account ID (`CDEMO-PGM-REENTER`): `2000-PROCESS-INPUTS` validates input; if valid, `9000-READ-ACCT` reads ACCTDAT and then CUSTDAT via CXACAIX; results are displayed.
3. Account ID must be non-empty; blank triggers "Account number not provided" error.
4. CXACAIX is read by account ID to resolve the card cross-reference; from there customer ID is obtained and CUSTDAT is read.
5. SSN is formatted on-screen as NNN-NN-NNNN using STRING.
6. PF3 returns to the calling program (`CDEMO-FROM-PROGRAM`/`CDEMO-FROM-TRANID`); if those are empty, returns to COMEN01C.
7. Any invalid AID key sets `CCARD-AID-ENTER` (treated as ENTER) — no "invalid key" message.
8. `WS-FOUND-ACCT-IN-MASTER` and `WS-FOUND-CUST-IN-MASTER` flags control which parts of the screen are populated; partial reads still display whatever was found.

## Notable COBOL Constructs
- **Dual CICS commarea slice:** `WS-COMMAREA(1:LENGTH OF CARDDEMO-COMMAREA)` carries the global commarea; `WS-COMMAREA(LENGTH+1:LENGTH OF WS-THIS-PROGCOMMAREA)` carries program-local context (CA-FROM-PROGRAM, CA-FROM-TRANID). Java equivalent: two separate fields in a session/state object.
- **CXACAIX AIX read:** Reads the alternate index by account ID to resolve card/customer linkage — no JOIN capability in native VSAM; Java must simulate with a secondary index lookup or JOIN.
- **FUNCTION CURRENT-DATE:** Used for screen header (no CICS ASKTIME here — batch-style date intrinsic).

## Copybook Dependencies
- `COCOM01Y` — `CARDDEMO-COMMAREA`
- `CVCRD01Y` — `CC-WORK-AREA` with CCARD-* fields (AID keys, error message)
- `COACTVW` — BMS mapset (CACTVWAI, CACTVWAO)
- `CVACT01Y` — `ACCOUNT-RECORD` (ACCT-*)
- `CVACT02Y` — `CARD-RECORD` (used via CVACT02Y in prior programs; not directly copied here)
- `CVACT03Y` — `CARD-XREF-RECORD` (XREF-ACCT-ID, XREF-CARD-NUM)
- `CVCUS01Y` — `CUSTOMER-RECORD` (CUST-*)
- `COTTL01Y`, `CSDAT01Y`, `CSMSG01Y`, `CSMSG02Y`, `CSUSR01Y` — standard copybooks
- `DFHBMSCA`, `DFHAID` — CICS attribute/AID constants

## Called Programs
None (XCTL only)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `WS-CARD-RID-CARDNUM` | `X(16)` | Card number used as CXACAIX key |
| `WS-CARD-RID-ACCT-ID` | `9(11)` | Account ID |
| `WS-ACCOUNT-MASTER-READ-FLAG` | `X(1)` | `'1'` = found in ACCTDAT |
| `WS-CUST-MASTER-READ-FLAG` | `X(1)` | `'1'` = found in CUSTDAT |
