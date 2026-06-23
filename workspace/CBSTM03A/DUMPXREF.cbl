       IDENTIFICATION DIVISION.
       PROGRAM-ID. DUMPXREF.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO XREFFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE IS SEQUENTIAL
                  RECORD KEY IS IN-KEY
                  FILE STATUS IS FS.
           SELECT OUT-FILE ASSIGN TO XREFSEQ
                  ORGANIZATION IS SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD IN-FILE.
       01 IN-REC.
          05 IN-KEY PIC X(16).
          05 IN-DATA PIC X(34).
       FD OUT-FILE.
       01 OUT-REC PIC X(50).
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
