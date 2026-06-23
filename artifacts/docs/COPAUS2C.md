# COPAUS2C

## Purpose
COPAUS2C is the fraud review screen in CardDemo's Authorization sub-application. It is referenced by COPAUS1C (`WS-PGM-AUTH-FRAUD='COPAUS2C'`) and provides a view or action capability related to potentially fraudulent authorization messages in the IMS authorization database. Source code was not read directly — this entry is inferred from references in COPAUS1C.

## Sub-Application
`app-authorization-ims-db2-mq` — requires IMS DB and CICS IMS bridge; not part of the five-program core subset.

## Note
This program's source file is at `app/app-authorization-ims-db2-mq/cbl/COPAUS2C.cbl`. It was identified in the COPAUS1C reference (`WS-PGM-AUTH-FRAUD = 'COPAUS2C'`) but was not fully analyzed. Documentation should be supplemented from direct source reading before Phase 2–6 work on this sub-application.
