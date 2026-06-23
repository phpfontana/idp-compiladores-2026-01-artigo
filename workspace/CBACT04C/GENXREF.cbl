      ******************************************************************
      * GENXREF.cbl - Generate XREFFILE for CBACT04C tests
      *
      * CBACT04C reads XREFFILE by ALTERNATE KEY (FD-XREF-ACCT-ID).
      * This generator MUST declare the alternate key so GnuCOBOL
      * creates the correct indexed file with both key indexes.
      *
      * 2 records:
      *   CARD='4000002000000001', CUST=000000001, ACCT=00000000001
      *   CARD='4000002000000002', CUST=000000002, ACCT=00000000002
      *
      * CARD-XREF-RECORD layout (50 bytes):
      *   XREF-CARD-NUM  PIC X(16)   16 bytes  (primary key)
      *   XREF-CUST-ID   PIC 9(09)    9 bytes
      *   XREF-ACCT-ID   PIC 9(11)   11 bytes  (alternate key)
      *   FILLER         PIC X(14)   14 bytes
      *                              50 bytes total
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
                  ALTERNATE RECORD KEY IS GX-ACCT-ID
                  FILE STATUS  IS WS-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  XREF-FILE.
       01  GX-XREF-REC.
           05  GX-CARD-NUM            PIC X(16).
           05  GX-CUST-ID             PIC 9(09).
           05  GX-ACCT-ID             PIC 9(11).
           05  GX-FILLER              PIC X(14).

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

      *--- Card -> acct 1
           INITIALIZE WS-XREF-REC
           MOVE '4000002000000001'  TO XREF-CARD-NUM
           MOVE 000000001           TO XREF-CUST-ID
           MOVE 00000000001         TO XREF-ACCT-ID
           MOVE SPACES              TO XREF-FILLER
           MOVE WS-XREF-REC         TO GX-XREF-REC
           WRITE GX-XREF-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE XREF 1: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'XREF1: 4000002000000001 -> 00000000001'

      *--- Card -> acct 2
           INITIALIZE WS-XREF-REC
           MOVE '4000002000000002'  TO XREF-CARD-NUM
           MOVE 000000002           TO XREF-CUST-ID
           MOVE 00000000002         TO XREF-ACCT-ID
           MOVE SPACES              TO XREF-FILLER
           MOVE WS-XREF-REC         TO GX-XREF-REC
           WRITE GX-XREF-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE XREF 2: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'XREF2: 4000002000000002 -> 00000000002'

           CLOSE XREF-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR CLOSING XREFFILE: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENXREF COMPLETE: 2 records written'
           STOP RUN.
