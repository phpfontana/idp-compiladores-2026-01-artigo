      ******************************************************************
      * COBDATFT.cbl
      * COBOL stub replicating the assembler COBDATFT routine logic.
      * The assembler uses a DSECT (COREC) mapped as:
      *   COINTYPE  = offset 0 (1 byte)
      *   COINPDT   = offset 1 (20 bytes)
      *   COOUTYPE  = offset 21 (1 byte)
      *   COOUTDT   = offset 22 (20 bytes)
      *   COERMSG   = offset 42 (38 bytes) [approx, per CODATECN-ERROR-MSG]
      *
      * This maps exactly to CODATECN-REC as defined in CODATECN.cpy:
      *   CODATECN-TYPE     PIC X        (offset 0)
      *   CODATECN-INP-DATE PIC X(20)    (offset 1)
      *   CODATECN-OUTTYPE  PIC X        (offset 21)
      *   CODATECN-0UT-DATE PIC X(20)    (offset 22)
      *   CODATECN-ERROR-MSG PIC X(38)   (offset 42)
      *
      * Assembler VALIDIN2 logic (COINTYPE='2', COOUTYPE='2'):
      *   MVC   COOUTDT(4),COINPDT       -> YYYY from COINPDT[0:4]
      *   MVC   COOUTDT+4(2),COINPDT+5   -> MM  from COINPDT[5:7]
      *   MVC   COOUTDT+6(2),COINPDT+8   -> DD  from COINPDT[8:10]
      * Input format:  YYYY-MM-DD  (COINPDT positions 1-10, rest spaces)
      * Output format: YYYYMMDD    (COOUTDT positions 1-8, rest unchanged)
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBDATFT.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ERROR-MSG PIC X(13) VALUE 'INVALID INPUT'.

       LINKAGE SECTION.
       COPY CODATECN.

       PROCEDURE DIVISION USING CODATECN-REC.

       0000-MAIN.
           EVALUATE CODATECN-TYPE
               WHEN '1'
                   PERFORM 1000-TYPE1-IN
               WHEN '2'
                   PERFORM 2000-TYPE2-IN
               WHEN OTHER
                   PERFORM 9000-ERROR
           END-EVALUATE
           GOBACK.

      *---------------------------------------------------------------*
      * TYPE '1' input: YYYYMMDD -> convert based on COOUTYPE
      *---------------------------------------------------------------*
       1000-TYPE1-IN.
      *    Assembler VALIDIN1: checks COINPDT+4 is '-' -> error
      *    If COINPDT+4 = '-' that means it looks like YYYY-MM-DD,
      *    which contradicts TYPE '1', so error.
      *    Also if COOUTYPE='2' -> error (TYPE1 only produces TYPE1 out)
           IF CODATECN-INP-DATE(5:1) = '-'
               PERFORM 9000-ERROR
               GOBACK
           END-IF
           IF CODATECN-OUTTYPE = '2'
               PERFORM 9000-ERROR
               GOBACK
           END-IF
      *    TYPE '1' in (YYYYMMDD), TYPE '1' out (YYYY-MM-DD)
           MOVE CODATECN-INP-DATE(1:4) TO CODATECN-0UT-DATE(1:4)
           MOVE '-'                     TO CODATECN-0UT-DATE(5:1)
           MOVE CODATECN-INP-DATE(5:2) TO CODATECN-0UT-DATE(6:2)
           MOVE '-'                     TO CODATECN-0UT-DATE(8:1)
           MOVE CODATECN-INP-DATE(7:2) TO CODATECN-0UT-DATE(9:2).

      *---------------------------------------------------------------*
      * TYPE '2' input: YYYY-MM-DD -> YYYYMMDD
      * Assembler VALIDIN2:
      *   COOUTYPE='1' -> error
      *   MVC COOUTDT(4),COINPDT      : YYYY
      *   MVC COOUTDT+4(2),COINPDT+5  : MM  (skipping '-' at pos 4)
      *   MVC COOUTDT+6(2),COINPDT+8  : DD  (skipping '-' at pos 7)
      *---------------------------------------------------------------*
       2000-TYPE2-IN.
           IF CODATECN-OUTTYPE = '1'
               PERFORM 9000-ERROR
               GOBACK
           END-IF
      *    COINPDT[0:4] -> COOUTDT[0:4]  (YYYY, 1-based: positions 1-4)
           MOVE CODATECN-INP-DATE(1:4) TO CODATECN-0UT-DATE(1:4)
      *    COINPDT+5(2) -> COOUTDT+4(2)  (MM, 1-based: inp pos 6-7, out pos 5-6)
           MOVE CODATECN-INP-DATE(6:2) TO CODATECN-0UT-DATE(5:2)
      *    COINPDT+8(2) -> COOUTDT+6(2)  (DD, 1-based: inp pos 9-10, out pos 7-8)
           MOVE CODATECN-INP-DATE(9:2) TO CODATECN-0UT-DATE(7:2).

      *---------------------------------------------------------------*
      * Error handler
      *---------------------------------------------------------------*
       9000-ERROR.
           MOVE WS-ERROR-MSG TO CODATECN-ERROR-MSG(1:13).
