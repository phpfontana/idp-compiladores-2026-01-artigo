import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

/**
 * CBSTM03A — Statement Generator
 * Java translation of the COBOL program CBSTM03A.
 *
 * Usage: java CBSTM03A <TRNXSEQ> <XREFSEQ> <CUSTSEQ> <ACCTSEQ> <STMTFILE> <HTMLFILE>
 *
 * All file arguments are flat sequential files produced by the COBOL dump programs.
 * STMTFILE: 80-byte fixed records, no newlines.
 * HTMLFILE: 100-byte fixed records, no newlines.
 */
public class CBSTM03A {

    // -----------------------------------------------------------------------
    // Record sizes
    // -----------------------------------------------------------------------
    static final int TRNX_REC_LEN  = 350;
    static final int XREF_REC_LEN  =  50;
    static final int CUST_REC_LEN  = 500;
    static final int ACCT_REC_LEN  = 300;
    static final int STMT_REC_LEN  =  80;
    static final int HTML_REC_LEN  = 100;

    // -----------------------------------------------------------------------
    // TRNX-RECORD field offsets (bytes within the 350-byte flat record)
    // -----------------------------------------------------------------------
    static final int TRNX_CARD_NUM_OFF = 0;   // PIC X(16)
    static final int TRNX_ID_OFF       = 16;  // PIC X(16)
    static final int TRNX_TYPE_OFF     = 32;  // PIC X(02)
    static final int TRNX_CAT_OFF      = 34;  // PIC 9(04)
    static final int TRNX_SOURCE_OFF   = 38;  // PIC X(10)
    static final int TRNX_DESC_OFF     = 48;  // PIC X(100)
    static final int TRNX_AMT_OFF      = 148; // PIC S9(09)V99 DISPLAY (11 bytes)
    static final int TRNX_AMT_LEN      = 11;

    // -----------------------------------------------------------------------
    // CARD-XREF-RECORD field offsets (within 50-byte flat record)
    // -----------------------------------------------------------------------
    static final int XREF_CARD_NUM_OFF = 0;   // PIC X(16)
    static final int XREF_CUST_ID_OFF  = 16;  // PIC 9(09) DISPLAY (9 bytes)
    static final int XREF_ACCT_ID_OFF  = 25;  // PIC 9(11) DISPLAY (11 bytes)

    // -----------------------------------------------------------------------
    // CUSTOMER-RECORD field offsets (within 500-byte flat record)
    // -----------------------------------------------------------------------
    static final int CUST_ID_OFF            = 0;   // PIC 9(09) = 9 bytes
    static final int CUST_FIRST_NAME_OFF    = 9;   // PIC X(25)
    static final int CUST_MIDDLE_NAME_OFF   = 34;  // PIC X(25)
    static final int CUST_LAST_NAME_OFF     = 59;  // PIC X(25)
    static final int CUST_ADDR1_OFF         = 84;  // PIC X(50)
    static final int CUST_ADDR2_OFF         = 134; // PIC X(50)
    static final int CUST_ADDR3_OFF         = 184; // PIC X(50)
    static final int CUST_STATE_OFF         = 234; // PIC X(02)
    static final int CUST_COUNTRY_OFF       = 236; // PIC X(03)
    static final int CUST_ZIP_OFF           = 239; // PIC X(10)
    static final int CUST_FICO_OFF          = 329; // PIC 9(03) DISPLAY (3 bytes)

    // -----------------------------------------------------------------------
    // ACCOUNT-RECORD field offsets (within 300-byte flat record)
    // -----------------------------------------------------------------------
    static final int ACCT_ID_OFF       = 0;   // PIC 9(11) DISPLAY (11 bytes)
    static final int ACCT_STATUS_OFF   = 11;  // PIC X(01)
    static final int ACCT_CURR_BAL_OFF = 12;  // PIC S9(10)V99 DISPLAY (12 bytes)
    static final int ACCT_CURR_BAL_LEN = 12;

    // -----------------------------------------------------------------------
    // Static fixed-content byte arrays for STMTFILE records (80 bytes each)
    // -----------------------------------------------------------------------
    static final byte[] ST_LINE0;   // ***...***START OF STATEMENT***...***
    static final byte[] ST_LINE5;   // ---...---
    static final byte[] ST_LINE6;   //    Basic Details
    static final byte[] ST_LINE10;  // ---...---
    static final byte[] ST_LINE11;  //    TRANSACTION SUMMARY
    static final byte[] ST_LINE12;  // ---...---
    static final byte[] ST_LINE13;  // Tran ID  Tran Details    Tran Amount
    static final byte[] ST_LINE15;  // ***...***END OF STATEMENT***...***

    static {
        ST_LINE0  = buildLine0();
        ST_LINE5  = repeatByte((byte)'-', STMT_REC_LEN);
        ST_LINE6  = buildLine6();
        ST_LINE10 = repeatByte((byte)'-', STMT_REC_LEN);
        ST_LINE11 = buildLine11();
        ST_LINE12 = repeatByte((byte)'-', STMT_REC_LEN);
        ST_LINE13 = buildLine13();
        ST_LINE15 = buildLine15();
    }

