      ******************************************************************
      * DUMPXREF.cbl
      * Dump XREFFILE (indexed, 50-byte records) to sequential flat file.
      * XREFFILE has primary key (CARD-NUM) and alternate key (ACCT-ID).
      *
      * Input:  XREFFILE  (env var, indexed)
      * Output: XREFFILE_SEQ  (env var, sequential flat dump)
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DUMPXREF.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT XREF-FILE ASSIGN TO XREFFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS DX-CARD-NUM
                  ALTERNATE RECORD KEY IS DX-ACCT-ID
                  FILE STATUS  IS WS-XREF-STATUS.

           SELECT SEQ-FILE ASSIGN TO XREFFILE_SEQ
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS WS-SEQ-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  XREF-FILE.
       01  DX-XREF-REC.
           05  DX-CARD-NUM            PIC X(16).
           05  DX-CUST-ID             PIC 9(09).
           05  DX-ACCT-ID             PIC 9(11).
           05  DX-FILLER              PIC X(14).

       FD  SEQ-FILE.
       01  DS-SEQ-REC                 PIC X(50).

       WORKING-STORAGE SECTION.
       01  WS-XREF-STATUS.
           05  WS-XREF-STAT1          PIC X.
           05  WS-XREF-STAT2          PIC X.
       01  WS-SEQ-STATUS.
           05  WS-SEQ-STAT1           PIC X.
           05  WS-SEQ-STAT2           PIC X.
       01  WS-COUNT                   PIC 9(09) VALUE 0.
       01  WS-EOF                     PIC X VALUE 'N'.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT XREF-FILE
           IF WS-XREF-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING XREFFILE: ' WS-XREF-STATUS
               STOP RUN
           END-IF

           OPEN OUTPUT SEQ-FILE
           IF WS-SEQ-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING XREFFILE_SEQ: ' WS-SEQ-STATUS
               STOP RUN
           END-IF

           PERFORM UNTIL WS-EOF = 'Y'
               READ XREF-FILE
               IF WS-XREF-STATUS = '00'
                   ADD 1 TO WS-COUNT
                   MOVE DX-XREF-REC TO DS-SEQ-REC
                   WRITE DS-SEQ-REC
                   IF WS-SEQ-STATUS NOT = '00'
                       DISPLAY 'ERROR WRITING SEQ: ' WS-SEQ-STATUS
                       STOP RUN
                   END-IF
               ELSE
                   IF WS-XREF-STATUS = '10'
                       MOVE 'Y' TO WS-EOF
                   ELSE
                       DISPLAY 'ERROR READING XREFFILE: ' WS-XREF-STATUS
                       STOP RUN
                   END-IF
               END-IF
           END-PERFORM

           CLOSE XREF-FILE
           CLOSE SEQ-FILE
           DISPLAY 'DUMPXREF COMPLETE: ' WS-COUNT ' records dumped'
           STOP RUN.
