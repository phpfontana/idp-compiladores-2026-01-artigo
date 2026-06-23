      ******************************************************************
      * GENTCAT.cbl - Generate TCATBALF for CBTRN02C tests
      * 1 pre-existing record:
      *   ACCT=00000000002, TYPE=CR, CAT=0001, BAL=100.00
      *   TRN02 updates: 100+75=175
      *   TRN07 updates: 175+100=275
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

      *--- Pre-existing: ACCT=2, TYPE=CR, CAT=0001, BAL=100.00
           INITIALIZE WS-TCAT-REC
           MOVE 00000000002        TO TRANCAT-ACCT-ID
           MOVE 'CR'               TO TRANCAT-TYPE-CD
           MOVE 0001               TO TRANCAT-CD
           MOVE 100.00             TO TRAN-CAT-BAL
           MOVE SPACES             TO WS-FILLER
           MOVE WS-TCAT-REC        TO GT-TRAN-CAT-BAL-REC
           WRITE GT-TRAN-CAT-BAL-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TCAT 1: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TCAT1: ACCT=00000000002 CR/0001 BAL=100.00'

           CLOSE TCATBAL-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR CLOSING TCATBALF: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENTCAT COMPLETE: 1 record written'
           STOP RUN.
