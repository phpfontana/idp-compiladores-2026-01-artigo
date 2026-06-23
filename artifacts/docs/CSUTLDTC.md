# CSUTLDTC

## Purpose
CSUTLDTC is a COBOL subroutine that validates a date string against a given format mask by calling the IBM Language Environment (LE) API CEEDAYS. It is called by CICS programs (CORPT00C, COTRN02C) that need to verify user-entered dates before submitting reports or processing transactions. The subroutine returns a 15-character validation result string and sets RETURN-CODE to the CEEDAYS severity value.

## Inputs (LINKAGE SECTION)
- `LS-DATE` (`X(10)`) — date string to validate (e.g., `'2026-06-17'`)
- `LS-DATE-FORMAT` (`X(10)`) — CEEDAYS picture mask (e.g., `'YYYY-MM-DD'`)

## Outputs
- `LS-RESULT` (`X(80)`) — 80-character result message containing: severity code, message number, validation result text (15 chars), the test date, and the mask used
- `RETURN-CODE` — set to CEEDAYS SEVERITY value; 0 = valid date, non-zero = invalid

## Key Business Rules
1. The date and format strings are copied into CEEDAYS-compatible variable-length string structures (`Vstring-length` + `Vstring-text` with DEPENDING ON clause).
2. CEEDAYS converts the input date to a Lilian-format day count and populates FEEDBACK-CODE with detailed error information.
3. The FEEDBACK-TOKEN-VALUE 88-level conditions classify the CEEDAYS outcome into one of eight error types: insufficient data, bad date value, invalid era, unsupported range, invalid month, bad picture string, non-numeric data, or year-in-era zero.
4. `FC-INVALID-DATE` (value `X'0000000000000000'`) indicates a **valid** date despite the field name suggesting otherwise.
5. Any WHEN OTHER in the EVALUATE maps to `'Date is invalid'` — the catch-all for unrecognized CEEDAYS feedback codes.
6. The subroutine ends with `EXIT PROGRAM` (not GOBACK) — it is a nested or separately compiled subroutine, not a main program.
7. The 15-character `WS-RESULT` text is the primary signal callers use to check validity; the full `WS-MESSAGE` is returned in `LS-RESULT` for diagnostic display.

## Notable COBOL Constructs
- **OCCURS DEPENDING ON:** `Vstring-char OCCURS 0 TO 256 TIMES DEPENDING ON Vstring-length` — the variable-length string structure required by the CEEDAYS API; Java must either pass the string directly or mock the validation.
- **REDEFINES for feedback decode:** `CASE-2-CONDITION-ID REDEFINES CASE-1-CONDITION-ID` — overlays SEVERITY+MSG-NO with CLASS-CODE+CAUSE-CODE, giving two views of the same 4-byte feedback token.
- **88-level conditions on hexadecimal values:** `FC-INVALID-DATE VALUE X'0000000000000000'` — 8-byte token compared as a group; translating these 88-levels to Java requires explicit hex constant comparisons.
- **External LE API CALL:** `CALL "CEEDAYS" USING WS-DATE-TO-TEST, WS-DATE-FORMAT, OUTPUT-LILLIAN, FEEDBACK-CODE` — IBM Language Environment date service; Java equivalent is `LocalDate.parse()` with a DateTimeFormatter and exception catching.

## Copybook Dependencies
None

## Called Programs
- `CEEDAYS` — IBM LE date-to-Lilian-number conversion API

## Data Structures
| Field | PIC | Description |
|---|---|---|
| `LS-DATE` | `X(10)` | Input date string |
| `LS-DATE-FORMAT` | `X(10)` | CEEDAYS picture mask string |
| `LS-RESULT` | `X(80)` | Full diagnostic result message returned to caller |
| `OUTPUT-LILLIAN` | `S9(9) BINARY` | Lilian day count output from CEEDAYS (not used by callers) |
| `FEEDBACK-CODE` | 8-byte group | CEEDAYS API feedback token; 88-level conditions classify outcome |
| `WS-SEVERITY-N` | `9(4)` | Numeric severity extracted from feedback; also set to RETURN-CODE |
