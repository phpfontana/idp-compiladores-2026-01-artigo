# Equivalence Report — CBSTM03A

**Date/Time:** 2026-06-20T20:45  
**Verifier:** equivalence-verifier subagent  
**Role constraint:** read-and-run only; no Java or COBOL source files were edited

---

## Test Command

```bash
cd /Users/fontana/Desktop/idp-compiladores-2026-01-av02
./workspace/CBSTM03A/run_characterization.sh java
```

Exit code: **0**  
Wall clock: **~1s**

---

## Comparisons

| # | File | Result | Test size (bytes) | Golden size (bytes) | Test SHA256 | Golden SHA256 |
|---|---|---|---|---|---|---|
| 1 | STMTFILE | **PASS** | 3280 | 3280 | `36506c03fad48aac7cd761b620cfaac35343a9970fea253b94e32fc53a6c976a` | `36506c03fad48aac7cd761b620cfaac35343a9970fea253b94e32fc53a6c976a` |
| 2 | HTMLFILE | **PASS** | 16100 | 16100 | `d474aaa17265051a2164269a06209c5e7b8955ee407764cca3ce21f22573210e` | `d474aaa17265051a2164269a06209c5e7b8955ee407764cca3ce21f22573210e` |
| 3 | stdout   | **PASS** | 202 | 202 | `ce1ff28132b776dd73ffeedced45490ebccc9e2963f6ad1dfc42cf6d433d903a` | `ce1ff28132b776dd73ffeedced45490ebccc9e2963f6ad1dfc42cf6d433d903a` |

All SHA256 hashes are identical between test output and golden master.

---

## Overall Verdict

**ACCEPTED — 3/3 PASS**

The Java translation of CBSTM03A produces byte-for-byte identical output to the COBOL golden master across all three output artifacts (STMTFILE, HTMLFILE, stdout). No differences were detected.
