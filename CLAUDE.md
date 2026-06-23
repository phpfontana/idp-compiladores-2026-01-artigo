# COBOL Modernization Experiment — Agent Protocol

This repository runs a controlled experiment: *can an LLM agent modernize COBOL
to Java while preserving exact behavior, and at what cost?* The results feed an
IEEE paper, so the integrity of the **record** matters as much as the modernized
code itself.

**Read `design.md` before doing anything.** It defines the research question, the
metrics, and the procedure. Do **not** edit `design.md` or `environment.md`
during a run — they are frozen inputs.

## Roles

You (the main agent) **plan and orchestrate**. You do not do phase work directly;
you delegate each phase to its subagent in `.claude/agents/`. Subagents cannot
plan, so hand each one a complete, explicit task. The pipeline:

| Phase | Work | Subagent |
|---|---|---|
| 0 | Static analysis | `cobol-doc-expert` |
| 1 | Documentation | `cobol-doc-expert` |
| 2 | Characterization testing | `characterization-tester` |
| 3 | Translation | `migration-engineer` |
| 4 | Equivalence verification | `equivalence-verifier` |
| 5 | Optimization | `optimizer` |
| 6 | Quality gating | `optimizer` |

## The five rules that protect the experiment

1. **Append-only records.** Never overwrite or delete anything in `logs/` or
   `results/`. Append only. If a number changes, append a new dated entry; do not
   rewrite the old one.
2. **Never fabricate a measurement.** If a value was not measured, write
   `not measured`. Record raw numbers — not rounded, not improved. This is data.
3. **The equivalence gate is hard.** A translation is *accepted* only when
   `equivalence-verifier` reports a 100% match against the COBOL golden master.
   An optimization is *kept* only if it still passes equivalence **and** improves
   the performance metric. Correctness is a constraint; performance is the objective.
4. **Separation of duty.** `equivalence-verifier` may read and run code but must
   never edit the migrated Java. It cannot be allowed to "fix" code to make tests
   pass — that would corrupt the result.
5. **Pin everything.** Use only the versions recorded in `environment.md`. If a
   version is unknown, stop and ask — do not guess.

## After every phase, for every program

Append one line to `logs/run-log.md`:

```
YYYY-MM-DDThh:mm  <phase>  <program>  <action>  <result>  <wall_clock>  <interventions>
```

Then update the matching cell in `workspace/progress.md`.

## Scope

Documentation phases (0–1) cover the **whole repository**. Execution phases (2–6)
cover only the **five-program core subset** named in `design.md`. Do not expand
scope without recording the reason in `logs/run-log.md`.
