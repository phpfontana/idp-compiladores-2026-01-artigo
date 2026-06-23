# Golden Master Manifest — CBSTM03A

Generated: 2026-06-20
GnuCOBOL version: 3.2.0
Platform: macOS (darwin arm64)

## Test Data Summary
- 2 cards, 3 transactions total
- Card 1 (4000002000000001): 2 transactions ($10000.00 + $5000.00)
- Card 2 (4000002000000002): 1 transaction ($7500.00)
- 2 XREF records
- 2 customer records (CUST-ID 000000001, 000000002)
- 2 account records (ACCT-ID 00000000001, 00000000002)

## File Inventory

| File | Size (bytes) | SHA256 | Format | Description |
|------|-------------|--------|--------|-------------|
| golden_STMTFILE | 3280 | 36506c03fad48aac7cd761b620cfaac35343a9970fea253b94e32fc53a6c976a | Binary (no newlines), fixed 80-char records | Plain-text statement output (2 statements) |
| golden_HTMLFILE | 16100 | d474aaa17265051a2164269a06209c5e7b8955ee407764cca3ce21f22573210e | Binary (no newlines), fixed 100-char records | HTML statement output (2 statements) |
| golden_stdout.txt | 202 | ce1ff28132b776dd73ffeedced45490ebccc9e2963f6ad1dfc42cf6d433d903a | ASCII text with newlines | Stdout: PSA stub header + DD name display |

## Notes
- STMTFILE and HTMLFILE are fixed-length record files with no line terminators (GnuCOBOL LINE SEQUENTIAL disabled for these FD definitions, producing raw fixed-format output).
- Compare byte-for-byte with `cmp` command.
- PSA/TCB/TIOT block was replaced with stub displays (lines 266-291 of original).
- CUSTREC.cpy was rewritten locally to fix tab-expansion column overflow issue in original source.
