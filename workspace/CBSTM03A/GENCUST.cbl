       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENCUST.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUST-FILE ASSIGN TO CUSTFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS FD-CUST-ID
                  FILE STATUS  IS CUSTFILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  CUST-FILE.
       01  FD-CUSTFILE-REC.
           05 FD-CUST-ID               PIC X(09).
           05 FD-CUST-FIRST-NAME       PIC X(25).
           05 FD-CUST-MIDDLE-NAME      PIC X(25).
           05 FD-CUST-LAST-NAME        PIC X(25).
           05 FD-CUST-ADDR-LINE-1      PIC X(50).
           05 FD-CUST-ADDR-LINE-2      PIC X(50).
           05 FD-CUST-ADDR-LINE-3      PIC X(50).
           05 FD-CUST-ADDR-STATE-CD    PIC X(02).
           05 FD-CUST-ADDR-COUNTRY-CD  PIC X(03).
           05 FD-CUST-ADDR-ZIP         PIC X(10).
           05 FD-CUST-PHONE-NUM-1      PIC X(15).
           05 FD-CUST-PHONE-NUM-2      PIC X(15).
           05 FD-CUST-SSN              PIC 9(09).
           05 FD-CUST-GOVT-ISSUED-ID   PIC X(20).
           05 FD-CUST-DOB-YYYYMMDD     PIC X(10).
           05 FD-CUST-EFT-ACCOUNT-ID   PIC X(10).
           05 FD-CUST-PRI-CARD-IND     PIC X(01).
           05 FD-CUST-FICO-SCORE       PIC 9(03).
           05 FD-CUST-FILLER           PIC X(168).

       WORKING-STORAGE SECTION.
       01  CUSTFILE-STATUS.
           05  CUSTFILE-STAT1      PIC X.
           05  CUSTFILE-STAT2      PIC X.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT CUST-FILE.

      * Customer 1
           MOVE '000000001'         TO FD-CUST-ID
           MOVE 'JOHN                     ' TO FD-CUST-FIRST-NAME
           MOVE 'M                        ' TO FD-CUST-MIDDLE-NAME
           MOVE 'DOE                      ' TO FD-CUST-LAST-NAME
           MOVE '100 MAIN STREET                                   '
                                    TO FD-CUST-ADDR-LINE-1
           MOVE 'APT 101                                           '
                                    TO FD-CUST-ADDR-LINE-2
           MOVE 'SEATTLE                                           '
                                    TO FD-CUST-ADDR-LINE-3
           MOVE 'WA'                TO FD-CUST-ADDR-STATE-CD
           MOVE 'USA'               TO FD-CUST-ADDR-COUNTRY-CD
           MOVE '98101     '        TO FD-CUST-ADDR-ZIP
           MOVE '555-555-1234   '   TO FD-CUST-PHONE-NUM-1
           MOVE '555-555-5678   '   TO FD-CUST-PHONE-NUM-2
           MOVE 123456789           TO FD-CUST-SSN
           MOVE 'DL-WA-123456789     ' TO FD-CUST-GOVT-ISSUED-ID
           MOVE '1980-01-15'        TO FD-CUST-DOB-YYYYMMDD
           MOVE 'EFT0000001'        TO FD-CUST-EFT-ACCOUNT-ID
           MOVE 'Y'                 TO FD-CUST-PRI-CARD-IND
           MOVE 750                 TO FD-CUST-FICO-SCORE
           MOVE SPACES              TO FD-CUST-FILLER
           WRITE FD-CUSTFILE-REC.

      * Customer 2
           MOVE '000000002'         TO FD-CUST-ID
           MOVE 'JANE                     ' TO FD-CUST-FIRST-NAME
           MOVE 'A                        ' TO FD-CUST-MIDDLE-NAME
           MOVE 'SMITH                    ' TO FD-CUST-LAST-NAME
           MOVE '200 OAK AVENUE                                    '
                                    TO FD-CUST-ADDR-LINE-1
           MOVE 'SUITE 200                                         '
                                    TO FD-CUST-ADDR-LINE-2
           MOVE 'BELLEVUE                                          '
                                    TO FD-CUST-ADDR-LINE-3
           MOVE 'WA'                TO FD-CUST-ADDR-STATE-CD
           MOVE 'USA'               TO FD-CUST-ADDR-COUNTRY-CD
           MOVE '98004     '        TO FD-CUST-ADDR-ZIP
           MOVE '555-555-9876   '   TO FD-CUST-PHONE-NUM-1
           MOVE '555-555-4321   '   TO FD-CUST-PHONE-NUM-2
           MOVE 987654321           TO FD-CUST-SSN
           MOVE 'DL-WA-987654321     ' TO FD-CUST-GOVT-ISSUED-ID
           MOVE '1985-06-20'        TO FD-CUST-DOB-YYYYMMDD
           MOVE 'EFT0000002'        TO FD-CUST-EFT-ACCOUNT-ID
           MOVE 'Y'                 TO FD-CUST-PRI-CARD-IND
           MOVE 680                 TO FD-CUST-FICO-SCORE
           MOVE SPACES              TO FD-CUST-FILLER
           WRITE FD-CUSTFILE-REC.

           CLOSE CUST-FILE.
           STOP RUN.
