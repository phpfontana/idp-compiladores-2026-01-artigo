# COPAUS0C

## Purpose
COPAUS0C is a CICS COBOL IMS BMS program that presents a paginated summary list of authorization messages from the IMS authorization database. It is the summary screen in the Authorization sub-application's inquiry flow; selecting a row drills into COPAUS1C (detail view). Trans-ID is `CPVS`.

## Sub-Application
`app-authorization-ims-db2-mq` — requires IMS DB and CICS IMS bridge; not part of the five-program core subset.

## Inputs
- IMS PCB `PSBPAUTB` via DL/I GN/GU calls — authorization summary segments
- BMS map input: account filter, pagination controls (PF7/PF8)
- `ACCTDAT`, `CUSTDAT`, `CARDDAT`, `CXACAIX`, `CCXREF` CICS VSAM — supplementary account/card data for display

## Outputs
- BMS map output: paginated list of authorization summary records (account ID, auth amount `WS-AUTH-AMT PIC -zzzzzzz9.99`, auth date `X(08)`, auth time `X(08)`)
- `XCTL` to `COPAUS1C` — when user selects a row for detail view
- `XCTL` to `COMEN01C` — PF3 exit to main menu

## Key Business Rules
1. `WS-DECLINE-REASON-TABLE`: inline 20-byte entries encode numeric reason codes and descriptions: `'0000APPROVED'`, `'3100INVALID CARD'`, `'4100INSUFFICNT FUND'` etc. — used to decode authorization status codes for display.
2. Pagination: WS-REC-COUNT, WS-IDX, WS-PAGE-NUM with same PF7/PF8 pattern as COTRN00C.
3. WS-AUTH-APRV-STAT decoded using the decline reason table for the status column.
