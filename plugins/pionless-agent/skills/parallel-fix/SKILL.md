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

1. Orient: `git rev-parse --show-toplevel`, `git branch --show-current`, skim `ls` + root `CLAUDE.md` if present. Run `git status --short` — if there are uncommitted changes, **warn the user** that workers branch from HEAD and will not see those changes, and recommend stashing (`git stash`) before proceeding. Do not abort; let the user decide.
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

## Phase 3 — Parallel dispatch with file-overlap serialization

1. Read the finalized todo file. Collect all rows with `status: pending`.

2. **Compute file-overlap chains.** Parse each task's `Files` column into a set of paths (strip `:line` suffixes — we compare file-level). Build connected components: two tasks are in the same chain if their file sets intersect. Tasks with no file overlap with anyone become singleton chains.

   Rationale: two workers touching the same file in separate worktrees can each "succeed" independently and then silently lose intent at merge time. Serializing them within a chain means the second task sees the first's fix already applied — eliminating the class of merge bug.

3. For each pending task, build a task card:

```text
task_id: <#>
severity: <severity>
files: <files column, parsed to list>
issue: <issue column verbatim>
verification_hint: <optional extra context>
base_branch: <branch from the todo header>
```

4. **Dispatch across chains, serial within each chain.** At most `--max` chains active simultaneously (default 4). Launch the **first pending task of each active chain** in one assistant message (single batch of up to `--max` parallel `Agent` calls with `isolation: "worktree"`, subagent_type `fix-worker`). Mark each dispatched row `dispatched`.

5. When a worker returns, parse its JSON output. Update the row:
   - `status: fixed` → mark `fixed`; append result to the "Worker results" section (branch, worktree_path, summary, self_check_result).
   - `status: skipped` → mark `skipped`; append the skip reason + evidence the worker cited.
   - `status: failed` (incl. reason `insufficient_verification`) → mark `failed`; append the failure reason + self-check output tail if present.
   - Malformed JSON → mark `failed` with `malformed_output`.

6. **Merge-back for the chain's completed task now**, before dispatching the chain's next task. Run the phase 4 merge procedure (below) for this single task. Only after its branch is merged into the working branch do you dispatch the next task in this chain — the new worker will then see the previous fix already in its base worktree.

7. Keep up to `--max` chains in flight. Whenever any chain's task is done (merged or terminal), dispatch that chain's next task (or pick up a new chain if this one is finished). Loop until every chain is done.

---

## Phase 4 — Merge back

Called per task as it completes within its chain (not as a big batch at the end). For a task with `status: fixed`:

1. `git merge --no-ff <branch>` against the current working branch.
2. On conflict (should be rare now that overlapping tasks are chained — if it still happens, the chain algorithm missed something or the worker touched a file outside its declared set):
   - `git status` to list conflicted paths.
   - Read each, resolve sensibly (prefer the worker's change; keep both if intents don't overlap; never silently drop changes).
   - `git add <files>` + `git commit` (default merge message is fine).
   - Mark the row `conflict-resolved` in the todo file.
3. If merge fails for any other reason, mark `failed` with the error and continue.
4. If `git merge` reports "Already up to date" (worker claimed fixed but worktree had no commits), mark `failed` with `empty_commit`.

**Per-worker cleanup — always, not just on `fixed`.** After processing any worker result that reported a non-empty `worktree_path` (regardless of status: `fixed`, `conflict-resolved`, `failed`, and even some `skipped` workers that accidentally committed something):

5. `git worktree remove <path>` — add `--force` if the path has uncommitted leftover changes.
6. `git branch -D <branch>` — `-D` is safe because the merge is already done (for fixed) or the changes are being discarded (for failed).
7. If any cleanup step errors (worktree already gone, branch not found), log it and continue — don't block.

Workers with `status: skipped` that reported NO `worktree_path` auto-cleaned via the harness; skip their entry.

After all chains complete:

8. Sanity check: `git worktree list` — should show no leftover fix-worker worktrees. If any remain, list them for the user and attempt force-remove.
9. Print a summary table (task#, final status, files touched).

---

## Phase 5 — Final self-check + loop

1. Detect toolchain (same rules as fix-worker: `package.json` / `Cargo.toml` / `pyproject.toml` / `go.mod` / `tsconfig.json`). Run the combined check with generous timeout (180s+).
2. **Pass** → print "all green" with the last lines of output, then stop.
3. **Fail** → run the check **one more time** immediately (same command, same timeout) to rule out flakiness. If the second run passes, print "all green (flaky pass on retry)" and stop. If the second run also fails, capture the failure output (tail ~200 lines), announce "Final check failed — starting follow-up round `<N>`", and re-enter **phase 1** using the failure output as the new description. Write the new todo file at `.claude/fix-queue/YYYYMMDD-HHMM-followup-<N>.md`. Pause for user review as normal.
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
