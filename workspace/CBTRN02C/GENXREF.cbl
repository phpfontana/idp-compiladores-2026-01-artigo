      ******************************************************************
      * GENXREF.cbl - Generate XREFFILE for CBTRN02C tests
      * 5 records:
      *   4000002000000000 -> acct 00000000001 (valid)
      *   4000002000000001 -> acct 00000000002 (valid)
      *   4000002000000002 -> acct 00000000003 (over-limit)
      *   4000002000000003 -> acct 00000000004 (expired)
      *   4000002000000099 -> acct 00000000099 (missing -> reject 101)
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENXREF.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT XREF-FILE ASSIGN TO XREFFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS GX-CARD-NUM
                  FILE STATUS  IS WS-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  XREF-FILE.
       01  GX-XREF-REC.
           05  GX-CARD-NUM            PIC X(16).
           05  GX-XREF-DATA           PIC X(34).

       WORKING-STORAGE SECTION.
       01  WS-STATUS.
           05  WS-STAT1               PIC X.
           05  WS-STAT2               PIC X.

       01  WS-XREF-REC.
           05  XREF-CARD-NUM          PIC X(16).
           05  XREF-CUST-ID           PIC 9(09).
           05  XREF-ACCT-ID           PIC 9(11).
           05  XREF-FILLER            PIC X(14).

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT XREF-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING XREFFILE: ' WS-STATUS
               STOP RUN
           END-IF

      *--- Card -> acct 1 (valid)
           INITIALIZE WS-XREF-REC
           MOVE '4000002000000000'  TO XREF-CARD-NUM
           MOVE 000000001           TO XREF-CUST-ID
           MOVE 00000000001         TO XREF-ACCT-ID
           MOVE SPACES              TO XREF-FILLER
           MOVE WS-XREF-REC         TO GX-XREF-REC
           WRITE GX-XREF-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE XREF 1: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'XREF1: 4000002000000000 -> 00000000001'

      *--- Card -> acct 2 (valid, pre-existing TCATBAL)
           INITIALIZE WS-XREF-REC
           MOVE '4000002000000001'  TO XREF-CARD-NUM
           MOVE 000000002           TO XREF-CUST-ID
           MOVE 00000000002         TO XREF-ACCT-ID
           MOVE SPACES              TO XREF-FILLER
           MOVE WS-XREF-REC         TO GX-XREF-REC
           WRITE GX-XREF-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE XREF 2: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'XREF2: 4000002000000001 -> 00000000002'

      *--- Card -> acct 3 (over-limit)
           INITIALIZE WS-XREF-REC
           MOVE '4000002000000002'  TO XREF-CARD-NUM
           MOVE 000000003           TO XREF-CUST-ID
           MOVE 00000000003         TO XREF-ACCT-ID
           MOVE SPACES              TO XREF-FILLER
           MOVE WS-XREF-REC         TO GX-XREF-REC
           WRITE GX-XREF-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE XREF 3: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'XREF3: 4000002000000002 -> 00000000003'

      *--- Card -> acct 4 (expired)
           INITIALIZE WS-XREF-REC
           MOVE '4000002000000003'  TO XREF-CARD-NUM
           MOVE 000000004           TO XREF-CUST-ID
           MOVE 00000000004         TO XREF-ACCT-ID
           MOVE SPACES              TO XREF-FILLER
           MOVE WS-XREF-REC         TO GX-XREF-REC
           WRITE GX-XREF-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE XREF 4: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'XREF4: 4000002000000003 -> 00000000004'

      *--- Card -> acct 99 (account missing -> reject 101)
           INITIALIZE WS-XREF-REC
           MOVE '4000002000000099'  TO XREF-CARD-NUM
           MOVE 000000099           TO XREF-CUST-ID
           MOVE 00000000099         TO XREF-ACCT-ID
           MOVE SPACES              TO XREF-FILLER
           MOVE WS-XREF-REC         TO GX-XREF-REC
           WRITE GX-XREF-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE XREF 5: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'XREF5: 4000002000000099 -> 00000000099 (missing)'

           CLOSE XREF-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR CLOSING XREFFILE: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENXREF COMPLETE: 5 records written'
           STOP RUN.
