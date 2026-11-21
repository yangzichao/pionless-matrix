# Workspace Reconstruction

Workspace reconstruction works only if the workspace lives in a **file**, not just in conversation context.

## Protocol

1. At project start, create or reuse the `deep-research/` directory and derive the run prefix (SKILL.md *Output*).
2. Write the initial workspace state to `deep-research/<prefix>.workspace.md` from `assets/workspace-template.md`.
3. After each meaningful step (search, fetch, worker or verifier return, plan-board update), overwrite that same file. Keep entries terse; the workspace is working notes, not running prose.
4. Before each new iteration, read **only** that workspace file. Do not rely on earlier conversation turns for research state.
5. When the gate passes, dispatch the drafter with the workspace path; it returns the synthesized draft. Then dispatch the writer with that draft and the report path `deep-research/<prefix>.md`. The writer owns the report file write; you never write the draft prose or the report yourself outside a drafter or writer pass.

## What to keep in the workspace

The workspace holds only the canonical blocks (full skeleton in `assets/workspace-template.md`):

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
- Any prose draft written by you; the drafter produces the prose draft, once, at gate-pass time, from the terse Findings.

These can exist externally for audit (e.g., the persisted workspace history if you keep one), but the active reasoning context should stay compact.

## Why

Without file-backed reconstruction, the loop slowly poisons itself with stale context. A 4-iteration loop without reconstruction often performs worse than a 2-iteration loop with reconstruction.
