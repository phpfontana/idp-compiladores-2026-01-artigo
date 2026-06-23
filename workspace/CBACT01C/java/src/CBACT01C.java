import java.io.*;
import java.nio.charset.StandardCharsets;

/**
 * CBACT01C.java – Java translation of CBACT01C.CBL (CardDemo batch account processor).
 *
 * Translation strategy:
 *   - Input:  $ACCTFILE_SEQ  – flat sequential dump of the BDB indexed ACCTFILE,
 *             300-byte fixed records produced by DUMPSEQ.cbl.
 *   - Output: $OUTFILE  (107-byte flat sequential records)
 *             $ARRYFILE (110-byte flat sequential records)
 *             $VBRCFILE (variable-length records with 4-byte RDW header)
 *   - Stdout: GnuCOBOL DISPLAY output – matches golden_stdout.txt exactly
 *             (after stripping libcob warnings).
 *
 * Numeric encoding:
 *   DISPLAY S9(10)V99 (12 bytes):
 *     – positive: 12 ASCII digit bytes, all 0x30–0x39
 *     – negative: first 11 digit bytes normal, last byte = digit_byte + 0x40
 *     – DISPLAY output: 12 decoded digit chars + '+' or '-'
 *
 *   COMP-3 S9(10)V99 (7 bytes): packed BCD, 12 digits + sign nibble
 *     – positive sign nibble: 0x0C
 *     – negative sign nibble: 0x0D
 *
 * GnuCOBOL buffer persistence:
 *   OUT-ACCT-CURR-CYC-DEBIT (COMP-3) in the FD buffer is NOT re-initialized
 *   between WRITE calls.  Record 1 writes 2525.00 (sentinel); records 2 & 3
 *   also write 2525.00 because the buffer retains that value.
 *
 * CODATECN-0UT-DATE is 20 bytes initialised to 0x00 by GnuCOBOL.
 * COBDATFT fills bytes 0–7 with YYYYMMDD; bytes 8–19 remain 0x00.
 * OUT-ACCT-REISSUE-DATE = first 10 bytes = YYYYMMDD + 0x00 0x00.
 */
public class CBACT01C {

    // ----------------------------------------------------------------
    //  Constants
    // ----------------------------------------------------------------
    private static final int ACCT_RECORD_LEN = 300;

    // Field offsets / lengths in ACCOUNT-RECORD (input, 300 bytes)
    private static final int OFF_ACCT_ID              = 0;   // 9(11)
    private static final int OFF_ACCT_ACTIVE_STATUS   = 11;  // X(1)
    private static final int OFF_ACCT_CURR_BAL        = 12;  // S9(10)V99 DISPLAY 12
    private static final int OFF_ACCT_CREDIT_LIMIT    = 24;  // S9(10)V99 DISPLAY 12
    private static final int OFF_ACCT_CASH_CREDIT     = 36;  // S9(10)V99 DISPLAY 12
    private static final int OFF_ACCT_OPEN_DATE       = 48;  // X(10)
    private static final int OFF_ACCT_EXPIRAION_DATE  = 58;  // X(10)
    private static final int OFF_ACCT_REISSUE_DATE    = 68;  // X(10)
    private static final int OFF_ACCT_CYC_CREDIT      = 78;  // S9(10)V99 DISPLAY 12
    private static final int OFF_ACCT_CYC_DEBIT       = 90;  // S9(10)V99 DISPLAY 12
    private static final int OFF_ACCT_ADDR_ZIP        = 102; // X(10)
    private static final int OFF_ACCT_GROUP_ID        = 112; // X(10)

    // OUT-ACCT-REC field offsets (107 bytes total)
    private static final int OUT_ACCT_ID              = 0;   // 9(11)  11
    private static final int OUT_ACTIVE_STATUS        = 11;  // X(1)    1
    private static final int OUT_CURR_BAL             = 12;  // DISPLAY 12
    private static final int OUT_CREDIT_LIMIT         = 24;  // DISPLAY 12
    private static final int OUT_CASH_CREDIT          = 36;  // DISPLAY 12
    private static final int OUT_OPEN_DATE            = 48;  // X(10)  10
    private static final int OUT_EXPIRAION_DATE       = 58;  // X(10)  10
    private static final int OUT_REISSUE_DATE         = 68;  // X(10)  10
    private static final int OUT_CYC_CREDIT           = 78;  // DISPLAY 12
    private static final int OUT_CYC_DEBIT_COMP3      = 90;  // COMP-3   7
    private static final int OUT_GROUP_ID             = 97;  // X(10)  10
    private static final int OUT_RECORD_LEN           = 107;