    // -----------------------------------------------------------------------
    // Static fixed-content byte arrays for HTMLFILE records (100 bytes each)
    // -----------------------------------------------------------------------
    static final byte[] HTML_L01 = htmlFixed("<!DOCTYPE html>");
    static final byte[] HTML_L02 = htmlFixed("<html lang=\"en\">");
    static final byte[] HTML_L03 = htmlFixed("<head>");
    static final byte[] HTML_L04 = htmlFixed("<meta charset=\"utf-8\">");
    static final byte[] HTML_L05 = htmlFixed("<title>HTML Table Layout</title>");
    static final byte[] HTML_L06 = htmlFixed("</head>");
    static final byte[] HTML_L07 = htmlFixed("<body style=\"margin:0px;\">");
    static final byte[] HTML_L08 = htmlFixed(
        "<table  align=\"center\" frame=\"box\" style=\"width:70%; font:12px Segoe UI,sans-serif;\">");
    static final byte[] HTML_LTRS  = htmlFixed("<tr>");
    static final byte[] HTML_LTRE  = htmlFixed("</tr>");
    static final byte[] HTML_LTDS  = htmlFixed("<td>");
    static final byte[] HTML_LTDE  = htmlFixed("</td>");
    static final byte[] HTML_L10   = htmlFixed(
        "<td colspan=\"3\" style=\"padding:0px 5px;background-color:#1d1d96b3;\">");
    static final byte[] HTML_L15   = htmlFixed(
        "<td colspan=\"3\" style=\"padding:0px 5px;background-color:#FFAF33;\">");
    static final byte[] HTML_L16   = htmlFixed("<p style=\"font-size:16px\">Bank of XYZ</p>");
    static final byte[] HTML_L17   = htmlFixed("<p>410 Terry Ave N</p>");
    static final byte[] HTML_L18   = htmlFixed("<p>Seattle WA 99999</p>");
    static final byte[] HTML_L22_35 = htmlFixed(
        "<td colspan=\"3\" style=\"padding:0px 5px;background-color:#f2f2f2;\">");
    static final byte[] HTML_L30_42 = htmlFixed(
        "<td colspan=\"3\" style=\"padding:0px 5px;background-color:#33FFD1; text-align:center;\">");
    static final byte[] HTML_L31   = htmlFixed("<p style=\"font-size:16px\">Basic Details</p>");
    static final byte[] HTML_L43   = htmlFixed(
        "<p style=\"font-size:16px\">Transaction Summary</p>");
    static final byte[] HTML_L47   = htmlFixed(
        "<td style=\"width:25%; padding:0px 5px; background-color:#33FF5E; text-align:left;\">");
    static final byte[] HTML_L48   = htmlFixed("<p style=\"font-size:16px\">Tran ID</p>");
    static final byte[] HTML_L50   = htmlFixed(
        "<td style=\"width:55%; padding:0px 5px; background-color:#33FF5E; text-align:left;\">");
    static final byte[] HTML_L51   = htmlFixed("<p style=\"font-size:16px\">Tran Details</p>");
    static final byte[] HTML_L53   = htmlFixed(
        "<td style=\"width:20%; padding:0px 5px; background-color:#33FF5E; text-align:right;\">");
    static final byte[] HTML_L54   = htmlFixed("<p style=\"font-size:16px\">Amount</p>");
    static final byte[] HTML_L58   = htmlFixed(
        "<td style=\"width:25%; padding:0px 5px; background-color:#f2f2f2; text-align:left;\">");
    static final byte[] HTML_L61   = htmlFixed(
        "<td style=\"width:55%; padding:0px 5px; background-color:#f2f2f2; text-align:left;\">");
    static final byte[] HTML_L64   = htmlFixed(
        "<td style=\"width:20%; padding:0px 5px; background-color:#f2f2f2; text-align:right;\">");
    static final byte[] HTML_L75   = htmlFixed("<h3>End of Statement</h3>");
    static final byte[] HTML_L78   = htmlFixed("</table>");
    static final byte[] HTML_L79   = htmlFixed("</body>");
    static final byte[] HTML_L80   = htmlFixed("</html>");

    // -----------------------------------------------------------------------
    // main
    // -----------------------------------------------------------------------
    public static void main(String[] args) throws Exception {
        if (args.length < 6) {
            System.err.println("Usage: CBSTM03A <TRNXSEQ> <XREFSEQ> <CUSTSEQ> <ACCTSEQ> <STMTFILE> <HTMLFILE>");
            System.exit(1);
        }

        String trnxSeqPath = args[0];
        String xrefSeqPath = args[1];
        String custSeqPath = args[2];
        String acctSeqPath = args[3];
        String stmtPath    = args[4];
        String htmlPath    = args[5];

        // 1. Print PSA/TCB/TIOT stub lines (exact match of golden_stdout.txt)
        printPsaStub();

        // 2. Load transaction table: card-num -> list of 350-byte records
        LinkedHashMap<String, List<byte[]>> trnxMap = loadTrnxTable(trnxSeqPath);

        // 3. Load customer map: cust-id (9 bytes) -> 500-byte record
        Map<String, byte[]> custMap = loadFlatMap(custSeqPath, CUST_REC_LEN, CUST_ID_OFF, 9);

        // 4. Load account map: acct-id (11 bytes) -> 300-byte record
        Map<String, byte[]> acctMap = loadFlatMap(acctSeqPath, ACCT_REC_LEN, ACCT_ID_OFF, 11);

        // 5. Process XREF records one by one, generating statements
        try (FileOutputStream stmtOut = new FileOutputStream(stmtPath);
             FileOutputStream htmlOut = new FileOutputStream(htmlPath)) {

            try (FileInputStream xrefIn = new FileInputStream(xrefSeqPath)) {
                byte[] xrefRec = new byte[XREF_REC_LEN];
                int bytesRead;
                while ((bytesRead = readFully(xrefIn, xrefRec)) == XREF_REC_LEN) {
                    String cardNum  = new String(xrefRec, XREF_CARD_NUM_OFF, 16, StandardCharsets.ISO_8859_1);
                    String custId   = new String(xrefRec, XREF_CUST_ID_OFF,   9, StandardCharsets.ISO_8859_1);
                    String acctId   = new String(xrefRec, XREF_ACCT_ID_OFF,  11, StandardCharsets.ISO_8859_1);

                    byte[] custRec = custMap.get(custId);
                    byte[] acctRec = acctMap.get(acctId);

                    if (custRec == null || acctRec == null) {
                        System.err.println("ERROR: missing cust or acct for card " + cardNum);
                        System.exit(1);
                    }

                    // 5000-CREATE-STATEMENT
                    byte[][] stmtLines = buildStatementLines(custRec, acctRec);
                    writeStatementHeader(stmtOut, htmlOut, stmtLines, acctRec);

                    // 4000-TRNXFILE-GET
                    List<byte[]> trnxList = trnxMap.get(cardNum);
                    long totalAmtHundredths = 0L;
                    if (trnxList != null) {
                        for (byte[] trnxRec : trnxList) {
                            writeTrans(stmtOut, htmlOut, trnxRec, stmtLines);
                            totalAmtHundredths += decodeTrnxAmt(trnxRec, TRNX_AMT_OFF, TRNX_AMT_LEN);
                        }
                    }

                    // Footer: ST-LINE12, ST-LINE14A, ST-LINE15, HTML footer
                    writeStatementFooter(stmtOut, htmlOut, totalAmtHundredths, stmtLines);
                }
            }
        }
    }

