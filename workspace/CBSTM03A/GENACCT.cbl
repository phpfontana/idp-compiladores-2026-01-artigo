       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENACCT.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-FILE ASSIGN TO ACCTFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS FD-ACCT-ID
                  FILE STATUS  IS ACCTFILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-FILE.
       01  FD-ACCTFILE-REC.
           05 FD-ACCT-ID               PIC 9(11).
           05 FD-ACCT-ACTIVE-STATUS    PIC X(01).
           05 FD-ACCT-CURR-BAL         PIC S9(10)V99.
           05 FD-ACCT-CREDIT-LIMIT     PIC S9(10)V99.
           05 FD-ACCT-CASH-CRED-LIMIT  PIC S9(10)V99.
           05 FD-ACCT-OPEN-DATE        PIC X(10).
           05 FD-ACCT-EXPIR-DATE       PIC X(10).
           05 FD-ACCT-REISSUE-DATE     PIC X(10).
           05 FD-ACCT-CYC-CREDIT       PIC S9(10)V99.
           05 FD-ACCT-CYC-DEBIT        PIC S9(10)V99.
           05 FD-ACCT-ADDR-ZIP         PIC X(10).
           05 FD-ACCT-GROUP-ID         PIC X(10).
           05 FD-ACCT-FILLER           PIC X(178).

       WORKING-STORAGE SECTION.
       01  ACCTFILE-STATUS.
           05  ACCTFILE-STAT1      PIC X.
           05  ACCTFILE-STAT2      PIC X.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT ACCT-FILE.

      * Account 1 - Balance $1234.56
           MOVE 00000000001    TO FD-ACCT-ID
           MOVE 'Y'            TO FD-ACCT-ACTIVE-STATUS
           MOVE +123456        TO FD-ACCT-CURR-BAL
           MOVE +500000        TO FD-ACCT-CREDIT-LIMIT
           MOVE +250000        TO FD-ACCT-CASH-CRED-LIMIT
           MOVE '2020-01-01'   TO FD-ACCT-OPEN-DATE
           MOVE '2027-01-01'   TO FD-ACCT-EXPIR-DATE
           MOVE '2024-01-01'   TO FD-ACCT-REISSUE-DATE
           MOVE +000000        TO FD-ACCT-CYC-CREDIT
           MOVE +000000        TO FD-ACCT-CYC-DEBIT
           MOVE '98101     '   TO FD-ACCT-ADDR-ZIP
           MOVE 'GRP001    '   TO FD-ACCT-GROUP-ID
           MOVE SPACES         TO FD-ACCT-FILLER
           WRITE FD-ACCTFILE-REC.

      * Account 2 - Balance $500.00
           MOVE 00000000002    TO FD-ACCT-ID
           MOVE 'Y'            TO FD-ACCT-ACTIVE-STATUS
           MOVE +50000         TO FD-ACCT-CURR-BAL
           MOVE +300000        TO FD-ACCT-CREDIT-LIMIT
           MOVE +150000        TO FD-ACCT-CASH-CRED-LIMIT
           MOVE '2021-06-01'   TO FD-ACCT-OPEN-DATE
           MOVE '2028-06-01'   TO FD-ACCT-EXPIR-DATE
           MOVE '2025-06-01'   TO FD-ACCT-REISSUE-DATE
           MOVE +000000        TO FD-ACCT-CYC-CREDIT
           MOVE +000000        TO FD-ACCT-CYC-DEBIT
           MOVE '98004     '   TO FD-ACCT-ADDR-ZIP
           MOVE 'GRP001    '   TO FD-ACCT-GROUP-ID
           MOVE SPACES         TO FD-ACCT-FILLER
           WRITE FD-ACCTFILE-REC.

           CLOSE ACCT-FILE.
           STOP RUN.
