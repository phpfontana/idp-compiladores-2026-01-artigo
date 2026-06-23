       IDENTIFICATION DIVISION.
       PROGRAM-ID. CBSTM03B-DRIVER.
      ******************************************************************
      * Driver program that tests CBSTM03B subroutine by exercising:
      *   - TRNXFILE: open, read-sequential all records, close
      *   - XREFFILE: open, read-sequential all records, close
      *   - CUSTFILE: open, read-by-key '000000001', '000000002', close
      *   - ACCTFILE: open, read-by-key '00000000001','00000000002',close
      *
      * Output file: one 80-char line per CBSTM03B call
      *   columns 1-8:  DD name
      *   column  9:    space
      *   column  10:   OPER
      *   column  11:   space
      *   columns 12-13: RC
      *   column  14:   space
      *   columns 15-64: first 50 bytes of FLDT (spaces for open/close)
      ******************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT OUTPUT-FILE ASSIGN TO DRVOUTPUT
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS OUTPUT-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  OUTPUT-FILE.
       01  OUTPUT-REC             PIC X(80).

       WORKING-STORAGE SECTION.
       01  OUTPUT-STATUS.
           05  OUTPUT-STAT1       PIC X.
           05  OUTPUT-STAT2       PIC X.

      * The linkage area we pass to CBSTM03B
       01  WS-M03B-AREA.
           05  WS-M03B-DD         PIC X(08).
           05  WS-M03B-OPER       PIC X(01).
           05  WS-M03B-RC         PIC X(02).
           05  WS-M03B-KEY        PIC X(25).
           05  WS-M03B-KEY-LN     PIC S9(4).
           05  WS-M03B-FLDT       PIC X(1000).

      * Output line work area
       01  WS-OUT-LINE.
           05  WS-OUT-DD          PIC X(08).
           05  FILLER             PIC X(01) VALUE SPACE.
           05  WS-OUT-OPER        PIC X(01).
           05  FILLER             PIC X(01) VALUE SPACE.
           05  WS-OUT-RC          PIC X(02).
           05  FILLER             PIC X(01) VALUE SPACE.
           05  WS-OUT-FLDT        PIC X(50).
           05  FILLER             PIC X(16) VALUE SPACES.

       01  WS-EOF-SW              PIC X(01) VALUE 'N'.
           88  WS-EOF             VALUE 'Y'.

       PROCEDURE DIVISION.

       0000-MAIN.
           OPEN OUTPUT OUTPUT-FILE.

           PERFORM 1000-TEST-TRNXFILE.
           PERFORM 2000-TEST-XREFFILE.
           PERFORM 3000-TEST-CUSTFILE.
           PERFORM 4000-TEST-ACCTFILE.

           CLOSE OUTPUT-FILE.
           STOP RUN.

      ******************************************************************
      * TRNXFILE: open, read-all-sequential, close
      ******************************************************************
       1000-TEST-TRNXFILE.

           MOVE 'TRNXFILE' TO WS-M03B-DD.
           MOVE 'O'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY WS-M03B-FLDT.
           MOVE ZEROS      TO WS-M03B-KEY-LN.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

           MOVE 'N' TO WS-EOF-SW.
           PERFORM UNTIL WS-EOF
               MOVE 'TRNXFILE' TO WS-M03B-DD
               MOVE 'R'        TO WS-M03B-OPER
               MOVE SPACES     TO WS-M03B-KEY
               MOVE ZEROS      TO WS-M03B-KEY-LN
               MOVE SPACES     TO WS-M03B-FLDT
               CALL 'CBSTM03B' USING WS-M03B-AREA
               PERFORM 9100-WRITE-LINE
               IF WS-M03B-RC = '10'
                   MOVE 'Y' TO WS-EOF-SW
               END-IF
           END-PERFORM.

           MOVE 'TRNXFILE' TO WS-M03B-DD.
           MOVE 'C'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY WS-M03B-FLDT.
           MOVE ZEROS      TO WS-M03B-KEY-LN.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

       2000-TEST-XREFFILE.

           MOVE 'XREFFILE' TO WS-M03B-DD.
           MOVE 'O'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY WS-M03B-FLDT.
           MOVE ZEROS      TO WS-M03B-KEY-LN.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

           MOVE 'N' TO WS-EOF-SW.
           PERFORM UNTIL WS-EOF
               MOVE 'XREFFILE' TO WS-M03B-DD
               MOVE 'R'        TO WS-M03B-OPER
               MOVE SPACES     TO WS-M03B-KEY
               MOVE ZEROS      TO WS-M03B-KEY-LN
               MOVE SPACES     TO WS-M03B-FLDT
               CALL 'CBSTM03B' USING WS-M03B-AREA
               PERFORM 9100-WRITE-LINE
               IF WS-M03B-RC = '10'
                   MOVE 'Y' TO WS-EOF-SW
               END-IF
           END-PERFORM.

           MOVE 'XREFFILE' TO WS-M03B-DD.
           MOVE 'C'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY WS-M03B-FLDT.
           MOVE ZEROS      TO WS-M03B-KEY-LN.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

       3000-TEST-CUSTFILE.

           MOVE 'CUSTFILE' TO WS-M03B-DD.
           MOVE 'O'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY WS-M03B-FLDT.
           MOVE ZEROS      TO WS-M03B-KEY-LN.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

           MOVE 'CUSTFILE' TO WS-M03B-DD.
           MOVE 'K'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY.
           MOVE '000000001' TO WS-M03B-KEY(1:9).
           MOVE +9          TO WS-M03B-KEY-LN.
           MOVE SPACES      TO WS-M03B-FLDT.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

           MOVE 'CUSTFILE' TO WS-M03B-DD.
           MOVE 'K'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY.
           MOVE '000000002' TO WS-M03B-KEY(1:9).
           MOVE +9          TO WS-M03B-KEY-LN.
           MOVE SPACES      TO WS-M03B-FLDT.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

           MOVE 'CUSTFILE' TO WS-M03B-DD.
           MOVE 'C'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY WS-M03B-FLDT.
           MOVE ZEROS      TO WS-M03B-KEY-LN.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

       4000-TEST-ACCTFILE.

           MOVE 'ACCTFILE' TO WS-M03B-DD.
           MOVE 'O'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY WS-M03B-FLDT.
           MOVE ZEROS      TO WS-M03B-KEY-LN.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

           MOVE 'ACCTFILE' TO WS-M03B-DD.
           MOVE 'K'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY.
           MOVE '00000000001' TO WS-M03B-KEY(1:11).
           MOVE +11           TO WS-M03B-KEY-LN.
           MOVE SPACES        TO WS-M03B-FLDT.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

           MOVE 'ACCTFILE' TO WS-M03B-DD.
           MOVE 'K'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY.
           MOVE '00000000002' TO WS-M03B-KEY(1:11).
           MOVE +11           TO WS-M03B-KEY-LN.
           MOVE SPACES        TO WS-M03B-FLDT.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

           MOVE 'ACCTFILE' TO WS-M03B-DD.
           MOVE 'C'        TO WS-M03B-OPER.
           MOVE SPACES     TO WS-M03B-KEY WS-M03B-FLDT.
           MOVE ZEROS      TO WS-M03B-KEY-LN.
           CALL 'CBSTM03B' USING WS-M03B-AREA.
           PERFORM 9100-WRITE-LINE.

      ******************************************************************
      * Write one 80-char output line; also DISPLAY to stdout
      ******************************************************************
       9100-WRITE-LINE.
           MOVE WS-M03B-DD   TO WS-OUT-DD.
           MOVE WS-M03B-OPER TO WS-OUT-OPER.
           MOVE WS-M03B-RC   TO WS-OUT-RC.
           IF WS-M03B-OPER = 'R' OR WS-M03B-OPER = 'K'
               MOVE WS-M03B-FLDT(1:50) TO WS-OUT-FLDT
           ELSE
               MOVE SPACES TO WS-OUT-FLDT
           END-IF.
           MOVE WS-OUT-LINE TO OUTPUT-REC.
           WRITE OUTPUT-REC.
           DISPLAY WS-OUT-LINE.
