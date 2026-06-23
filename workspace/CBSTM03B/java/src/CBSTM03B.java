import java.io.*;
import java.nio.file.*;
import java.util.*;

/**
 * CBSTM03B.java — Java translation of COBOL CBSTM03B subroutine + CBSTM03B-DRIVER
 *
 * Replicates the exact 19-call sequence from CBSTM03B_DRIVER.cbl, reading from
 * flat sequential dump files instead of indexed VSAM files.
 *
 * Output format (matches COBOL driver):
 *   - DRVOUTPUT file: 19 fixed 80-byte records (no newlines)
 *   - stdout:          19 lines of 80 chars each + newline
 *
 * Usage: java CBSTM03B <TRNXSEQ> <XREFSEQ> <CUSTSEQ> <ACCTSEQ> <DRVOUTPUT>
 *
 * Record sizes:
 *   TRNXSEQ: 350 bytes/record
 *   XREFSEQ:  50 bytes/record
 *   CUSTSEQ: 500 bytes/record
 *   ACCTSEQ: 300 bytes/record
 */
public class CBSTM03B {

    // Record sizes
    private static final int TRNX_REC_SIZE = 350;
    private static final int XREF_REC_SIZE = 50;
    private static final int CUST_REC_SIZE = 500;
    private static final int ACCT_REC_SIZE = 300;

    // Return codes
    private static final String RC_OK  = "00";
    private static final String RC_EOF = "10";

    // Sequential file state
    private byte[] trnxData;
    private int    trnxPos;   // next record index for sequential read

    private byte[] xrefData;
    private int    xrefPos;

    // Keyed file maps: key (String) -> record (byte[])
    private Map<String, byte[]> custMap;
    private Map<String, byte[]> acctMap;

    // Output stream for DRVOUTPUT (80-byte records, no newlines)
    private OutputStream drvOut;

    public CBSTM03B(String trnxSeqPath, String xrefSeqPath,
                    String custSeqPath, String acctSeqPath,
                    String drvOutputPath) throws IOException {
        // Load sequential files into byte arrays
        trnxData = Files.readAllBytes(Paths.get(trnxSeqPath));
        trnxPos  = 0;

        xrefData = Files.readAllBytes(Paths.get(xrefSeqPath));
        xrefPos  = 0;

        // Load keyed files into maps
        custMap = loadKeyedFile(custSeqPath, CUST_REC_SIZE, 9);   // key = bytes 0-8 (9 bytes)
        acctMap = loadKeyedFile(acctSeqPath, ACCT_REC_SIZE, 11);  // key = bytes 0-10 (11 bytes)

        drvOut = new FileOutputStream(drvOutputPath);
    }

    /**
     * Loads a sequential file into a map keyed by the first keyLen bytes of each record.
     */
    private static Map<String, byte[]> loadKeyedFile(String path, int recSize, int keyLen)
            throws IOException {
        byte[] data = Files.readAllBytes(Paths.get(path));
        Map<String, byte[]> map = new LinkedHashMap<>();
        int numRecs = data.length / recSize;
        for (int i = 0; i < numRecs; i++) {
            byte[] rec = Arrays.copyOfRange(data, i * recSize, (i + 1) * recSize);
            String key = new String(rec, 0, keyLen, java.nio.charset.StandardCharsets.ISO_8859_1);
            map.put(key, rec);
        }
        return map;
    }

    /**
     * Write one output line to DRVOUTPUT (80 bytes, no newline) and to stdout (80 chars + newline).
     *
     * Output line layout (matching COBOL driver WS-OUT-LINE):
     *   cols  1- 8: DD name (8 chars, space-padded)
     *   col   9:    space
     *   col  10:    OPER (1 char)
     *   col  11:    space
     *   cols 12-13: RC (2 chars)
     *   col  14:    space
     *   cols 15-64: first 50 bytes of FLDT (or spaces for O/C operations)
     *   cols 65-80: spaces (16 chars)
     */
    private void writeLine(String dd, char oper, String rc, byte[] fldt, boolean showFldt)
            throws IOException {
        // Build 80-byte output record
        byte[] line = new byte[80];
        Arrays.fill(line, (byte) ' ');

        // DD name: cols 1-8 (indices 0-7)
        byte[] ddBytes = paddedAscii(dd, 8);
        System.arraycopy(ddBytes, 0, line, 0, 8);

        // col 9 (index 8): space (already filled)

        // OPER: col 10 (index 9)
        line[9] = (byte) oper;

        // col 11 (index 10): space (already filled)

        // RC: cols 12-13 (indices 11-12)
        line[11] = (byte) rc.charAt(0);
        line[12] = (byte) rc.charAt(1);

        // col 14 (index 13): space (already filled)

        // FLDT (50 bytes): cols 15-64 (indices 14-63)
        if (showFldt && fldt != null) {
            int copyLen = Math.min(50, fldt.length);
            System.arraycopy(fldt, 0, line, 14, copyLen);
            // remaining bytes 14+copyLen .. 63 remain spaces
        }
        // cols 65-80 (indices 64-79): spaces (already filled)

        // Write 80 bytes to DRVOUTPUT (no newline)
        drvOut.write(line);

        // Write 80 chars + newline to stdout
        System.out.write(line);
        System.out.write((byte) '\n');
        System.out.flush();
    }

