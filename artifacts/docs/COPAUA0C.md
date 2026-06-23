# COPAUA0C

## Purpose
COPAUA0C is a CICS COBOL IMS MQ program — the Card Authorization Decision engine in CardDemo's Authorization sub-application. It receives authorization requests from an IBM MQ request queue (WS-REQUEST-QNAME), reads ACCTDAT/CUSTDAT/CARDDAT/CCXREF to evaluate the request, and sends an authorization decision (approved/declined with available amount) back to the MQ reply queue (WS-REPLY-QNAME). It also writes to an IMS database via PSB PSBPAUTB. Trans-ID is `CP00`.

## Sub-Application
`app-authorization-ims-db2-mq` — not part of the five-program core subset; requires IMS DB and IBM MQ which are not available in the GnuCOBOL test environment.

## Inputs
- IBM MQ request queue (WS-REQUEST-QNAME, up to 500 messages per CICS task via `WS-REQSTS-PROCESS-LIMIT`)
- `ACCTDAT` CICS VSAM KSDS — account master; read to check credit limit and current balance
- `CUSTDAT` CICS VSAM KSDS — customer master
- `CARDDAT` CICS VSAM KSDS — card master; read to validate card status
- `CCXREF` CICS VSAM KSDS — card-to-account cross-reference; read by card number to resolve account

## Outputs
- MQ reply to WS-REPLY-QNAME with authorization decision: WS-AVAILABLE-AMT, WS-APPROVED-AMT, WS-AUTH-APRV-STAT
- IMS DB write via PCB (PSBPAUTB) — stores authorization record
- EXEC CICS ASKTIME + FORMATTIME for WS-CUR-DATE-X6, WS-CUR-TIME-X6, WS-TIME-WITH-MS (timestamp for auth record)

## Key Business Rules
1. Reads up to `WS-REQSTS-PROCESS-LIMIT` (500) MQ messages per invocation.
2. For each message: reads CCXREF to get account, reads ACCTDAT to get credit limit and current balance.
3. `WS-AVAILABLE-AMT = ACCT-CREDIT-LIMIT - ACCT-CURR-BAL`.
4. If `WS-TRANSACTION-AMT <= WS-AVAILABLE-AMT` → approved; otherwise declined.
5. WS-SAVE-CORRELID stores the MQ correlation ID for request/reply matching.
6. IMS PCB write records the authorization decision in the authorization DB.
7. MQ MQGET with correlation ID for targeted reply routing.

## Notable COBOL Constructs
- **IBM MQ MQPUT/MQGET via CALL:** Uses WS-REQUEST-QNAME (X(48)) — CICS MQ CALL interface (not EXEC CICS MQ); condition codes via WS-COMPCODE/WS-REASON (S9(9) BINARY).
- **Dual middleware:** Simultaneously uses CICS (file control for VSAM), IMS (DL/I for auth DB), and IBM MQ — the most technically complex program in the repository.
- **WS-ABS-TIME COMP-3:** Same EXEC CICS ASKTIME pattern as COBIL00C; 15-digit packed decimal.

## Copybook Dependencies
IMS PCB structures (PSBPAUTB), IBM MQ message descriptor and option copybooks; CVACT01Y, CVACT03Y for VSAM file layouts.
