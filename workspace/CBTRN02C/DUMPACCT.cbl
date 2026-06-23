      ******************************************************************
      * DUMPACCT.cbl
      * Dump ACCTFILE (indexed, 300-byte records) to sequential flat file.
      * Used for golden master comparison of account after-state.
      *
      * Input:  ACCTFILE  (env var, indexed)
      * Output: ACCTSEQ   (env var, sequential flat dump)
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DUMPACCT.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-FILE ASSIGN TO ACCTFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS DA-ACCT-ID
                  FILE STATUS  IS WS-ACCT-STATUS.

           SELECT SEQ-FILE ASSIGN TO ACCTSEQ
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS WS-SEQ-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-FILE.
       01  DA-ACCT-REC.
           05  DA-ACCT-ID             PIC 9(11).
           05  DA-ACCT-DATA           PIC X(289).

       FD  SEQ-FILE.
       01  DS-SEQ-REC                 PIC X(300).

       WORKING-STORAGE SECTION.
       01  WS-ACCT-STATUS.
           05  WS-ACCT-STAT1          PIC X.
           05  WS-ACCT-STAT2          PIC X.
       01  WS-SEQ-STATUS.
           05  WS-SEQ-STAT1           PIC X.
           05  WS-SEQ-STAT2           PIC X.
       01  WS-COUNT                   PIC 9(09) VALUE 0.
       01  WS-EOF                     PIC X VALUE 'N'.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT ACCT-FILE
           IF WS-ACCT-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING ACCTFILE: ' WS-ACCT-STATUS
               STOP RUN
           END-IF

           OPEN OUTPUT SEQ-FILE
           IF WS-SEQ-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING ACCTSEQ: ' WS-SEQ-STATUS
               STOP RUN
           END-IF

           PERFORM UNTIL WS-EOF = 'Y'
               READ ACCT-FILE
               IF WS-ACCT-STATUS = '00'
                   ADD 1 TO WS-COUNT
                   MOVE DA-ACCT-REC TO DS-SEQ-REC
                   WRITE DS-SEQ-REC
                   IF WS-SEQ-STATUS NOT = '00'
                       DISPLAY 'ERROR WRITING SEQ: ' WS-SEQ-STATUS
                       STOP RUN
                   END-IF
               ELSE
                   IF WS-ACCT-STATUS = '10'
                       MOVE 'Y' TO WS-EOF
                   ELSE
                       DISPLAY 'ERROR READING ACCTFILE: ' WS-ACCT-STATUS
                       STOP RUN
                   END-IF
               END-IF
           END-PERFORM

           CLOSE ACCT-FILE
           CLOSE SEQ-FILE
           DISPLAY 'DUMPACCT COMPLETE: ' WS-COUNT ' records dumped'
           STOP RUN.
