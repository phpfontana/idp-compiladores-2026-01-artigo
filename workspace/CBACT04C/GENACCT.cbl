      ******************************************************************
      * GENACCT.cbl - Generate ACCTFILE for CBACT04C tests
      *
      * ACCOUNT-RECORD layout (300 bytes):
      *   ACCT-ID               PIC 9(11)       11 bytes
      *   ACCT-ACTIVE-STATUS    PIC X(01)        1 byte
      *   ACCT-CURR-BAL         PIC S9(10)V99   12 bytes (DISPLAY)
      *   ACCT-CREDIT-LIMIT     PIC S9(10)V99   12 bytes
      *   ACCT-CASH-CREDIT-LIMIT PIC S9(10)V99  12 bytes
      *   ACCT-OPEN-DATE        PIC X(10)       10 bytes
      *   ACCT-EXPIRAION-DATE   PIC X(10)       10 bytes
      *   ACCT-REISSUE-DATE     PIC X(10)       10 bytes
      *   ACCT-CURR-CYC-CREDIT  PIC S9(10)V99   12 bytes
      *   ACCT-CURR-CYC-DEBIT   PIC S9(10)V99   12 bytes
      *   ACCT-ADDR-ZIP         PIC X(10)       10 bytes
      *   ACCT-GROUP-ID         PIC X(10)       10 bytes
      *   FILLER                PIC X(178)     178 bytes
      *                                 Total: 300 bytes
      *
      * 2 accounts:
      *   ACCT=00000000001: BAL=5000.00, CREDIT-LIM=10000.00,
      *                     CYC-CREDIT=100.00, CYC-DEBIT=50.00,
      *                     GROUP-ID='GRP0000001'
      *   ACCT=00000000002: BAL=8000.00, CREDIT-LIM=20000.00,
      *                     CYC-CREDIT=200.00, CYC-DEBIT=80.00,
      *                     GROUP-ID='GRP0000001'
      *
      * After CBACT04C runs:
      *   ACCT1: BAL = 5000.00 + 12.50 = 5012.50, CYC-CREDIT=0, CYC-DEBIT=0
      *   ACCT2: BAL = 8000.00 + 24.50 = 8024.50, CYC-CREDIT=0, CYC-DEBIT=0
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENACCT.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-FILE ASSIGN TO ACCTFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS GA-ACCT-ID
                  FILE STATUS  IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-FILE.
       01  GA-ACCT-REC.
           05  GA-ACCT-ID             PIC 9(11).
           05  GA-ACCT-DATA           PIC X(289).

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
      * RECORD 1: ACCT=00000000001
      *   GROUP-ID='GRP0000001' (used to look up DISCGRP entries)
      *   ACCT-CURR-BAL=5000.00
      *   After run: BAL=5012.50, CYC-CREDIT=0, CYC-DEBIT=0
      *---------------------------------------------------------------*
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 00000000001        TO ACCT-ID
           MOVE 'Y'                TO ACCT-ACTIVE-STATUS
           MOVE 5000.00            TO ACCT-CURR-BAL
           MOVE 10000.00           TO ACCT-CREDIT-LIMIT
           MOVE 5000.00            TO ACCT-CASH-CREDIT-LIMIT
           MOVE '2020-01-01'       TO ACCT-OPEN-DATE
           MOVE '2030-01-01'       TO ACCT-EXPIRAION-DATE
           MOVE '2020-01-01'       TO ACCT-REISSUE-DATE
           MOVE 100.00             TO ACCT-CURR-CYC-CREDIT
           MOVE 50.00              TO ACCT-CURR-CYC-DEBIT
           MOVE '10001     '       TO ACCT-ADDR-ZIP
           MOVE 'GRP0000001'       TO ACCT-GROUP-ID
           MOVE SPACES             TO WS-FILLER
           MOVE WS-ACCOUNT-RECORD  TO GA-ACCT-REC
           WRITE GA-ACCT-REC
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'ERROR WRITING RECORD 1: ' WS-FILE-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENACCT: wrote ACCT=1 BAL=5000.00 GRP=GRP0000001'

      *---------------------------------------------------------------*
      * RECORD 2: ACCT=00000000002
      *   GROUP-ID='GRP0000001'
      *   ACCT-CURR-BAL=8000.00
      *   After run: BAL=8024.50, CYC-CREDIT=0, CYC-DEBIT=0
      *---------------------------------------------------------------*
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 00000000002        TO ACCT-ID
           MOVE 'Y'                TO ACCT-ACTIVE-STATUS
           MOVE 8000.00            TO ACCT-CURR-BAL
           MOVE 20000.00           TO ACCT-CREDIT-LIMIT
           MOVE 10000.00           TO ACCT-CASH-CREDIT-LIMIT
           MOVE '2020-02-01'       TO ACCT-OPEN-DATE
           MOVE '2030-01-01'       TO ACCT-EXPIRAION-DATE
           MOVE '2020-02-01'       TO ACCT-REISSUE-DATE
           MOVE 200.00             TO ACCT-CURR-CYC-CREDIT
           MOVE 80.00              TO ACCT-CURR-CYC-DEBIT
           MOVE '20002     '       TO ACCT-ADDR-ZIP
           MOVE 'GRP0000001'       TO ACCT-GROUP-ID
           MOVE SPACES             TO WS-FILLER
           MOVE WS-ACCOUNT-RECORD  TO GA-ACCT-REC
           WRITE GA-ACCT-REC
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'ERROR WRITING RECORD 2: ' WS-FILE-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENACCT: wrote ACCT=2 BAL=8000.00 GRP=GRP0000001'

           CLOSE ACCT-FILE
           IF WS-FILE-STATUS NOT = '00'
               DISPLAY 'ERROR CLOSING ACCTFILE: ' WS-FILE-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENACCT COMPLETE: 2 records written'
           STOP RUN.
