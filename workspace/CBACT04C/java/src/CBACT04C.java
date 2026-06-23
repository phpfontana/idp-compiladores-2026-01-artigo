import java.io.*;
import java.nio.charset.Charset;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * CBACT04C - Interest Calculator
 *
 * Java translation of COBOL CBACT04C.CBL (CardDemo).
 * Reads sequential dumps of indexed files via environment variables.
 *
 * Environment variables:
 *   TCATBALF_SEQ   - 50-byte sequential dump of TCATBALF
 *   XREFFILE_SEQ   - 50-byte sequential dump of XREFFILE
 *   DISCGRP_SEQ    - 50-byte sequential dump of DISCGRP
 *   ACCTFILE_SEQ   - 300-byte sequential dump of ACCTFILE (input)
 *   TRANSACT       - 350-byte sequential transaction output
 *   ACCTFILE_SEQ_OUT - 300-byte sequential dump of ACCTFILE (after update)
 *
 * Command-line argument:
 *   args[0] = PARM-DATE (10 chars, e.g. "2026-06-17")
 */
public class CBACT04C {

    // ---------------------------------------------------------------
    // TCATBALF record layout (50 bytes)
    // TRANCAT-ACCT-ID  PIC 9(11) = 11 bytes at offset 0
    // TRANCAT-TYPE-CD  PIC X(02) =  2 bytes at offset 11
    // TRANCAT-CD       PIC 9(04) =  4 bytes at offset 13
    // TRAN-CAT-BAL     PIC S9(09)V99 = 11 bytes at offset 17 (DISPLAY)
    // FILLER           PIC X(22) = 22 bytes at offset 28
    static final int TCAT_REC_LEN = 50;
    static final int TCAT_ACCT_OFF = 0;
    static final int TCAT_ACCT_LEN = 11;
    static final int TCAT_TYPE_OFF = 11;
    static final int TCAT_TYPE_LEN = 2;
    static final int TCAT_CD_OFF = 13;
    static final int TCAT_CD_LEN = 4;
    static final int TCAT_BAL_OFF = 17;
    static final int TCAT_BAL_LEN = 11; // S9(09)V99 DISPLAY

    // ---------------------------------------------------------------
    // XREFFILE record layout (50 bytes)
    // XREF-CARD-NUM  PIC X(16) = 16 bytes at offset 0
    // XREF-CUST-ID   PIC 9(09) =  9 bytes at offset 16
    // XREF-ACCT-ID   PIC 9(11) = 11 bytes at offset 25
    // FILLER         PIC X(14) = 14 bytes at offset 36
    static final int XREF_REC_LEN = 50;
    static final int XREF_CARD_OFF = 0;
    static final int XREF_CARD_LEN = 16;
    static final int XREF_ACCT_OFF = 25;
    static final int XREF_ACCT_LEN = 11;

    // ---------------------------------------------------------------
    // DISCGRP record layout (50 bytes)
    // DIS-ACCT-GROUP-ID  PIC X(10) = 10 bytes at offset 0
    // DIS-TRAN-TYPE-CD   PIC X(02) =  2 bytes at offset 10
    // DIS-TRAN-CAT-CD    PIC 9(04) =  4 bytes at offset 12
    // DIS-INT-RATE       PIC S9(04)V99 DISPLAY = 6 bytes at offset 16
    // FILLER             PIC X(28) = 28 bytes at offset 22
    static final int DISCGRP_REC_LEN = 50;
    static final int DIS_GROUP_OFF = 0;
    static final int DIS_GROUP_LEN = 10;
    static final int DIS_TYPE_OFF = 10;
    static final int DIS_TYPE_LEN = 2;
    static final int DIS_CD_OFF = 12;
    static final int DIS_CD_LEN = 4;
    static final int DIS_RATE_OFF = 16;
    static final int DIS_RATE_LEN = 6; // S9(04)V99 DISPLAY

