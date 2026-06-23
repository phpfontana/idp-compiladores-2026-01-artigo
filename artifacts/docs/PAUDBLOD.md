# PAUDBLOD

## Purpose
PAUDBLOD is a batch IMS COBOL program that loads the IMS authorization database from sequential flat files — the inverse operation of PAUDBUNL. It reads two input files (INFILE1 for root segments X(100), INFILE2 for child segments with ROOT-SEG-KEY + CHILD-SEG-REC) and issues DL/I ISRT calls to load them into the IMS authorization database. `WS-PGMNAME = 'IMSUNLOD'` (shared literal between all IMS utility programs).

## Sub-Application
`app-authorization-ims-db2-mq` — not part of the five-program core subset.

## Inputs
- `INFILE1` (INFIL1-REC PIC X(100)) — sequential flat file of root authorization segments
- `INFILE2` (INFIL2-REC: ROOT-SEG-KEY S9(11) COMP-3 + CHILD-SEG-REC X(200)) — sequential flat file of child authorization segments
- IMS PCB `PSBPAUTB` — target IMS database

## Outputs
- IMS authorization database loaded with ISRT DL/I calls
- Counters: WS-NO-SUMRY-READ, WS-NO-DTL-READ, WS-TOT-REC-WRITTEN
- IMS checkpoint via CHKP calls

## Key Business Rules
File statuses `WS-INFIL1-STATUS` and `WS-INFIL2-STATUS` checked for `'10'` (end-of-file). Julian date fields (CURRENT-YYDDD) used for authorization date processing during load.
