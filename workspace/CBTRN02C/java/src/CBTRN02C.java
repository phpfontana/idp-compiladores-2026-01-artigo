/**
 * CBTRN02C.java
 * Java translation of CBTRN02C.cbl (CardDemo batch transaction poster).
 *
 * Reads DALYTRAN (sequential 350-byte records), validates each transaction
 * against XREFFILE_SEQ and ACCTFILE_SEQ (sequential dumps of indexed files),
 * posts accepted transactions to TRANFILE_SEQ, rejects to DALYREJS,
 * updates ACCTFILE_SEQ_OUT and TCATBALF_SEQ_OUT.
 *
 * Environment variables consumed:
 *   DALYTRAN        - input sequential file (350 bytes/rec)
 *   XREFFILE_SEQ    - sequential dump of XREFFILE (50 bytes/rec)
 *   ACCTFILE_SEQ    - sequential dump of ACCTFILE (300 bytes/rec)
 *   TCATBALF_SEQ    - sequential dump of TCATBALF (50 bytes/rec)
 *   TRANFILE_SEQ    - output sequential TRANFILE (350 bytes/rec)
 *   DALYREJS        - output reject file (430 bytes/rec)
 *   ACCTFILE_SEQ_OUT - output sequential ACCTFILE after-state (300 bytes/rec)
 *   TCATBALF_SEQ_OUT - output sequential TCATBAL after-state (50 bytes/rec)
 *
 * Compile: javac -d out src/CBTRN02C.java
 * OpenJDK 21.0.11 LTS only. No external libraries.
 */

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.temporal.ChronoField;
import java.util.*;

public class CBTRN02C {

    // ---- Record sizes ----
    static final int DALYTRAN_LEN = 350;
    static final int XREF_LEN     = 50;
    static final int ACCT_LEN     = 300;
    static final int TCAT_LEN     = 50;
    static final int TRAN_LEN     = 350;
    static final int REJS_LEN     = 430;

    // ---- DALYTRAN-RECORD offsets ----
    static final int DT_ID         = 0;   // X(16)
    static final int DT_TYPE_CD    = 16;  // X(2)
    static final int DT_CAT_CD     = 18;  // 9(4) = 4 bytes display
    static final int DT_SOURCE     = 22;  // X(10)
    static final int DT_DESC       = 32;  // X(100)
    static final int DT_AMT        = 132; // S9(9)V99 DISPLAY = 11 bytes
    static final int DT_MERCHANT_ID= 143; // 9(9) = 9 bytes display
    static final int DT_MERCH_NAME = 152; // X(50)
    static final int DT_MERCH_CITY = 202; // X(50)
    static final int DT_MERCH_ZIP  = 252; // X(10)
    static final int DT_CARD_NUM   = 262; // X(16)
    static final int DT_ORIG_TS    = 278; // X(26)
    static final int DT_PROC_TS    = 304; // X(26)
    // FILLER X(20) at 330

    // ---- CARD-XREF-RECORD offsets (50 bytes) ----
    static final int XR_CARD_NUM   = 0;   // X(16)
    static final int XR_CUST_ID    = 16;  // 9(9) = 9 bytes
    static final int XR_ACCT_ID    = 25;  // 9(11) = 11 bytes
    // FILLER X(14) at 36

    // ---- ACCOUNT-RECORD offsets (300 bytes) ----
    static final int AC_ACCT_ID    = 0;   // 9(11)
    static final int AC_STATUS     = 11;  // X(1)
    static final int AC_CURR_BAL   = 12;  // S9(10)V99 = 12 bytes
    static final int AC_CREDIT_LIM = 24;  // S9(10)V99 = 12 bytes
    static final int AC_CASH_LIM   = 36;  // S9(10)V99 = 12 bytes
    static final int AC_OPEN_DATE  = 48;  // X(10)
    static final int AC_EXPIRY     = 58;  // X(10)
    static final int AC_REISSUE    = 68;  // X(10)
    static final int AC_CYC_CREDIT = 78;  // S9(10)V99 = 12 bytes
    static final int AC_CYC_DEBIT  = 90;  // S9(10)V99 = 12 bytes
    static final int AC_ADDR_ZIP   = 102; // X(10)
    static final int AC_GROUP_ID   = 112; // X(10)
    // FILLER X(178) at 122

    // ---- TRAN-CAT-BAL-RECORD offsets (50 bytes) ----
    static final int TC_ACCT_ID    = 0;   // 9(11)
    static final int TC_TYPE_CD    = 11;  // X(2)
    static final int TC_CAT_CD     = 13;  // 9(4) = 4 bytes
    static final int TC_BAL        = 17;  // S9(9)V99 = 11 bytes
    // FILLER X(22) at 28