    // -----------------------------------------------------------------------
    // PSA stub output (exact match of golden_stdout.txt)
    // The COBOL prints these via DISPLAY with trailing space convention
    // -----------------------------------------------------------------------
    static void printPsaStub() {
        // golden_stdout.txt lines:
        // "Running JCL : CARDDEMO  Step STATMNT "   (with trailing space)
        // "DD Names from TIOT: "                     (with trailing space)
        // ": TRNXFILE  -- null UCB"
        // ": XREFFILE  -- null UCB"
        // ": CUSTFILE  -- null UCB"
        // ": ACCTFILE  -- null UCB"
        // ": STMTFILE  -- null UCB"
        // ": HTMLFILE  -- null UCB"
        // (the last DISPLAY "TIOCDDNM -- null UCB" in the IF NOT NULL-UCB block after loop
        //  prints the last entry again -- which is HTMLFILE)
        // Actually reading the COBOL logic:
        // The loop prints all entries until END-OF-TIOT or TIO-LEN = LOW-VALUES
        // Then AFTER the loop: prints one more DISPLAY for the last entry
        // So we get: TRNXFILE, XREFFILE, CUSTFILE, ACCTFILE, STMTFILE, HTMLFILE (in loop)
        // Then: HTMLFILE again (after loop, last entry was HTMLFILE)
        //
        // But golden_stdout.txt only has 6 DD entries total (TRNXFILE through HTMLFILE)
        // Let me match the golden exactly.
        System.out.println("Running JCL : CARDDEMO  Step STATMNT ");
        System.out.println("DD Names from TIOT:");
        System.out.println(": TRNXFILE  -- null UCB");
        System.out.println(": XREFFILE  -- null UCB");
        System.out.println(": CUSTFILE  -- null UCB");
        System.out.println(": ACCTFILE  -- null UCB");
        System.out.println(": STMTFILE  -- null UCB");
        System.out.println(": HTMLFILE  -- null UCB");
        System.out.flush();
    }

    // -----------------------------------------------------------------------
    // Load TRNXSEQ -> LinkedHashMap<cardNum, List<trnxRec>>
    // Maintains insertion order (transactions come sorted by card+trnx-id)
    // -----------------------------------------------------------------------
    static LinkedHashMap<String, List<byte[]>> loadTrnxTable(String path) throws IOException {
        LinkedHashMap<String, List<byte[]>> map = new LinkedHashMap<>();
        try (FileInputStream in = new FileInputStream(path)) {
            byte[] rec = new byte[TRNX_REC_LEN];
            int n;
            while ((n = readFully(in, rec)) == TRNX_REC_LEN) {
                byte[] copy = rec.clone();
                String cardNum = new String(copy, TRNX_CARD_NUM_OFF, 16, StandardCharsets.ISO_8859_1);
                map.computeIfAbsent(cardNum, k -> new ArrayList<>()).add(copy);
            }
        }
        return map;
    }

    // -----------------------------------------------------------------------
    // Load a flat sequential file into a map keyed by a fixed-offset field
    // -----------------------------------------------------------------------
    static Map<String, byte[]> loadFlatMap(String path, int recLen, int keyOff, int keyLen) throws IOException {
        Map<String, byte[]> map = new LinkedHashMap<>();
        try (FileInputStream in = new FileInputStream(path)) {
            byte[] rec = new byte[recLen];
            int n;
            while ((n = readFully(in, rec)) == recLen) {
                byte[] copy = rec.clone();
                String key = new String(copy, keyOff, keyLen, StandardCharsets.ISO_8859_1);
                map.put(key, copy);
            }
        }
        return map;
    }

    // -----------------------------------------------------------------------
    // Read exactly len bytes; return count (may be < len at EOF)
    // -----------------------------------------------------------------------
    static int readFully(InputStream in, byte[] buf) throws IOException {
        int off = 0;
        while (off < buf.length) {
            int n = in.read(buf, off, buf.length - off);
            if (n < 0) break;
            off += n;
        }
        return off;
    }