    // ARR-ARRAY-REC field offsets (110 bytes total)
    // ARR-ACCT-ID: 0–10 (11 bytes)
    // ARR-ACCT-BAL(i): each occurrence = 12 (DISPLAY) + 7 (COMP-3) = 19 bytes
    //   BAL(1): 11–29
    //   BAL(2): 30–48
    //   BAL(3): 49–67
    //   BAL(4): 68–86
    //   BAL(5): 87–105
    // ARR-FILLER PIC X(4): 106–109
    private static final int ARR_ACCT_ID             = 0;
    private static final int ARR_RECORD_LEN          = 110;

    // COMP-3 2525.00: S9(10)V99, value = 252500 as integer
    private static final byte[] COMP3_2525_00 = packComp3(252500L, false);

    // COMP-3 constants for ARRYFILE
    private static final byte[] COMP3_1005_00  = packComp3(100500L, false);
    private static final byte[] COMP3_1525_00  = packComp3(152500L, false);
    private static final byte[] COMP3_2500_00N = packComp3(250000L, true);

    // Pre-encoded BAL(3) CURR-BAL constant: -1025.00 (DISPLAY S9(10)V99)
    private static final byte[] DISPLAY_NEG_1025_00 = encodeDisplaySigned(-102500L);

    // Pre-allocated RDW header for VBR records (reused per-iteration)
    private static final byte[] RDW_BUF = new byte[4];

