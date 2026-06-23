       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENXREF.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT XREF-FILE ASSIGN TO XREFFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS FD-XREF-CARD-NUM
                  FILE STATUS  IS XREFFILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  XREF-FILE.
       01  FD-XREFFILE-REC.
           05 FD-XREF-CARD-NUM     PIC X(16).
           05 FD-XREF-CUST-ID      PIC 9(09).
           05 FD-XREF-ACCT-ID      PIC 9(11).
           05 FD-XREF-FILLER       PIC X(14).

       WORKING-STORAGE SECTION.
       01  XREFFILE-STATUS.
           05  XREFFILE-STAT1      PIC X.
           05  XREFFILE-STAT2      PIC X.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT XREF-FILE.

      * Record 1: Card 1 -> Cust 1, Acct 1
           MOVE '4000002000000001' TO FD-XREF-CARD-NUM
           MOVE 000000001          TO FD-XREF-CUST-ID
           MOVE 00000000001        TO FD-XREF-ACCT-ID
           MOVE SPACES             TO FD-XREF-FILLER
           WRITE FD-XREFFILE-REC.

      * Record 2: Card 2 -> Cust 2, Acct 2
           MOVE '4000002000000002' TO FD-XREF-CARD-NUM
           MOVE 000000002          TO FD-XREF-CUST-ID
           MOVE 00000000002        TO FD-XREF-ACCT-ID
           MOVE SPACES             TO FD-XREF-FILLER
           WRITE FD-XREFFILE-REC.

           CLOSE XREF-FILE.
           STOP RUN.
