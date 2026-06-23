# COACCT01

## Purpose
COACCT01 is a CICS IS INITIAL MQ listener program in the CardDemo `app-vsam-mq` sub-application. It receives account query messages from an IBM MQ queue, reads the ACCTDAT CICS VSAM dataset, and sends the account record back to a reply queue. It is a service-oriented integration bridge between MQ-based callers and the CICS/VSAM account store.

## Sub-Application
`app-vsam-mq` — not part of the five-program core subset; requires IBM MQ (`CMQGMOV`, `CMQPMOV`, `CMQMDV` copybooks).

## Inputs
- `MQ-QUEUE PIC X(48)` — IBM MQ request queue name; MQGET to receive account query
- `MQ-BUFFER PIC X(1000)` — message buffer (contains account ID query)
- `ACCTDAT` CICS VSAM KSDS — account master; read by key parsed from MQ message

## Outputs
- `MQ-QUEUE-REPLY PIC X(48)` — IBM MQ reply queue; MQPUT to send account record
- Response correlated via `MQ-CORRELID PIC X(24)` / `SAVE-CORELID`

## Key Business Rules
1. `IS INITIAL` — program is not re-entrant; each CICS task starts fresh (no persistent WS state).
2. `WS-MQ-MSG-FLAG` (`NO-MORE-MSGS = 'Y'`) — controls the MQGET loop; exits when queue is empty.
3. `WS-RESP-QUEUE-STS`, `WS-ERR-QUEUE-STS`, `WS-REPLY-QUEUE-STS` — track queue open states.
4. `MQ-HCONN` / `MQ-HOBJ` (S9(9) BINARY) — MQ connection and object handles.
5. EXEC CICS ASKTIME + FORMATTIME for `WS-MMDDYYYY X(10)` and `WS-TIME X(8)` — timestamp for reply.
6. `SAVE-CORELID`, `SAVE-MSGID`, `SAVE-REPLY2Q` — correlation ID and reply-to-queue saved before processing to enable proper MQPUT response.

## Notable COBOL Constructs
- **IBM MQ CALL interface:** `MQCONN`/`MQOPEN`/`MQGET`/`MQPUT`/`MQCLOSE`/`MQDISC` via CALL (not EXEC MQ); condition codes checked via WS-CONDITION-CODE and WS-REASON-CODE (both S9(9) BINARY).
- **CMQGMOV/CMQPMOV/CMQMDV:** IBM MQ copybooks for get-message-options, put-message-options, and message-descriptor — no Java equivalent; Java uses IBM MQ JMS or MQ classes for Java.
