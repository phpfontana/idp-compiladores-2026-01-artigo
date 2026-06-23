# CBTRN02C Golden Master Manifest

Generated: 2026-06-17
GnuCOBOL version: 3.2.0 (-std=ibm)
Runner: characterization-tester subagent

## Test Transaction Design (7 transactions)

### Input Files

| File | Format | Content |
|---|---|---|
| DALYTRAN | Sequential, 350 bytes/rec | 7 test transactions |
| XREFFILE | Indexed, key=XREF-CARD-NUM X(16), 50 bytes/rec | 5 card-to-account mappings |
| ACCTFILE | Indexed, key=ACCT-ID 9(11), 300 bytes/rec | 4 accounts |
| TCATBALF | Indexed, composite key 17 bytes, 50 bytes/rec | 1 pre-existing balance record |

### Transactions (in processing order)

| # | ID | Card | AMT | Outcome | Reason |
|---|---|---|---|---|---|
| 1 | TRN0000000000001 | 4000002000000000 | +50.00 | ACCEPTED | WS-TEMP-BAL=200-0+50=250 <=1000; expiry 2030-12-31 >= 2026-01-15 |
| 2 | TRN0000000000002 | 4000002000000001 | +75.00 | ACCEPTED | WS-TEMP-BAL=0-0+75=75 <=2000; expiry 2030-12-31 >= 2026-01-15 |
| 3 | TRN0000000000003 | 9999999999999999 | +10.00 | REJECT 0100 | Card not found in XREFFILE (INVALID KEY) |
| 4 | TRN0000000000004 | 4000002000000099 | +20.00 | REJECT 0101 | XREF found (acct 99), but account 00000000099 not in ACCTFILE |
| 5 | TRN0000000000005 | 4000002000000002 | +50.00 | REJECT 0102 | WS-TEMP-BAL=990-0+50=1040 > limit 1000 |
| 6 | TRN0000000000006 | 4000002000000003 | +25.00 | REJECT 0103 | Expiry 2020-01-01 < ORIG-TS(1:10)=2026-01-15 |
| 7 | TRN0000000000007 | 4000002000000001 | +100.00 | ACCEPTED | WS-TEMP-BAL=75-0+100=175 <=2000; expiry 2030 passes |

Note on TRN05: Both limit and expiry checks run (no early exit between them).
Limit: 1040 > 1000 → sets reason 0102. Expiry: 2030-12-31 >= 2026-01-15 → no change.
Final reason = 0102.

### XREFFILE Contents (5 records)

| XREF-CARD-NUM | XREF-CUST-ID | XREF-ACCT-ID | Notes |
|---|---|---|---|
| 4000002000000000 | 000000001 | 00000000001 | Valid account 1 |
| 4000002000000001 | 000000002 | 00000000002 | Valid account 2 |
| 4000002000000002 | 000000003 | 00000000003 | Over-limit account |
| 4000002000000003 | 000000004 | 00000000004 | Expired account |
| 4000002000000099 | 000000099 | 00000000099 | Account 99 does NOT exist → reject 101 |
| 9999999999999999 | (absent) | (absent) | Not in XREFFILE → reject 100 |

### ACCTFILE Initial State (4 records)

| ACCT-ID | CURR-BAL | CREDIT-LIMIT | EXPIRY | CYC-CREDIT | CYC-DEBIT | Notes |
|---|---|---|---|---|---|---|
| 00000000001 | 500.00 | 1000.00 | 2030-12-31 | 200.00 | 0.00 | Valid |
| 00000000002 | 1000.00 | 2000.00 | 2030-12-31 | 0.00 | 0.00 | Valid |
| 00000000003 | 990.00 | 1000.00 | 2030-12-31 | 990.00 | 0.00 | Over-limit test |
| 00000000004 | 100.00 | 5000.00 | 2020-01-01 | 0.00 | 0.00 | Expired |

### TCATBALF Initial State (1 record)

| TRANCAT-ACCT-ID | TRANCAT-TYPE-CD | TRANCAT-CD | TRAN-CAT-BAL |
|---|---|---|---|
| 00000000002 | CR | 0001 | 100.00 |

## Expected After-State

### ACCTFILE After-State

