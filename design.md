# Experimental Design (frozen)

Do not edit during a run. Changing the design mid-experiment invalidates the data.

## Research question

Can an LLM agent modernize COBOL legacy code — translating it, documenting it, and
optimizing it — while preserving exact behavioral equivalence, and at what cost in
time, tokens, and human intervention?

## Structural hypothesis

COBOL's resistance to automated translation is structural, not syntactic: failures
concentrate in constructs that carry implicit semantic contracts — `COMP-3`/`PICTURE`
decimal arithmetic, `REDEFINES` aliasing, `PERFORM THRU` control flow, shared
`WORKING-STORAGE` state, and inter-program `CALL` linkage. We expect translation
errors to cluster on these constructs unless the pipeline explicitly preserves their
contracts.

## Core subset (Phases 2–6)

| Program | Function | Construct coverage |
|---|---|---|
| `CBACT01C` | Account file reader | Indexed I/O; baseline case |
| `CBTRN02C` | Transaction posting | Validation logic; reject handling |
| `CBACT04C` | Interest calculation | `COMP-3` arithmetic; rate fallback |
| `CBSTM03A` | Statement generation | Multi-file coordination; `REDEFINES` |
| `CBSTM03B` | Statement I/O subroutine | Inter-program `CALL` linkage |

Documentation phases (0–1) run on the full repository (31 programs, 30 copybooks).

## Metrics

### Accuracy
- **Functional equivalence (primary, binary per program).** Fraction of
  characterization test cases where Java output matches the COBOL golden master at
  three levels: final output files, record-level field values, and observable
  intermediate values. A program PASSES only at 100%. Decimal values compared
  exactly, scale included — never approximately.
- **Construct-level fidelity.** For each targeted construct (see hypothesis),
  whether behavior is preserved. Reported per program; ties results back to the
  paper's construct-coverage table.
- **Documentation faithfulness.** Human-validated sample: fraction of extracted
  business rules judged correct (e.g. 10 rules per program).
- **Build success.** Whether the migrated Java compiles cleanly.

### Efficiency
- **Wall-clock time** per phase, per program.
- **Token / cost** per phase.
- **Human interventions** — count of manual corrections or re-prompts. The autonomy
  signal; the one the demo never reports.
- **Throughput** — LOC translated per unit time; files documented per hour.
- **Optimization gain** — % improvement on the performance metric among changes
  that passed the equivalence gate.

## The two-stage gate (central design point)

```
translation candidate ──► equivalence-verifier ──► 100% match? ──► ACCEPTED
                                                  └─ no ────────► REJECTED (revise)

optimization candidate ─► still passes equivalence? ─► metric improved? ─► KEEP
                          └─ no ──► REVERT          └─ no ──► REVERT
```

Correctness is a hard constraint, gated before performance is ever considered.
Performance is the objective, optimized only within the correctness-preserving
region. Discarded candidates are recorded too — they are data.

## Comparability controls

Pin and hold constant across all runs (record actual values in `environment.md`):
the model, GnuCOBOL 3.1.2 (`-std=ibm`), the Java version, the CardDemo commit hash,
and the per-program test datasets. Report per-program metrics that scale with program
characteristics rather than aggregate system size, so results remain interpretable.

## Per-program success criterion

A program is *successfully modernized* when: (1) it is documented, (2) it has a
characterization test suite, (3) its Java translation is ACCEPTED at the equivalence
gate, and (4) Phase 6 quality evidence is recorded. Optimization (Phase 5) is
reported as gain, not as a pass/fail condition.
