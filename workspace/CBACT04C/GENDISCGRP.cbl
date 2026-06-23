      ******************************************************************
      * GENDISCGRP.cbl - Generate DISCGRP file for CBACT04C tests
      *
      * DIS-GROUP-RECORD layout (50 bytes):
      *   DIS-ACCT-GROUP-ID  PIC X(10)      10 bytes  (key part 1)
      *   DIS-TRAN-TYPE-CD   PIC X(02)       2 bytes  (key part 2)
      *   DIS-TRAN-CAT-CD    PIC 9(04)       4 bytes  (key part 3)
      *   DIS-INT-RATE       PIC S9(04)V99   6 bytes  (annual % DISPLAY)
      *   FILLER             PIC X(28)      28 bytes
      *                                     50 bytes total
      *
      * DIS-INT-RATE encoding (S9(04)V99 DISPLAY, 6 bytes):
      *   12.00% annual -> stored as '001200' (6 digits: 0012 + 00)
      *    6.00% annual -> stored as '000600'
      *   18.00% annual -> stored as '001800'
      *
      * Records (in key order for indexed sequential write):
      *   1. 'DEFAULT   ' + 'DR' + 0003: RATE=18.00% (fallback for acct2 DR/0003)
      *   2. 'GRP0000001' + 'CR' + 0001: RATE=12.00% (acct1 CR/0001, acct2 CR/0001)
      *   3. 'GRP0000001' + 'DB' + 0002: RATE= 6.00% (acct1 DB/0002)
      *
      * Key sort order: X(10)+X(02)+9(04) ascending ASCII:
      *   'DEFAULT   ' < 'GRP0000001' (D < G)
      *   Within 'GRP0000001': 'CR' < 'DB' (C < D)
      *   Within 'GRP0000001'+'CR': 0001 < 0001 N/A
      *
      * Note: No entry for 'GRP0000001'+'DR'+0003, which triggers the
      *       fallback logic in CBACT04C (status '23' -> try 'DEFAULT').
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENDISCGRP.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT DISCGRP-FILE ASSIGN TO DISCGRP
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS GD-DISCGRP-KEY
                  FILE STATUS  IS WS-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  DISCGRP-FILE.
       01  GD-DISCGRP-REC.
           05  GD-DISCGRP-KEY.
               10  GD-DIS-ACCT-GROUP-ID   PIC X(10).
               10  GD-DIS-TRAN-TYPE-CD    PIC X(02).
               10  GD-DIS-TRAN-CAT-CD     PIC 9(04).
           05  GD-DISCGRP-DATA            PIC X(34).

       WORKING-STORAGE SECTION.
       01  WS-STATUS.
           05  WS-STAT1               PIC X.
           05  WS-STAT2               PIC X.

       01  WS-DISCGRP-REC.
           05  WS-DIS-ACCT-GROUP-ID   PIC X(10).
           05  WS-DIS-TRAN-TYPE-CD    PIC X(02).
           05  WS-DIS-TRAN-CAT-CD     PIC 9(04).
           05  WS-DIS-INT-RATE        PIC S9(04)V99.
           05  WS-FILLER              PIC X(28).

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT DISCGRP-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING DISCGRP: ' WS-STATUS
               STOP RUN
           END-IF

      *--- Record 1: 'DEFAULT   ' + 'DR' + 0003 -> RATE=18.00%
      * This is the fallback entry when GRP0000001+DR+0003 not found
      * 'DEFAULT   ' = 'DEFAULT' + 3 trailing spaces (10 chars total)
           INITIALIZE WS-DISCGRP-REC
           MOVE 'DEFAULT   '        TO WS-DIS-ACCT-GROUP-ID
           MOVE 'DR'                TO WS-DIS-TRAN-TYPE-CD
           MOVE 0003                TO WS-DIS-TRAN-CAT-CD
           MOVE 18.00               TO WS-DIS-INT-RATE
           MOVE SPACES              TO WS-FILLER
           MOVE WS-DISCGRP-REC      TO GD-DISCGRP-REC
           WRITE GD-DISCGRP-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE DISCGRP 1: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'DISCGRP1: DEFAULT    DR/0003 RATE=18.00%'

      *--- Record 2: 'GRP0000001' + 'CR' + 0001 -> RATE=12.00%
      * Used for acct1 CR/0001 and acct2 CR/0001
           INITIALIZE WS-DISCGRP-REC
           MOVE 'GRP0000001'        TO WS-DIS-ACCT-GROUP-ID
           MOVE 'CR'                TO WS-DIS-TRAN-TYPE-CD
           MOVE 0001                TO WS-DIS-TRAN-CAT-CD
           MOVE 12.00               TO WS-DIS-INT-RATE
           MOVE SPACES              TO WS-FILLER
           MOVE WS-DISCGRP-REC      TO GD-DISCGRP-REC
           WRITE GD-DISCGRP-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE DISCGRP 2: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'DISCGRP2: GRP0000001 CR/0001 RATE=12.00%'

      *--- Record 3: 'GRP0000001' + 'DB' + 0002 -> RATE=6.00%
      * Used for acct1 DB/0002
           INITIALIZE WS-DISCGRP-REC
           MOVE 'GRP0000001'        TO WS-DIS-ACCT-GROUP-ID
           MOVE 'DB'                TO WS-DIS-TRAN-TYPE-CD
           MOVE 0002                TO WS-DIS-TRAN-CAT-CD
           MOVE 6.00                TO WS-DIS-INT-RATE
           MOVE SPACES              TO WS-FILLER
           MOVE WS-DISCGRP-REC      TO GD-DISCGRP-REC
           WRITE GD-DISCGRP-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE DISCGRP 3: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'DISCGRP3: GRP0000001 DB/0002 RATE=6.00%'

           CLOSE DISCGRP-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR CLOSING DISCGRP: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENDISCGRP COMPLETE: 3 records written'
           STOP RUN.