    // ---------------------------------------------------------------
    // ACCOUNT-RECORD layout (300 bytes)
    // ACCT-ID               PIC 9(11)       11 bytes at offset 0
    // ACCT-ACTIVE-STATUS    PIC X(01)        1 byte  at offset 11
    // ACCT-CURR-BAL         PIC S9(10)V99   12 bytes at offset 12  (DISPLAY)
    // ACCT-CREDIT-LIMIT     PIC S9(10)V99   12 bytes at offset 24
    // ACCT-CASH-CREDIT-LIMIT PIC S9(10)V99  12 bytes at offset 36
    // ACCT-OPEN-DATE        PIC X(10)       10 bytes at offset 48
    // ACCT-EXPIRAION-DATE   PIC X(10)       10 bytes at offset 58
    // ACCT-REISSUE-DATE     PIC X(10)       10 bytes at offset 68
    // ACCT-CURR-CYC-CREDIT  PIC S9(10)V99   12 bytes at offset 78
    // ACCT-CURR-CYC-DEBIT   PIC S9(10)V99   12 bytes at offset 90
    // ACCT-ADDR-ZIP         PIC X(10)       10 bytes at offset 102
    // ACCT-GROUP-ID         PIC X(10)       10 bytes at offset 112
    // FILLER                PIC X(178)     178 bytes at offset 122
    static final int ACCT_REC_LEN = 300;
    static final int ACCT_ID_OFF = 0;
    static final int ACCT_ID_LEN = 11;
    static final int ACCT_STATUS_OFF = 11;
    static final int ACCT_BAL_OFF = 12;
    static final int ACCT_BAL_LEN = 12; // S9(10)V99
    static final int ACCT_CREDIT_LIM_OFF = 24;
    static final int ACCT_CASH_LIM_OFF = 36;
    static final int ACCT_OPEN_DATE_OFF = 48;
    static final int ACCT_EXP_DATE_OFF = 58;
    static final int ACCT_REISSUE_DATE_OFF = 68;
    static final int ACCT_CYC_CREDIT_OFF = 78;
    static final int ACCT_CYC_CREDIT_LEN = 12;
    static final int ACCT_CYC_DEBIT_OFF = 90;
    static final int ACCT_CYC_DEBIT_LEN = 12;
    static final int ACCT_ADDR_ZIP_OFF = 102;
    static final int ACCT_GROUP_ID_OFF = 112;
    static final int ACCT_GROUP_ID_LEN = 10;

    // ---------------------------------------------------------------
    // TRAN-RECORD layout (350 bytes)
    // TRAN-ID           PIC X(16)       16 bytes at offset 0
    // TRAN-TYPE-CD      PIC X(02)        2 bytes at offset 16
    // TRAN-CAT-CD       PIC 9(04)        4 bytes at offset 18
    // TRAN-SOURCE       PIC X(10)       10 bytes at offset 22
    // TRAN-DESC         PIC X(100)     100 bytes at offset 32
    // TRAN-AMT          PIC S9(09)V99   11 bytes at offset 132 (DISPLAY)
    // TRAN-MERCHANT-ID  PIC 9(09)        9 bytes at offset 143
    // TRAN-MERCHANT-NAME PIC X(50)      50 bytes at offset 152
    // TRAN-MERCHANT-CITY PIC X(50)      50 bytes at offset 202
    // TRAN-MERCHANT-ZIP  PIC X(10)      10 bytes at offset 252
    // TRAN-CARD-NUM     PIC X(16)       16 bytes at offset 262
    // TRAN-ORIG-TS      PIC X(26)       26 bytes at offset 278
    // TRAN-PROC-TS      PIC X(26)       26 bytes at offset 304
    // FILLER            PIC X(20)       20 bytes at offset 330
    static final int TRAN_REC_LEN = 350;

    // Cached charset to avoid repeated static-field dereference in hot paths
    static final Charset LATIN1 = java.nio.charset.StandardCharsets.ISO_8859_1;