    // ----------------------------------------------------------------
    //  Entry point
    // ----------------------------------------------------------------
    public static void main(String[] args) throws Exception {
        String acctFileSeq = System.getenv("ACCTFILE_SEQ");
        if (acctFileSeq == null) acctFileSeq = System.getenv("ACCTFILE");
        String outFilePath  = System.getenv("OUTFILE");
        String arryFilePath = System.getenv("ARRYFILE");
        String vbrcFilePath = System.getenv("VBRCFILE");

        if (acctFileSeq == null || outFilePath == null ||
                arryFilePath == null || vbrcFilePath == null) {
            System.err.println("Required env vars: ACCTFILE_SEQ (or ACCTFILE), OUTFILE, ARRYFILE, VBRCFILE");
            System.exit(1);
        }

        printlnRaw("START OF EXECUTION OF PROGRAM CBACT01C");

        // ---- Output buffers ----
        // outRecord persists between writes (GnuCOBOL FD buffer behaviour)
        byte[] outRecord  = new byte[OUT_RECORD_LEN];
        byte[] arrRecord  = new byte[ARR_RECORD_LEN];
        byte[] vbr1       = new byte[12];
        byte[] vbr2       = new byte[39];

        try (
            FileInputStream  fis  = new FileInputStream(acctFileSeq);
            FileOutputStream fout = new FileOutputStream(outFilePath);
            FileOutputStream farr = new FileOutputStream(arryFilePath);
            FileOutputStream fvbr = new FileOutputStream(vbrcFilePath)
        ) {
            byte[] acctRec = new byte[ACCT_RECORD_LEN];
            int bytesRead;

            while ((bytesRead = fis.read(acctRec)) == ACCT_RECORD_LEN) {

                // ---- 1100-DISPLAY-ACCT-RECORD ----
                display1100(acctRec);

                // ---- 1300-POPUL-ACCT-RECORD ----
                // Copy fields into outRecord
                System.arraycopy(acctRec, OFF_ACCT_ID,            outRecord, OUT_ACCT_ID,       11);
                outRecord[OUT_ACTIVE_STATUS] = acctRec[OFF_ACCT_ACTIVE_STATUS];
                System.arraycopy(acctRec, OFF_ACCT_CURR_BAL,      outRecord, OUT_CURR_BAL,       12);
                System.arraycopy(acctRec, OFF_ACCT_CREDIT_LIMIT,  outRecord, OUT_CREDIT_LIMIT,   12);
                System.arraycopy(acctRec, OFF_ACCT_CASH_CREDIT,   outRecord, OUT_CASH_CREDIT,    12);
                System.arraycopy(acctRec, OFF_ACCT_OPEN_DATE,     outRecord, OUT_OPEN_DATE,      10);
                System.arraycopy(acctRec, OFF_ACCT_EXPIRAION_DATE,outRecord, OUT_EXPIRAION_DATE, 10);

                // COBDATFT: convert ACCT-REISSUE-DATE (YYYY-MM-DD) -> YYYYMMDD + 0x00 0x00
                // Optimisation: write directly into outRecord to avoid byte[] allocation
                cobdatftInPlace(acctRec, OFF_ACCT_REISSUE_DATE, outRecord, OUT_REISSUE_DATE);

                // CURR-CYC-CREDIT (DISPLAY, copy as-is)
                System.arraycopy(acctRec, OFF_ACCT_CYC_CREDIT, outRecord, OUT_CYC_CREDIT, 12);

                // OUT-ACCT-CURR-CYC-DEBIT: write 2525.00 ONLY if input debit == 0
                // (buffer retains previous value if not overwritten)
                if (isDisplayZero(acctRec, OFF_ACCT_CYC_DEBIT)) {
                    System.arraycopy(COMP3_2525_00, 0, outRecord, OUT_CYC_DEBIT_COMP3, 7);
                }
                // else: buffer keeps whatever was previously written

                System.arraycopy(acctRec, OFF_ACCT_GROUP_ID, outRecord, OUT_GROUP_ID, 10);

                // ---- 1350-WRITE-ACCT-RECORD ----
                fout.write(outRecord);

                // ---- INITIALIZE ARR-ARRAY-REC ----
                initializeArrRecord(arrRecord);

                // ---- 1400-POPUL-ARRAY-RECORD ----
                // ARR-ACCT-ID
                System.arraycopy(acctRec, OFF_ACCT_ID, arrRecord, 0, 11);

                // BAL(1): CURR-BAL = ACCT-CURR-BAL, DEBIT = +1005.00
                System.arraycopy(acctRec, OFF_ACCT_CURR_BAL, arrRecord, 11, 12);
                System.arraycopy(COMP3_1005_00, 0, arrRecord, 23, 7);

                // BAL(2): CURR-BAL = ACCT-CURR-BAL, DEBIT = +1525.00
                System.arraycopy(acctRec, OFF_ACCT_CURR_BAL, arrRecord, 30, 12);
                System.arraycopy(COMP3_1525_00, 0, arrRecord, 42, 7);

                // BAL(3): CURR-BAL = -1025.00, DEBIT = -2500.00
                // Optimisation: use pre-encoded constant to avoid per-iteration allocation
                System.arraycopy(DISPLAY_NEG_1025_00, 0, arrRecord, 49, 12);
                System.arraycopy(COMP3_2500_00N, 0, arrRecord, 61, 7);

                // BAL(4), BAL(5): remain zero from INITIALIZE (already done)

                // ---- 1450-WRITE-ARRY-RECORD ----
                farr.write(arrRecord);

                // ---- INITIALIZE VBRC-REC1 ----
                // (not needed in Java - we populate directly)

                // ---- 1500-POPUL-VBRC-RECORD ----
                // VBR1: ACCT-ID (11) + ACTIVE-STATUS (1) = 12 bytes
                System.arraycopy(acctRec, OFF_ACCT_ID, vbr1, 0, 11);
                vbr1[11] = acctRec[OFF_ACCT_ACTIVE_STATUS];

                // VBR2: ACCT-ID (11) + CURR-BAL (12) + CREDIT-LIMIT (12) + REISSUE-YYYY (4) = 39 bytes
                System.arraycopy(acctRec, OFF_ACCT_ID, vbr2, 0, 11);
                System.arraycopy(acctRec, OFF_ACCT_CURR_BAL,     vbr2, 11, 12);
                System.arraycopy(acctRec, OFF_ACCT_CREDIT_LIMIT, vbr2, 23, 12);
                // WS-ACCT-REISSUE-YYYY = first 4 chars of ACCT-REISSUE-DATE (original, before COBDATFT)
                System.arraycopy(acctRec, OFF_ACCT_REISSUE_DATE, vbr2, 35, 4);

                // DISPLAY VBRC-REC1 and VBRC-REC2
                printRaw("VBRC-REC1:");
                printRaw(vbr1);
                printlnRaw("");
                printRaw("VBRC-REC2:");
                printRaw(vbr2);
                printlnRaw("");

                // DISPLAY ACCOUNT-RECORD (raw 300 bytes)
                printRaw(acctRec);
                printlnRaw("");

                // ---- 1550-WRITE-VB1-RECORD ----
                writeVbrRecord(fvbr, vbr1, 12);

                // ---- 1575-WRITE-VB2-RECORD ----
                writeVbrRecord(fvbr, vbr2, 39);
            }
        }

        printlnRaw("END OF EXECUTION OF PROGRAM CBACT01C");
        System.out.flush();
    }

