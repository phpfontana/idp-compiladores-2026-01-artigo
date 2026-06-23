# CBSTM03B

## Purpose
CBSTM03B is a COBOL I/O subroutine called exclusively by CBSTM03A. It encapsulates all file open, close, read, and write operations for four VSAM files — TRNXFILE, XREFFILE, CUSTFILE, and ACCTFILE — behind a single CALL interface. The caller passes a control area specifying the file DD name, an operation code, an optional key, and a data buffer; CBSTM03B performs the requested I/O and returns a 2-character file-status code. This design isolates CBSTM03A's business logic from VSAM details and concentrates all file-status exception handling in one module.

## Inputs (LINKAGE SECTION)
All parameters are passed via a single group item `LK-M03B-AREA`:
- `LK-M03B-DD` (`X(08)`) — JCL DD name identifying the file: `TRNXFILE`, `XREFFILE`, `CUSTFILE`, `ACCTFILE`
- `LK-M03B-OPER` (`X(01)`) — Operation code: `O`=Open, `C`=Close, `R`=Read-sequential, `K`=Read-by-key, `W`=Write, `Z`=Rewrite
- `LK-M03B-RC` (`X(02)`) — Return code written by CBSTM03B after each call; mirrors VSAM file-status values
- `LK-M03B-KEY` (`X(25)`) — Key value used for `K` (keyed-read) operations
- `LK-M03B-KLEN` (`S9(4) COMP`) — Length of the active portion of `LK-M03B-KEY`
- `LK-M03B-FLDT` (`X(1000)`) — Data field: populated by CBSTM03B for reads; consumed by CBSTM03B for writes

## Outputs
- `LK-M03B-RC` — 2-character return code after every operation; `'00'`=OK, `'10'`=EOF, `'04'`=open warning, `'23'`=key not found, `'00'`=write OK
- All four VSAM files as side effects of write/rewrite operations

## Key Business Rules
1. CBSTM03B dispatches on `LK-M03B-DD` to select the appropriate internal file handle, then dispatches on `LK-M03B-OPER` to select the operation.
2. TRNXFILE and XREFFILE are sequential files; only `O`, `C`, and `R` operations are valid for them.
3. CUSTFILE and ACCTFILE are VSAM KSDS files; only `O`, `C`, and `K` operations are valid for them (no sequential read or write from CBSTM03B).
4. After every VSAM operation, `LK-M03B-RC` is set from the file-status field (`WS-TRNX-STATUS`, `WS-XREF-STATUS`, `WS-CUST-STATUS`, `WS-ACCT-STATUS`) before returning to the caller.
5. A file-status of `'00'` or `'04'` on OPEN is treated as success; any other status causes an ABEND via `PERFORM 9999-ABEND`.
6. A read returning status `'10'` (EOF) is a normal return code — the caller checks it to stop iteration.
7. For operation `K`, the key is moved from `LK-M03B-KEY` (trimmed to `LK-M03B-KLEN` bytes) into the appropriate file's record-key field before issuing `READ ... KEY IS`.
8. For operation `W` (write), `LK-M03B-FLDT` is moved into the file record area before issuing `WRITE`.
9. For operation `Z` (rewrite), `LK-M03B-FLDT` is moved into the file record area before issuing `REWRITE`.
10. CBSTM03B never calls CBSTM03A back; it is a pure subroutine with no upward dependencies.

## Notable COBOL Constructs
- **PERFORM THRU pattern:** Each operation paragraph uses `PERFORM <para> THRU <para>-EXIT` where `<para>-EXIT` is an empty `EXIT` statement — the standard z/OS mainframe fence pattern for structured paragraph scoping.
- **LINKAGE SECTION parameter passing:** The entire control interface is a single by-reference group item `LK-M03B-AREA`; all sub-fields are defined as LINKAGE-SECTION subordinate items.
- **File-status variable per file:** Each of the four files has its own 2-character `WS-xx-STATUS` working-storage field; after each I/O verb the status is copied to `LK-M03B-RC` for the caller to inspect.
- **SELECT...ASSIGN:** All four files are defined with `ORGANIZATION IS INDEXED`, `ACCESS MODE IS DYNAMIC` (CUSTFILE, ACCTFILE) or `ACCESS MODE IS SEQUENTIAL` (TRNXFILE, XREFFILE); dynamic access allows both sequential and keyed reads from the same OPEN.
- **No COPY statements:** CBSTM03B defines all record layouts inline rather than using copybooks, which means its record structures must be manually kept in sync with the shared copybooks used in CBSTM03A. This is a maintenance risk for the Java translator.

## Copybook Dependencies
None — all record layouts are defined inline in CBSTM03B's DATA DIVISION.

## Called Programs
- `CEE3ABD` — LE ABEND routine invoked from `9999-ABEND` on unexpected file status

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `LK-M03B-DD` | `X(08)` | DD name selector: TRNXFILE, XREFFILE, CUSTFILE, ACCTFILE |
| `LK-M03B-OPER` | `X(01)` | Operation: O=open, C=close, R=read-seq, K=read-key, W=write, Z=rewrite |
| `LK-M03B-RC` | `X(02)` | Return code; VSAM file-status value |
| `LK-M03B-KEY` | `X(25)` | Lookup key for K operations |
| `LK-M03B-KLEN` | `S9(4) COMP` | Active length of LK-M03B-KEY |
| `LK-M03B-FLDT` | `X(1000)` | Data buffer passed to or from the file operation |
| `WS-TRNX-STATUS` | `X(02)` | File status for TRNXFILE after each I/O |
| `WS-XREF-STATUS` | `X(02)` | File status for XREFFILE after each I/O |
| `WS-CUST-STATUS` | `X(02)` | File status for CUSTFILE after each I/O |
| `WS-ACCT-STATUS` | `X(02)` | File status for ACCTFILE after each I/O |
