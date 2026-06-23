# CBACT04C Golden Master Manifest

Generated: 2026-06-17  
GnuCOBOL version: 3.2.0 (-std=ibm)

## PARM-DATE Mechanism

CBACT04C declares `PROCEDURE DIVISION USING EXTERNAL-PARMS` where EXTERNAL-PARMS is a LINKAGE SECTION 01-level containing:
- `PARM-LENGTH PIC S9(04) COMP` (2 bytes binary)
- `PARM-DATE PIC X(10)` (the run date string)

**Problem**: GnuCOBOL refuses to compile a program with PROCEDURE DIVISION USING as a standalone executable (`-x`). The error is: `executable program requested but PROCEDURE/ENTRY has USING clause`.

**Solution**: Compile CBACT04C as a shared module (`cobc -std=ibm -m -o CBACT04C.dylib`) and create a driver program `CBACT04C_DRIVER.cbl` that:
1. Declares `WS-EXTERNAL-PARMS` in WORKING-STORAGE with PARM-LENGTH=10 and PARM-DATE='2026-06-17' hard-coded
2. Calls `CBACT04C` using `CALL 'CBACT04C' USING WS-EXTERNAL-PARMS`

The driver is compiled as executable: `cobc -std=ibm -x -o CBACT04C_DRIVER CBACT04C_DRIVER.cbl`

Run command: `COB_LIBRARY_PATH=<workspace> ./CBACT04C_DRIVER`

PARM-DATE='2026-06-17' is embedded in CBACT04C_DRIVER.cbl. To test a different date, modify the VALUE clause in CBACT04C_DRIVER.cbl and recompile.

For Java testing: the Java program receives the date as a command-line argument: `java MainClass 2026-06-17`

## Test Data Description

### TCATBALF (4 records, indexed sequential, 50 bytes/record)

| ACCT-ID     | TYPE-CD | CAT-CD | TRAN-CAT-BAL | Purpose           |
|-------------|---------|--------|--------------|-------------------|
| 00000000001 | CR      | 0001   | +1000.00     | Normal rate lookup |
| 00000000001 | DB      | 0002   | +500.00      | Normal rate lookup |
| 00000000002 | CR      | 0001   | +2000.00     | Normal rate lookup |
| 00000000002 | DR      | 0003   | +300.00      | Rate fallback test |

### DISCGRP (3 records, indexed random, 50 bytes/record)

| ACCT-GROUP-ID | TYPE-CD | CAT-CD | DIS-INT-RATE | Purpose                    |
|---------------|---------|--------|--------------|----------------------------|
| DEFAULT       | DR      | 0003   | 18.00%       | Fallback for unknown group |
| GRP0000001    | CR      | 0001   | 12.00%       | Credit interest rate       |
| GRP0000001    | DB      | 0002   | 6.00%        | Debit interest rate        |

Note: No entry for GRP0000001+DR+0003 — this triggers the fallback path (DISCGRP-STATUS='23').

### XREFFILE (2 records, indexed with primary+alternate key, 50 bytes/record)

| XREF-CARD-NUM    | XREF-CUST-ID | XREF-ACCT-ID | Purpose              |
|------------------|--------------|--------------|----------------------|
| 4000002000000001 | 000000001    | 00000000001  | Card for account 1   |
| 4000002000000002 | 000000002    | 00000000002  | Card for account 2   |

CRITICAL: XREFFILE must be created with both PRIMARY KEY (XREF-CARD-NUM) and ALTERNATE KEY (XREF-ACCT-ID). CBACT04C reads by alternate key. The GENXREF program declares `ALTERNATE RECORD KEY IS GX-ACCT-ID`.

### ACCTFILE (2 records, indexed I-O, 300 bytes/record)

| ACCT-ID     | BAL-BEFORE | CREDIT-LIMIT | CYC-CREDIT | CYC-DEBIT | GROUP-ID   |
|-------------|------------|--------------|------------|-----------|------------|
| 00000000001 | 5000.00    | 10000.00     | 100.00     | 50.00     | GRP0000001 |
| 00000000002 | 8000.00    | 20000.00     | 200.00     | 80.00     | GRP0000001 |

## Expected Interest Calculations

### Account 00000000001 (GROUP-ID=GRP0000001)

**CR/0001: BAL=1000.00, RATE=12.00% annual**
```
WS-MONTHLY-INT = (1000.00 × 12.00) / 1200 = 12000.00 / 1200 = 10.00
```

**DB/0002: BAL=500.00, RATE=6.00% annual**
```
WS-MONTHLY-INT = (500.00 × 6.00) / 1200 = 3000.00 / 1200 = 2.50
```

**WS-TOTAL-INT = 10.00 + 2.50 = 12.50**

**ACCT-CURR-BAL after = 5000.00 + 12.50 = 5012.50**  
**ACCT-CURR-CYC-CREDIT after = 0.00**  
**ACCT-CURR-CYC-DEBIT after = 0.00**

Account 1 update is triggered by the account-change detection (next record belongs to account 2).

### Account 00000000002 (GROUP-ID=GRP0000001)

**CR/0001: BAL=2000.00, RATE=12.00% annual**
```
WS-MONTHLY-INT = (2000.00 × 12.00) / 1200 = 24000.00 / 1200 = 20.00
```

