      ******************************************************************
      * GENACCT.cbl - Generate ACCTFILE for CBTRN02C tests
      * 4 accounts:
      *  1: valid, limit=1000, credit=200, debit=0, expiry=2030-12-31
      *  2: valid, limit=2000, credit=0,   debit=0, expiry=2030-12-31
      *  3: over-limit test, limit=1000, credit=990, debit=0
      *  4: expired, limit=5000, expiry=2020-01-01
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
                  FILE STATUS  IS WS-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-FILE.
       01  GA-ACCT-REC.
           05  GA-ACCT-ID             PIC 9(11).
           05  GA-ACCT-DATA           PIC X(289).

       WORKING-STORAGE SECTION.
       01  WS-STATUS.
           05  WS-STAT1               PIC X.
           05  WS-STAT2               PIC X.

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
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING ACCTFILE: ' WS-STATUS
               STOP RUN
           END-IF

      *--- Acct 1: valid, credit=200, debit=0, limit=1000
      * TRN01: WS-TEMP-BAL=200-0+50=250 <=1000 PASS; expiry 2030 PASS
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 00000000001        TO ACCT-ID
           MOVE 'Y'                TO ACCT-ACTIVE-STATUS
           MOVE 500.00             TO ACCT-CURR-BAL
           MOVE 1000.00            TO ACCT-CREDIT-LIMIT
           MOVE 500.00             TO ACCT-CASH-CREDIT-LIMIT
           MOVE '2020-01-01'       TO ACCT-OPEN-DATE
           MOVE '2030-12-31'       TO ACCT-EXPIRAION-DATE
           MOVE '2023-01-01'       TO ACCT-REISSUE-DATE
           MOVE 200.00             TO ACCT-CURR-CYC-CREDIT
           MOVE 0                  TO ACCT-CURR-CYC-DEBIT
           MOVE '10001-0001'       TO ACCT-ADDR-ZIP
           MOVE 'GRP0000001'       TO ACCT-GROUP-ID
           MOVE SPACES             TO WS-FILLER
           MOVE WS-ACCOUNT-RECORD  TO GA-ACCT-REC
           WRITE GA-ACCT-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE ACCT 1: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'ACCT1: id=00000000001 limit=1000 cr=200'

      *--- Acct 2: valid, credit=0, debit=0, limit=2000
      * TRN02: WS-TEMP-BAL=0-0+75=75 <=2000 PASS
      * TRN07: after TRN02: cr=75, WS-TEMP-BAL=75-0+100=175 <=2000 PASS
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 00000000002        TO ACCT-ID
           MOVE 'Y'                TO ACCT-ACTIVE-STATUS
           MOVE 1000.00            TO ACCT-CURR-BAL
           MOVE 2000.00            TO ACCT-CREDIT-LIMIT
           MOVE 1000.00            TO ACCT-CASH-CREDIT-LIMIT
           MOVE '2019-06-01'       TO ACCT-OPEN-DATE
           MOVE '2030-12-31'       TO ACCT-EXPIRAION-DATE
           MOVE '2022-06-01'       TO ACCT-REISSUE-DATE
           MOVE 0.00               TO ACCT-CURR-CYC-CREDIT
           MOVE 0.00               TO ACCT-CURR-CYC-DEBIT
           MOVE '20002-0002'       TO ACCT-ADDR-ZIP
           MOVE 'GRP0000002'       TO ACCT-GROUP-ID
           MOVE SPACES             TO WS-FILLER
           MOVE WS-ACCOUNT-RECORD  TO GA-ACCT-REC
           WRITE GA-ACCT-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE ACCT 2: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'ACCT2: id=00000000002 limit=2000 cr=0'

      *--- Acct 3: over-limit, credit=990, debit=0, limit=1000
      * TRN05: WS-TEMP-BAL=990-0+50=1040 >1000 REJECT 102
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 00000000003        TO ACCT-ID
           MOVE 'Y'                TO ACCT-ACTIVE-STATUS
           MOVE 990.00             TO ACCT-CURR-BAL
           MOVE 1000.00            TO ACCT-CREDIT-LIMIT
           MOVE 500.00             TO ACCT-CASH-CREDIT-LIMIT
           MOVE '2021-03-15'       TO ACCT-OPEN-DATE
           MOVE '2030-12-31'       TO ACCT-EXPIRAION-DATE
           MOVE '2024-03-15'       TO ACCT-REISSUE-DATE
           MOVE 990.00             TO ACCT-CURR-CYC-CREDIT
           MOVE 0.00               TO ACCT-CURR-CYC-DEBIT
           MOVE '30003-0003'       TO ACCT-ADDR-ZIP
           MOVE 'GRP0000003'       TO ACCT-GROUP-ID
           MOVE SPACES             TO WS-FILLER
           MOVE WS-ACCOUNT-RECORD  TO GA-ACCT-REC
           WRITE GA-ACCT-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE ACCT 3: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'ACCT3: id=00000000003 limit=1000 cr=990 (overlimit)'

      *--- Acct 4: expired, limit=5000, expiry=2020-01-01
      * TRN06: WS-TEMP-BAL=0-0+25=25 <=5000 PASS
      *         expiry 2020-01-01 < 2026-01-15 REJECT 103
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 00000000004        TO ACCT-ID
           MOVE 'Y'                TO ACCT-ACTIVE-STATUS
           MOVE 100.00             TO ACCT-CURR-BAL
           MOVE 5000.00            TO ACCT-CREDIT-LIMIT
           MOVE 2500.00            TO ACCT-CASH-CREDIT-LIMIT
           MOVE '2015-01-01'       TO ACCT-OPEN-DATE
           MOVE '2020-01-01'       TO ACCT-EXPIRAION-DATE
           MOVE '2018-01-01'       TO ACCT-REISSUE-DATE
           MOVE 0.00               TO ACCT-CURR-CYC-CREDIT
           MOVE 0.00               TO ACCT-CURR-CYC-DEBIT
           MOVE '40004-0004'       TO ACCT-ADDR-ZIP
           MOVE 'GRP0000004'       TO ACCT-GROUP-ID
           MOVE SPACES             TO WS-FILLER
           MOVE WS-ACCOUNT-RECORD  TO GA-ACCT-REC
           WRITE GA-ACCT-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE ACCT 4: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'ACCT4: id=00000000004 expiry=2020-01-01 (expired)'

           CLOSE ACCT-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR CLOSING ACCTFILE: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENACCT COMPLETE: 4 records written'
           STOP RUN.