    // ---- TRAN-RECORD offsets (same as DALYTRAN) ----
    static final int TR_ID         = 0;
    static final int TR_TYPE_CD    = 16;
    static final int TR_CAT_CD     = 18;
    static final int TR_SOURCE     = 22;
    static final int TR_DESC       = 32;
    static final int TR_AMT        = 132;
    static final int TR_MERCHANT_ID= 143;
    static final int TR_MERCH_NAME = 152;
    static final int TR_MERCH_CITY = 202;
    static final int TR_MERCH_ZIP  = 252;
    static final int TR_CARD_NUM   = 262;
    static final int TR_ORIG_TS    = 278;
    static final int TR_PROC_TS    = 304;

    // ---- REJECT-RECORD offsets (430 bytes) ----
    static final int RJ_TRAN_DATA  = 0;   // X(350) = copy of DALYTRAN record
    static final int RJ_REASON     = 350; // 9(4) = 4 bytes display
    static final int RJ_DESC       = 354; // X(76)

    // Validation reason codes
    static final int REASON_OK     = 0;
    static final int REASON_100    = 100; // card not found
    static final int REASON_101    = 101; // account not found
    static final int REASON_102    = 102; // overlimit
    static final int REASON_103    = 103; // expired

    // ---- Numeric encode/decode for S9(n)V99 DISPLAY ----

    /**
     * Read S9(n)V99 DISPLAY (len bytes) -> long in hundredths (cents).
     * COBOL DISPLAY signed numeric: if last byte >= 0x70, negative.
     */
    static long readSignedDisplay(byte[] rec, int off, int len) {
        int lastByte = rec[off + len - 1] & 0xFF;
        boolean negative = (lastByte >= 0x70);
        byte lastDigit = negative ? (byte)(lastByte - 0x40) : (byte)lastByte;
        long v = 0;
        for (int i = 0; i < len - 1; i++) {
            v = v * 10 + (rec[off + i] - '0');
        }
        v = v * 10 + (lastDigit - '0');
        return negative ? -v : v;
    }

    /**
     * Write S9(n)V99 DISPLAY (len bytes) from value in hundredths.
     * Fills all len bytes with digits. If negative, last byte gets +0x40.
     */
    static void writeSignedDisplay(byte[] rec, int off, int len, long valueHundredths) {
        boolean neg = valueHundredths < 0;
        long av = Math.abs(valueHundredths);
        for (int i = len - 1; i >= 0; i--) {
            rec[off + i] = (byte)('0' + av % 10);
            av /= 10;
        }
        if (neg) {
            rec[off + len - 1] += 0x40;
        }
    }

    /**
     * Read 9(n) DISPLAY unsigned -> long.
     */
    static long readUnsignedDisplay(byte[] rec, int off, int len) {
        long v = 0;
        for (int i = 0; i < len; i++) {
            v = v * 10 + (rec[off + i] - '0');
        }
        return v;
    }

    /**
     * Build DB2-format timestamp string from current wall clock.
     * Format: YYYY-MM-DD-HH.MM.SS.cc0000 (26 chars)
     * cc = centiseconds (milliseconds / 10)
     */
    static String getDb2Timestamp() {
        LocalDateTime now = LocalDateTime.now();
        int centiseconds = now.get(ChronoField.MILLI_OF_SECOND) / 10;
        return String.format("%04d-%02d-%02d-%02d.%02d.%02d.%02d0000",
            now.getYear(), now.getMonthValue(), now.getDayOfMonth(),
            now.getHour(), now.getMinute(), now.getSecond(),
            centiseconds);
    }

    /**
     * Copy bytes from src at srcOff (srcLen bytes) into dst at dstOff (dstLen bytes).
     * If srcLen < dstLen, pad with spaces. If srcLen > dstLen, truncate.
     */
    static void copyBytesSpacePad(byte[] dst, int dstOff, int dstLen,
                                   byte[] src, int srcOff, int srcLen) {
        int copy = Math.min(dstLen, srcLen);
        System.arraycopy(src, srcOff, dst, dstOff, copy);
        for (int i = copy; i < dstLen; i++) {
            dst[dstOff + i] = ' ';
        }
    }

    /**
     * Copy ASCII string (space-padded) into byte array at offset.
     */
    static void putString(byte[] rec, int off, int len, String s) {
        byte[] sb = s.getBytes(java.nio.charset.StandardCharsets.ISO_8859_1);
        int copy = Math.min(len, sb.length);
        System.arraycopy(sb, 0, rec, off, copy);
        for (int i = copy; i < len; i++) {
            rec[off + i] = ' ';
        }
    }

