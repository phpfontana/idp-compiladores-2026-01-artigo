# COPAUS1C

## Purpose
COPAUS1C is a CICS COBOL IMS BMS program that displays the detail view of a single authorization message from the IMS authorization database. It is the drill-down screen called from COPAUS0C (summary list) and can also navigate to COPAUS2C (fraud review). Trans-ID is `CPVD`.

## Sub-Application
`app-authorization-ims-db2-mq` — requires IMS DB and CICS IMS bridge; not part of the five-program core subset.

## Inputs
- IMS PCB `PSBPAUTB` via DL/I GU call — specific authorization detail segment keyed by `WS-AUTH-KEY`
- `WS-ACCT-ID PIC 9(11)` — account ID for display context

## Outputs
- BMS map output: authorization detail (amount `WS-AUTH-AMT`, date `WS-AUTH-DATE X(08)`, time `WS-AUTH-TIME X(08)`, account ID, decline reason)
- `XCTL` to `COPAUS0C` — PF3 back to summary
- `XCTL` to `COPAUS2C` — fraud review for this authorization (`WS-PGM-AUTH-FRAUD='COPAUS2C'`)

## Key Business Rules
1. `WS-DECLINE-REASON-TABLE` (same as COPAUS0C): inline 20-byte entries decode numeric reason codes; same table copied into both programs.
2. `WS-AUTHS-EOF` flag governs browse loop exit.
3. PF key to COPAUS2C provides a direct path from detail to fraud review.
