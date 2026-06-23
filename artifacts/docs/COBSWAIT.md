# COBSWAIT

## Purpose
COBSWAIT is a minimal batch utility program that reads a wait duration in centiseconds from SYSIN, then CALLs the z/OS assembler routine MVSWAIT to perform a timed wait (sleep). It is used in JCL job streams to introduce controlled delays.

## Inputs
- `SYSIN` — accepts an 8-character string (`PARM-VALUE`) containing a centisecond count

## Outputs
- None (side effect: CPU execution suspended for the specified duration via MVSWAIT)

## Key Business Rules
1. PARM-VALUE is accepted as an 8-character alphanumeric value from SYSIN and MOVE'd verbatim into the 8-digit binary field MVSWAIT-TIME.
2. MVSWAIT is called with MVSWAIT-TIME as the only parameter; no return value is used.
3. Program terminates with STOP RUN (not GOBACK — this is a main-program style, not a subroutine).

## Notable COBOL Constructs
- **ACCEPT from SYSIN:** Uses `ACCEPT PARM-VALUE FROM SYSIN` — not a file read, but the DD-name-based input path common in z/OS batch.
- **COMP binary field:** `MVSWAIT-TIME PIC 9(8) COMP` — binary 4-byte integer passed to the assembler routine.
- **External assembler CALL:** `CALL 'MVSWAIT' USING MVSWAIT-TIME` — MVSWAIT is an IBM z/OS or vendor-provided macro/routine; Java equivalent is `Thread.sleep()`.

## Copybook Dependencies
None

## Called Programs
- `MVSWAIT` — z/OS assembler wait routine; suspends execution for the given centisecond count

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `MVSWAIT-TIME` | `9(8) COMP` | Wait duration in centiseconds |
| `PARM-VALUE` | `X(8)` | Raw input from SYSIN |