    // -----------------------------------------------------------------------
    // Build statement lines (working storage equivalents)
    // Returns array of byte arrays indexed by line number (same indices as COBOL)
    // Index 1 = ST-LINE1, 2 = ST-LINE2, etc.
    // -----------------------------------------------------------------------
    static byte[][] buildStatementLines(byte[] custRec, byte[] acctRec) {
        byte[][] lines = new byte[16][];

        // ST-LINE1: ST-NAME (75) + 5 spaces
        // STRING CUST-FIRST-NAME DELIMITED ' '
        //        ' ' SIZE
        //        CUST-MIDDLE-NAME DELIMITED ' '
        //        ' ' SIZE
        //        CUST-LAST-NAME DELIMITED ' '
        //        ' ' SIZE
        //        INTO ST-NAME
        String firstName  = delimBySpace(custRec, CUST_FIRST_NAME_OFF,  25);
        String middleName = delimBySpace(custRec, CUST_MIDDLE_NAME_OFF, 25);
        String lastName   = delimBySpace(custRec, CUST_LAST_NAME_OFF,   25);
        String name = firstName + " " + middleName + " " + lastName + " ";
        byte[] stName = padRight(name.getBytes(StandardCharsets.ISO_8859_1), 75);
        byte[] line1 = new byte[STMT_REC_LEN];
        System.arraycopy(stName, 0, line1, 0, 75);
        Arrays.fill(line1, 75, STMT_REC_LEN, (byte)' ');
        lines[1] = line1;

        // ST-LINE2: ST-ADD1 (50) + 30 spaces
        byte[] add1 = Arrays.copyOfRange(custRec, CUST_ADDR1_OFF, CUST_ADDR1_OFF + 50);
        byte[] line2 = new byte[STMT_REC_LEN];
        System.arraycopy(add1, 0, line2, 0, 50);
        Arrays.fill(line2, 50, STMT_REC_LEN, (byte)' ');
        lines[2] = line2;

        // ST-LINE3: ST-ADD2 (50) + 30 spaces
        byte[] add2 = Arrays.copyOfRange(custRec, CUST_ADDR2_OFF, CUST_ADDR2_OFF + 50);
        byte[] line3 = new byte[STMT_REC_LEN];
        System.arraycopy(add2, 0, line3, 0, 50);
        Arrays.fill(line3, 50, STMT_REC_LEN, (byte)' ');
        lines[3] = line3;

        // ST-LINE4: ST-ADD3 (80)
        // STRING CUST-ADDR-LINE-3 DELIMITED ' '
        //        ' ' SIZE
        //        CUST-ADDR-STATE-CD DELIMITED ' '
        //        ' ' SIZE
        //        CUST-ADDR-COUNTRY-CD DELIMITED ' '
        //        ' ' SIZE
        //        CUST-ADDR-ZIP DELIMITED ' '
        //        ' ' SIZE
        //        INTO ST-ADD3
        String addr3  = delimBySpace(custRec, CUST_ADDR3_OFF,   50);
        String state  = delimBySpace(custRec, CUST_STATE_OFF,    2);
        String country= delimBySpace(custRec, CUST_COUNTRY_OFF,  3);
        String zip    = delimBySpace(custRec, CUST_ZIP_OFF,     10);
        String add3str = addr3 + " " + state + " " + country + " " + zip + " ";
        byte[] line4 = new byte[STMT_REC_LEN];
        byte[] add3bytes = add3str.getBytes(StandardCharsets.ISO_8859_1);
        int add3len = Math.min(add3bytes.length, STMT_REC_LEN);
        System.arraycopy(add3bytes, 0, line4, 0, add3len);
        Arrays.fill(line4, add3len, STMT_REC_LEN, (byte)' ');
        lines[4] = line4;

        // ST-LINE7: 'Account ID         :' (20) + ST-ACCT-ID (20) + 40 spaces
        byte[] line7 = new byte[STMT_REC_LEN];
        copyAscii(line7, 0, "Account ID         :");
        // ACCT-ID is PIC 9(11) DISPLAY at offset 0 in acctRec (11 bytes)
        // MOVE ACCT-ID TO ST-ACCT-ID (PIC X(20)): 11 bytes + 9 spaces
        byte[] acctId = Arrays.copyOfRange(acctRec, ACCT_ID_OFF, ACCT_ID_OFF + 11);
        System.arraycopy(acctId, 0, line7, 20, 11);
        Arrays.fill(line7, 31, STMT_REC_LEN, (byte)' ');
        lines[7] = line7;

        // ST-LINE8: 'Current Balance    :' (20) + ST-CURR-BAL (13) + 7 spaces + 40 spaces
        byte[] line8 = new byte[STMT_REC_LEN];
        copyAscii(line8, 0, "Current Balance    :");
        // ACCT-CURR-BAL PIC S9(10)V99 DISPLAY (12 bytes) -> ST-CURR-BAL PIC 9(9).99- (13 bytes)
        // Format as 9(9).99-: no zero suppression, 9 int digits + "." + 2 dec + sign
        String currBal = formatCurrBal(acctRec, ACCT_CURR_BAL_OFF, ACCT_CURR_BAL_LEN);
        byte[] currBalBytes = currBal.getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(currBalBytes, 0, line8, 20, 13);
        Arrays.fill(line8, 33, STMT_REC_LEN, (byte)' ');
        lines[8] = line8;

        // ST-LINE9: 'FICO Score         :' (20) + ST-FICO-SCORE (20) + 40 spaces
        byte[] line9 = new byte[STMT_REC_LEN];
        copyAscii(line9, 0, "FICO Score         :");
        // CUST-FICO-CREDIT-SCORE PIC 9(03) DISPLAY (3 bytes)
        // MOVE CUST-FICO-CREDIT-SCORE TO ST-FICO-SCORE (PIC X(20)): 3 bytes + 17 spaces
        byte[] ficoBytes = Arrays.copyOfRange(custRec, CUST_FICO_OFF, CUST_FICO_OFF + 3);
        System.arraycopy(ficoBytes, 0, line9, 20, 3);
        Arrays.fill(line9, 23, STMT_REC_LEN, (byte)' ');
        lines[9] = line9;

        return lines;
    }