    // ----------------------------------------------------------------
    //  COBDATFT inline: YYYY-MM-DD -> YYYYMMDD + 0x00 0x00
    //  Optimised form: writes directly into the destination buffer,
    //  avoiding a per-record byte[10] allocation.
    // ----------------------------------------------------------------
    private static void cobdatftInPlace(byte[] rec, int srcOff, byte[] dst, int dstOff) {
        // YYYY
        dst[dstOff]     = rec[srcOff];
        dst[dstOff + 1] = rec[srcOff + 1];
        dst[dstOff + 2] = rec[srcOff + 2];
        dst[dstOff + 3] = rec[srcOff + 3];
        // MM (skip '-' at srcOff+4)
        dst[dstOff + 4] = rec[srcOff + 5];
        dst[dstOff + 5] = rec[srcOff + 6];
        // DD (skip '-' at srcOff+7)
        dst[dstOff + 6] = rec[srcOff + 8];
        dst[dstOff + 7] = rec[srcOff + 9];
        // bytes 8-9: GnuCOBOL initialises CODATECN-0UT-DATE to 0x00
        // outRecord was allocated with new byte[] (zero-filled), and these
        // positions are only ever written by this function, so they remain 0x00.
        dst[dstOff + 8] = 0x00;
        dst[dstOff + 9] = 0x00;
    }

    // ----------------------------------------------------------------
    //  INITIALIZE ARR-ARRAY-REC
    //  - PIC 9(11) -> 0x30 * 11 (ASCII '0')
    //  - PIC S9(10)V99 DISPLAY -> 0x30 * 12
    //  - PIC S9(10)V99 COMP-3  -> 0x00*6 + 0x0C
    //  - PIC X(4) FILLER       -> 0x20 * 4 (spaces)
    // ----------------------------------------------------------------
    private static void initializeArrRecord(byte[] arr) {
        // ARR-ACCT-ID (9(11)): ASCII zeros
        for (int i = 0; i < 11; i++) arr[i] = 0x30;

        // 5 occurrences of ARR-ACCT-BAL (19 bytes each)
        for (int occ = 0; occ < 5; occ++) {
            int base = 11 + occ * 19;
            // ARR-ACCT-CURR-BAL (DISPLAY 12 bytes): ASCII zeros
            for (int i = 0; i < 12; i++) arr[base + i] = 0x30;
            // ARR-ACCT-CURR-CYC-DEBIT (COMP-3 7 bytes): +0
            for (int i = 0; i < 6; i++) arr[base + 12 + i] = 0x00;
            arr[base + 12 + 6] = 0x0C;
        }

        // ARR-FILLER PIC X(4): spaces
        arr[106] = 0x20;
        arr[107] = 0x20;
        arr[108] = 0x20;
        arr[109] = 0x20;
    }

    // ----------------------------------------------------------------
    //  Check whether a DISPLAY S9(10)V99 field is zero.
    //  Positive zero: all 12 bytes are 0x30.
    //  Negative zero is not expected here (GnuCOBOL MOVE 0 gives positive).
    // ----------------------------------------------------------------
    private static boolean isDisplayZero(byte[] rec, int offset) {
        for (int i = 0; i < 12; i++) {
            byte b = rec[offset + i];
            int digit;
            if (i == 11) {
                // Last byte may have overpunch
                if ((b & 0xFF) >= 0x70) {
                    digit = (b & 0xFF) - 0x40 - 0x30;
                } else {
                    digit = b - 0x30;
                }
            } else {
                digit = b - 0x30;
            }
            if (digit != 0) return false;
        }
        return true;
    }

