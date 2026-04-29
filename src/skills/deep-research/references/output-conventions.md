# Output Conventions

## Directory

All research output goes into a `deep-research/` directory at the project root. Create it if it does not exist.

## Filename prefix

Derive a single run prefix per research job:

```
YYYY-MM-DD-HHMM-<topic>
```

Where:

- `YYYY-MM-DD` is the current date.
- `HHMM` is the current hour and minute (24h, no separator).
- `<topic>` is a short lowercase hyphenated slug derived from the research question.

Example: `2026-04-26-1530-ai-agent-frameworks`

## Files

Use the same prefix for both files of a run:

- `deep-research/<prefix>.workspace.md` — workspace state, overwritten after every meaningful step.
- `deep-research/<prefix>.md` — final report.

## Forbidden

- Writing to the project root.
- Arbitrary names like `report.md` or `workspace.md`.
- Paths outside `deep-research/`.

## Subagent file writes

In the canonical setup only one subagent writes a file: `deep-research-writer`. The orchestrator passes it the full report path (`deep-research/<prefix>.md`) at dispatch time — workers, verifiers, and the drafter return JSON and never write to disk. The orchestrator owns the workspace file write itself.

## Host without write access

If the host has no file-write tool, surface this immediately. The loop protocol and workspace reconstruction depend on file-backed state; without writes, do the workflow with a more compact in-memory state and warn the user about the loss.