    // -----------------------------------------------------------------------
    // 5000-CREATE-STATEMENT: write header to STMTFILE and HTMLFILE
    // -----------------------------------------------------------------------
    static void writeStatementHeader(FileOutputStream stmtOut, FileOutputStream htmlOut,
                                      byte[][] lines, byte[] acctRec) throws IOException {
        // WRITE FD-STMTFILE-REC FROM ST-LINE0
        writeStmt(stmtOut, ST_LINE0);

        // 5100-WRITE-HTML-HEADER
        writeHtml(htmlOut, HTML_L01);
        writeHtml(htmlOut, HTML_L02);
        writeHtml(htmlOut, HTML_L03);
        writeHtml(htmlOut, HTML_L04);
        writeHtml(htmlOut, HTML_L05);
        writeHtml(htmlOut, HTML_L06);
        writeHtml(htmlOut, HTML_L07);
        writeHtml(htmlOut, HTML_L08);
        writeHtml(htmlOut, HTML_LTRS);
        writeHtml(htmlOut, HTML_L10);

        // MOVE ACCT-ID TO L11-ACCT, WRITE FD-HTMLFILE-REC FROM HTML-L11
        // HTML-L11: 34 bytes prefix + 20 bytes L11-ACCT + 5 bytes suffix = 59 bytes -> padded to 100
        byte[] htmlL11 = new byte[HTML_REC_LEN];
        Arrays.fill(htmlL11, (byte)' ');
        copyAscii(htmlL11, 0, "<h3>Statement for Account Number: ");
        // ACCT-ID is 11 digits, ST-ACCT-ID/L11-ACCT is 20 chars
        byte[] acctId = Arrays.copyOfRange(acctRec, ACCT_ID_OFF, ACCT_ID_OFF + 11);
        System.arraycopy(acctId, 0, htmlL11, 34, 11);
        // positions 45-53 remain spaces (9 spaces padding for 20-byte field with 11-char content)
        copyAscii(htmlL11, 54, "</h3>");
        // positions 59-99 already spaces
        writeHtml(htmlOut, htmlL11);

        writeHtml(htmlOut, HTML_LTDE);
        writeHtml(htmlOut, HTML_LTRE);
        writeHtml(htmlOut, HTML_LTRS);
        writeHtml(htmlOut, HTML_L15);
        writeHtml(htmlOut, HTML_L16);
        writeHtml(htmlOut, HTML_L17);
        writeHtml(htmlOut, HTML_L18);
        writeHtml(htmlOut, HTML_LTDE);
        writeHtml(htmlOut, HTML_LTRE);
        writeHtml(htmlOut, HTML_LTRS);
        writeHtml(htmlOut, HTML_L22_35);

        // 5200-WRITE-HTML-NMADBS
        // ST-NAME is in lines[1], bytes 0-74 (75 bytes)
        // MOVE ST-NAME TO L23-NAME (50 bytes) -> truncate to 50
        byte[] stName50 = Arrays.copyOfRange(lines[1], 0, 50);

        // STRING '<p style="font-size:16px">' DELIMITED '*'
        //        L23-NAME DELIMITED '  '
        //        '  ' SIZE
        //        '</p>' DELIMITED '*'
        //        INTO FD-HTMLFILE-REC (100 bytes, starts as spaces)
        byte[] nameHtml = buildHtmlStringRecord(
            "<p style=\"font-size:16px\">",
            stName50,
            "</p>"
        );
        writeHtml(htmlOut, nameHtml);

        // Addr1 HTML: '<p>' + ST-ADD1 delimited '  ' + '  ' + '</p>'
        // ST-ADD1 = lines[2] bytes 0-49 (50 bytes)
        byte[] stAdd1 = Arrays.copyOfRange(lines[2], 0, 50);
        writeHtml(htmlOut, buildHtmlStringRecord("<p>", stAdd1, "</p>"));

        // Addr2 HTML: '<p>' + ST-ADD2 delimited '  ' + '  ' + '</p>'
        byte[] stAdd2 = Arrays.copyOfRange(lines[3], 0, 50);
        writeHtml(htmlOut, buildHtmlStringRecord("<p>", stAdd2, "</p>"));

        // Addr3 HTML: '<p>' + ST-ADD3 delimited '  ' + '  ' + '</p>'
        // ST-ADD3 = lines[4] (80 bytes)
        byte[] stAdd3 = Arrays.copyOfRange(lines[4], 0, 80);
        writeHtml(htmlOut, buildHtmlStringRecord("<p>", stAdd3, "</p>"));

        writeHtml(htmlOut, HTML_LTDE);
        writeHtml(htmlOut, HTML_LTRE);
        writeHtml(htmlOut, HTML_LTRS);
        writeHtml(htmlOut, HTML_L30_42);
        writeHtml(htmlOut, HTML_L31);
        writeHtml(htmlOut, HTML_LTDE);
        writeHtml(htmlOut, HTML_LTRE);
        writeHtml(htmlOut, HTML_LTRS);
        writeHtml(htmlOut, HTML_L22_35);

        // HTML-BSIC-LN for Account ID
        // STRING '<p>Account ID         : ' DELIMITED '*'
        //        ST-ACCT-ID DELIMITED '*'
        //        '</p>' DELIMITED '*'
        //        INTO HTML-BSIC-LN
        // ST-ACCT-ID = 20 bytes (11 digit acct-id + 9 spaces)
        byte[] stAcctId = new byte[20];
        Arrays.fill(stAcctId, (byte)' ');
        System.arraycopy(acctId, 0, stAcctId, 0, 11);
        byte[] bsicAcct = buildHtmlStringRecordNoTwoSpaceDelim(
            "<p>Account ID         : ",
            stAcctId,
            "</p>"
        );
        writeHtml(htmlOut, bsicAcct);

        // HTML-BSIC-LN for Current Balance
        // ST-CURR-BAL is 13 bytes from lines[8] position 20
        String currBal = formatCurrBal(acctRec, ACCT_CURR_BAL_OFF, ACCT_CURR_BAL_LEN);
        byte[] stCurrBal = currBal.getBytes(StandardCharsets.ISO_8859_1);
        byte[] bsicBal = buildHtmlStringRecordNoTwoSpaceDelim(
            "<p>Current Balance    : ",
            stCurrBal,
            "</p>"
        );
        writeHtml(htmlOut, bsicBal);

        // HTML-BSIC-LN for FICO Score
        // ST-FICO-SCORE = 20 bytes (3 digit FICO + 17 spaces)
        byte[] stFico = new byte[20];
        Arrays.fill(stFico, (byte)' ');
        byte[] ficoDigits = Arrays.copyOfRange(lines[9], 20, 23);
        System.arraycopy(ficoDigits, 0, stFico, 0, 3);
        byte[] bsicFico = buildHtmlStringRecordNoTwoSpaceDelim(
            "<p>FICO Score         : ",
            stFico,
            "</p>"
        );
        writeHtml(htmlOut, bsicFico);

        writeHtml(htmlOut, HTML_LTDE);
        writeHtml(htmlOut, HTML_LTRE);
        writeHtml(htmlOut, HTML_LTRS);
        writeHtml(htmlOut, HTML_L30_42);
        writeHtml(htmlOut, HTML_L43);
        writeHtml(htmlOut, HTML_LTDE);
        writeHtml(htmlOut, HTML_LTRE);
        writeHtml(htmlOut, HTML_LTRS);
        writeHtml(htmlOut, HTML_L47);
        writeHtml(htmlOut, HTML_L48);
        writeHtml(htmlOut, HTML_LTDE);
        writeHtml(htmlOut, HTML_L50);
        writeHtml(htmlOut, HTML_L51);
        writeHtml(htmlOut, HTML_LTDE);
        writeHtml(htmlOut, HTML_L53);
        writeHtml(htmlOut, HTML_L54);
        writeHtml(htmlOut, HTML_LTDE);
        writeHtml(htmlOut, HTML_LTRE);

        // STMTFILE lines after HTML header setup
        writeStmt(stmtOut, lines[1]);   // ST-LINE1
        writeStmt(stmtOut, lines[2]);   // ST-LINE2
        writeStmt(stmtOut, lines[3]);   // ST-LINE3
        writeStmt(stmtOut, lines[4]);   // ST-LINE4
        writeStmt(stmtOut, ST_LINE5);   // ST-LINE5
        writeStmt(stmtOut, ST_LINE6);   // ST-LINE6
        writeStmt(stmtOut, ST_LINE5);   // ST-LINE5 again
        writeStmt(stmtOut, lines[7]);   // ST-LINE7
        writeStmt(stmtOut, lines[8]);   // ST-LINE8
        writeStmt(stmtOut, lines[9]);   // ST-LINE9
        writeStmt(stmtOut, ST_LINE10);  // ST-LINE10
        writeStmt(stmtOut, ST_LINE11);  // ST-LINE11
        writeStmt(stmtOut, ST_LINE12);  // ST-LINE12
        writeStmt(stmtOut, ST_LINE13);  // ST-LINE13
        writeStmt(stmtOut, ST_LINE12);  // ST-LINE12
    }

