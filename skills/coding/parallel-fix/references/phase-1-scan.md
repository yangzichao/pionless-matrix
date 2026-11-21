# Phase 1 — Find & Draft

**Goal: maximize recall.** Find every plausible issue within scope. The user prunes in phase 2 — your job is not to miss things. Err on the side of over-reporting. A thin queue means you scanned too timidly; redo it.

## Steps

### 1. Orient

Run, in order:

- `git rev-parse --show-toplevel`
- `git branch --show-current`
- `ls` of the project root
- read the project's root agent instruction files if present (`AGENTS.md`, `CLAUDE.md` or similar)
- `git status --short`

If `git status` shows uncommitted changes, **warn the user** that every fix runs in a worktree branched from HEAD and will not see those changes; recommend `git stash` before proceeding. Do not abort — let the user decide.

### 2. Scope, category, checklist

Parse the description and define three things explicitly. Write them into the queue-file header.

- **Scope** — the file or directory set to scan. Stay within what the description names; within scope, go deep.
- **Category** — one of: `security` / `bugs` / `performance` / `types` / `lint-cleanup` / `tests` / `docs` / `mixed`.
- **Checklist** — concrete items to look for. Seed by category from `references/checklist-by-category.md`. List **at least 6–10** items.

For `mixed` or unclear, build the checklist from the description plus your judgment.

### 3. Three-angle scan

Run three scans over the same scope and checklist, each with a distinct angle: A (direct), B (adversarial), C (harsh reviewer). The angles, the input card and the output format are defined in `roles/scanner.md`.

Build one scanner card per angle:

```text
angle: <A | B | C>
scope: <scope from step 2>
checklist:
  - <checklist items from step 2>
description: <the user's description, verbatim>
```

- If you can start subagents: start three, each with a fresh context (not a fork of this conversation). Give each the full text of `roles/scanner.md`, then its card. Start all three at once if your host allows parallel subagents; otherwise run them one after another. Ask for read-only work if your host lets you restrict tools.
- If you cannot: run the three angles yourself, one at a time, in this thread. Before each, re-read `roles/scanner.md`, work only from that angle's card, and produce exactly the output it specifies. Quality should not drop; only parallelism is lost.

Each scan returns lines of the form:

```
file:line | severity (high|med|low) | checklist item or angle | issue description
```

### 4. Self-pass — what did they all miss?

After the three angles return, read the actual code in scope yourself. Ask: **"what did all three miss?"** Likely gaps:

- the same bug repeated across files — if they found one instance, grep the pattern and enumerate all of them,
- cross-file interaction bugs (A calls B with assumptions B does not meet),
- issues in adjacent config, build, migration, or CI files,
- boring-but-real items like missing validation on a public entrypoint,
- inverted or mismatched defaults.

Add your findings to the pool.

### 5. Merge, dedupe, classify

Combine A + B + C + self. Dedupe by `(file, line, issue-kind)`. Classify each as `high` / `med` / `low`. **Keep low-confidence findings** — prefix the `Issue` field with `[low-confidence]` so the user can prune in phase 2. Bias toward including, not excluding.

### 6. Thin-pool retry (capped)

If after merge the pool is noticeably smaller than the checklist suggested (e.g., ≤3 findings on a non-trivial scope), run **one** additional pass:

- add 2–3 more items to the checklist, or
- expand scope by one adjacent directory, and
- re-run angle C only, dispatched the same way as step 3.

Cap at one retry. If the pool is still thin, finalize as-is and flag "thin results" in the summary so the user knows.

### 7. Write the queue file

Derive a slug from the description (lowercase, dashes, ≤30 chars). Ensure `.parallel-fix/queue/` exists (`mkdir -p`). Write the queue file at:

```
<project>/.parallel-fix/queue/YYYYMMDD-HHMM-<slug>.md
```

Use `assets/queue-file-template.md` for the structure.

### 8. Stop

Print a compact summary — total tasks, severity breakdown, per-pass counts, path to the queue file — and **stop this turn**. Do not proceed to phase 3 yet.
