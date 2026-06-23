# DBUNLDGS

## Purpose
DBUNLDGS is a batch IMS COBOL program that unloads the IMS authorization database to sequential flat files. `WS-PGMNAME = 'IMSUNLOD'` identifies it internally. Output file assignments are commented out in the source — the program structure is present but the FILE-CONTROL SELECT statements are commented, suggesting this is a skeleton or development-stage program. Both output file layouts are defined in WORKING-STORAGE instead of the FILE SECTION (OPFIL1-REC X(100) and OPFIL2-REC with ROOT-SEG-KEY and CHILD-SEG-REC).

## Sub-Application
`app-authorization-ims-db2-mq` — not part of the five-program core subset.

## Inputs
- IMS PCB `PSBPAUTB` — authorization database accessed via DL/I GN calls

## Outputs
- `OUTFIL1` (commented out) — sequential file of 100-byte flat records
- `OUTFIL2` (commented out) — sequential file of (ROOT-SEG-KEY S9(11) COMP-3 + CHILD-SEG-REC X(200))
- IMS checkpoint records via CHKP call (WK-CHKPT-ID = 'RMAD' || counter)

## Notable
FILE SELECT statements are commented out (`*SELECT OPFILE1 ...`); the program will not compile/run as-is without uncommenting them. Compare with PAUDBUNL (the completed version).
