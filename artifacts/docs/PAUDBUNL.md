# PAUDBUNL

## Purpose
PAUDBUNL is a batch IMS COBOL program that unloads the IMS authorization database to sequential flat files — the completed version of DBUNLDGS (which has commented-out file assignments). It writes root authorization segments to OUTFIL1 (X(100)) and child segments to OUTFIL2 (ROOT-SEG-KEY S9(11) COMP-3 + CHILD-SEG-REC X(200)) using DL/I GN/GHN calls. `WS-PGMNAME = 'IMSUNLOD'`.

## Sub-Application
`app-authorization-ims-db2-mq` — not part of the five-program core subset.

## Inputs
- IMS PCB `PSBPAUTB` — authorization database read via DL/I GN (get next) calls
- Julian date input (CURRENT-YYDDD) for expiry comparison during selective unload

## Outputs
- `OUTFIL1` (OPFIL1-REC PIC X(100)) — sequential flat file of root authorization segments
- `OUTFIL2` (OPFIL2-REC: ROOT-SEG-KEY + CHILD-SEG-REC X(200)) — sequential flat file of child segments
- Counters: WS-NO-SUMRY-READ, WS-NO-DTL-READ, WS-TOT-REC-WRITTEN
- IMS checkpoint via CHKP

## Relationship to DBUNLDGS
DBUNLDGS has identical structure but commented-out FILE-CONTROL SELECT statements — PAUDBUNL is the operational version with active file assignments.