    // ---------------------------------------------------------------
    // State variables
    private final String parmDate;
    private final Map<String, byte[]> discgrpMap;   // key=16-char string -> 50-byte record
    private final Map<String, byte[]> xrefMap;       // key=11-char acctId -> 50-byte record
    private Map<String, byte[]> acctMap;             // key=11-char acctId -> 300-byte record (mutable)
    private final List<String> acctOrder;            // insertion order for output

    private long wsMonthlyInt;   // in hundredths (long)
    private long wsTotalInt;     // in hundredths (long)
    private int wsTranIdSuffix;
    private boolean wsFirstTime;
    private String wsLastAcctNum;
    private byte[] currentXrefCardNum;  // 16 bytes
    private byte[] currentAcctRecord;   // 300 bytes (current account loaded)

    public CBACT04C(String parmDate,
                    Map<String, byte[]> discgrpMap,
                    Map<String, byte[]> xrefMap,
                    Map<String, byte[]> acctMap,
                    List<String> acctOrder) {
        this.parmDate = parmDate;
        this.discgrpMap = discgrpMap;
        this.xrefMap = xrefMap;
        this.acctMap = acctMap;
        this.acctOrder = acctOrder;
        this.wsMonthlyInt = 0;
        this.wsTotalInt = 0;
        this.wsTranIdSuffix = 0;
        this.wsFirstTime = true;
        this.wsLastAcctNum = "           "; // 11 spaces
        this.currentXrefCardNum = new byte[16];
        this.currentAcctRecord = null;
    }

    /**
     * Run the main program logic.
     *
     * @param tcatRecords  list of 50-byte TCATBALF records (sequential)
     * @param tranOut      output stream for TRANSACT records
     * @return list of updated 300-byte account records in original order
     */
    public void run(List<byte[]> tcatRecords, OutputStream tranOut) throws IOException {

        System.out.println("START OF EXECUTION OF PROGRAM CBACT04C");

        boolean endOfFile = false;

        // The COBOL loop:
        // PERFORM UNTIL END-OF-FILE = 'Y'
        //   IF END-OF-FILE = 'N'
        //     PERFORM 1000-TCATBALF-GET-NEXT
        //     IF END-OF-FILE = 'N'
        //       ... process record ...
        //     END-IF
        //   ELSE
        //     PERFORM 1050-UPDATE-ACCOUNT  <- DEAD CODE
        //   END-IF
        // END-PERFORM
        //
        // The dead code bug: when GET-NEXT sets EOF='Y', inner IF is skipped,
        // outer loop re-evaluates, finds 'Y', exits. ELSE branch never runs.

        int recordIndex = 0;

        while (!endOfFile) {
            // IF END-OF-FILE = 'N'
            if (!endOfFile) {
                // PERFORM 1000-TCATBALF-GET-NEXT
                byte[] tcatRec;
                if (recordIndex < tcatRecords.size()) {
                    tcatRec = tcatRecords.get(recordIndex++);
                } else {
                    endOfFile = true;
                    tcatRec = null;
                }

                if (!endOfFile && tcatRec != null) {
                    // DISPLAY TRAN-CAT-BAL-RECORD
                    // The record is exactly 50 bytes; print as string
                    System.out.write(tcatRec);
                    System.out.println();
                    System.out.flush();

                    String tranAcctId = new String(tcatRec, TCAT_ACCT_OFF, TCAT_ACCT_LEN,
                                                    LATIN1);

                    if (!tranAcctId.equals(wsLastAcctNum)) {
                        if (!wsFirstTime) {
                            // PERFORM 1050-UPDATE-ACCOUNT
                            perform1050UpdateAccount();
                        } else {
                            wsFirstTime = false;
                        }
                        // MOVE 0 TO WS-TOTAL-INT
                        wsTotalInt = 0;
                        // MOVE TRANCAT-ACCT-ID TO WS-LAST-ACCT-NUM
                        wsLastAcctNum = tranAcctId;
                        // PERFORM 1100-GET-ACCT-DATA
                        perform1100GetAcctData(tranAcctId);
                        // PERFORM 1110-GET-XREF-DATA
                        perform1110GetXrefData(tranAcctId);
                    }

                    // Get account group from current account record
                    String acctGroupId = new String(currentAcctRecord, ACCT_GROUP_ID_OFF, ACCT_GROUP_ID_LEN,
                                                     LATIN1);
                    String tranTypeCd = new String(tcatRec, TCAT_TYPE_OFF, TCAT_TYPE_LEN,
                                                    LATIN1);
                    String tranCatCd = new String(tcatRec, TCAT_CD_OFF, TCAT_CD_LEN,
                                                   LATIN1);

                    // PERFORM 1200-GET-INTEREST-RATE
                    long disIntRate = perform1200GetInterestRate(acctGroupId, tranTypeCd, tranCatCd);

                    if (disIntRate != 0) {
                        // PERFORM 1300-COMPUTE-INTEREST
                        long tranCatBal = parseSigned9n2Display(tcatRec, TCAT_BAL_OFF, TCAT_BAL_LEN);
                        perform1300ComputeInterest(tranCatBal, disIntRate, tranAcctId, tranOut);
                        // PERFORM 1400-COMPUTE-FEES (stub - no-op)
                    }
                }
                // else: endOfFile became true, fall through
            }
            // else branch would be: PERFORM 1050-UPDATE-ACCOUNT (dead code)
        }

        System.out.println("END OF EXECUTION OF PROGRAM CBACT04C");
        System.out.flush();
    }