    // ----------------------------------------------------------------
    //  Pack a non-negative integer value into 7-byte COMP-3 BCD.
    //  value = abs(displayInteger), negative = sign flag
    // ----------------------------------------------------------------
    private static byte[] packComp3(long value, boolean negative) {
        byte[] result = new byte[7];
        // 12 BCD digits + sign nibble = 13 nibbles = 7 bytes (with upper nibble of byte 0 = 0)
        // Store as 14 nibbles in 7 bytes: nibble 0 is high nibble of byte 0
        // Digits packed left to right, sign nibble in low nibble of byte 6
        //
        // For S9(10)V99: 12 decimal digits total
        // value already has the implied decimal scaled (e.g. 252500 for 2525.00)
        // We need 12 digits: leading zeros if needed
        // Packed as 7 bytes: byte[0] high = digit 0, byte[0] low = digit 1, ...
        //                    byte[5] high = digit 10, byte[5] low = digit 11,
        //                    byte[6] high = ... wait, 12 digits + sign = 13 nibbles
        // Standard BCD packing for odd number of digits with sign:
        // 12 digits need 6 bytes for digits (24 nibbles), sign in last nibble
        // BUT: with sign nibble, total 13 nibbles fits in 7 bytes (14 nibbles, 1 padding nibble)
        // Layout: [0000 D1][D2 D3][D4 D5][D6 D7][D8 D9][D10 D11][D12 SIGN]
        // where SIGN = 0xC (positive) or 0xD (negative)

        // Extract 12 digits
        long v = value;
        int[] digits = new int[12];
        for (int i = 11; i >= 0; i--) {
            digits[i] = (int)(v % 10);
            v /= 10;
        }

        // Pack: first byte has leading 0 nibble + digit[0]
        result[0] = (byte)(digits[0] & 0x0F);
        result[1] = (byte)((digits[1] << 4) | digits[2]);
        result[2] = (byte)((digits[3] << 4) | digits[4]);
        result[3] = (byte)((digits[5] << 4) | digits[6]);
        result[4] = (byte)((digits[7] << 4) | digits[8]);
        result[5] = (byte)((digits[9] << 4) | digits[10]);
        result[6] = (byte)((digits[11] << 4) | (negative ? 0x0D : 0x0C));

        return result;
    }

    // ----------------------------------------------------------------
    //  Encode a signed integer value as DISPLAY S9(10)V99 (12 bytes).
    //  value = scaled integer (already multiplied by 100).
    //  Positive: 12 ASCII digit bytes (0x30–0x39)
    //  Negative: first 11 bytes = digits 0x30–0x39, last byte = digit + 0x40
    // ----------------------------------------------------------------
    private static byte[] encodeDisplaySigned(long scaledValue) {
        byte[] result = new byte[12];
        boolean neg = scaledValue < 0;
        long v = Math.abs(scaledValue);

        // Fill digits right to left
        for (int i = 11; i >= 0; i--) {
            int digit = (int)(v % 10);
            v /= 10;
            result[i] = (byte)(0x30 + digit);
        }

        // Overpunch last byte for negative
        if (neg) {
            result[11] = (byte)((result[11] & 0xFF) + 0x40);
        }

        return result;
    }

    // ----------------------------------------------------------------
    //  Write a VBR record with 4-byte RDW header.
    //  RDW: 2-byte big-endian payload length + 2 zero bytes
    // ----------------------------------------------------------------
    private static void writeVbrRecord(FileOutputStream fos, byte[] payload, int len) throws IOException {
        // Optimisation: reuse pre-allocated RDW_BUF instead of allocating per call
        RDW_BUF[0] = (byte)((len >> 8) & 0xFF);
        RDW_BUF[1] = (byte)(len & 0xFF);
        RDW_BUF[2] = 0x00;
        RDW_BUF[3] = 0x00;
        fos.write(RDW_BUF);
        fos.write(payload, 0, len);
    }

    // ----------------------------------------------------------------
    //  DISPLAY helpers – write raw bytes to stdout without charset conversion
    //  GnuCOBOL DISPLAY appends a newline after each statement.
    // ----------------------------------------------------------------

    /** Print a string literal (ASCII safe) + newline */
    private static void printlnRaw(String s) throws IOException {
        System.out.write(s.getBytes(StandardCharsets.ISO_8859_1));
        System.out.write('\n');
    }