    private static byte[] paddedAscii(String s, int len) {
        byte[] b = new byte[len];
        Arrays.fill(b, (byte) ' ');
        byte[] sb = s.getBytes(java.nio.charset.StandardCharsets.ISO_8859_1);
        System.arraycopy(sb, 0, b, 0, Math.min(sb.length, len));
        return b;
    }

    // ---- Operations mirroring CBSTM03B subroutine ----

    /** TRNXFILE O */
    private void trnxOpen() throws IOException {
        trnxPos = 0;
        writeLine("TRNXFILE", 'O', RC_OK, null, false);
    }

    /** TRNXFILE R — returns true if a record was read, false on EOF */
    private boolean trnxRead() throws IOException {
        int offset = trnxPos * TRNX_REC_SIZE;
        if (offset + TRNX_REC_SIZE > trnxData.length) {
            // EOF
            writeLine("TRNXFILE", 'R', RC_EOF, null, false);
            return false;
        }
        byte[] rec = Arrays.copyOfRange(trnxData, offset, offset + TRNX_REC_SIZE);
        trnxPos++;
        writeLine("TRNXFILE", 'R', RC_OK, rec, true);
        return true;
    }

    /** TRNXFILE C */
    private void trnxClose() throws IOException {
        writeLine("TRNXFILE", 'C', RC_OK, null, false);
    }

    /** XREFFILE O */
    private void xrefOpen() throws IOException {
        xrefPos = 0;
        writeLine("XREFFILE", 'O', RC_OK, null, false);
    }

    /** XREFFILE R — returns true if a record was read, false on EOF */
    private boolean xrefRead() throws IOException {
        int offset = xrefPos * XREF_REC_SIZE;
        if (offset + XREF_REC_SIZE > xrefData.length) {
            writeLine("XREFFILE", 'R', RC_EOF, null, false);
            return false;
        }
        byte[] rec = Arrays.copyOfRange(xrefData, offset, offset + XREF_REC_SIZE);
        xrefPos++;
        writeLine("XREFFILE", 'R', RC_OK, rec, true);
        return true;
    }

    /** XREFFILE C */
    private void xrefClose() throws IOException {
        writeLine("XREFFILE", 'C', RC_OK, null, false);
    }

    /** CUSTFILE O */
    private void custOpen() throws IOException {
        writeLine("CUSTFILE", 'O', RC_OK, null, false);
    }

    /** CUSTFILE K — key lookup */
    private void custReadKey(String key) throws IOException {
        byte[] rec = custMap.get(key);
        if (rec == null) {
            writeLine("CUSTFILE", 'K', "23", null, false);
        } else {
            writeLine("CUSTFILE", 'K', RC_OK, rec, true);
        }
    }

    /** CUSTFILE C */
    private void custClose() throws IOException {
        writeLine("CUSTFILE", 'C', RC_OK, null, false);
    }

    /** ACCTFILE O */
    private void acctOpen() throws IOException {
        writeLine("ACCTFILE", 'O', RC_OK, null, false);
    }

    /** ACCTFILE K — key lookup */
    private void acctReadKey(String key) throws IOException {
        byte[] rec = acctMap.get(key);
        if (rec == null) {
            writeLine("ACCTFILE", 'K', "23", null, false);
        } else {
            writeLine("ACCTFILE", 'K', RC_OK, rec, true);
        }
    }

    /** ACCTFILE C */
    private void acctClose() throws IOException {
        writeLine("ACCTFILE", 'C', RC_OK, null, false);
    }

    /**
     * Replicates the exact 19-call sequence from CBSTM03B_DRIVER.cbl.
     */
    private void runDriver() throws IOException {
        // ---- 1000-TEST-TRNXFILE ----
        // Call 1: TRNXFILE O
        trnxOpen();

        // Calls 2-5: TRNXFILE R until EOF
        boolean trnxEof = false;
        while (!trnxEof) {
            trnxEof = !trnxRead();
        }

        // Call 6: TRNXFILE C
        trnxClose();

        // ---- 2000-TEST-XREFFILE ----
        // Call 7: XREFFILE O
        xrefOpen();

        // Calls 8-10: XREFFILE R until EOF
        boolean xrefEof = false;
        while (!xrefEof) {
            xrefEof = !xrefRead();
        }

        // Call 11: XREFFILE C
        xrefClose();

        // ---- 3000-TEST-CUSTFILE ----
        // Call 12: CUSTFILE O
        custOpen();

        // Call 13: CUSTFILE K '000000001'
        custReadKey("000000001");

        // Call 14: CUSTFILE K '000000002'
        custReadKey("000000002");

        // Call 15: CUSTFILE C
        custClose();

        // ---- 4000-TEST-ACCTFILE ----
        // Call 16: ACCTFILE O
        acctOpen();

        // Call 17: ACCTFILE K '00000000001'
        acctReadKey("00000000001");

        // Call 18: ACCTFILE K '00000000002'
        acctReadKey("00000000002");

        // Call 19: ACCTFILE C
        acctClose();

        drvOut.flush();
        drvOut.close();
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 5) {
            System.err.println("Usage: java CBSTM03B <TRNXSEQ> <XREFSEQ> <CUSTSEQ> <ACCTSEQ> <DRVOUTPUT>");
            System.exit(1);
        }
        String trnxSeq    = args[0];
        String xrefSeq    = args[1];
        String custSeq    = args[2];
        String acctSeq    = args[3];
        String drvOutput  = args[4];

        CBSTM03B driver = new CBSTM03B(trnxSeq, xrefSeq, custSeq, acctSeq, drvOutput);
        driver.runDriver();
    }
}