**DR/0003: BAL=300.00 — fallback path**
- DISCGRP lookup for GRP0000001+DR+0003 returns status '23' (not found)
- Code moves 'DEFAULT' to FD-DIS-ACCT-GROUP-ID, re-reads DISCGRP
- DEFAULT+DR+0003 found, RATE=18.00% annual
```
WS-MONTHLY-INT = (300.00 × 18.00) / 1200 = 5400.00 / 1200 = 4.50
```

**WS-TOTAL-INT = 20.00 + 4.50 = 24.50** (accumulated in WS-TOTAL-INT but NEVER posted)

## ACCTFILE After-State (Golden)

| ACCT-ID     | BAL-AFTER | CYC-CREDIT-AFTER | CYC-DEBIT-AFTER | Notes                          |
|-------------|-----------|------------------|-----------------|-------------------------------|
| 00000000001 | 5012.50   | 0.00             | 0.00            | Updated on account-change      |
| 00000000002 | 8000.00   | 200.00           | 80.00           | NOT updated (dead-code bug)    |

## Known COBOL Bug: Last Account Never Posted

CBACT04C has a logic defect in its EOF handling. The main loop:
```
PERFORM UNTIL END-OF-FILE = 'Y'
    IF END-OF-FILE = 'N'
        PERFORM 1000-TCATBALF-GET-NEXT
        IF END-OF-FILE = 'N'
          ...process record...
        END-IF
    ELSE
        PERFORM 1050-UPDATE-ACCOUNT  <- DEAD CODE
    END-IF
END-PERFORM
```

The ELSE branch (1050-UPDATE-ACCOUNT for the last account) is DEAD CODE:
- When `1000-TCATBALF-GET-NEXT` sets `END-OF-FILE='Y'`, we skip the inner IF and fall through to END-IF (outer)
- Control returns to PERFORM UNTIL, which evaluates `END-OF-FILE = 'Y'` as TRUE and exits
- The ELSE branch is NEVER reached

Consequence: the last account processed (00000000002) accumulates interest in WS-TOTAL-INT and writes TRANSACT records correctly, but the ACCTFILE REWRITE is never performed. ACCT-CURR-BAL, ACCT-CURR-CYC-CREDIT, and ACCT-CURR-CYC-DEBIT retain their pre-run values.

**Java MUST replicate this behavior exactly** — this is the golden master.

## TRANSACT Output (Golden)

4 records, 350 bytes each. Sequential file.

| TRAN-ID          | TYPE | CAT  | AMT       | CARD-NUM         |
|------------------|------|------|-----------|------------------|
| 2026-06-17000001 | 01   | 0005 | +10.00    | 4000002000000001 |
| 2026-06-17000002 | 01   | 0005 | +2.50     | 4000002000000001 |
| 2026-06-17000003 | 01   | 0005 | +20.00    | 4000002000000002 |
| 2026-06-17000004 | 01   | 0005 | +4.50     | 4000002000000002 |

TRAN-ID format: PARM-DATE (10) + WS-TRANID-SUFFIX (6, right-justified, zero-padded).  
TRAN-SOURCE: 'System    ' (10 chars, space-padded).  
TRAN-DESC: 'Int. for a/c 00000000001' or '...00000000002' (left-justified, space-padded to 100).

## Timestamp Masking

Two fields are non-deterministic (set via `FUNCTION CURRENT-DATE`):

| Field         | Offset (0-based) | Length | Masked range  |
|---------------|-----------------|--------|---------------|
| TRAN-ORIG-TS  | 278             | 26     | bytes 278-303 |
| TRAN-PROC-TS  | 304             | 26     | bytes 304-329 |

Both are set to the same timestamp value (DB2 format: `YYYY-MM-DD-HH.MM.SS.mm0000`).
Both ranges are zeroed (byte value 0x00) in `golden_TRANSACT_masked` before comparison.

Masking Python snippet (used in run_characterization.sh):
```python
data = open('TRANSACT','rb').read()
out = bytearray(data)
for i in range(0, len(out), 350):
    for j in list(range(278, 304)) + list(range(304, 330)):
        if i+j < len(out): out[i+j] = 0
open('golden_TRANSACT_masked','wb').write(bytes(out))
```

## Golden File Inventory

| File                    | Size    | Description                                |
|-------------------------|---------|--------------------------------------------|
| golden_TRANSACT_masked  | 1400 B  | 4×350 TRANSACT records, both TS zeroed     |
| golden_ACCTSEQ          | 600 B   | 2×300 ACCTFILE sequential dump after run   |
| golden_stdout.txt       | 340 B   | DISPLAY output from CBACT04C               |

## Comparisons in run_characterization.sh

1. `golden_TRANSACT_masked` — byte-for-byte (TRANSACT after masking both TS fields)
2. `golden_ACCTSEQ` — byte-for-byte (ACCTFILE dumped to sequential after run)
3. `golden_stdout.txt` — byte-for-byte after stripping `libcob:` warnings

## Numeric Encoding Notes

**S9(09)V99 DISPLAY (TRAN-AMT, 11 bytes):**  
Positive value: pure ASCII digits. +10.00 = "00000001000" (11 bytes).

**S9(10)V99 DISPLAY (ACCT-CURR-BAL, 12 bytes):**  
Positive value: pure ASCII digits. +5012.50 = "000000501250" (12 bytes).  
Negative value: last byte gets +0x40 overpunch.

**S9(04)V99 DISPLAY (DIS-INT-RATE, 6 bytes):**  
+12.00 stored as "001200" (6 bytes).

**S9(04) COMP (PARM-LENGTH, 2 bytes):**  
Binary big-endian. Value 10 = 0x000A.