    /** 1050-UPDATE-ACCOUNT: add total interest to balance, zero cyc fields, rewrite */
    private void perform1050UpdateAccount() {
        if (currentAcctRecord == null) return;

        // ADD WS-TOTAL-INT TO ACCT-CURR-BAL
        long currentBal = parseSigned10n2Display(currentAcctRecord, ACCT_BAL_OFF, ACCT_BAL_LEN);
        long newBal = currentBal + wsTotalInt;
        formatSigned10n2Display(newBal, currentAcctRecord, ACCT_BAL_OFF, ACCT_BAL_LEN);

        // MOVE 0 TO ACCT-CURR-CYC-CREDIT
        formatSigned10n2Display(0, currentAcctRecord, ACCT_CYC_CREDIT_OFF, ACCT_CYC_CREDIT_LEN);
        // MOVE 0 TO ACCT-CURR-CYC-DEBIT
        formatSigned10n2Display(0, currentAcctRecord, ACCT_CYC_DEBIT_OFF, ACCT_CYC_DEBIT_LEN);

        // REWRITE: update the map
        acctMap.put(wsLastAcctNum, currentAcctRecord.clone());
    }

    /** 1100-GET-ACCT-DATA: load account record by key */
    private void perform1100GetAcctData(String acctId) {
        byte[] rec = acctMap.get(acctId);
        if (rec == null) {
            System.out.println("ACCOUNT NOT FOUND: " + acctId);
            currentAcctRecord = new byte[ACCT_REC_LEN];
            return;
        }
        currentAcctRecord = rec.clone();
    }

    /** 1110-GET-XREF-DATA: load xref card number by alternate key (acct ID) */
    private void perform1110GetXrefData(String acctId) {
        byte[] rec = xrefMap.get(acctId);
        if (rec == null) {
            System.out.println("ACCOUNT NOT FOUND: " + acctId);
            currentXrefCardNum = new byte[16];
            return;
        }
        // XREF-CARD-NUM is first 16 bytes
        currentXrefCardNum = Arrays.copyOfRange(rec, XREF_CARD_OFF, XREF_CARD_OFF + XREF_CARD_LEN);
    }