    /**
     * Get ASCII string from byte array.
     */
    static String getString(byte[] rec, int off, int len) {
        return new String(rec, off, len, java.nio.charset.StandardCharsets.ISO_8859_1);
    }

    public static void main(String[] args) throws IOException {
        System.out.println("START OF EXECUTION OF PROGRAM CBTRN02C");

        String dalytranPath    = System.getenv("DALYTRAN");
        String xrefSeqPath     = System.getenv("XREFFILE_SEQ");
        String acctSeqPath     = System.getenv("ACCTFILE_SEQ");
        String tcatSeqPath     = System.getenv("TCATBALF_SEQ");
        String tranfileSeqPath = System.getenv("TRANFILE_SEQ");
        String dalyrjsPath     = System.getenv("DALYREJS");
        String acctOutPath     = System.getenv("ACCTFILE_SEQ_OUT");
        String tcatOutPath     = System.getenv("TCATBALF_SEQ_OUT");

        // ---- Load XREFFILE into map: card-num(16) -> xref record(50) ----
        Map<String, byte[]> xrefMap = new LinkedHashMap<>();
        try (FileInputStream fis = new FileInputStream(xrefSeqPath)) {
            byte[] rec = new byte[XREF_LEN];
            int n;
            while ((n = fis.readNBytes(rec, 0, XREF_LEN)) == XREF_LEN) {
                String cardNum = getString(rec, XR_CARD_NUM, 16);
                xrefMap.put(cardNum, rec.clone());
            }
        }

        // ---- Load ACCTFILE into map: acct-id(11 chars) -> acct record(300) ----
        // Preserve insertion order so we can write back in original order
        Map<String, byte[]> acctMap = new LinkedHashMap<>();
        List<String> acctOrder = new ArrayList<>();
        try (FileInputStream fis = new FileInputStream(acctSeqPath)) {
            byte[] rec = new byte[ACCT_LEN];
            int n;
            while ((n = fis.readNBytes(rec, 0, ACCT_LEN)) == ACCT_LEN) {
                String acctId = getString(rec, AC_ACCT_ID, 11);
                acctMap.put(acctId, rec.clone());
                acctOrder.add(acctId);
            }
        }

        // ---- Load TCATBALF into map: 17-char key -> tcat record(50) ----
        // Key = acctId(11) + typeCd(2) + catCd(4)
        // Use TreeMap so iteration is in key-sorted order (matches indexed file output)
        Map<String, byte[]> tcatMap = new TreeMap<>();
        try (FileInputStream fis = new FileInputStream(tcatSeqPath)) {
            byte[] rec = new byte[TCAT_LEN];
            int n;
            while ((n = fis.readNBytes(rec, 0, TCAT_LEN)) == TCAT_LEN) {
                String key = getString(rec, TC_ACCT_ID, 11)
                           + getString(rec, TC_TYPE_CD, 2)
                           + getString(rec, TC_CAT_CD, 4);
                tcatMap.put(key, rec.clone());
            }
        }

        // ---- Open output files ----
        FileOutputStream tranOut  = new FileOutputStream(tranfileSeqPath);
        FileOutputStream rejsOut  = new FileOutputStream(dalyrjsPath);

        // ---- Process DALYTRAN ----
        long wsTransactionCount = 0;
        long wsRejectCount      = 0;

        try (FileInputStream dalytranIn = new FileInputStream(dalytranPath)) {
            byte[] dalytranRec = new byte[DALYTRAN_LEN];
            int n;

            while ((n = dalytranIn.readNBytes(dalytranRec, 0, DALYTRAN_LEN)) == DALYTRAN_LEN) {
                wsTransactionCount++;

                int  wsValidationFailReason = REASON_OK;
                String wsValidationFailDesc  = "";

                // ---- 1500-A-LOOKUP-XREF ----
                String cardNum = getString(dalytranRec, DT_CARD_NUM, 16);
                byte[] xrefRec = xrefMap.get(cardNum);

                if (xrefRec == null) {
                    // INVALID KEY -> reject 100
                    wsValidationFailReason = 100;
                    wsValidationFailDesc   = "INVALID CARD NUMBER FOUND";
                } else {
                    // ---- 1500-B-LOOKUP-ACCT ----
                    String xrefAcctId = getString(xrefRec, XR_ACCT_ID, 11);
                    byte[] acctRec    = acctMap.get(xrefAcctId);

                    if (acctRec == null) {
                        // INVALID KEY -> reject 101
                        wsValidationFailReason = 101;
                        wsValidationFailDesc   = "ACCOUNT RECORD NOT FOUND";
                    } else {
                        // Both checks run; last one wins if both fail

                        // ---- Check 1: credit limit ----
                        // COMPUTE WS-TEMP-BAL = ACCT-CURR-CYC-CREDIT
                        //                     - ACCT-CURR-CYC-DEBIT
                        //                     + DALYTRAN-AMT
                        long cycCredit = readSignedDisplay(acctRec, AC_CYC_CREDIT, 12);
                        long cycDebit  = readSignedDisplay(acctRec, AC_CYC_DEBIT,  12);
                        long dalytranAmt = readSignedDisplay(dalytranRec, DT_AMT, 11);
                        long wsTempBal = cycCredit - cycDebit + dalytranAmt;

                        long creditLimit = readSignedDisplay(acctRec, AC_CREDIT_LIM, 12);

                        if (creditLimit >= wsTempBal) {
                            // pass - no change
                        } else {
                            wsValidationFailReason = 102;
                            wsValidationFailDesc   = "OVERLIMIT TRANSACTION";
                        }

                        // ---- Check 2: expiry date ----
                        // IF ACCT-EXPIRAION-DATE >= DALYTRAN-ORIG-TS(1:10) -> CONTINUE
                        // ELSE -> reject 103
                        String expiryDate = getString(acctRec, AC_EXPIRY, 10);
                        String origTs10   = getString(dalytranRec, DT_ORIG_TS, 10);

                        if (expiryDate.compareTo(origTs10) >= 0) {
                            // pass - no change
                        } else {
                            wsValidationFailReason = 103;
                            wsValidationFailDesc   = "TRANSACTION RECEIVED AFTER ACCT EXPIRATION";
                        }

                        // ---- 2000-POST-TRANSACTION if no failure ----
                        if (wsValidationFailReason == REASON_OK) {
                            // Build TRAN-RECORD from DALYTRAN-RECORD fields.
                            // Initialize to 0x00 (IBM COBOL WS default) - FILLER stays as zeros.
                            byte[] tranRec = new byte[TRAN_LEN]; // Java default: all 0x00

                            // Copy all fields from DALYTRAN to TRAN
                            copyBytesSpacePad(tranRec, TR_ID,         16, dalytranRec, DT_ID,         16);
                            copyBytesSpacePad(tranRec, TR_TYPE_CD,     2, dalytranRec, DT_TYPE_CD,     2);
                            copyBytesSpacePad(tranRec, TR_CAT_CD,      4, dalytranRec, DT_CAT_CD,      4);
                            copyBytesSpacePad(tranRec, TR_SOURCE,     10, dalytranRec, DT_SOURCE,     10);
                            copyBytesSpacePad(tranRec, TR_DESC,      100, dalytranRec, DT_DESC,      100);
                            copyBytesSpacePad(tranRec, TR_AMT,        11, dalytranRec, DT_AMT,        11);
                            copyBytesSpacePad(tranRec, TR_MERCHANT_ID, 9, dalytranRec, DT_MERCHANT_ID, 9);
                            copyBytesSpacePad(tranRec, TR_MERCH_NAME, 50, dalytranRec, DT_MERCH_NAME, 50);
                            copyBytesSpacePad(tranRec, TR_MERCH_CITY, 50, dalytranRec, DT_MERCH_CITY, 50);
                            copyBytesSpacePad(tranRec, TR_MERCH_ZIP,  10, dalytranRec, DT_MERCH_ZIP,  10);
                            copyBytesSpacePad(tranRec, TR_CARD_NUM,   16, dalytranRec, DT_CARD_NUM,   16);
                            copyBytesSpacePad(tranRec, TR_ORIG_TS,    26, dalytranRec, DT_ORIG_TS,    26);

                            // Set TRAN-PROC-TS to current DB2 timestamp
                            String ts = getDb2Timestamp();
                            putString(tranRec, TR_PROC_TS, 26, ts);

                            // FILLER at 330 stays spaces (already filled)

                            // 2700-UPDATE-TCATBAL
                            String tcatKey = xrefAcctId
                                           + getString(dalytranRec, DT_TYPE_CD, 2)
                                           + getString(dalytranRec, DT_CAT_CD,  4);

                            byte[] tcatRec = tcatMap.get(tcatKey);
                            if (tcatRec == null) {
                                // 2700-A-CREATE-TCATBAL-REC
                                System.out.println("TCATBAL record not found for key : " + tcatKey + ".. Creating.");
                                // COBOL: INITIALIZE sets alphanumeric fields to spaces, numeric to 0.
                                // FILLER fields are NOT touched by INITIALIZE, so they stay at WS
                                // default (0x00). Java new byte[] is already all 0x00.
                                tcatRec = new byte[TCAT_LEN]; // 0x00 everywhere (FILLER stays 0x00)
                                // Fill alphanumeric key fields with spaces first, then write values
                                // (INITIALIZE of alphanumeric = spaces; key parts are PIC 9 which = 0)
                                putString(tcatRec, TC_ACCT_ID, 11, xrefAcctId);
                                copyBytesSpacePad(tcatRec, TC_TYPE_CD, 2, dalytranRec, DT_TYPE_CD, 2);
                                copyBytesSpacePad(tcatRec, TC_CAT_CD,  4, dalytranRec, DT_CAT_CD,  4);
                                // TRAN-CAT-BAL starts at 0, ADD DALYTRAN-AMT
                                long newBal = dalytranAmt; // 0 + amt
                                writeSignedDisplay(tcatRec, TC_BAL, 11, newBal);
                                // FILLER X(22) at offset 28 stays 0x00 (not touched)
                                tcatMap.put(tcatKey, tcatRec);
                            } else {
                                // 2700-B-UPDATE-TCATBAL-REC
                                long oldBal = readSignedDisplay(tcatRec, TC_BAL, 11);
                                long newBal = oldBal + dalytranAmt;
                                writeSignedDisplay(tcatRec, TC_BAL, 11, newBal);
                                // tcatRec is the same reference in the map - already updated
                            }

                            // 2800-UPDATE-ACCOUNT-REC
                            // ADD DALYTRAN-AMT TO ACCT-CURR-BAL
                            long currBal = readSignedDisplay(acctRec, AC_CURR_BAL, 12);
                            currBal += dalytranAmt;
                            writeSignedDisplay(acctRec, AC_CURR_BAL, 12, currBal);

                            if (dalytranAmt >= 0) {
                                // ADD DALYTRAN-AMT TO ACCT-CURR-CYC-CREDIT
                                long newCycCredit = readSignedDisplay(acctRec, AC_CYC_CREDIT, 12) + dalytranAmt;
                                writeSignedDisplay(acctRec, AC_CYC_CREDIT, 12, newCycCredit);
                            } else {
                                // ADD DALYTRAN-AMT TO ACCT-CURR-CYC-DEBIT
                                long newCycDebit = readSignedDisplay(acctRec, AC_CYC_DEBIT, 12) + dalytranAmt;
                                writeSignedDisplay(acctRec, AC_CYC_DEBIT, 12, newCycDebit);
                            }
                            // acctRec is reference in map - already updated

                            // 2900-WRITE-TRANSACTION-FILE
                            tranOut.write(tranRec);
                        }
                    }
                }

                // Write reject record if validation failed
                if (wsValidationFailReason != REASON_OK) {
                    wsRejectCount++;
                    // 2500-WRITE-REJECT-REC
                    byte[] rejRec = new byte[REJS_LEN];
                    Arrays.fill(rejRec, (byte)' ');

                    // Copy DALYTRAN-RECORD (350 bytes) into reject record
                    System.arraycopy(dalytranRec, 0, rejRec, RJ_TRAN_DATA, DALYTRAN_LEN);

                    // Write validation trailer: WS-VALIDATION-FAIL-REASON 9(4) + DESC X(76)
                    String reasonStr = String.format("%04d", wsValidationFailReason);
                    putString(rejRec, RJ_REASON, 4, reasonStr);
                    putString(rejRec, RJ_DESC,  76, wsValidationFailDesc);

                    rejsOut.write(rejRec);
                }
            }
        }

        tranOut.close();
        rejsOut.close();

        // ---- Write ACCTFILE_SEQ_OUT (in original order) ----
        try (FileOutputStream acctOut = new FileOutputStream(acctOutPath)) {
            for (String key : acctOrder) {
                acctOut.write(acctMap.get(key));
            }
        }

        // ---- Write TCATBALF_SEQ_OUT (sorted by key, matching indexed file sequential dump order) ----
        try (FileOutputStream tcatOut = new FileOutputStream(tcatOutPath)) {
            for (byte[] rec : tcatMap.values()) {
                tcatOut.write(rec);
            }
        }

        // ---- DISPLAY counts ----
        System.out.printf("TRANSACTIONS PROCESSED :%09d%n", wsTransactionCount);
        System.out.printf("TRANSACTIONS REJECTED  :%09d%n", wsRejectCount);
        System.out.println("END OF EXECUTION OF PROGRAM CBTRN02C");

        // Exit code 4 if rejections present
        if (wsRejectCount > 0) {
            System.exit(4);
        }
    }
}
