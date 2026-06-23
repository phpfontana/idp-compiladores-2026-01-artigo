# CBSTM03A

## Purpose
CBSTM03A is a batch COBOL program that generates customer account statements in two formats simultaneously: a plain-text file (80-character records to STMTFILE) and an HTML file (100-character records to HTMLFILE). It reads the transaction file, cross-reference file, customer file, and account file — but delegates all file I/O to the subroutine CBSTM03B via a control-area CALL interface. The program is explicitly designed to exercise mainframe-specific constructs including control-block addressing (PSA/TCB/TIOT), `ALTER`/`GO TO` statements, COMP and COMP-3 variables, a two-dimensional OCCURS table, and inter-program CALL linkage.

## Inputs
All input file I/O is routed through CBSTM03B:
- `TRNXFILE` — VSAM KSDS transaction file (sequential read); keyed by (CARD-NUM + TRAN-ID)
- `XREFFILE` — VSAM KSDS card cross-reference (sequential read)
- `CUSTFILE` — VSAM KSDS customer file (random read by CUST-ID)
- `ACCTFILE` — VSAM KSDS account file (random read by ACCT-ID)

## Outputs
- `STMTFILE` — Sequential plain-text statement file; 80-character records; one statement per customer
- `HTMLFILE` — Sequential HTML statement file; 100-character records; complete HTML document per customer

## Key Business Rules
1. On startup, the program reads PSA/TCB/TIOT control blocks to discover and display JCL DD names — a mainframe system programming technique not typical in application programs.
2. The program uses `ALTER ... TO PROCEED TO` statements at paragraph 8100-FILE-OPEN to dynamically redirect `GO TO` targets based on the `WS-FL-DD` state variable — a deprecated but valid COBOL construct.
3. Processing order: open TRNXFILE → read all transactions into an in-memory 2-D table → open XREFFILE → open CUSTFILE → open ACCTFILE → then iterate XREFFILE sequentially; for each XREF record, fetch customer and account by key, generate a statement, then look up that account's transactions in the in-memory table.
4. All transactions are pre-loaded into `WS-TRNX-TABLE`: up to 51 unique card numbers (`WS-CARD-TBL OCCURS 51 TIMES`) each with up to 10 transactions (`WS-TRAN-TBL OCCURS 10 TIMES`) — hard limits; overflow is silently ignored.
5. For each XREF record, the program writes both a plain-text statement (ST-LINE* records) and an HTML statement to the respective output files.
6. The plain-text statement includes: customer name and address, account-id, current balance, FICO score, and a transaction summary table.
7. The HTML statement is a full HTML document with inline CSS styling (hardcoded as 88-level values on HTML-FIXED-LN).
8. Transaction amounts are accumulated in `WS-TOTAL-AMT` (COMP-3) and written as a total expense line at end of each statement.
9. CBSTM03B is called with operation codes: `'O'`=Open, `'C'`=Close, `'R'`=Read-sequential, `'K'`=Read-by-key, `'W'`=Write, `'Z'`=Rewrite.
10. CBSTM03B returns a 2-character return code mirroring VSAM file-status values (`'00'`=OK, `'10'`=EOF, `'04'`=open warning).

## Notable COBOL Constructs
- **Mainframe control block addressing:** `SET ADDRESS OF PSA-BLOCK TO PSAPTR` / `SET ADDRESS OF TCB-BLOCK TO TCB-POINT` reads real z/OS system control blocks via POINTER-typed LINKAGE SECTION fields; this technique requires z/OS to run and has no direct Java equivalent.
- **ALTER / GO TO:** `ALTER 8100-FILE-OPEN TO PROCEED TO 8100-TRNXFILE-OPEN` dynamically changes the target of a `GO TO` at runtime; the Java translator must replace this with a dispatch table or state machine.
- **COMP and COMP-3 variables:** `CR-CNT`, `TR-CNT`, `CR-JMP`, `TR-JMP` are `COMP` (binary halfword); `WS-TOTAL-AMT PIC S9(9)V99` is `COMP-3` (packed decimal). Java must use `short`/`int` for COMP and `BigDecimal` for COMP-3.
- **Two-dimensional OCCURS:** `WS-CARD-TBL OCCURS 51 TIMES` containing `WS-TRAN-TBL OCCURS 10 TIMES` — a 51×10 in-memory transaction table; Java maps to a 2-D array or List of Lists.
- **Inter-program CALL linkage:** `CALL 'CBSTM03B' USING WS-M03B-AREA` passes a 1036-byte control area by reference; CBSTM03B must be separately compiled and loaded; Java equivalent is a method call or separate class.
- **PERFORM THRU:** `PERFORM 5100-WRITE-HTML-HEADER THRU 5100-EXIT` — executes a range of consecutive paragraphs; the `EXIT` paragraph acts as a fence; the Java translator must inline the paragraph range.
- **REDEFINES:** `TIOT-INDEX REDEFINES BUMP-TIOT POINTER` — overlays a `PIC S9(08) BINARY` with a `POINTER` to enable arithmetic on a pointer value (TIOT navigation).

## Copybook Dependencies
- `COSTM01` — provides `TRNX-RECORD` layout (TRNX-CARD-NUM, TRNX-ID, TRNX-REST, TRNX-AMT, TRNX-DESC) and report header/detail line structures
- `CVACT03Y` — provides `CARD-XREF-RECORD` (XREF-CARD-NUM, XREF-CUST-ID, XREF-ACCT-ID)
- `CUSTREC` — provides `CUSTOMER-RECORD` (CUST-FIRST-NAME, CUST-LAST-NAME, CUST-ADDR-*, CUST-FICO-CREDIT-SCORE)
- `CVACT01Y` — provides `ACCOUNT-RECORD` (ACCT-ID, ACCT-CURR-BAL)

## Called Programs
- `CBSTM03B` — I/O subroutine; all file operations routed through this call
- `CEE3ABD` — LE ABEND routine

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `WS-M03B-DD` | `X(08)` | DD name for CBSTM03B: TRNXFILE, XREFFILE, CUSTFILE, ACCTFILE |
| `WS-M03B-OPER` | `X(01)` | Operation code: O=open, C=close, R=read-seq, K=read-key, W=write, Z=rewrite |
| `WS-M03B-RC` | `X(02)` | Return code from CBSTM03B; mirrors VSAM file status |
| `WS-M03B-KEY` | `X(25)` | Key value for keyed reads (CUST-ID or ACCT-ID) |
| `WS-M03B-FLDT` | `X(1000)` | Data field passed to/from CBSTM03B |
| `WS-CARD-TBL OCCURS 51` | group | One entry per unique card number in transaction file |
| `WS-TRAN-TBL OCCURS 10` | group | Up to 10 transactions per card |
| `WS-TOTAL-AMT` | `S9(9)V99 COMP-3` | Accumulated transaction total for current statement |
