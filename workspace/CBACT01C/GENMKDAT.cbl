      ******************************************************************
      * GENMKDAT.cbl
      * Generate test account records for CBACT01C characterization.
      *
      * Three test cases:
      * 1. Account 00000000001 - ACCT-CURR-CYC-DEBIT = 0
      *    (triggers 2525.00 sentinel write in CBACT01C)
      * 2. Account 00000000002 - ACCT-CURR-CYC-DEBIT != 0 (normal)
      *    REISSUE-DATE = 2020-01-15 (exercises COBDATFT conversion)
      * 3. Account 00000000003 - ACCT-CURR-CYC-DEBIT != 0
      *    Different balance/limit values
      *
      * ACCOUNT-RECORD layout (300 bytes total):
      *   ACCT-ID               PIC 9(11)       11 bytes
      *   ACCT-ACTIVE-STATUS    PIC X(01)        1 byte
      *   ACCT-CURR-BAL         PIC S9(10)V99   12 bytes (display)
      *   ACCT-CREDIT-LIMIT     PIC S9(10)V99   12 bytes
      *   ACCT-CASH-CREDIT-LIMIT PIC S9(10)V99  12 bytes
      *   ACCT-OPEN-DATE        PIC X(10)       10 bytes
      *   ACCT-EXPIRAION-DATE   PIC X(10)       10 bytes
      *   ACCT-REISSUE-DATE     PIC X(10)       10 bytes
      *   ACCT-CURR-CYC-CREDIT  PIC S9(10)V99   12 bytes
      *   ACCT-CURR-CYC-DEBIT   PIC S9(10)V99   12 bytes
      *   ACCT-ADDR-ZIP         PIC X(10)       10 bytes
      *   ACCT-GROUP-ID         PIC X(10)       10 bytes
      *   FILLER                PIC X(178)      178 bytes
      *                                  Total: 300 bytes
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENMKDAT.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-FILE ASSIGN TO ACCTFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS GEN-ACCT-ID
                  FILE STATUS  IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-FILE.
       01  GEN-ACCT-REC.
           05  GEN-ACCT-ID            PIC 9(11).
           05  GEN-ACCT-DATA          PIC X(289).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05  WS-STATUS-1            PIC X.
           05  WS-STATUS-2            PIC X.

       01  WS-ACCOUNT-RECORD.
           05  ACCT-ID                PIC 9(11).
           05  ACCT-ACTIVE-STATUS     PIC X(01).
           05  ACCT-CURR-BAL          PIC S9(10)V99.
           05  ACCT-CREDIT-LIMIT      PIC S9(10)V99.
           05  ACCT-CASH-CREDIT-LIMIT PIC S9(10)V99.
           05  ACCT-OPEN-DATE         PIC X(10).
           05  ACCT-EXPIRAION-DATE    PIC X(10).
           05  ACCT-REISSUE-DATE      PIC X(10).
           05  ACCT-CURR-CYC-CREDIT   PIC S9(10)V99.
           05  ACCT-CURR-CYC-DEBIT    PIC S9(10)V99.
           05  ACCT-ADDR-ZIP          PIC X(10).
           05  ACCT-GROUP-ID          PIC X(10).
           05  WS-FILLER              PIC X(178).

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT ACCT-FILE
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING ACCTFILE: ' WS-FILE-STATUS
               STOP RUN
           END-IF

      *---------------------------------------------------------------*
      * RECORD 1: ACCT-CURR-CYC-DEBIT = 0
      * Triggers the 2525.00 sentinel in CBACT01C (1300-POPUL-ACCT-RECORD)
      *---------------------------------------------------------------*
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 00000000001        TO ACCT-ID
           MOVE 'Y'                TO ACCT-ACTIVE-STATUS
           MOVE 1234567890.50      TO ACCT-CURR-BAL
           MOVE 5000000000.00      TO ACCT-CREDIT-LIMIT
           MOVE 2500000000.00      TO ACCT-CASH-CREDIT-LIMIT
           MOVE '2018-03-01'       TO ACCT-OPEN-DATE
           MOVE '2025-03-01'       TO ACCT-EXPIRAION-DATE
           MOVE '2020-03-01'       TO ACCT-REISSUE-DATE
           MOVE 100000.00          TO ACCT-CURR-CYC-CREDIT
           MOVE 0                  TO ACCT-CURR-CYC-DEBIT
           MOVE '10001-0001'       TO ACCT-ADDR-ZIP
           MOVE 'GRP0000001'       TO ACCT-GROUP-ID
           MOVE SPACES             TO WS-FILLER
           MOVE WS-ACCOUNT-RECORD  TO GEN-ACCT-REC
           WRITE GEN-ACCT-REC
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'ERROR WRITING RECORD 1: ' WS-FILE-STATUS
               STOP RUN
           END-IF
           DISPLAY 'WROTE RECORD 1 (DEBIT=0, triggers 2525.00 sentinel)'

      *---------------------------------------------------------------*
      * RECORD 2: ACCT-CURR-CYC-DEBIT != 0, REISSUE-DATE exercises
      *           COBDATFT: 2020-01-15 -> 20200115
      *---------------------------------------------------------------*
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 00000000002        TO ACCT-ID
           MOVE 'Y'                TO ACCT-ACTIVE-STATUS
           MOVE 9876543210.99      TO ACCT-CURR-BAL
           MOVE 9999999999.00      TO ACCT-CREDIT-LIMIT
           MOVE 4999999999.00      TO ACCT-CASH-CREDIT-LIMIT
           MOVE '2015-06-15'       TO ACCT-OPEN-DATE
           MOVE '2026-06-15'       TO ACCT-EXPIRAION-DATE
           MOVE '2020-01-15'       TO ACCT-REISSUE-DATE
           MOVE 250000.75          TO ACCT-CURR-CYC-CREDIT
           MOVE 175000.25          TO ACCT-CURR-CYC-DEBIT
           MOVE '90210-5555'       TO ACCT-ADDR-ZIP
           MOVE 'PREMGROUP1'       TO ACCT-GROUP-ID
           MOVE SPACES             TO WS-FILLER
           MOVE WS-ACCOUNT-RECORD  TO GEN-ACCT-REC
           WRITE GEN-ACCT-REC
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'ERROR WRITING RECORD 2: ' WS-FILE-STATUS
               STOP RUN
           END-IF
           DISPLAY 'WROTE RECORD 2 (DEBIT!=0, REISSUE=2020-01-15)'

      *---------------------------------------------------------------*
      * RECORD 3: ACCT-CURR-CYC-DEBIT != 0, different amounts
      *           REISSUE-DATE = 1999-12-31 (year boundary)
      *---------------------------------------------------------------*
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 00000000003        TO ACCT-ID
           MOVE 'N'                TO ACCT-ACTIVE-STATUS
           MOVE -500.00            TO ACCT-CURR-BAL
           MOVE 1000000.00         TO ACCT-CREDIT-LIMIT
           MOVE 500000.00          TO ACCT-CASH-CREDIT-LIMIT
           MOVE '2000-01-01'       TO ACCT-OPEN-DATE
           MOVE '2024-12-31'       TO ACCT-EXPIRAION-DATE
           MOVE '1999-12-31'       TO ACCT-REISSUE-DATE
           MOVE 0                  TO ACCT-CURR-CYC-CREDIT
           MOVE 500.00             TO ACCT-CURR-CYC-DEBIT
           MOVE '33333-9999'       TO ACCT-ADDR-ZIP
           MOVE 'STDGROUP01'       TO ACCT-GROUP-ID
           MOVE SPACES             TO WS-FILLER
           MOVE WS-ACCOUNT-RECORD  TO GEN-ACCT-REC
           WRITE GEN-ACCT-REC
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'ERROR WRITING RECORD 3: ' WS-FILE-STATUS
               STOP RUN
           END-IF
           DISPLAY 'WROTE RECORD 3 (DEBIT!=0, REISSUE=1999-12-31)'

           CLOSE ACCT-FILE
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'ERROR CLOSING ACCTFILE: ' WS-FILE-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENMKDAT COMPLETE: 3 records written to ACCTFILE'
           STOP RUN.
