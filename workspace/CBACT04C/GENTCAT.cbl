      ******************************************************************
      * GENTCAT.cbl - Generate TCATBALF for CBACT04C tests
      *
      * 4 records for 2 accounts:
      * ACCT=00000000001, TYPE=CR, CAT=0001, BAL=+1000.00
      * ACCT=00000000001, TYPE=DB, CAT=0002, BAL=+500.00
      * ACCT=00000000002, TYPE=CR, CAT=0001, BAL=+2000.00
      * ACCT=00000000002, TYPE=DR, CAT=0003, BAL=+300.00  (fallback test)
      *
      * TRAN-CAT-BAL-RECORD layout (50 bytes):
      *   TRANCAT-ACCT-ID  PIC 9(11)      11 bytes  (key part 1)
      *   TRANCAT-TYPE-CD  PIC X(02)       2 bytes  (key part 2)
      *   TRANCAT-CD       PIC 9(04)       4 bytes  (key part 3)
      *   TRAN-CAT-BAL     PIC S9(09)V99  11 bytes  (DISPLAY)
      *   FILLER           PIC X(22)      22 bytes
      *                                   50 bytes total
      *
      * Records must be written in key order (indexed sequential).
      * Key: TRANCAT-ACCT-ID(11) + TRANCAT-TYPE-CD(2) + TRANCAT-CD(4)
      * Ascending: acct 1 CR/0001, acct 1 DB/0002, acct 2 CR/0001, acct 2 DR/0003
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENTCAT.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TCATBAL-FILE ASSIGN TO TCATBALF
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS GT-TRAN-CAT-KEY
                  FILE STATUS  IS WS-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TCATBAL-FILE.
       01  GT-TRAN-CAT-BAL-REC.
           05  GT-TRAN-CAT-KEY.
               10  GT-TRANCAT-ACCT-ID   PIC 9(11).
               10  GT-TRANCAT-TYPE-CD   PIC X(02).
               10  GT-TRANCAT-CD        PIC 9(04).
           05  GT-TCAT-DATA             PIC X(33).

       WORKING-STORAGE SECTION.
       01  WS-STATUS.
           05  WS-STAT1               PIC X.
           05  WS-STAT2               PIC X.

       01  WS-TCAT-REC.
           05  WS-TRAN-CAT-KEY.
               10  TRANCAT-ACCT-ID    PIC 9(11).
               10  TRANCAT-TYPE-CD    PIC X(02).
               10  TRANCAT-CD         PIC 9(04).
           05  TRAN-CAT-BAL           PIC S9(09)V99.
           05  WS-FILLER              PIC X(22).

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT TCATBAL-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING TCATBALF: ' WS-STATUS
               STOP RUN
           END-IF

      *--- Record 1: ACCT=00000000001, TYPE=CR, CAT=0001, BAL=1000.00
      * Expected: RATE=12.00% -> WS-MONTHLY-INT = (1000.00 * 12.00)/1200 = 10.00
           INITIALIZE WS-TCAT-REC
           MOVE 00000000001        TO TRANCAT-ACCT-ID
           MOVE 'CR'               TO TRANCAT-TYPE-CD
           MOVE 0001               TO TRANCAT-CD
           MOVE 1000.00            TO TRAN-CAT-BAL
           MOVE SPACES             TO WS-FILLER
           MOVE WS-TCAT-REC        TO GT-TRAN-CAT-BAL-REC
           WRITE GT-TRAN-CAT-BAL-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TCAT 1: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TCAT1: ACCT=00000000001 CR/0001 BAL=1000.00'

      *--- Record 2: ACCT=00000000001, TYPE=DB, CAT=0002, BAL=500.00
      * Expected: RATE=6.00% -> WS-MONTHLY-INT = (500.00 * 6.00)/1200 = 2.50
           INITIALIZE WS-TCAT-REC
           MOVE 00000000001        TO TRANCAT-ACCT-ID
           MOVE 'DB'               TO TRANCAT-TYPE-CD
           MOVE 0002               TO TRANCAT-CD
           MOVE 500.00             TO TRAN-CAT-BAL
           MOVE SPACES             TO WS-FILLER
           MOVE WS-TCAT-REC        TO GT-TRAN-CAT-BAL-REC
           WRITE GT-TRAN-CAT-BAL-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TCAT 2: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TCAT2: ACCT=00000000001 DB/0002 BAL=500.00'

      *--- Record 3: ACCT=00000000002, TYPE=CR, CAT=0001, BAL=2000.00
      * Expected: RATE=12.00% -> WS-MONTHLY-INT = (2000.00 * 12.00)/1200 = 20.00
           INITIALIZE WS-TCAT-REC
           MOVE 00000000002        TO TRANCAT-ACCT-ID
           MOVE 'CR'               TO TRANCAT-TYPE-CD
           MOVE 0001               TO TRANCAT-CD
           MOVE 2000.00            TO TRAN-CAT-BAL
           MOVE SPACES             TO WS-FILLER
           MOVE WS-TCAT-REC        TO GT-TRAN-CAT-BAL-REC
           WRITE GT-TRAN-CAT-BAL-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TCAT 3: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TCAT3: ACCT=00000000002 CR/0001 BAL=2000.00'

      *--- Record 4: ACCT=00000000002, TYPE=DR, CAT=0003, BAL=300.00
      * No specific DISCGRP entry for GRP0000001+DR+0003
      * -> triggers fallback to DEFAULT+DR+0003 with RATE=18.00%
      * Expected: WS-MONTHLY-INT = (300.00 * 18.00)/1200 = 4.50
           INITIALIZE WS-TCAT-REC
           MOVE 00000000002        TO TRANCAT-ACCT-ID
           MOVE 'DR'               TO TRANCAT-TYPE-CD
           MOVE 0003               TO TRANCAT-CD
           MOVE 300.00             TO TRAN-CAT-BAL
           MOVE SPACES             TO WS-FILLER
           MOVE WS-TCAT-REC        TO GT-TRAN-CAT-BAL-REC
           WRITE GT-TRAN-CAT-BAL-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TCAT 4: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TCAT4: ACCT=2 DR/0003 BAL=300.00 fallback'

           CLOSE TCATBAL-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR CLOSING TCATBALF: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENTCAT COMPLETE: 4 records written'
           STOP RUN.
