      ******************************************************************
      * GENDALY.cbl - Generate DALYTRAN for CBTRN02C tests
      * 7 transactions:
      * TRN01 ACCEPT: card=4000002000000000 AMT=+50.00 CR/0001
      * TRN02 ACCEPT: card=4000002000000001 AMT=+75.00 CR/0001
      * TRN03 REJ100: card=9999999999999999 (not in XREFFILE)
      * TRN04 REJ101: card=4000002000000099 (xref ok, acct 99 missing)
      * TRN05 REJ102: card=4000002000000002 AMT=+50.00 (overlimit)
      * TRN06 REJ103: card=4000002000000003 AMT=+25.00 (expired acct)
      * TRN07 ACCEPT: card=4000002000000001 AMT=+100.00 CR/0001
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENDALY.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT DALY-FILE ASSIGN TO DALYTRAN
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS WS-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  DALY-FILE.
       01  GD-DALY-REC.
           05  GD-DALY-DATA           PIC X(350).

       WORKING-STORAGE SECTION.
       01  WS-STATUS.
           05  WS-STAT1               PIC X.
           05  WS-STAT2               PIC X.

       01  WS-DALY-REC.
           05  DALYTRAN-ID            PIC X(16).
           05  DALYTRAN-TYPE-CD       PIC X(02).
           05  DALYTRAN-CAT-CD        PIC 9(04).
           05  DALYTRAN-SOURCE        PIC X(10).
           05  DALYTRAN-DESC          PIC X(100).
           05  DALYTRAN-AMT           PIC S9(09)V99.
           05  DALYTRAN-MERCHANT-ID   PIC 9(09).
           05  DALYTRAN-MERCHANT-NAME PIC X(50).
           05  DALYTRAN-MERCHANT-CITY PIC X(50).
           05  DALYTRAN-MERCHANT-ZIP  PIC X(10).
           05  DALYTRAN-CARD-NUM      PIC X(16).
           05  DALYTRAN-ORIG-TS       PIC X(26).
           05  DALYTRAN-PROC-TS       PIC X(26).
           05  DALYTRAN-FILLER        PIC X(20).

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT DALY-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING DALYTRAN: ' WS-STATUS
               STOP RUN
           END-IF

      *--- TRN01: ACCEPT, card=4000002000000000, AMT=+50.00 ---
           INITIALIZE WS-DALY-REC
           MOVE 'TRN0000000000001'  TO DALYTRAN-ID
           MOVE 'CR'                TO DALYTRAN-TYPE-CD
           MOVE 0001                TO DALYTRAN-CAT-CD
           MOVE 'BATCH     '        TO DALYTRAN-SOURCE
           MOVE 'VALID CREDIT PURCHASE ONE                        '
               & '                                                '
                                    TO DALYTRAN-DESC
           MOVE 50.00               TO DALYTRAN-AMT
           MOVE 000000001           TO DALYTRAN-MERCHANT-ID
           MOVE 'MERCHANT ONE                                      '
                                    TO DALYTRAN-MERCHANT-NAME
           MOVE 'NEW YORK                                          '
                                    TO DALYTRAN-MERCHANT-CITY
           MOVE '10001-0001'        TO DALYTRAN-MERCHANT-ZIP
           MOVE '4000002000000000'  TO DALYTRAN-CARD-NUM
           MOVE '2026-01-15-10.00.00.000000'
                                    TO DALYTRAN-ORIG-TS
           MOVE SPACES              TO DALYTRAN-PROC-TS
           MOVE SPACES              TO DALYTRAN-FILLER
           MOVE WS-DALY-REC         TO GD-DALY-DATA
           WRITE GD-DALY-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TRN01: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TRN01: ACCEPT card=4000002000000000 +50.00'

      *--- TRN02: ACCEPT, card=4000002000000001, AMT=+75.00 ---
           INITIALIZE WS-DALY-REC
           MOVE 'TRN0000000000002'  TO DALYTRAN-ID
           MOVE 'CR'                TO DALYTRAN-TYPE-CD
           MOVE 0001                TO DALYTRAN-CAT-CD
           MOVE 'BATCH     '        TO DALYTRAN-SOURCE
           MOVE 'VALID CREDIT PURCHASE TWO W EXISTING TCATBAL    '
               & '                                                '
                                    TO DALYTRAN-DESC
           MOVE 75.00               TO DALYTRAN-AMT
           MOVE 000000002           TO DALYTRAN-MERCHANT-ID
           MOVE 'MERCHANT TWO                                      '
                                    TO DALYTRAN-MERCHANT-NAME
           MOVE 'LOS ANGELES                                       '
                                    TO DALYTRAN-MERCHANT-CITY
           MOVE '90210-5555'        TO DALYTRAN-MERCHANT-ZIP
           MOVE '4000002000000001'  TO DALYTRAN-CARD-NUM
           MOVE '2026-01-15-11.00.00.000000'
                                    TO DALYTRAN-ORIG-TS
           MOVE SPACES              TO DALYTRAN-PROC-TS
           MOVE SPACES              TO DALYTRAN-FILLER
           MOVE WS-DALY-REC         TO GD-DALY-DATA
           WRITE GD-DALY-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TRN02: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TRN02: ACCEPT card=4000002000000001 +75.00'

      *--- TRN03: REJECT 100, card=9999999999999999 ---
           INITIALIZE WS-DALY-REC
           MOVE 'TRN0000000000003'  TO DALYTRAN-ID
           MOVE 'CR'                TO DALYTRAN-TYPE-CD
           MOVE 0001                TO DALYTRAN-CAT-CD
           MOVE 'BATCH     '        TO DALYTRAN-SOURCE
           MOVE 'INVALID CARD NUMBER TEST                         '
               & '                                                '
                                    TO DALYTRAN-DESC
           MOVE 10.00               TO DALYTRAN-AMT
           MOVE 000000003           TO DALYTRAN-MERCHANT-ID
           MOVE 'MERCHANT THREE                                    '
                                    TO DALYTRAN-MERCHANT-NAME
           MOVE 'CHICAGO                                           '
                                    TO DALYTRAN-MERCHANT-CITY
           MOVE '60601-0000'        TO DALYTRAN-MERCHANT-ZIP
           MOVE '9999999999999999'  TO DALYTRAN-CARD-NUM
           MOVE '2026-01-15-12.00.00.000000'
                                    TO DALYTRAN-ORIG-TS
           MOVE SPACES              TO DALYTRAN-PROC-TS
           MOVE SPACES              TO DALYTRAN-FILLER
           MOVE WS-DALY-REC         TO GD-DALY-DATA
           WRITE GD-DALY-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TRN03: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TRN03: REJECT100 card=9999999999999999'

      *--- TRN04: REJECT 101, card=4000002000000099 (acct 99 missing) ---
           INITIALIZE WS-DALY-REC
           MOVE 'TRN0000000000004'  TO DALYTRAN-ID
           MOVE 'CR'                TO DALYTRAN-TYPE-CD
           MOVE 0001                TO DALYTRAN-CAT-CD
           MOVE 'BATCH     '        TO DALYTRAN-SOURCE
           MOVE 'ACCOUNT NOT FOUND TEST                           '
               & '                                                '
                                    TO DALYTRAN-DESC
           MOVE 20.00               TO DALYTRAN-AMT
           MOVE 000000004           TO DALYTRAN-MERCHANT-ID
           MOVE 'MERCHANT FOUR                                     '
                                    TO DALYTRAN-MERCHANT-NAME
           MOVE 'HOUSTON                                           '
                                    TO DALYTRAN-MERCHANT-CITY
           MOVE '77001-0000'        TO DALYTRAN-MERCHANT-ZIP
           MOVE '4000002000000099'  TO DALYTRAN-CARD-NUM
           MOVE '2026-01-15-13.00.00.000000'
                                    TO DALYTRAN-ORIG-TS
           MOVE SPACES              TO DALYTRAN-PROC-TS
           MOVE SPACES              TO DALYTRAN-FILLER
           MOVE WS-DALY-REC         TO GD-DALY-DATA
           WRITE GD-DALY-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TRN04: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TRN04: REJECT101 card=4000002000000099'

      *--- TRN05: REJECT 102, card=4000002000000002, AMT=+50.00 ---
      * Acct3: cr=990, deb=0, lim=1000
      * WS-TEMP-BAL=990-0+50=1040 >1000 -> REJECT 102
      * expiry 2030 passes; final reason=102
           INITIALIZE WS-DALY-REC
           MOVE 'TRN0000000000005'  TO DALYTRAN-ID
           MOVE 'DR'                TO DALYTRAN-TYPE-CD
           MOVE 0001                TO DALYTRAN-CAT-CD
           MOVE 'BATCH     '        TO DALYTRAN-SOURCE
           MOVE 'OVER CREDIT LIMIT TEST                           '
               & '                                                '
                                    TO DALYTRAN-DESC
           MOVE 50.00               TO DALYTRAN-AMT
           MOVE 000000005           TO DALYTRAN-MERCHANT-ID
           MOVE 'MERCHANT FIVE                                     '
                                    TO DALYTRAN-MERCHANT-NAME
           MOVE 'PHOENIX                                           '
                                    TO DALYTRAN-MERCHANT-CITY
           MOVE '85001-0000'        TO DALYTRAN-MERCHANT-ZIP
           MOVE '4000002000000002'  TO DALYTRAN-CARD-NUM
           MOVE '2026-01-15-14.00.00.000000'
                                    TO DALYTRAN-ORIG-TS
           MOVE SPACES              TO DALYTRAN-PROC-TS
           MOVE SPACES              TO DALYTRAN-FILLER
           MOVE WS-DALY-REC         TO GD-DALY-DATA
           WRITE GD-DALY-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TRN05: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TRN05: REJECT102 card=4000002000000002 overlimit'

      *--- TRN06: REJECT 103, card=4000002000000003, AMT=+25.00 ---
      * Acct4: cr=0, deb=0, lim=5000, expiry=2020-01-01
      * WS-TEMP-BAL=0-0+25=25 <=5000 limit PASSES
      * expiry 2020-01-01 < 2026-01-15 -> REJECT 103
           INITIALIZE WS-DALY-REC
           MOVE 'TRN0000000000006'  TO DALYTRAN-ID
           MOVE 'CR'                TO DALYTRAN-TYPE-CD
           MOVE 0001                TO DALYTRAN-CAT-CD
           MOVE 'BATCH     '        TO DALYTRAN-SOURCE
           MOVE 'ACCOUNT EXPIRED TEST                             '
               & '                                                '
                                    TO DALYTRAN-DESC
           MOVE 25.00               TO DALYTRAN-AMT
           MOVE 000000006           TO DALYTRAN-MERCHANT-ID
           MOVE 'MERCHANT SIX                                      '
                                    TO DALYTRAN-MERCHANT-NAME
           MOVE 'PHILADELPHIA                                      '
                                    TO DALYTRAN-MERCHANT-CITY
           MOVE '19101-0000'        TO DALYTRAN-MERCHANT-ZIP
           MOVE '4000002000000003'  TO DALYTRAN-CARD-NUM
           MOVE '2026-01-15-15.00.00.000000'
                                    TO DALYTRAN-ORIG-TS
           MOVE SPACES              TO DALYTRAN-PROC-TS
           MOVE SPACES              TO DALYTRAN-FILLER
           MOVE WS-DALY-REC         TO GD-DALY-DATA
           WRITE GD-DALY-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TRN06: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TRN06: REJECT103 card=4000002000000003 expired'

      *--- TRN07: ACCEPT, card=4000002000000001, AMT=+100.00 ---
      * After TRN02: acct2 cr=75, deb=0
      * WS-TEMP-BAL=75-0+100=175 <=2000 PASS; expiry 2030 PASS
           INITIALIZE WS-DALY-REC
           MOVE 'TRN0000000000007'  TO DALYTRAN-ID
           MOVE 'CR'                TO DALYTRAN-TYPE-CD
           MOVE 0001                TO DALYTRAN-CAT-CD
           MOVE 'BATCH     '        TO DALYTRAN-SOURCE
           MOVE 'SECOND ACCEPT SAME CARD UPDATES TCATBAL AGAIN   '
               & '                                                '
                                    TO DALYTRAN-DESC
           MOVE 100.00              TO DALYTRAN-AMT
           MOVE 000000007           TO DALYTRAN-MERCHANT-ID
           MOVE 'MERCHANT SEVEN                                    '
                                    TO DALYTRAN-MERCHANT-NAME
           MOVE 'SAN ANTONIO                                       '
                                    TO DALYTRAN-MERCHANT-CITY
           MOVE '78201-0000'        TO DALYTRAN-MERCHANT-ZIP
           MOVE '4000002000000001'  TO DALYTRAN-CARD-NUM
           MOVE '2026-01-15-16.00.00.000000'
                                    TO DALYTRAN-ORIG-TS
           MOVE SPACES              TO DALYTRAN-PROC-TS
           MOVE SPACES              TO DALYTRAN-FILLER
           MOVE WS-DALY-REC         TO GD-DALY-DATA
           WRITE GD-DALY-REC
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERR WRITE TRN07: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'TRN07: ACCEPT card=4000002000000001 +100.00'

           CLOSE DALY-FILE
           IF WS-STATUS NOT = '00'
               DISPLAY 'ERROR CLOSING DALYTRAN: ' WS-STATUS
               STOP RUN
           END-IF
           DISPLAY 'GENDALY COMPLETE: 7 records written'
           STOP RUN.