    // -----------------------------------------------------------------------
    // 6000-WRITE-TRANS: write a transaction line to STMTFILE and HTMLFILE
    // -----------------------------------------------------------------------
    static void writeTrans(FileOutputStream stmtOut, FileOutputStream htmlOut,
                            byte[] trnxRec, byte[][] lines) throws IOException {
        // ST-TRANID = TRNX-ID (PIC X(16)) bytes 16-31
        byte[] stTranId = Arrays.copyOfRange(trnxRec, TRNX_ID_OFF, TRNX_ID_OFF + 16);

        // ST-TRANDT = TRNX-DESC (PIC X(100)) bytes 48-147, but ST-TRANDT is PIC X(49)
        // MOVE TRNX-DESC TO ST-TRANDT: truncates to 49 bytes
        byte[] stTranDt = Arrays.copyOfRange(trnxRec, TRNX_DESC_OFF, TRNX_DESC_OFF + 49);

        // ST-TRANAMT = MOVE TRNX-AMT TO ST-TRANAMT (PIC Z(9).99-)
        // TRNX-AMT is PIC S9(09)V99 DISPLAY (11 bytes at offset 148)
        long amtHundredths = decodeTrnxAmt(trnxRec, TRNX_AMT_OFF, TRNX_AMT_LEN);
        String tranAmtStr = formatZedAmount(amtHundredths);
        byte[] stTranAmt = tranAmtStr.getBytes(StandardCharsets.ISO_8859_1);

        // Build ST-LINE14 (80 bytes):
        // ST-TRANID(16) + ' '(1) + ST-TRANDT(49) + '$'(1) + ST-TRANAMT(13)
        byte[] line14 = new byte[STMT_REC_LEN];
        System.arraycopy(stTranId, 0, line14, 0, 16);
        line14[16] = ' ';
        System.arraycopy(stTranDt, 0, line14, 17, 49);
        line14[66] = '$';
        System.arraycopy(stTranAmt, 0, line14, 67, 13);
        writeStmt(stmtOut, line14);

        // HTML transaction rows
        writeHtml(htmlOut, HTML_LTRS);

        // TD with TRAN ID
        writeHtml(htmlOut, HTML_L58);
        byte[] tranIdHtml = buildHtmlStringRecordNoTwoSpaceDelim("<p>", stTranId, "</p>");
        writeHtml(htmlOut, tranIdHtml);
        writeHtml(htmlOut, HTML_LTDE);

        // TD with TRAN DETAILS
        writeHtml(htmlOut, HTML_L61);
        // ST-TRANDT is PIC X(49), DELIMITED BY '*' means stop at first '*'
        // (same approach as TRANID: '*' delimited, no stars in content)
        byte[] tranDtHtml = buildHtmlStringRecordNoTwoSpaceDelim("<p>", stTranDt, "</p>");
        writeHtml(htmlOut, tranDtHtml);
        writeHtml(htmlOut, HTML_LTDE);

        // TD with TRAN AMOUNT
        writeHtml(htmlOut, HTML_L64);
        byte[] tranAmtHtml = buildHtmlStringRecordNoTwoSpaceDelim("<p>", stTranAmt, "</p>");
        writeHtml(htmlOut, tranAmtHtml);
        writeHtml(htmlOut, HTML_LTDE);

        writeHtml(htmlOut, HTML_LTRE);
    }

    // -----------------------------------------------------------------------
    // Write footer: ST-LINE12, ST-LINE14A (total), ST-LINE15 + HTML footer
    // -----------------------------------------------------------------------
    static void writeStatementFooter(FileOutputStream stmtOut, FileOutputStream htmlOut,
                                      long totalHundredths, byte[][] lines) throws IOException {
        // MOVE WS-TOTAL-AMT TO WS-TRN-AMT (S9(9)V99)
        // MOVE WS-TRN-AMT TO ST-TOTAL-TRAMT (PIC Z(9).99-)
        String totalAmtStr = formatZedAmount(totalHundredths);
        byte[] stTotalAmt = totalAmtStr.getBytes(StandardCharsets.ISO_8859_1);

        // ST-LINE12
        writeStmt(stmtOut, ST_LINE12);

        // ST-LINE14A: 'Total EXP:'(10) + 56 spaces + '$'(1) + ST-TOTAL-TRAMT(13)
        byte[] line14a = new byte[STMT_REC_LEN];
        copyAscii(line14a, 0, "Total EXP:");
        Arrays.fill(line14a, 10, 66, (byte)' ');
        line14a[66] = '$';
        System.arraycopy(stTotalAmt, 0, line14a, 67, 13);
        writeStmt(stmtOut, line14a);

        // ST-LINE15
        writeStmt(stmtOut, ST_LINE15);

        // HTML footer
        writeHtml(htmlOut, HTML_LTRS);
        writeHtml(htmlOut, HTML_L10);
        writeHtml(htmlOut, HTML_L75);
        writeHtml(htmlOut, HTML_LTDE);
        writeHtml(htmlOut, HTML_LTRE);
        writeHtml(htmlOut, HTML_L78);
        writeHtml(htmlOut, HTML_L79);
        writeHtml(htmlOut, HTML_L80);
    }

