# Name Catalog

Maps cryptic COBOL identifiers to plain descriptions. Built in Phase 0.

| Name | Type | Plain description |
|---|---|---|
| _e.g. CBACT04C_ | program | _interest calculation batch program_ |
| CBACT01C | program | Reads account VSAM file sequentially; writes to three output files |
| CBACT02C | program | Reads and prints card VSAM file sequentially |
| CBACT03C | program | Reads and prints account cross-reference VSAM file |
| CBACT04C | program | Batch interest calculator; posts interest charges to accounts |
| CBCUS01C | program | Reads and prints customer VSAM file sequentially |
| CBEXPORT | program | Exports customer, account, card, xref, transaction data for migration |
| CBIMPORT | program | Imports multi-record migration file; splits into normalized files |
| CBSTM03A | program | Generates account statements in plain text and HTML formats |
| CBSTM03B | program | I/O subroutine for CBSTM03A; handles all file operations |
| CBTRN01C | program | Reads daily transactions; validates card and account existence |
| CBTRN02C | program | Posts daily transactions; validates, updates accounts, writes rejects |
| CBTRN03C | program | Prints transaction detail report filtered by date range |
| COACTUPC | program | CICS online account update screen handler |
| COACTVWC | program | CICS online account view screen handler |
| COADM01C | program | CICS admin menu for admin users |
| COBIL00C | program | CICS online bill payment screen handler |
| COBSWAIT | program | Batch utility: waits for N centiseconds (calls MVSWAIT) |
| COCRDLIC | program | CICS online credit card list screen handler |
| COCRDSLC | program | CICS online credit card select screen handler |
| COCRDUPC | program | CICS online credit card update screen handler |
| COMEN01C | program | CICS online main menu for regular users |
| CORPT00C | program | CICS program to submit report batch job via JES internal reader TDQ |
| COSGN00C | program | CICS signon screen; authenticates users against USRSEC file |
| COTRN00C | program | CICS transaction list/view screen handler |
| COTRN01C | program | CICS transaction add/inquiry screen handler |
| COTRN02C | program | CICS transaction add with date validation screen handler |
| COUSR00C | program | CICS user management list screen handler |
| COUSR01C | program | CICS user inquiry screen handler |
| COUSR02C | program | CICS user add screen handler |
| COUSR03C | program | CICS user delete screen handler |
| CSUTLDTC | program | Date validation utility; wraps CEEDAYS Lilian-date API |
| CBPAUP0C | program | Authorization batch update (IMS/DB2/MQ sub-application) |
| COPAUA0C | program | Authorization CICS inquiry screen (IMS/DB2/MQ sub-application) |
| COPAUS0C | program | Authorization CICS summary screen 0 (IMS/DB2/MQ sub-application) |
| COPAUS1C | program | Authorization CICS summary screen 1 (IMS/DB2/MQ sub-application) |
| COPAUS2C | program | Authorization CICS summary screen 2 (IMS/DB2/MQ sub-application) |
| COBTUPDT | program | Transaction type DB2 batch update program |
| COTRTLIC | program | Transaction type CICS list screen (DB2 sub-application) |
| COTRTUPC | program | Transaction type CICS update screen (DB2 sub-application) |
| COACCT01 | program | VSAM/MQ account inquiry program |
| CODATE01 | program | VSAM/MQ date utility program |
| CVACT01Y | copybook | Account master record layout (ACCT-ID, balances, dates, group-id) |
| CVACT02Y | copybook | Card record layout (CARD-NUM, CARD-ACCT-ID, CVV, expiration) |
| CVACT03Y | copybook | Card-to-account cross-reference record layout (XREF-CARD-NUM, CUST-ID, ACCT-ID) |
| CVCUS01Y | copybook | Customer master record layout (CUST-ID, name, address, SSN, FICO) |
| CVCRD01Y | copybook | Credit card data record layout for CICS screens |
| CVTRA01Y | copybook | Transaction category balance record (TRANCAT-ACCT-ID, TYPE-CD, CAT-CD, BAL) |
| CVTRA02Y | copybook | Disclosure group interest rate record (DIS-ACCT-GROUP-ID, DIS-INT-RATE) |
| CVTRA03Y | copybook | Transaction type description record (TRAN-TYPE, TRAN-TYPE-DESC) |
| CVTRA04Y | copybook | Transaction category description record (TRAN-CAT-KEY, TRAN-CAT-TYPE-DESC) |
| CVTRA05Y | copybook | Transaction master record layout (TRAN-ID, type, amount, timestamps, card-num) |
| CVTRA06Y | copybook | Daily transaction input record layout (DALYTRAN-ID, card-num, amount, merchant) |
| CVTRA07Y | copybook | Transaction report formatting record (REPT-*) |
| CVEXPORT | copybook | Export multi-record layout with typed sub-records (C/A/X/T/D types) |
| CUSTREC | copybook | Customer record layout used by CBSTM03A (CUSTOMER-RECORD) |
| COSTM01 | copybook | Statement control and TRNX-RECORD layout used by CBSTM03A |
| COCOM01Y | copybook | Common communication area (CARDDEMO-COMMAREA) passed between CICS programs |
| COADM02Y | copybook | Admin screen working-storage menu option definitions |
| CODATECN | copybook | Date conversion parameter block (CODATECN-REC) for COBDATFT |
| COMEN02Y | copybook | Main menu working-storage option definitions |
| COTTL01Y | copybook | Screen title and header working-storage variables |
| CSDAT01Y | copybook | Current date/time working-storage variables (WS-CURDATE-DATA) |
| CSLKPCDY | copybook | Lookup and decode table definitions |
| CSMSG01Y | copybook | Standard error and informational message text constants |
| CSMSG02Y | copybook | Additional error message text constants |
| CSSETATY | copybook | Screen attribute byte constants (colour, intensity) |
| CSSTRPFY | copybook | String strip/pad formatting utility macros |
| CSUSR01Y | copybook | User security record layout (USRSEC file) |
| CSUTLDPY | copybook | Date utility parameter record for CSUTLDTC call |
| CSUTLDWY | copybook | Date utility working-storage variables |
| UNUSED1Y | copybook | Unused placeholder copybook (no content referenced) |
| CCPAUERY | copybook | Authorization query record layout (IMS/DB2/MQ) |
| CCPAURLY | copybook | Authorization reply record layout (IMS/DB2/MQ) |
| CCPAURQY | copybook | Authorization request record layout (IMS/DB2/MQ) |
| CIPAUDTY | copybook | Authorization data type definitions (IMS/DB2/MQ) |
| CIPAUSMY | copybook | Authorization summary record layout (IMS/DB2/MQ) |
| IMSFUNCS | copybook | IMS function code constants |
| CSDB2RPY | copybook | DB2 response/reply record layout (transaction-type sub-app) |
| CSDB2RWY | copybook | DB2 response working-storage layout (transaction-type sub-app) |
| COPAU00 | copybook | Authorization BMS map 0 (screen layout) |
| COPAU01 | copybook | Authorization BMS map 1 (screen layout) |
| COTRTLI | copybook | Transaction type list BMS map (screen layout) |
| COTRTUP | copybook | Transaction type update BMS map (screen layout) |
