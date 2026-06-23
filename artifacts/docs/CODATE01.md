# CODATE01

## Purpose
CODATE01 is a CICS IS INITIAL MQ listener program in the CardDemo `app-vsam-mq` sub-application. It receives date/time query messages from an IBM MQ queue and replies with the current date and time obtained via EXEC CICS ASKTIME/FORMATTIME. It is a utility service that provides the current timestamp to MQ-based callers.

## Sub-Application
`app-vsam-mq` — not part of the five-program core subset; requires IBM MQ.

## Inputs
- `MQ-QUEUE PIC X(48)` — IBM MQ request queue; MQGET for incoming date requests
- No VSAM file access — date comes from EXEC CICS ASKTIME

## Outputs
- `MQ-QUEUE-REPLY PIC X(48)` — IBM MQ reply queue; MQPUT with `WS-MMDDYYYY X(10)` and `WS-TIME X(8)`
- `WS-ABS-TIME PIC S9(15) COMP-3 VALUE ZERO` — CICS absolute time (packed decimal)

## Key Business Rules
1. Identical MQ infrastructure to COACCT01 (same MQGET/MQPUT pattern, same correlation ID handling).
2. `IS INITIAL` — stateless; each invocation is independent.
3. No file I/O — the sole purpose is to return the current date/time from CICS.
4. `WS-MMDDYYYY` (X(10)) and `WS-TIME` (X(8)) are populated via FORMATTIME after ASKTIME.

## Relationship to COACCT01
CODATE01 and COACCT01 share identical MQ infrastructure (same WS structure names and copybooks) but serve different purposes: COACCT01 accesses ACCTDAT, CODATE01 returns system date/time. Both are IS INITIAL programs with the same MQ listener loop pattern.
