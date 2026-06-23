# COBOL Modernization Experiment

A Claude Code scaffold for the experiment in the IEEE paper: modernizing the AWS
CardDemo COBOL application to Java with an LLM agent, measuring accuracy and
efficiency under a hard equivalence gate.

## Layout
- `CLAUDE.md` — protocol auto-loaded every session (the rules the agent follows).
- `design.md`, `environment.md` — frozen experiment inputs. Do not edit mid-run.
- `.claude/agents/` — one subagent per phase.
- `workspace/` — the agent's working memory (catalog, relationships, progress, diagrams).
- `logs/run-log.md` — append-only action trace.
- `results/` — measured metrics, verification outcomes, ISO mapping.
- `findings.md` — interpretation for the paper.
- `artifacts/` — generated docs, characterization tests, migrated Java.

## Run
1. Fill in `environment.md` (versions, CardDemo commit, model).
2. Place the CardDemo source under `artifacts/` or point the agent at its path.
3. Launch Claude Code in this directory and start with Phase 0:
   > "Read design.md and CLAUDE.md, then run Phase 0 via the cobol-doc-expert subagent."
4. Proceed phase by phase. The agent plans; subagents execute.

## Notes
- Subagents load at session start; if you edit a file in `.claude/agents/`, restart
  the session (or use `/agents`) to pick up the change.
- Optional: a `PostToolUse` hook in `.claude/settings.json` can auto-append to the
  run log. Left out here to keep the scaffold robust; see the Claude Code hooks docs
  if you want deterministic logging.