| ACCT-ID | CURR-BAL | CYC-CREDIT | CYC-DEBIT | Changes |
|---|---|---|---|---|
| 00000000001 | 550.00 | 250.00 | 0.00 | TRN01 +50 applied |
| 00000000002 | 1175.00 | 175.00 | 0.00 | TRN02 +75 and TRN07 +100 applied |
| 00000000003 | 990.00 | 990.00 | 0.00 | No change (rejected) |
| 00000000004 | 100.00 | 0.00 | 0.00 | No change (rejected) |

### TCATBALF After-State

| TRANCAT-ACCT-ID | TYPE | CAT | TRAN-CAT-BAL | Changes |
|---|---|---|---|---|
| 00000000001 | CR | 0001 | 50.00 | Created by TRN01 (new record) |
| 00000000002 | CR | 0001 | 275.00 | Updated: 100+75+100 (TRN02 and TRN07) |

### DALYREJS After-State (4 reject records, 430 bytes each)

| Record | Card | Reason Code | Description |
|---|---|---|---|
| 1 | 9999999999999999 | 0100 | INVALID CARD NUMBER FOUND |
| 2 | 4000002000000099 | 0101 | ACCOUNT RECORD NOT FOUND |
| 3 | 4000002000000002 | 0102 | OVERLIMIT TRANSACTION |
| 4 | 4000002000000003 | 0103 | TRANSACTION RECEIVED AFTER ACCT EXPIRATION |

### TRANFILE After-State (3 accepted, 350 bytes each, indexed)

| Record | TRAN-ID | Card | AMT | PROC-TS |
|---|---|---|---|---|
| 1 | TRN0000000000001 | 4000002000000000 | +50.00 | MASKED (non-deterministic) |
| 2 | TRN0000000000002 | 4000002000000001 | +75.00 | MASKED (non-deterministic) |
| 3 | TRN0000000000007 | 4000002000000001 | +100.00 | MASKED (non-deterministic) |

### STDOUT

```
START OF EXECUTION OF PROGRAM CBTRN02C
TCATBAL record not found for key : 00000000001CR0001.. Creating.
TRANSACTIONS PROCESSED :000000007
TRANSACTIONS REJECTED  :000000004
END OF EXECUTION OF PROGRAM CBTRN02C
```

Exit code: 4 (expected — rejections present; per program spec: RETURN-CODE=4 if WS-REJECT-COUNT > 0)

## Non-Determinism Handling

### TRAN-PROC-TS Masking (CRITICAL)

**Field**: TRAN-PROC-TS at offset 304, length 26 bytes within each 350-byte TRAN-RECORD.

**Source**: Set by `Z-GET-DB2-FORMAT-TIMESTAMP` using `FUNCTION CURRENT-DATE`. Changes on every run.

**Masking approach**: Zero bytes 304-329 (0-indexed) in every 350-byte record of the TRANFILE sequential dump before byte-for-byte comparison. Applied to both the golden copy and the test copy.

**Python snippet**:
```python
data = open(filename, 'rb').read()
out = bytearray(data)
for i in range(0, len(out), 350):
    for j in range(304, 330):
        if i+j < len(out):
            out[i+j] = 0
open(output, 'wb').write(bytes(out))
```

**Justification**: TRAN-PROC-TS is a processing timestamp stamped at the time the transaction is posted. It is intentionally non-deterministic and has no impact on correctness of business logic. The masking ensures the golden master comparison is stable across runs and machines, while all other fields (including TRAN-ORIG-TS and all amounts/codes) remain verified byte-for-byte.

### No Other Non-Determinism Found

- DALYREJS: fully deterministic (no timestamps written)
- ACCTFILE: fully deterministic after-state (only amounts updated, no wall-clock writes)
- TCATBALF: fully deterministic after-state

## Golden Files

| File | Size | Contents |
|---|---|---|
| `golden_DALYREJS` | 1720 bytes | 4 reject records × 430 bytes |
| `golden_TRNSEQ_masked` | 1050 bytes | 3 accepted transaction records × 350 bytes, PROC-TS zeroed |
| `golden_ACCTSEQ` | 1200 bytes | 4 account records × 300 bytes (after-state) |
| `golden_TCATSEQ` | 100 bytes | 2 TCATBAL records × 50 bytes (after-state) |
| `golden_stdout.txt` | 209 bytes | DISPLAY output from CBTRN02C |

## Run Script

`workspace/CBTRN02C/run_characterization.sh` — re-runnable; accepts optional Java binary path as `$1`.
Returns exit 0 (all pass) or exit 1 (any fail).
