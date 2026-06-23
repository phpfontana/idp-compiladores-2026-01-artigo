      ******************************************************************
      * CEE3ABD.cbl
      * Stub for IBM Language Environment CEE3ABD (abend).
      * Accepts: ABCODE PIC S9(9) BINARY, TIMING PIC S9(9) BINARY
      * Behavior: display abend code and stop run.
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CEE3ABD.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       LINKAGE SECTION.
       01  LS-ABCODE   PIC S9(9) BINARY.
       01  LS-TIMING   PIC S9(9) BINARY.

       PROCEDURE DIVISION USING LS-ABCODE, LS-TIMING.
       0000-MAIN.
           DISPLAY 'CEE3ABD CALLED: ABCODE=' LS-ABCODE
                   ' TIMING=' LS-TIMING
           STOP RUN.
