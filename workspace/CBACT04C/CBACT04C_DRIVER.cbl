      ******************************************************************
      * CBACT04C_DRIVER.cbl
      * Driver to call CBACT04C with EXTERNAL-PARMS linkage.
      *
      * CBACT04C declares:
      *   LINKAGE SECTION.
      *   01  EXTERNAL-PARMS.
      *       05  PARM-LENGTH   PIC S9(04) COMP.   (2 bytes binary)
      *       05  PARM-DATE     PIC X(10).          (10 bytes)
      *
      * This driver hard-codes PARM-DATE = '2026-06-17' and calls
      * CBACT04C using CALL ... USING.
      *
      * The date is accepted via the ACCEPT FROM COMMAND-LINE approach
      * but since we need to pass it to CBACT04C, we hard-code it here.
      * If you need a different date, modify PARM-DATE-VALUE below.
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CBACT04C-DRIVER.

       WORKING-STORAGE SECTION.
       01  WS-EXTERNAL-PARMS.
           05  PARM-LENGTH             PIC S9(04) COMP VALUE 10.
           05  PARM-DATE               PIC X(10)  VALUE '2026-06-17'.

       PROCEDURE DIVISION.
       0000-MAIN.
           CALL 'CBACT04C' USING WS-EXTERNAL-PARMS
           STOP RUN.