    /**
     * 1200-GET-INTEREST-RATE
     * Returns DIS-INT-RATE in hundredths (long).
     * On '23' (not found): print messages, try DEFAULT fallback.
     */
    private long perform1200GetInterestRate(String acctGroupId, String tranTypeCd, String tranCatCd) {
        String key = acctGroupId + tranTypeCd + tranCatCd;
        byte[] rec = discgrpMap.get(key);

        if (rec == null) {
            // DISCGRP-STATUS = '23' (record not found)
            System.out.println("DISCLOSURE GROUP RECORD MISSING");
            System.out.println("TRY WITH DEFAULT GROUP CODE");
            System.out.flush();

            // Try DEFAULT
            String defaultKey = "DEFAULT   " + tranTypeCd + tranCatCd;
            rec = discgrpMap.get(defaultKey);
            if (rec == null) {
                System.out.println("ERROR READING DEFAULT DISCLOSURE GROUP");
                System.exit(12);
            }
        }

        // DIS-INT-RATE: PIC S9(04)V99 DISPLAY at offset 16, 6 bytes
        return parseSigned4n2Display(rec, DIS_RATE_OFF, DIS_RATE_LEN);
    }

    /**
     * 1300-COMPUTE-INTEREST
     * WS-MONTHLY-INT = (TRAN-CAT-BAL * DIS-INT-RATE) / 1200
     * Using integer hundredths arithmetic.
     */
    private void perform1300ComputeInterest(long tranCatBalHundredths, long disIntRateHundredths,
                                             String acctId, OutputStream tranOut) throws IOException {
        // Both values are in hundredths.
        // Formula: monthly_int = (bal * rate) / 1200
        // Where bal is in hundredths and rate is annual % in hundredths
        // So: monthly_int_hundredths = (bal_hundredths * rate_hundredths) / (1200 * 100)
        long monthlyIntHundredths = (tranCatBalHundredths * disIntRateHundredths) / (1200L * 100L);
        wsMonthlyInt = monthlyIntHundredths;
        wsTotalInt += monthlyIntHundredths;

        // PERFORM 1300-B-WRITE-TX
        perform1300BWriteTx(acctId, tranOut);
    }

