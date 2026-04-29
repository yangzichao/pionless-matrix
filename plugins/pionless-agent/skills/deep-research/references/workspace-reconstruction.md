# Workspace Reconstruction

Workspace reconstruction works only if the workspace lives in a **file**, not just in conversation context.

## Protocol

1. At project start, create or reuse a `deep-research/` directory in the current workspace.
2. Derive a topic slug and run prefix in the form `YYYY-MM-DD-HHMM-<topic>` (`references/output-conventions.md`).
3. Write the initial workspace state to `deep-research/<prefix>.workspace.md` using `assets/workspace-template.md`.
4. After each meaningful step (search, fetch, synthesis, worker return), overwrite that same file.
5. Before each new iteration, read **only** that workspace file. Do not rely on earlier conversation turns for research state.
6. When the gate passes, dispatch `deep-research-writer` with the report path `deep-research/<prefix>.md`. The writer owns the final-report file write; the orchestrator never writes that file directly.

## What to keep in the workspace

The workspace holds only the four canonical blocks:

- `Research question` — the exact objective and constraints.
- `Evolving report` — the best current draft, already cleaned and deduplicated.
- `Immediate context` — only the facts, tensions, and next-step cues needed right now.
- `Open tasks` — the remaining frontier on the plan board.

Plus mandatory header sections from `assets/workspace-template.md`:

- `Loop State` — iteration counter, gate status, stale-rounds counter, search/fetch/subagent counters.
- `Gate Checklist` — the completion-gate criteria as checkboxes.

## What to discard

- Full raw page content from prior fetches.
- Full prior search-result lists.
- Long worker transcripts.
- Earlier draft revisions of the report.

These can exist externally for audit (e.g., the persisted workspace history if you keep one), but the active reasoning context should stay compact.

## Why

Without file-backed reconstruction, the loop slowly poisons itself with stale context. A 4-iteration loop without reconstruction often performs worse than a 2-iteration loop with reconstruction.
