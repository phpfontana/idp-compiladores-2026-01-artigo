      ******************************************************************
      * DUMPDISCGRP.cbl
      * Dump DISCGRP (indexed, 50-byte records) to sequential flat file.
      *
      * Input:  DISCGRP  (env var, indexed)
      * Output: DISCGRP_SEQ  (env var, sequential flat dump)
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DUMPDISCGRP.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT DISCGRP-FILE ASSIGN TO DISCGRP
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS DD-DISCGRP-KEY
                  FILE STATUS  IS WS-DISCGRP-STATUS.

           SELECT SEQ-FILE ASSIGN TO DISCGRP_SEQ
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS WS-SEQ-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  DISCGRP-FILE.
       01  DD-DISCGRP-REC.
           05  DD-DISCGRP-KEY.
               10  DD-DIS-ACCT-GROUP-ID   PIC X(10).
               10  DD-DIS-TRAN-TYPE-CD    PIC X(02).
               10  DD-DIS-TRAN-CAT-CD     PIC 9(04).
           05  DD-DISCGRP-DATA            PIC X(34).

       FD  SEQ-FILE.
       01  DS-SEQ-REC                 PIC X(50).

       WORKING-STORAGE SECTION.
       01  WS-DISCGRP-STATUS.
           05  WS-DISCGRP-STAT1       PIC X.
           05  WS-DISCGRP-STAT2       PIC X.
       01  WS-SEQ-STATUS.
           05  WS-SEQ-STAT1           PIC X.
           05  WS-SEQ-STAT2           PIC X.
       01  WS-COUNT                   PIC 9(09) VALUE 0.
       01  WS-EOF                     PIC X VALUE 'N'.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT DISCGRP-FILE
           IF WS-DISCGRP-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING DISCGRP: ' WS-DISCGRP-STATUS
               STOP RUN
           END-IF

           OPEN OUTPUT SEQ-FILE
           IF WS-SEQ-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING DISCGRP_SEQ: ' WS-SEQ-STATUS
               STOP RUN
           END-IF

           PERFORM UNTIL WS-EOF = 'Y'
               READ DISCGRP-FILE
               IF WS-DISCGRP-STATUS = '00'
                   ADD 1 TO WS-COUNT
                   MOVE DD-DISCGRP-REC TO DS-SEQ-REC
                   WRITE DS-SEQ-REC
                   IF WS-SEQ-STATUS NOT = '00'
                       DISPLAY 'ERROR WRITING SEQ: ' WS-SEQ-STATUS
                       STOP RUN
                   END-IF
               ELSE
                   IF WS-DISCGRP-STATUS = '10'
                       MOVE 'Y' TO WS-EOF
                   ELSE
                       DISPLAY 'ERROR READING DISCGRP'
                       STOP RUN
                   END-IF
               END-IF
           END-PERFORM

           CLOSE DISCGRP-FILE
           CLOSE SEQ-FILE
           DISPLAY 'DUMPDISCGRP COMPLETE: ' WS-COUNT ' records dumped'
           STOP RUN.
