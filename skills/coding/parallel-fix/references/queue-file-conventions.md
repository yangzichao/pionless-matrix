# Queue File Conventions

The queue file is the user's live log throughout the run. The orchestrator updates it at every state transition.

## Location

```
<project>/.parallel-fix/queue/YYYYMMDD-HHMM-<slug>.md
```

Where:

- `YYYYMMDD-HHMM` is the time the run started (24h, no separators between Y/M/D, hyphen between date and time).
- `<slug>` is a lowercase hyphenated slug of the description, ≤30 chars.

Always `mkdir -p .parallel-fix/queue/` if the directory does not exist. Do not ask first. Queue files from runs before version 2.0.0 live in `.claude/fix-queue/`; read them there when resuming an old run.

## Skeleton

`assets/queue-file-template.md`.

## Tasks table — strict columns

```
| # | Severity | Files | Issue | Found by | Status |
```

### Files column — strict format

Comma-separated list of paths. Each entry is one of:

- `path`
- `path:line`
- `path:line-range`

The orchestrator parses this column by splitting on commas, stripping whitespace, and stripping any `:...` suffix to get the file-level set used for chain computation.

**Do not** use other delimiters. No `;`, no newlines inside the cell, no bracketed JSON. Workers receive the parsed list as a JSON array in their task card, and may modify only those files.

### Found by column

Provenance label(s): `A` / `B` / `C` / `Self`, comma-separated (e.g., `A,C`). Not parsed by downstream phases — purely informational so the user can gauge coverage during phase 2 review.

### Status column — allowed values

`pending` / `dispatched` / `fixed` / `conflict-resolved` / `skipped` / `failed`.

Status transitions are owned by the orchestrator. The user can hand-edit but should generally not change a `dispatched` row mid-run; phase 3 treats a `dispatched` row with no worker result as stranded.

## Worker results section

Below the tasks table. The orchestrator appends one entry per terminal worker result, in the order they returned (fields per phase 3, step 5).

## Updates

- The orchestrator overwrites the file in place after every transition.
- Do not delete or rename the file mid-run — the user may have it open.
- After phase 5, the file is left in its final state; do not delete on completion.
