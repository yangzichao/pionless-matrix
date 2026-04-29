# Workspace Reconstruction

Workspace reconstruction works only if the workspace lives in a **file**, not just in conversation context.

## Protocol

1. At project start, create or reuse a `deep-research/` directory in the current workspace.
2. Derive a topic slug and run prefix in the form `YYYY-MM-DD-HHMM-<topic>` (`references/output-conventions.md`).
3. Write the initial workspace state to `deep-research/<prefix>.workspace.md` using `assets/workspace-template.md`.
4. After each meaningful step (search, fetch, worker return, plan-board update), overwrite that same file. Keep entries terse — the workspace is working notes, not running prose.
5. Before each new iteration, read **only** that workspace file. Do not rely on earlier conversation turns for research state.
6. When the gate passes, dispatch `deep-research-drafter` with the workspace path; it returns the synthesized draft. Then dispatch `deep-research-writer` with that draft and the report path `deep-research/<prefix>.md`. The writer owns the final-report file write; the orchestrator never writes that file directly and never writes the draft prose itself.

## What to keep in the workspace

The workspace holds only the canonical blocks (see `assets/workspace-template.md` for the full skeleton):

- `Research Question` — the exact objective, constraints, mode, and chosen style.
- `Working Thesis` (research mode only) — current best answer, confidence, last revised iteration.
- `Plan Board` — the subquestions, priority, status, confidence.
- `Findings` — terse bullets only (one claim per line with source and confidence). Not running prose; the drafter expands these at gate-pass time.
- `Next Action` — what the next iteration targets.

Plus mandatory header sections:

- `Loop State` — iteration counter, gate status, stale-rounds counter.
- `Gate Checklist` — the completion-gate criteria as checkboxes.

## What to discard

- Full raw page content from prior fetches.
- Full prior search-result lists.
- Long worker transcripts.
- Any prose draft written by the orchestrator — the drafter produces the prose draft, once, at gate-pass time, from the terse Findings.

These can exist externally for audit (e.g., the persisted workspace history if you keep one), but the active reasoning context should stay compact.

## Why

Without file-backed reconstruction, the loop slowly poisons itself with stale context. A 4-iteration loop without reconstruction often performs worse than a 2-iteration loop with reconstruction.
