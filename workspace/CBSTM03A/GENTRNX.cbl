       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENTRNX.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRNX-FILE ASSIGN TO TRNXFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS FD-TRNXS-ID
                  FILE STATUS  IS TRNXFILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TRNX-FILE.
       01  FD-TRNXFILE-REC.
           05 FD-TRNXS-ID.
              10  FD-TRNX-CARD              PIC X(16).
              10  FD-TRNX-ID                PIC X(16).
           05 FD-TRNX-TYPE-CD               PIC X(02).
           05 FD-TRNX-CAT-CD                PIC 9(04).
           05 FD-TRNX-SOURCE                PIC X(10).
           05 FD-TRNX-DESC                  PIC X(100).
           05 FD-TRNX-AMT                   PIC S9(09)V99.
           05 FD-TRNX-MERCHANT-ID           PIC 9(09).
           05 FD-TRNX-MERCHANT-NAME         PIC X(50).
           05 FD-TRNX-MERCHANT-CITY         PIC X(50).
           05 FD-TRNX-MERCHANT-ZIP          PIC X(10).
           05 FD-TRNX-ORIG-TS               PIC X(26).
           05 FD-TRNX-PROC-TS               PIC X(26).
           05 FD-TRNX-FILLER                PIC X(20).

       WORKING-STORAGE SECTION.
       01  TRNXFILE-STATUS.
           05  TRNXFILE-STAT1      PIC X.
           05  TRNXFILE-STAT2      PIC X.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT TRNX-FILE.

      * ---- Record 1: Card 1, Trnx 1 - Online Purchase $100.00 ----
           INITIALIZE FD-TRNXFILE-REC.
           MOVE '4000002000000001' TO FD-TRNX-CARD.
           MOVE '0000000000000001' TO FD-TRNX-ID.
           MOVE '01' TO FD-TRNX-TYPE-CD.
           MOVE 1 TO FD-TRNX-CAT-CD.
           MOVE 'WEB' TO FD-TRNX-SOURCE(1:3).
           MOVE 'Online Purchase - Amazon' TO FD-TRNX-DESC(1:24).
           MOVE +10000 TO FD-TRNX-AMT.
           MOVE 123456789 TO FD-TRNX-MERCHANT-ID.
           MOVE 'AMAZON COM' TO FD-TRNX-MERCHANT-NAME(1:10).
           MOVE 'SEATTLE' TO FD-TRNX-MERCHANT-CITY(1:7).
           MOVE '98101' TO FD-TRNX-MERCHANT-ZIP(1:5).
           MOVE '2026-06-17-10.00.00.000000' TO FD-TRNX-ORIG-TS.
           MOVE '2026-06-17-10.01.00.000000' TO FD-TRNX-PROC-TS.
           WRITE FD-TRNXFILE-REC.

      * ---- Record 2: Card 1, Trnx 2 - Gas Station $50.00 ----
           INITIALIZE FD-TRNXFILE-REC.
           MOVE '4000002000000001' TO FD-TRNX-CARD.
           MOVE '0000000000000002' TO FD-TRNX-ID.
           MOVE '01' TO FD-TRNX-TYPE-CD.
           MOVE 2 TO FD-TRNX-CAT-CD.
           MOVE 'POS' TO FD-TRNX-SOURCE(1:3).
           MOVE 'Gas Station - Shell' TO FD-TRNX-DESC(1:19).
           MOVE +5000 TO FD-TRNX-AMT.
           MOVE 987654321 TO FD-TRNX-MERCHANT-ID.
           MOVE 'SHELL OIL' TO FD-TRNX-MERCHANT-NAME(1:9).
           MOVE 'REDMOND' TO FD-TRNX-MERCHANT-CITY(1:7).
           MOVE '98052' TO FD-TRNX-MERCHANT-ZIP(1:5).
           MOVE '2026-06-17-11.00.00.000000' TO FD-TRNX-ORIG-TS.
           MOVE '2026-06-17-11.01.00.000000' TO FD-TRNX-PROC-TS.
           WRITE FD-TRNXFILE-REC.

      * ---- Record 3: Card 2, Trnx 3 - Restaurant $75.00 ----
           INITIALIZE FD-TRNXFILE-REC.
           MOVE '4000002000000002' TO FD-TRNX-CARD.
           MOVE '0000000000000003' TO FD-TRNX-ID.
           MOVE '01' TO FD-TRNX-TYPE-CD.
           MOVE 1 TO FD-TRNX-CAT-CD.
           MOVE 'POS' TO FD-TRNX-SOURCE(1:3).
           MOVE 'Restaurant - Olive Garden' TO FD-TRNX-DESC(1:25).
           MOVE +7500 TO FD-TRNX-AMT.
           MOVE 555666777 TO FD-TRNX-MERCHANT-ID.
           MOVE 'OLIVE GARDEN' TO FD-TRNX-MERCHANT-NAME(1:12).
           MOVE 'BELLEVUE' TO FD-TRNX-MERCHANT-CITY(1:8).
           MOVE '98004' TO FD-TRNX-MERCHANT-ZIP(1:5).
           MOVE '2026-06-17-12.00.00.000000' TO FD-TRNX-ORIG-TS.
           MOVE '2026-06-17-12.01.00.000000' TO FD-TRNX-PROC-TS.
           WRITE FD-TRNXFILE-REC.

           CLOSE TRNX-FILE.
           STOP RUN.