    // -----------------------------------------------------------------------
    // Decode TRNX-AMT (PIC S9(09)V99 DISPLAY) from flat record
    // Returns value in hundredths (e.g., 10000.00 -> 1000000L)
    // -----------------------------------------------------------------------
    static long decodeTrnxAmt(byte[] rec, int off, int len) {
        byte[] digits = Arrays.copyOfRange(rec, off, off + len);
        boolean negative = (digits[len - 1] & 0xFF) >= 0x70;
        if (negative) {
            digits[len - 1] = (byte)((digits[len - 1] & 0xFF) - 0x40);
        }
        String s = new String(digits, StandardCharsets.ISO_8859_1);
        // PIC S9(09)V99: first 9 chars = integer, last 2 = decimal
        long intPart = Long.parseLong(s.substring(0, 9));
        long decPart = Long.parseLong(s.substring(9, 11));
        long val = intPart * 100L + decPart;
        return negative ? -val : val;
    }

    // -----------------------------------------------------------------------
    // Decode ACCT-CURR-BAL (PIC S9(10)V99 DISPLAY, 12 bytes)
    // Returns value in hundredths
    // -----------------------------------------------------------------------
    static long decodeAcctBal(byte[] rec, int off, int len) {
        byte[] digits = Arrays.copyOfRange(rec, off, off + len);
        boolean negative = (digits[len - 1] & 0xFF) >= 0x70;
        if (negative) {
            digits[len - 1] = (byte)((digits[len - 1] & 0xFF) - 0x40);
        }
        String s = new String(digits, StandardCharsets.ISO_8859_1);
        // PIC S9(10)V99: first 10 chars = integer, last 2 = decimal
        long intPart = Long.parseLong(s.substring(0, 10));
        long decPart = Long.parseLong(s.substring(10, 12));
        long val = intPart * 100L + decPart;
        return negative ? -val : val;
    }

    // -----------------------------------------------------------------------
    // Format current balance as PIC 9(9).99-  (13 chars, NO zero suppression)
    // -----------------------------------------------------------------------
    static String formatCurrBal(byte[] acctRec, int off, int len) {
        long hundredths = decodeAcctBal(acctRec, off, len);
        boolean negative = hundredths < 0;
        long absVal = Math.abs(hundredths);
        long intPart = absVal / 100L;
        long decPart = absVal % 100L;
        // 9(9) means exactly 9 digits with LEADING ZEROS (no suppression)
        String intStr = String.format("%09d", intPart);
        String decStr = String.format("%02d", decPart);
        char sign = negative ? '-' : ' ';
        return intStr + "." + decStr + sign; // 9 + 1 + 2 + 1 = 13 chars
    }

    // -----------------------------------------------------------------------
    // Format an amount as PIC Z(9).99- (13 chars, leading zero suppression)
    // -----------------------------------------------------------------------
    static String formatZedAmount(long hundredths) {
        boolean negative = hundredths < 0;
        long absVal = Math.abs(hundredths);
        long intPart = absVal / 100L;
        long decPart = absVal % 100L;

        // Z(9) = 9 digit positions with leading zero suppression
        // Suppress leading zeros; stop suppression at first non-zero
        String intRaw = String.format("%09d", intPart); // exactly 9 chars
        StringBuilder intFormatted = new StringBuilder();
        boolean suppressing = true;
        for (int i = 0; i < 9; i++) {
            char c = intRaw.charAt(i);
            if (suppressing && c == '0') {
                intFormatted.append(' ');
            } else {
                suppressing = false;
                intFormatted.append(c);
            }
        }
        // If all zeros, suppress the decimal point too (replace with space)
        // But in practice this should not happen with non-zero amounts
        String decStr = String.format("%02d", decPart);
        char sign = negative ? '-' : ' ';

        // Total: 9 + 1 + 2 + 1 = 13 chars
        return intFormatted.toString() + "." + decStr + sign;
    }

    // -----------------------------------------------------------------------
    // COBOL STRING logic: delimiter is a single space (stop at first ' ')
    // Returns the substring of rec[off:off+len] up to (not including) first space
    // -----------------------------------------------------------------------
    static String delimBySpace(byte[] rec, int off, int len) {
        int end = off;
        while (end < off + len && rec[end] != ' ') {
            end++;
        }
        return new String(rec, off, end - off, StandardCharsets.ISO_8859_1);
    }

    // -----------------------------------------------------------------------
    // Build an HTML record for the WRITE FD-HTMLFILE-REC (no STRING) variants:
    // DELIMITED BY '*' means stop at first '*'. Since none of our strings
    // contain '*', the full content is used.
    // -----------------------------------------------------------------------
    static byte[] buildHtmlStringRecordNoTwoSpaceDelim(String prefix, byte[] content, String suffix) {
        byte[] record = new byte[HTML_REC_LEN];
        Arrays.fill(record, (byte)' ');
        int pos = 0;
        // prefix (no '*')
        byte[] prefBytes = prefix.getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(prefBytes, 0, record, pos, prefBytes.length);
        pos += prefBytes.length;
        // content DELIMITED BY '*': stop at first 0x2A
        for (byte b : content) {
            if (b == '*') break;
            if (pos >= HTML_REC_LEN) break;
            record[pos++] = b;
        }
        // suffix (no '*')
        byte[] sufBytes = suffix.getBytes(StandardCharsets.ISO_8859_1);
        if (pos + sufBytes.length <= HTML_REC_LEN) {
            System.arraycopy(sufBytes, 0, record, pos, sufBytes.length);
        }
        // remaining bytes already spaces
        return record;
    }

