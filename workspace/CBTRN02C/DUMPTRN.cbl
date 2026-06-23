      ******************************************************************
      * DUMPTRN.cbl
      * Dump TRANFILE (indexed, 350-byte records) to sequential flat file.
      * Used for golden master comparison (before TRAN-PROC-TS masking).
      *
      * Input:  TRANFILE  (env var, indexed)
      * Output: TRNSEQ    (env var, sequential flat dump)
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DUMPTRN.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRAN-FILE ASSIGN TO TRANFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS DT-TRAN-ID
                  FILE STATUS  IS WS-TRAN-STATUS.

           SELECT SEQ-FILE ASSIGN TO TRNSEQ
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS WS-SEQ-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TRAN-FILE.
       01  DT-TRAN-REC.
           05  DT-TRAN-ID             PIC X(16).
           05  DT-TRAN-DATA           PIC X(334).

       FD  SEQ-FILE.
       01  DS-SEQ-REC                 PIC X(350).

       WORKING-STORAGE SECTION.
       01  WS-TRAN-STATUS.
           05  WS-TRAN-STAT1          PIC X.
           05  WS-TRAN-STAT2          PIC X.
       01  WS-SEQ-STATUS.
           05  WS-SEQ-STAT1           PIC X.
           05  WS-SEQ-STAT2           PIC X.
       01  WS-COUNT                   PIC 9(09) VALUE 0.
       01  WS-EOF                     PIC X VALUE 'N'.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT TRAN-FILE
           IF WS-TRAN-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING TRANFILE: ' WS-TRAN-STATUS
               STOP RUN
           END-IF

           OPEN OUTPUT SEQ-FILE
           IF WS-SEQ-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING TRNSEQ: ' WS-SEQ-STATUS
               STOP RUN
           END-IF

           PERFORM UNTIL WS-EOF = 'Y'
               READ TRAN-FILE
               IF WS-TRAN-STATUS = '00'
                   ADD 1 TO WS-COUNT
                   MOVE DT-TRAN-REC TO DS-SEQ-REC
                   WRITE DS-SEQ-REC
                   IF WS-SEQ-STATUS NOT = '00'
                       DISPLAY 'ERROR WRITING SEQ: ' WS-SEQ-STATUS
                       STOP RUN
                   END-IF
               ELSE
                   IF WS-TRAN-STATUS = '10'
                       MOVE 'Y' TO WS-EOF
                   ELSE
                       DISPLAY 'ERROR READING TRANFILE: ' WS-TRAN-STATUS
                       STOP RUN
                   END-IF
               END-IF
           END-PERFORM

           CLOSE TRAN-FILE
           CLOSE SEQ-FILE
           DISPLAY 'DUMPTRN COMPLETE: ' WS-COUNT ' records dumped'
           STOP RUN.