    /**
     * 1300-B-WRITE-TX: build and write TRAN-RECORD (350 bytes)
     */
    private void perform1300BWriteTx(String acctId, OutputStream tranOut) throws IOException {
        wsTranIdSuffix++;

        byte[] tranRec = new byte[TRAN_REC_LEN];
        // Initialize to zeros (matches COBOL WORKING-STORAGE initialized to low-values/zeros)
        // Note: COBOL WS fields for numeric (PIC 9...) initialize to zero ('0' in DISPLAY),
        // but STRING verb fills only up to the pointer, leaving rest untouched from WS init.
        // From golden: TRAN-DESC has null bytes after text, FILLER is null bytes.
        // TRAN-MERCHANT-NAME/CITY/ZIP are spaces (from MOVE SPACES).
        // So we start with zeros, then fill in the fields.

        // TRAN-ID (0-15): PARM-DATE (10) + right-justified 6-digit suffix
        // STRING PARM-DATE, WS-TRANID-SUFFIX DELIMITED BY SIZE INTO TRAN-ID
        // PARM-DATE is 10 chars, WS-TRANID-SUFFIX is PIC 9(06) = 6 digits
        String tranId = parmDate + String.format("%06d", wsTranIdSuffix);
        byte[] tranIdBytes = tranId.getBytes(LATIN1);
        System.arraycopy(tranIdBytes, 0, tranRec, 0, Math.min(16, tranIdBytes.length));

        // TRAN-TYPE-CD (16-17): '01'
        tranRec[16] = '0';
        tranRec[17] = '1';

        // TRAN-CAT-CD (18-21): MOVE '05' TO TRAN-CAT-CD
        // TRAN-CAT-CD is PIC 9(04) = 4 bytes DISPLAY
        // COBOL MOVE '05' to PIC 9(04): right-justified, zero-filled -> '0005'
        tranRec[18] = '0';
        tranRec[19] = '0';
        tranRec[20] = '0';
        tranRec[21] = '5';

        // TRAN-SOURCE (22-31): MOVE 'System' TO TRAN-SOURCE (PIC X(10))
        // 'System' is 6 chars, rest is spaces (COBOL MOVE X to X pads with spaces on right)
        byte[] sourceBytes = "System    ".getBytes(LATIN1);
        System.arraycopy(sourceBytes, 0, tranRec, 22, 10);

        // TRAN-DESC (32-131): STRING 'Int. for a/c ', ACCT-ID DELIMITED BY SIZE INTO TRAN-DESC
        // ACCT-ID is from ACCOUNT-RECORD (PIC 9(11)), which holds the 11-digit account ID
        // STRING fills from left, rest remains as initialized (zeros in WS)
        String descStr = "Int. for a/c " + acctId;
        byte[] descBytes = descStr.getBytes(LATIN1);
        // Only copy up to 100 bytes; rest stays as zeros (from array initialization)
        System.arraycopy(descBytes, 0, tranRec, 32, Math.min(100, descBytes.length));

        // TRAN-AMT (132-142): WS-MONTHLY-INT as S9(09)V99 DISPLAY = 11 bytes
        formatSigned9n2Display(wsMonthlyInt, tranRec, 132, 11);

        // TRAN-MERCHANT-ID (143-151): MOVE 0 TO TRAN-MERCHANT-ID (PIC 9(09))
        // Zero = '000000000'
        Arrays.fill(tranRec, 143, 152, (byte) '0');

        // TRAN-MERCHANT-NAME (152-201): MOVE SPACES -> 50 spaces
        Arrays.fill(tranRec, 152, 202, (byte) ' ');

        // TRAN-MERCHANT-CITY (202-251): MOVE SPACES -> 50 spaces
        Arrays.fill(tranRec, 202, 252, (byte) ' ');

        // TRAN-MERCHANT-ZIP (252-261): MOVE SPACES -> 10 spaces
        Arrays.fill(tranRec, 252, 262, (byte) ' ');

        // TRAN-CARD-NUM (262-277): XREF-CARD-NUM (16 bytes)
        System.arraycopy(currentXrefCardNum, 0, tranRec, 262, 16);

        // TRAN-ORIG-TS (278-303): DB2 format timestamp (26 bytes)
        // TRAN-PROC-TS (304-329): same timestamp
        byte[] ts = getDb2Timestamp();
        System.arraycopy(ts, 0, tranRec, 278, 26);
        System.arraycopy(ts, 0, tranRec, 304, 26);

        // FILLER (330-349): 20 bytes, stays as zeros from initialization

        tranOut.write(tranRec);
    }

    /**
     * Generate DB2 format timestamp: YYYY-MM-DD-HH.MM.SS.mm0000 (26 chars)
     * COB-MIL = centiseconds (2 digits from FUNCTION CURRENT-DATE positions 15-16)
     */
    private byte[] getDb2Timestamp() {
        LocalDateTime now = LocalDateTime.now();
        // FUNCTION CURRENT-DATE returns: YYYYMMDDHHmmSSCC...
        // COB-YYYY=4, COB-MM=2, COB-DD=2, COB-HH=2, COB-MIN=2, COB-SS=2, COB-MIL=2
        // DB2 format: YYYY-MM-DD-HH.MM.SS.mm0000
        String ts = String.format("%04d-%02d-%02d-%02d.%02d.%02d.%02d0000",
                now.getYear(), now.getMonthValue(), now.getDayOfMonth(),
                now.getHour(), now.getMinute(), now.getSecond(),
                (now.getNano() / 10_000_000)); // centiseconds
        return ts.getBytes(LATIN1);
    }

    // ---------------------------------------------------------------
    // Numeric parsing / formatting helpers
    // ---------------------------------------------------------------