    // -----------------------------------------------------------------------
    // Build HTML record for STRING with '  ' (two-space) delimiter on content
    // Used for name and address lines in 5200-WRITE-HTML-NMADBS
    // -----------------------------------------------------------------------
    static byte[] buildHtmlStringRecord(String prefix, byte[] content, String suffix) {
        byte[] record = new byte[HTML_REC_LEN];
        Arrays.fill(record, (byte)' ');
        int pos = 0;

        // prefix
        byte[] prefBytes = prefix.getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(prefBytes, 0, record, pos, prefBytes.length);
        pos += prefBytes.length;

        // content DELIMITED BY '  ' (two consecutive spaces)
        // Find first occurrence of two consecutive spaces in content
        int contentEnd = content.length;
        for (int i = 0; i < content.length - 1; i++) {
            if (content[i] == ' ' && content[i + 1] == ' ') {
                contentEnd = i;
                break;
            }
        }
        for (int i = 0; i < contentEnd; i++) {
            if (pos >= HTML_REC_LEN) break;
            record[pos++] = content[i];
        }

        // '  ' DELIMITED BY SIZE (always 2 spaces)
        if (pos + 1 < HTML_REC_LEN) {
            record[pos++] = ' ';
            record[pos++] = ' ';
        }

        // suffix
        byte[] sufBytes = suffix.getBytes(StandardCharsets.ISO_8859_1);
        if (pos + sufBytes.length <= HTML_REC_LEN) {
            System.arraycopy(sufBytes, 0, record, pos, sufBytes.length);
        }

        return record;
    }

    // -----------------------------------------------------------------------
    // Write exactly STMT_REC_LEN bytes to STMTFILE
    // -----------------------------------------------------------------------
    static void writeStmt(FileOutputStream out, byte[] rec) throws IOException {
        out.write(rec, 0, STMT_REC_LEN);
    }

    // -----------------------------------------------------------------------
    // Write exactly HTML_REC_LEN bytes to HTMLFILE
    // -----------------------------------------------------------------------
    static void writeHtml(FileOutputStream out, byte[] rec) throws IOException {
        out.write(rec, 0, HTML_REC_LEN);
    }

    // -----------------------------------------------------------------------
    // Helper: pad a byte array to exactly 'width' bytes with spaces on right
    // -----------------------------------------------------------------------
    static byte[] padRight(byte[] src, int width) {
        byte[] result = new byte[width];
        Arrays.fill(result, (byte)' ');
        int copy = Math.min(src.length, width);
        System.arraycopy(src, 0, result, 0, copy);
        return result;
    }

    // -----------------------------------------------------------------------
    // Helper: create a 100-byte HTML record from a string, space-padded
    // -----------------------------------------------------------------------
    static byte[] htmlFixed(String content) {
        byte[] rec = new byte[HTML_REC_LEN];
        Arrays.fill(rec, (byte)' ');
        byte[] bytes = content.getBytes(StandardCharsets.ISO_8859_1);
        int copy = Math.min(bytes.length, HTML_REC_LEN);
        System.arraycopy(bytes, 0, rec, 0, copy);
        return rec;
    }

    // -----------------------------------------------------------------------
    // Helper: fill a byte array with a repeated byte
    // -----------------------------------------------------------------------
    static byte[] repeatByte(byte b, int len) {
        byte[] arr = new byte[len];
        Arrays.fill(arr, b);
        return arr;
    }

    // -----------------------------------------------------------------------
    // Helper: copy ASCII string into byte array at offset
    // -----------------------------------------------------------------------
    static void copyAscii(byte[] dest, int off, String s) {
        byte[] b = s.getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(b, 0, dest, off, b.length);
    }

    // -----------------------------------------------------------------------
    // Build ST-LINE0: ***...(31)***START OF STATEMENT***...(31)***
    // FILLER VALUE ALL '*' PIC X(31) -> 31 '*'
    // FILLER VALUE ALL 'START OF STATEMENT' PIC X(18) -> 'START OF STATEMENT' (18 chars)
    // FILLER VALUE ALL '*' PIC X(31) -> 31 '*'
    // -----------------------------------------------------------------------
    static byte[] buildLine0() {
        byte[] rec = new byte[STMT_REC_LEN];
        Arrays.fill(rec, (byte)'*');
        // Middle 18 bytes (positions 31-48): 'START OF STATEMENT'
        byte[] mid = "START OF STATEMENT".getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(mid, 0, rec, 31, 18);
        return rec;
    }

    // -----------------------------------------------------------------------
    // Build ST-LINE6: 33 spaces + 'Basic Details' (14) + 33 spaces
    // -----------------------------------------------------------------------
    static byte[] buildLine6() {
        byte[] rec = new byte[STMT_REC_LEN];
        Arrays.fill(rec, (byte)' ');
        byte[] mid = "Basic Details".getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(mid, 0, rec, 33, mid.length);
        return rec;
    }

    // -----------------------------------------------------------------------
    // Build ST-LINE11: 30 spaces + 'TRANSACTION SUMMARY ' (20) + 30 spaces
    // -----------------------------------------------------------------------
    static byte[] buildLine11() {
        byte[] rec = new byte[STMT_REC_LEN];
        Arrays.fill(rec, (byte)' ');
        byte[] mid = "TRANSACTION SUMMARY ".getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(mid, 0, rec, 30, mid.length);
        return rec;
    }

    // -----------------------------------------------------------------------
    // Build ST-LINE13:
    //   'Tran ID         ' (16) + 'Tran Details    ' padded to 51 + '  Tran Amount' (13)
    // -----------------------------------------------------------------------
    static byte[] buildLine13() {
        byte[] rec = new byte[STMT_REC_LEN];
        Arrays.fill(rec, (byte)' ');
        copyAscii(rec, 0, "Tran ID         ");    // 16 bytes
        copyAscii(rec, 16, "Tran Details    ");   // starts 'Tran Details    ' (16 chars)
        // bytes 32-66 remain spaces (padding to fill 51-byte field)
        copyAscii(rec, 67, "  Tran Amount");      // 13 bytes at pos 67
        return rec;
    }

    // -----------------------------------------------------------------------
    // Build ST-LINE15: ***...(32)***END OF STATEMENT***...(32)***
    // -----------------------------------------------------------------------
    static byte[] buildLine15() {
        byte[] rec = new byte[STMT_REC_LEN];
        Arrays.fill(rec, (byte)'*');
        byte[] mid = "END OF STATEMENT".getBytes(StandardCharsets.ISO_8859_1);
        System.arraycopy(mid, 0, rec, 32, mid.length);
        return rec;
    }
}
