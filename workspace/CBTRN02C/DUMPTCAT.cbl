      ******************************************************************
      * DUMPTCAT.cbl
      * Dump TCATBALF (indexed, 50-byte records) to sequential flat file.
      * Used for golden master comparison of TCATBAL after-state.
      *
      * Input:  TCATBALF  (env var, indexed)
      * Output: TCATSEQ   (env var, sequential flat dump)
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DUMPTCAT.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TCATBAL-FILE ASSIGN TO TCATBALF
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS DC-TRAN-CAT-KEY
                  FILE STATUS  IS WS-TCAT-STATUS.

           SELECT SEQ-FILE ASSIGN TO TCATSEQ
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS WS-SEQ-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TCATBAL-FILE.
       01  DC-TCAT-REC.
           05  DC-TRAN-CAT-KEY.
               10  DC-TRANCAT-ACCT-ID PIC 9(11).
               10  DC-TRANCAT-TYPE-CD PIC X(02).
               10  DC-TRANCAT-CD      PIC 9(04).
           05  DC-TCAT-DATA           PIC X(33).

       FD  SEQ-FILE.
       01  DS-SEQ-REC                 PIC X(50).

       WORKING-STORAGE SECTION.
       01  WS-TCAT-STATUS.
           05  WS-TCAT-STAT1          PIC X.
           05  WS-TCAT-STAT2          PIC X.
       01  WS-SEQ-STATUS.
           05  WS-SEQ-STAT1           PIC X.
           05  WS-SEQ-STAT2           PIC X.
       01  WS-COUNT                   PIC 9(09) VALUE 0.
       01  WS-EOF                     PIC X VALUE 'N'.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT TCATBAL-FILE
           IF WS-TCAT-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING TCATBALF: ' WS-TCAT-STATUS
               STOP RUN
           END-IF

           OPEN OUTPUT SEQ-FILE
           IF WS-SEQ-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING TCATSEQ: ' WS-SEQ-STATUS
               STOP RUN
           END-IF

           PERFORM UNTIL WS-EOF = 'Y'
               READ TCATBAL-FILE
               IF WS-TCAT-STATUS = '00'
                   ADD 1 TO WS-COUNT
                   MOVE DC-TCAT-REC TO DS-SEQ-REC
                   WRITE DS-SEQ-REC
                   IF WS-SEQ-STATUS NOT = '00'
                       DISPLAY 'ERROR WRITING SEQ: ' WS-SEQ-STATUS
                       STOP RUN
                   END-IF
               ELSE
                   IF WS-TCAT-STATUS = '10'
                       MOVE 'Y' TO WS-EOF
                   ELSE
                       DISPLAY 'ERROR READING TCATBALF: ' WS-TCAT-STATUS
                       STOP RUN
                   END-IF
               END-IF
           END-PERFORM

           CLOSE TCATBAL-FILE
           CLOSE SEQ-FILE
           DISPLAY 'DUMPTCAT COMPLETE: ' WS-COUNT ' records dumped'
           STOP RUN.