    /**
     * Parse S9(09)V99 DISPLAY (11 bytes) -> long (hundredths)
     * Positive: digits '00000001000' = 1000 hundredths = 10.00
     * COBOL S9(n)V99 DISPLAY positive: pure ASCII digits.
     * Negative: last byte has overpunch (+0x40), but we only have positive in test data.
     */
    private long parseSigned9n2Display(byte[] buf, int off, int len) {
        // Check for negative overpunch on last byte
        byte lastByte = buf[off + len - 1];
        boolean negative = false;
        byte lastDigit = lastByte;

        // COBOL positive overpunch: none (just digit)
        // COBOL negative overpunch for DISPLAY: last digit byte += 0x40
        // Digits 0-9: 0x30-0x39. Overpunched negative: 0x70-0x79
        if (lastByte >= 0x70 && lastByte <= 0x79) {
            negative = true;
            lastDigit = (byte) (lastByte - 0x40);
        }

        long value = 0;
        for (int i = 0; i < len - 1; i++) {
            value = value * 10 + (buf[off + i] - '0');
        }
        value = value * 10 + (lastDigit - '0');

        return negative ? -value : value;
    }

    /**
     * Parse S9(10)V99 DISPLAY (12 bytes) -> long (hundredths)
     */
    private long parseSigned10n2Display(byte[] buf, int off, int len) {
        byte lastByte = buf[off + len - 1];
        boolean negative = false;
        byte lastDigit = lastByte;

        if (lastByte >= 0x70 && lastByte <= 0x79) {
            negative = true;
            lastDigit = (byte) (lastByte - 0x40);
        }

        long value = 0;
        for (int i = 0; i < len - 1; i++) {
            value = value * 10 + (buf[off + i] - '0');
        }
        value = value * 10 + (lastDigit - '0');

        return negative ? -value : value;
    }

    /**
     * Parse S9(04)V99 DISPLAY (6 bytes) -> long (hundredths)
     * E.g. '001200' = 1200 hundredths = 12.00%
     */
    private long parseSigned4n2Display(byte[] buf, int off, int len) {
        byte lastByte = buf[off + len - 1];
        boolean negative = false;
        byte lastDigit = lastByte;

        if (lastByte >= 0x70 && lastByte <= 0x79) {
            negative = true;
            lastDigit = (byte) (lastByte - 0x40);
        }

        long value = 0;
        for (int i = 0; i < len - 1; i++) {
            value = value * 10 + (buf[off + i] - '0');
        }
        value = value * 10 + (lastDigit - '0');

        return negative ? -value : value;
    }

    /**
     * Format long (hundredths) as S9(09)V99 DISPLAY (11 bytes)
     * Positive: pure ASCII digits.
     * Negative: last digit byte += 0x40 (overpunch).
     */
    private void formatSigned9n2Display(long hundredths, byte[] buf, int off, int len) {
        boolean negative = hundredths < 0;
        long abs = Math.abs(hundredths);

        // Fill right to left
        for (int i = len - 1; i >= 0; i--) {
            buf[off + i] = (byte) ('0' + (abs % 10));
            abs /= 10;
        }

        if (negative) {
            // Overpunch last byte
            buf[off + len - 1] += 0x40;
        }
    }

    /**
     * Format long (hundredths) as S9(10)V99 DISPLAY (12 bytes)
     */
    private void formatSigned10n2Display(long hundredths, byte[] buf, int off, int len) {
        boolean negative = hundredths < 0;
        long abs = Math.abs(hundredths);

        for (int i = len - 1; i >= 0; i--) {
            buf[off + i] = (byte) ('0' + (abs % 10));
            abs /= 10;
        }

        if (negative) {
            buf[off + len - 1] += 0x40;
        }
    }

    // ---------------------------------------------------------------
    // Static helpers for loading files
    // ---------------------------------------------------------------

    private static List<byte[]> loadSequentialFile(String path, int recLen) throws IOException {
        List<byte[]> records = new ArrayList<>();
        byte[] fileData = Files.readAllBytes(Paths.get(path));
        for (int i = 0; i + recLen <= fileData.length; i += recLen) {
            records.add(Arrays.copyOfRange(fileData, i, i + recLen));
        }
        return records;
    }

