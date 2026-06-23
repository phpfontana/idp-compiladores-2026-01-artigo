      ******************************************************************
      * DUMPSEQ.cbl - Read ACCTFILE (indexed) and write ACCTSEQ (flat)
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DUMPSEQ.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-IN ASSIGN TO ACCTFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS DS-ACCT-ID
                  FILE STATUS  IS WS-INST.

           SELECT ACCT-OUT ASSIGN TO ACCTSEQ
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS WS-OUTST.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-IN.
       01  DS-ACCT-IN-REC.
           05  DS-ACCT-ID             PIC 9(11).
           05  DS-ACCT-DATA           PIC X(289).

       FD  ACCT-OUT.
       01  DS-ACCT-OUT-REC            PIC X(300).

       WORKING-STORAGE SECTION.
       01  WS-INST                    PIC XX.
       01  WS-OUTST                   PIC XX.
       01  WS-EOF                     PIC X VALUE 'N'.
       01  WS-COUNT                   PIC 9(5) VALUE 0.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT  ACCT-IN
           IF WS-INST NOT = '00'
               DISPLAY 'DUMPSEQ: ERROR OPEN IN: ' WS-INST
               STOP RUN
           END-IF

           OPEN OUTPUT ACCT-OUT
           IF WS-OUTST NOT = '00'
               DISPLAY 'DUMPSEQ: ERROR OPEN OUT: ' WS-OUTST
               STOP RUN
           END-IF

           PERFORM UNTIL WS-EOF = 'Y'
               READ ACCT-IN INTO DS-ACCT-OUT-REC
               EVALUATE WS-INST
                   WHEN '00'
                       WRITE DS-ACCT-OUT-REC
                       IF WS-OUTST NOT = '00'
                           DISPLAY 'DUMPSEQ: WRITE ERR: '
                                   WS-OUTST
                           STOP RUN
                       END-IF
                       ADD 1 TO WS-COUNT
                   WHEN '10'
                       MOVE 'Y' TO WS-EOF
                   WHEN OTHER
                       DISPLAY 'DUMPSEQ: READ ERR: ' WS-INST
                       STOP RUN
               END-EVALUATE
           END-PERFORM

           CLOSE ACCT-IN
           CLOSE ACCT-OUT
           DISPLAY 'DUMPSEQ: ' WS-COUNT ' records -> ACCTSEQ'
           STOP RUN.