    /** Print a string literal (ASCII safe) without newline */
    private static void printRaw(String s) throws IOException {
        System.out.write(s.getBytes(StandardCharsets.ISO_8859_1));
    }

    /** Print raw bytes without newline */
    private static void printRaw(byte[] b) throws IOException {
        System.out.write(b);
    }

    // ----------------------------------------------------------------
    //  1100-DISPLAY-ACCT-RECORD
    //
    //  GnuCOBOL DISPLAY of PIC S9(10)V99 DISPLAY field renders as:
    //    <12 decoded digit chars><sign char>
    //  where sign char = '+' or '-', and negative last byte is decoded
    //  (subtract 0x40 from overpunched byte to get digit).
    // ----------------------------------------------------------------
    private static void display1100(byte[] rec) throws IOException {
        // ACCT-ID PIC 9(11): raw digits
        printRaw("ACCT-ID                 :");
        System.out.write(rec, OFF_ACCT_ID, 11);
        System.out.write('\n');

        // ACCT-ACTIVE-STATUS PIC X(1)
        printRaw("ACCT-ACTIVE-STATUS      :");
        System.out.write(rec[OFF_ACCT_ACTIVE_STATUS]);
        System.out.write('\n');

        // ACCT-CURR-BAL PIC S9(10)V99
        printRaw("ACCT-CURR-BAL           :");
        displaySignedNumeric(rec, OFF_ACCT_CURR_BAL);

        // ACCT-CREDIT-LIMIT PIC S9(10)V99
        printRaw("ACCT-CREDIT-LIMIT       :");
        displaySignedNumeric(rec, OFF_ACCT_CREDIT_LIMIT);

        // ACCT-CASH-CREDIT-LIMIT PIC S9(10)V99
        printRaw("ACCT-CASH-CREDIT-LIMIT  :");
        displaySignedNumeric(rec, OFF_ACCT_CASH_CREDIT);

        // ACCT-OPEN-DATE PIC X(10)
        printRaw("ACCT-OPEN-DATE          :");
        System.out.write(rec, OFF_ACCT_OPEN_DATE, 10);
        System.out.write('\n');

        // ACCT-EXPIRAION-DATE PIC X(10)
        printRaw("ACCT-EXPIRAION-DATE     :");
        System.out.write(rec, OFF_ACCT_EXPIRAION_DATE, 10);
        System.out.write('\n');

        // ACCT-REISSUE-DATE PIC X(10)
        printRaw("ACCT-REISSUE-DATE       :");
        System.out.write(rec, OFF_ACCT_REISSUE_DATE, 10);
        System.out.write('\n');

        // ACCT-CURR-CYC-CREDIT PIC S9(10)V99
        printRaw("ACCT-CURR-CYC-CREDIT    :");
        displaySignedNumeric(rec, OFF_ACCT_CYC_CREDIT);

        // ACCT-CURR-CYC-DEBIT PIC S9(10)V99
        printRaw("ACCT-CURR-CYC-DEBIT     :");
        displaySignedNumeric(rec, OFF_ACCT_CYC_DEBIT);

        // ACCT-GROUP-ID PIC X(10)
        printRaw("ACCT-GROUP-ID           :");
        System.out.write(rec, OFF_ACCT_GROUP_ID, 10);
        System.out.write('\n');

        // Separator (49 dashes)
        printlnRaw("-------------------------------------------------");
    }

    /**
     * DISPLAY a DISPLAY-format S9(10)V99 field (12 bytes).
     * GnuCOBOL decodes the overpunch on the last byte and appends '+' or '-'.
     */
    private static void displaySignedNumeric(byte[] rec, int offset) throws IOException {
        byte lastByte = rec[offset + 11];
        boolean negative = (lastByte & 0xFF) >= 0x70;

        // First 11 bytes: write as-is (they are ASCII digits)
        System.out.write(rec, offset, 11);

        // Last byte: decode the overpunch digit
        byte lastDigit;
        if (negative) {
            lastDigit = (byte)((lastByte & 0xFF) - 0x40);
        } else {
            lastDigit = lastByte;
        }
        System.out.write(lastDigit);

        // Sign character
        System.out.write(negative ? '-' : '+');
        System.out.write('\n');
    }
}
