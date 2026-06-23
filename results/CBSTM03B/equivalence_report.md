# CBSTM03B Equivalence Report

**Date:** 2026-06-21  
**Phase:** P4 — Equivalence Verification  
**Program:** CBSTM03B (COBOL I/O subroutine — Java translation)  
**Command:** `./workspace/CBSTM03B/run_characterization.sh java`  
**Overall Verdict:** ACCEPTED

---

## Comparison Results

### 1. test_OUTPUT_java vs golden_OUTPUT

| Attribute | Test (Java) | Golden (COBOL) |
|-----------|------------|----------------|
| File | `workspace/CBSTM03B/test_OUTPUT_java` | `results/CBSTM03B/golden_OUTPUT` |
| Size (bytes) | 1520 | 1520 |
| SHA-256 | `52442608db411f7bf838445692937639ffb03e61c902bc6cf501ba4bfd6c95ff` | `52442608db411f7bf838445692937639ffb03e61c902bc6cf501ba4bfd6c95ff` |
| Result | **PASS** | — |

### 2. test_stdout_java.txt vs golden_stdout.txt

| Attribute | Test (Java) | Golden (COBOL) |
|-----------|------------|----------------|
| File | `workspace/CBSTM03B/test_stdout_java.txt` | `results/CBSTM03B/golden_stdout.txt` |
| Size (bytes) | 1539 | 1539 |
| SHA-256 | `75bad4acc6cf35f88725f42dcad8093816fa43ac6db38eff19e9ca2b46557dd2` | `75bad4acc6cf35f88725f42dcad8093816fa43ac6db38eff19e9ca2b46557dd2` |
| Result | **PASS** | — |

---

## Summary

| Comparison | Result |
|------------|--------|
| OUTPUT file (fixed-record binary, 19×80 bytes) | PASS |
| stdout (19 lines of DISPLAY output) | PASS |
| **Overall** | **2/2 PASS — ACCEPTED** |

The Java translation of CBSTM03B produces byte-for-byte identical output for both
the sequential OUTPUT file and the stdout stream across all 19 CBSTM03B call
sequences (TRNXFILE O+3R+EOF+C, XREFFILE O+2R+EOF+C, CUSTFILE O+2K+C, ACCTFILE
O+2K+C). SHA-256 digests match exactly.

**Wall clock:** < 1 s  
**Exit code:** 0  
**Interventions:** 0
