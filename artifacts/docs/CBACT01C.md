# CBACT01C

## Purpose
CBACT01C is a batch COBOL program that reads the CardDemo account master file (ACCTFILE) sequentially and writes each account's fields into three different output files demonstrating VSAM indexed I/O, array-based records, and variable-length record (VBR) output. It also invokes an assembler date-formatting routine (COBDATFT) to reformat the account reissue date before writing.

## Inputs
- `ACCTFILE` — VSAM KSDS account master file; sequential read; record key `FD-ACCT-ID` (PIC 9(11))

## Outputs
- `OUTFILE` — Sequential flat output file; one formatted account record per input record
- `ARRYFILE` — Sequential flat output file; array-based record with 5-element balance/debit table
- `VBRCFILE` — Variable-length sequential file (RECORDING MODE V, 10–80 bytes); two sub-records per input: VBR1 (12 bytes: acct-id + status) and VBR2 (39 bytes: acct-id + bal + limit + reissue-year)

## Key Business Rules
1. Each account record from ACCTFILE is read sequentially until EOF (status `10`).
2. The account reissue date is passed through COBDATFT (assembler date formatter) with type `'2'` in/out; the reformatted date overwrites `OUT-ACCT-REISSUE-DATE`.
3. If `ACCT-CURR-CYC-DEBIT` is zero at write time, the value `2525.00` is substituted into `OUT-ACCT-CURR-CYC-DEBIT` — a hardcoded sentinel/default.
4. The array record always populates elements 1–3 only; elements 4–5 are left as initialised zeros.
5. Array element 1 and 2 carry `ACCT-CURR-BAL`; element 3 carries the hardcoded value `-1025.00`.
6. Array debit slots carry hardcoded values `1005.00`, `1525.00`, `-2500.00` for elements 1, 2, 3 respectively.
7. VBR record 1 (12 bytes) carries account-id and active-status; VBR record 2 (39 bytes) carries account-id, current balance, credit limit, and reissue year.
8. Any non-EOF, non-OK file status causes an immediate ABEND via `CEE3ABD`.
9. `OUTFILE-STATUS '10'` is treated as a soft warning (not an ABEND) at write time.

## Notable COBOL Constructs
- **Indexed I/O (KSDS sequential):** ACCTFILE is a VSAM KSDS accessed sequentially via `READ ACCTFILE-FILE INTO ACCOUNT-RECORD`; the key `FD-ACCT-ID` governs physical ordering.
- **REDEFINES:** `TWO-BYTES-ALPHA REDEFINES TWO-BYTES-BINARY` and `WS-REISSUE-DATE REDEFINES WS-ACCT-REISSUE-DATE` — overlay aliases; the binary interpretation must be byte-order-aware (big-endian mainframe).
- **COMP-3 field:** `OUT-ACCT-CURR-CYC-DEBIT` in the output record is declared `USAGE IS COMP-3` (packed decimal); Java must use `BigDecimal` or explicit BCD codec.
- **COMP (BINARY) field:** `OCCURS 5 TIMES` array in `ARRY-FILE` with `ARR-ACCT-CURR-CYC-DEBIT` as `COMP-3`.
- **Variable-length records:** VBRCFILE uses `RECORDING MODE IS V` with `RECORD IS VARYING ... DEPENDING ON WS-RECD-LEN`; the Java equivalent must write a 4-byte RDW prefix.
- **External CALL linkage:** `CALL 'COBDATFT' USING CODATECN-REC` — assembler routine for date formatting; semantic contract defined by CODATECN copybook.

## Copybook Dependencies
- `CVACT01Y` — provides `ACCOUNT-RECORD` group with `ACCT-ID`, `ACCT-CURR-BAL`, `ACCT-CREDIT-LIMIT`, `ACCT-CASH-CREDIT-LIMIT`, `ACCT-OPEN-DATE`, `ACCT-EXPIRAION-DATE`, `ACCT-REISSUE-DATE`, `ACCT-CURR-CYC-CREDIT`, `ACCT-CURR-CYC-DEBIT`, `ACCT-GROUP-ID`
- `CODATECN` — provides `CODATECN-REC` parameter block used to call COBDATFT

## Called Programs
- `COBDATFT` — assembler date-formatting routine; converts date between formats
- `CEE3ABD` — LE ABEND routine (abnormal termination)

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `FD-ACCT-ID` | `9(11)` | Account identifier (KSDS primary key) |
| `OUT-ACCT-CURR-BAL` | `S9(10)V99` | Current balance, signed decimal |
| `OUT-ACCT-CREDIT-LIMIT` | `S9(10)V99` | Credit limit, signed decimal |
| `OUT-ACCT-CURR-CYC-DEBIT` | `S9(10)V99 COMP-3` | Current cycle debit amount, packed decimal |
| `ARR-ACCT-BAL OCCURS 5` | group | Array of 5 (balance + COMP-3 debit) pairs |
| `VBR-REC` | `X(80)` | Variable-length output buffer; written with `WS-RECD-LEN` bytes active |
