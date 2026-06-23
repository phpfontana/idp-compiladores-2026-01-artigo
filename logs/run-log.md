# Run Log (append-only)

Never edit or delete past entries. Append one line per phase, per program.

Format:
`YYYY-MM-DDThh:mm  <phase>  <program>  <action>  <result>  <wall_clock>  <interventions>`

Example:
`2026-06-17T09:14  P4  CBACT04C  equivalence-check  REJECTED(2/14 fail)  4m02s  0`

---
2026-06-17T00:00  P0  ALL  static-analysis  DONE(44 programs: 31 main-app + 13 sub-app, 43 copybooks; catalog.md + relationships.md written)  not measured  1
2026-06-17T23:59  P1  ALL  documentation  DONE(44 program docs written in artifacts/docs/)  not measured  1
2026-06-17T20:47  P2  CBACT01C  characterization  DONE(3 test records, 4 golden output files, build: OK)  not measured  0
2026-06-17T21:01  P3  CBACT01C  translation  ACCEPTED(4/4 pass, build: OK)  14m  0
2026-06-17T21:03  P4  CBACT01C  equivalence-check  ACCEPTED(4/4 pass)  2m  0
2026-06-17T22:15  P5  CBACT01C  optimization  DONE(baseline=42.6ms/iter, optimized=41.7ms/iter, gain=2.07%, kept=1)  10m  0
2026-06-17T21:12  P6  CBACT01C  quality-gate  PASS(build:OK, equiv:4/4, doc-faithfulness:7/9, success-criterion:MET)  8m  0
2026-06-17T21:45  P2  CBTRN02C  characterization  DONE(7 test transactions, 5 golden output files, build: OK, 5/5 PASS)  not measured  0
2026-06-17T22:30  P3  CBTRN02C  translation  REJECTED(iteration 1: TRNSEQ FILLER 0x20 vs 0x00; TCATSEQ wrong order)  not measured  0
2026-06-17T22:35  P3  CBTRN02C  translation  REJECTED(iteration 2: TCATSEQ FILLER 0x20 vs 0x00 in new record)  not measured  0
2026-06-17T22:40  P3  CBTRN02C  translation  ACCEPTED(5/5 pass, build: OK)  ~30m  3
2026-06-17T21:44  P4  CBTRN02C  equivalence-check  ACCEPTED(5/5 pass)  3m  0
2026-06-17T21:48  P5  CBTRN02C  optimization  REJECTED-CANDIDATE(BufferedOutputStream+cached-charset: baseline=245ms/iter, optimized=247ms/iter, gain=0%, reverted — JVM startup dominates, I/O optimizations invisible at macro benchmark scale)  not measured  0
2026-06-17T21:52  P5  CBTRN02C  optimization  DONE(baseline=245ms/iter, optimized=not measured — no candidate kept; gain=0%, kept=0)  25m  0
2026-06-17T22:10  P6  CBTRN02C  quality-gate  PASS(build:OK, equiv:5/5, doc-faithfulness:11/11, success-criterion:MET)  5m  0
2026-06-17T22:05  P2  CBACT04C  characterization  DONE(2 accounts, 4 TCATBALF records, 3 golden output files, build: OK, 3/3 PASS; PARM-DATE via driver wrapper; last-account-never-posted bug documented)  not measured  0
2026-06-18T00:30  P3  CBACT04C  translation  ACCEPTED(3/3 pass, build: OK)  45m  1
2026-06-18T01:47  P4  CBACT04C  equivalence-check  ACCEPTED(3/3 pass)  5m  0
2026-06-18T02:15  P5  CBACT04C  optimization  DONE(baseline=291.4ms/iter, optimized=290.5ms/iter, gain=0.3%, candidate=cached-LATIN1-charset, equiv:3/3, kept=1)  20m  0
2026-06-18T02:30  P6  CBACT04C  quality-gate  PASS(build:OK, equiv:3/3, doc-faithfulness:13/13, success-criterion:MET)  15m  0
2026-06-20T20:10  P2  CBSTM03A  characterization  DONE(2 cards, 3 transactions, 2 XREF records, 3 golden output files, build: OK, 3/3 PASS; PSA/TCB/TIOT stubbed; CUSTREC.cpy tab-overflow fixed locally)  not measured  0
2026-06-20T21:30  P3  CBSTM03A  translation  ACCEPTED(3/3 pass, build: OK)  ~20m  1
2026-06-20T20:45  P4  CBSTM03A  equivalence-check  ACCEPTED(3/3 pass)  1s  0
2026-06-20T23:50  P5  CBSTM03A  optimization  DONE(baseline=67ms/iter, candidate1=BufferedOutputStream:68ms/iter:REJECTED, candidate2=cached-ISO_8859_1:78ms/iter:REJECTED — JVM startup dominates at 19KB output scale, kept=0)  30m  0
2026-06-20T23:50  P6  CBSTM03A  quality-gate  PASS(build:OK, equiv:3/3, doc-faithfulness:11/11, success-criterion:MET)  10m  0
2026-06-20T20:55  P2  CBSTM03B  characterization  DONE(4 file types, 19 CBSTM03B call sequences exercised: TRNXFILE O+3R+EOF+C, XREFFILE O+2R+EOF+C, CUSTFILE O+2K+C, ACCTFILE O+2K+C; 2 golden output files; build: OK; 2/2 PASS)  not measured  0
2026-06-20T<time>  P3  CBSTM03B  translation  ACCEPTED(2/2 pass, build: OK)  <5m  0
2026-06-21T00:02  P4  CBSTM03B  equivalence-check  ACCEPTED(2/2 pass)  1s  0
2026-06-20T22:15  P5  CBSTM03B  optimization  DONE(baseline=57ms/iter, candidate1=charset-cache+BufferedOutputStream:57ms/iter:REJECTED(no gain), candidate2=pre-built-DD-bytes+LINE_TEMPLATE:66ms/iter:REJECTED(no gain) — JVM startup dominates at <3KB file scale, kept=none)  20m  0
2026-06-20T22:35  P6  CBSTM03B  quality-gate  PASS(build:OK, equiv:2/2, doc-faithfulness:9/9, success-criterion:MET)  5m  0
