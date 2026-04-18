---
name: parallel-fix
description: Parallel-dispatch a queue of code fixes across a project. Use when the user wants to find-and-fix many issues in one sweep — security audits, bug hunts, lint cleanups, "fix all the TODOs", post-review fixes, type errors, or any batch of independent fixes. Scans for issues matching the user's description, pauses for user review, spawns one isolated `fix-worker` subagent per issue (each in its own git worktree), then merges their branches back into the working branch — resolving conflicts itself. Auto-retries up to 3 follow-up rounds if the final test run fails.
model: claude-sonnet-4-6
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep
---

# Parallel Fix

Use this skill when the user wants to scan the project for a class of issues and fix them in parallel. You (the Claude invoking this skill) act as the orchestrator, driving a five-phase flow: **find → pause-for-review → dispatch → merge-back → final-check (loop if failing)**.

## Invocation

Typical user invocations:
- `/parallel-fix check auth module for security issues`
- `/parallel-fix find obvious bugs in src/ --max 6`
- `/parallel-fix clean up unused imports across the repo`

`$ARGUMENTS` (or the user message text when auto-triggered) holds the full argument string. Parse:
- `--max N` (optional, default **4**) — max parallel workers per batch.
- Everything else is the **description** of what to find.

If the description is empty, ask the user what to look for and stop.

---

## Phase 1 — Find & draft

1. Orient: `git rev-parse --show-toplevel`, `git branch --show-current`, skim `ls` + root `CLAUDE.md` if present.
2. Scan for issues matching the description using Read/Grep/Glob. Scope to what the description names (e.g., "check auth module" → auth-related files only). Don't boil the ocean.
3. Classify each finding by severity: `high` / `medium` / `low`. Favor high-confidence findings; flag low-confidence ones explicitly.
4. Derive a slug from the description (lowercase, dashes, ≤30 chars).
5. Ensure `.claude/fix-queue/` exists (`mkdir -p`).
6. Write the todo file at `<project>/.claude/fix-queue/YYYYMMDD-HHMM-<slug>.md`:

```markdown
# Fix Queue — <YYYY-MM-DD HH:MM>
Source: <verbatim user description>
Branch: <current branch>
Max parallel: <N>

## Tasks
| # | Severity | Files | Issue | Status |
|---|----------|-------|-------|--------|
| 1 | high | src/auth/login.py:42 | SQL injection in query | pending |
| 2 | med  | ... | ... | pending |

## Worker results
_(filled in by orchestrator during dispatch)_
```

7. Print a compact summary to the user — total tasks, severity breakdown, path to the todo file — and **stop this turn**. Do not proceed to phase 3 yet.

---

## Phase 2 — User review (next turn)

Wait for the user's response. Route on intent:

| User says | Action |
|-----------|--------|
| "go" / "start" / "dispatch" / "run" | Proceed to phase 3 |
| "also look for X" / "find more Y" | Rescan for the extra scope, append new rows (continue numbering), print a diff of added rows, pause again |
| "drop #3" / "remove 2,5" / "keep only high" | Edit the todo file, confirm, pause again |
| User hand-edited the file | Re-read it, proceed if they also said "go", else confirm their intent |
| Anything ambiguous | Ask a clarifying question; do NOT dispatch |

---

## Phase 3 — Parallel dispatch

1. Read the finalized todo file. Collect all rows with `status: pending`.
2. For each pending task, build a task card:

```text
task_id: <#>
severity: <severity>
files: <files column, parsed to list>
issue: <issue column verbatim>
verification_hint: <optional extra context>
base_branch: <branch from the todo header>
```

3. Dispatch in batches of `--max` (default 4). **Put all Agent calls in a single assistant message** so they run in parallel. Call shape:

```
Agent({
  description: "Fix task <#>: <brief>",
  subagent_type: "fix-worker",
  isolation: "worktree",
  prompt: "<the task card>"
})
```

Before dispatching, mark each task row as `dispatched`.

4. When a batch returns, parse each worker's JSON output. Update the row:
   - `status: fixed` → mark `fixed`; append the result to the "Worker results" section with `branch`, `worktree_path`, `summary`, `self_check_result`.
   - `status: skipped` → mark `skipped`; append the skip reason.
   - `status: failed` → mark `failed`; append the failure reason + any self-check output tail.
   - Malformed JSON → mark `failed` with `malformed_output`.
5. Start the next batch. Repeat until all pending tasks are processed.

---

## Phase 4 — Merge back

For each task with `status: fixed`, in task_id order:

1. `git merge --no-ff <branch>` against the current working branch.
2. On conflict:
   - `git status` to list conflicted paths.
   - Read each, resolve sensibly (prefer the worker's change; keep both if intents don't overlap; never silently drop changes).
   - `git add <files>` + `git commit` (default merge message is fine).
   - Mark the row `conflict-resolved` in the todo file.
3. If merge fails for any other reason, mark `failed` with the error and continue.
4. If `git merge` reports "Already up to date" (worker claimed fixed but worktree had no commits), mark `failed` with `empty_commit`.

After all merges:

5. Clean up each processed worker: `git worktree remove <path>` then `git branch -D <branch>`.
6. Print a summary table (task#, final status, files touched).

---

## Phase 5 — Final self-check + loop

1. Detect toolchain (same rules as fix-worker: `package.json` / `Cargo.toml` / `pyproject.toml` / `go.mod` / `tsconfig.json`). Run the combined check with generous timeout (180s+).
2. **Pass** → print "all green" with the last lines of output, then stop.
3. **Fail** → capture failure output (tail ~200 lines), announce "Final check failed — starting follow-up round `<N>`", and re-enter **phase 1** using the failure output as the new description. Write the new todo file at `.claude/fix-queue/YYYYMMDD-HHMM-followup-<N>.md`. Pause for user review as normal.
4. **Hard budget: 3 follow-up rounds max.** After the 3rd fails, stop and print the residual failure with "requires manual intervention". Do not loop further.

---

## State & safety rules

- Always update the todo file's status column at every transition. It's the user's live log.
- Never push. Never force-push. Never rewrite history on the working branch.
- If the user Ctrl-C's mid-dispatch, leftover worktrees may remain. Note this in your output so they can run `git worktree list` and clean up manually.
- If `.claude/fix-queue/` doesn't exist in a project that doesn't use `.claude/`, still create it — don't ask.
- Use compact markdown tables in all reports; avoid walls of prose.
- End each run with a one-paragraph executive summary: counts by final status + path to the todo file.

## Related

- `fix-worker` agent (`src/agents/fix-worker.md`) — the single-fix worker this skill dispatches. One spawn per task, each in its own worktree via `isolation: "worktree"`.
