       IDENTIFICATION DIVISION.
       PROGRAM-ID. DUMPTRNX.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO TRNXFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE IS SEQUENTIAL
                  RECORD KEY IS IN-KEY
                  FILE STATUS IS FS.
           SELECT OUT-FILE ASSIGN TO TRNXSEQ
                  ORGANIZATION IS SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD IN-FILE.
       01 IN-REC.
          05 IN-KEY PIC X(32).
          05 IN-DATA PIC X(318).
       FD OUT-FILE.
       01 OUT-REC PIC X(350).
       WORKING-STORAGE SECTION.
       01 FS PIC XX.
       PROCEDURE DIVISION.
           OPEN INPUT IN-FILE OUTPUT OUT-FILE.
           PERFORM UNTIL FS = '10'
               READ IN-FILE INTO OUT-REC
               IF FS = '00'
                   WRITE OUT-REC
               END-IF
           END-PERFORM.
           CLOSE IN-FILE OUT-FILE.
           STOP RUN.