    // ---------------------------------------------------------------
    // main
    // ---------------------------------------------------------------

    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.err.println("Usage: CBACT04C <PARM-DATE>");
            System.exit(1);
        }
        String parmDate = args[0];

        // Read environment variables for file paths
        String tcatbalfSeqPath   = System.getenv("TCATBALF_SEQ");
        String xreffileSeqPath   = System.getenv("XREFFILE_SEQ");
        String discgrpSeqPath    = System.getenv("DISCGRP_SEQ");
        String acctfileSeqPath   = System.getenv("ACCTFILE_SEQ");
        String transactPath      = System.getenv("TRANSACT");
        String acctfileSeqOutPath = System.getenv("ACCTFILE_SEQ_OUT");

        if (tcatbalfSeqPath == null) { System.err.println("Missing TCATBALF_SEQ"); System.exit(1); }
        if (xreffileSeqPath == null) { System.err.println("Missing XREFFILE_SEQ"); System.exit(1); }
        if (discgrpSeqPath == null)  { System.err.println("Missing DISCGRP_SEQ");  System.exit(1); }
        if (acctfileSeqPath == null) { System.err.println("Missing ACCTFILE_SEQ"); System.exit(1); }
        if (transactPath == null)    { System.err.println("Missing TRANSACT");     System.exit(1); }
        if (acctfileSeqOutPath == null) { System.err.println("Missing ACCTFILE_SEQ_OUT"); System.exit(1); }

        // Load TCATBALF (sequential, 50-byte records)
        List<byte[]> tcatRecords = loadSequentialFile(tcatbalfSeqPath, TCAT_REC_LEN);

        // Load XREFFILE (sequential, 50-byte records) into map keyed by ACCT-ID (11 chars)
        Map<String, byte[]> xrefMap = new LinkedHashMap<>();
        for (byte[] rec : loadSequentialFile(xreffileSeqPath, XREF_REC_LEN)) {
            String acctId = new String(rec, XREF_ACCT_OFF, XREF_ACCT_LEN,
                                       LATIN1);
            xrefMap.put(acctId, rec);
        }

        // Load DISCGRP (sequential, 50-byte records) into map keyed by 16-char key
        Map<String, byte[]> discgrpMap = new LinkedHashMap<>();
        for (byte[] rec : loadSequentialFile(discgrpSeqPath, DISCGRP_REC_LEN)) {
            // Key = DIS-ACCT-GROUP-ID(10) + DIS-TRAN-TYPE-CD(2) + DIS-TRAN-CAT-CD(4) = 16 chars
            String key = new String(rec, DIS_GROUP_OFF, DIS_GROUP_LEN + DIS_TYPE_LEN + DIS_CD_LEN,
                                    LATIN1);
            discgrpMap.put(key, rec);
        }

        // Load ACCTFILE (sequential, 300-byte records) into map keyed by ACCT-ID (11 chars)
        Map<String, byte[]> acctMap = new LinkedHashMap<>();
        List<String> acctOrder = new ArrayList<>();
        for (byte[] rec : loadSequentialFile(acctfileSeqPath, ACCT_REC_LEN)) {
            String acctId = new String(rec, ACCT_ID_OFF, ACCT_ID_LEN,
                                       LATIN1);
            acctMap.put(acctId, rec);
            acctOrder.add(acctId);
        }

        // Open output files
        try (FileOutputStream transactOut = new FileOutputStream(transactPath)) {
            // Run the program
            CBACT04C prog = new CBACT04C(parmDate, discgrpMap, xrefMap, acctMap, acctOrder);
            prog.run(tcatRecords, transactOut);

            // Write ACCTFILE_SEQ_OUT: account records in original order
            try (FileOutputStream acctOut = new FileOutputStream(acctfileSeqOutPath)) {
                for (String acctId : acctOrder) {
                    byte[] rec = acctMap.get(acctId);
                    if (rec != null) {
                        acctOut.write(rec);
                    }
                }
            }
        }
    }
}
