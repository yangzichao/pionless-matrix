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

## Phase 1 — Find & draft (aggressive multi-angle scan)

**Goal: maximize recall.** Find every plausible issue within scope. The user prunes in phase 2 — your job is not to miss things. Err on the side of over-reporting. A thin queue means you scanned too timidly; redo it.

1. **Orient**: `git rev-parse --show-toplevel`, `git branch --show-current`, skim `ls` + root `CLAUDE.md` if present. Run `git status --short` — if there are uncommitted changes, **warn the user** that workers branch from HEAD and will not see those changes, and recommend stashing (`git stash`) before proceeding. Do not abort; let the user decide.

2. **Scope & checklist.** Parse the description and define three things explicitly (write them into the todo-file header later):
   - **Scope** — the file/dir set to scan. Stay within what the description names — don't boil the ocean, but within scope go as deep as you can.
   - **Category** — classify as one of: `security` / `bugs` / `performance` / `types` / `lint-cleanup` / `tests` / `docs` / `mixed`.
   - **Checklist** — enumerate concrete items to look for. Seed from category:
     - `security` → OWASP-style: SQLi, XSS, CSRF, auth/session bypass, IDOR, SSRF, path traversal, command/template injection, crypto misuse, hardcoded secrets/keys, unsafe deserialization, insecure defaults, TOCTOU, missing rate-limit/authZ on sensitive endpoints.
     - `bugs` → null/undefined deref, race conditions, off-by-one, resource leaks (unclosed files/connections/subscriptions), swallowed exceptions, wrong type coercion, missing input validation, shadowed vars, async/await misuse, unchecked promise rejections, dead branches.
     - `performance` → N+1 queries, unbounded loops/recursion, sync I/O in async path, missing indexes, redundant work in hot paths, unbounded memory growth, blocking the event loop.
     - `types` → unsafe casts, `any`/`unknown` leaks, missing null guards, wrong generics, ignored type errors (`@ts-ignore`, `# type: ignore`).
     - `lint-cleanup` → dead code, unused imports/vars/params, magic numbers, duplicated blocks, stale TODO/FIXME/XXX, inconsistent naming.
     - `tests` → missing coverage for public APIs, sleep-based flakiness, over-mocking (especially of the unit under test), missing edge/error cases, tests that don't actually assert.
     - `docs` → stale references, broken links, wrong signatures, missing invariants/preconditions.
     - For `mixed` or unclear, build the checklist from the description + your judgment. List at least 6–10 concrete items.

3. **Three-angle parallel scan.** In a **single message**, spawn three `Explore` subagents (`thoroughness: "very thorough"`) over the SAME scope and checklist, each with a distinct angle. Pass the full scope + checklist to each; request structured output `file:line | severity (high/med/low) | checklist item or angle | issue description`.
   - **Agent A — Direct**: "Find every instance matching any checklist item within <scope>. Don't filter by confidence — flag low-confidence inline. Grep exhaustively for each item; don't stop at the first hit per file."
   - **Agent B — Adversarial**: "You are an attacker / fuzzer / malicious user. Within <scope>, find every place that breaks under hostile input, unexpected state, concurrent calls, partial failures, or edge cases the author didn't anticipate. What would you exploit? What input crashes this? What invariant is assumed but not enforced? What happens on auth-expired, network-dropped, or half-written state?"
   - **Agent C — Harsh reviewer**: "You are the strictest staff-level code reviewer. Within <scope>, flag everything that would fail your review: fragile patterns, hidden assumptions, subtle bugs, bad abstractions, inconsistent error handling, concurrency smells, API misuse, missing guards on public entrypoints. Assume the author is junior and missed things. Be ruthless; a passing review is the failure mode."

4. **Self-pass — what did they all miss?** After the three agents return, read the actual code in scope yourself and ask: **"what did all three miss?"** Likely gaps: (a) same bug repeated across files — if they found one instance, grep the pattern and enumerate all of them; (b) cross-file interaction bugs (A calls B with assumptions B doesn't meet); (c) issues in adjacent config/build/migration/CI files; (d) boring-but-real items like missing validation on a public entrypoint; (e) inverted or mismatched defaults. Add your findings to the pool.

5. **Merge, dedupe, classify.** Combine A + B + C + self. Dedupe by (file, line, issue-kind). Classify each as `high` / `med` / `low`. **Keep low-confidence findings** — prefix their `Issue` field with `[low-confidence]` so the user can prune in phase 2. Bias toward including, not excluding. If after merge you have noticeably fewer findings than the checklist suggested (e.g. ≤3 findings on a non-trivial scope), run **one** additional pass: add 2–3 more items to the checklist (or expand scope by one adjacent directory) and re-run Agent C only. Cap at one retry — if the pool is still thin, finalize as-is and flag "thin results" in the summary so the user knows.

6. Derive a slug from the description (lowercase, dashes, ≤30 chars). Ensure `.claude/fix-queue/` exists (`mkdir -p`). Write the todo file at `<project>/.claude/fix-queue/YYYYMMDD-HHMM-<slug>.md`:

```markdown
# Fix Queue — <YYYY-MM-DD HH:MM>
Source: <verbatim user description>
Scope: <files/dirs scanned>
Category: <category>
Branch: <current branch>
Max parallel: <N>

## Checklist applied
- <item 1>
- <item 2>
- ...

## Scan coverage
- Agent A (direct): <N findings>
- Agent B (adversarial): <N findings>
- Agent C (harsh reviewer): <N findings>
- Self-pass (cross-cutting): <N findings>
- After dedupe: <N unique tasks>

## Tasks
| # | Severity | Files | Issue | Found by | Status |
|---|----------|-------|-------|----------|--------|
| 1 | high | src/auth/login.py:42 | SQL injection in query | A,C | pending |
| 2 | med  | src/auth/session.py, src/auth/tokens.py:88 | stale token not invalidated | B | pending |
| 3 | low  | src/util/cache.py:12 | [low-confidence] possible race on eviction | C | pending |

**Files column format (strict):** comma-separated list of paths. Each entry is either `path` or `path:line` or `path:line-range`. The orchestrator parses this column by splitting on commas and stripping whitespace + any `:...` suffix to get the file-level set for chain computation. Do not use other delimiters (no `;`, no newlines inside the cell, no bracketed JSON). Workers receive the parsed list as a JSON array in their task card.

**Found by column:** label(s) from `A` / `B` / `C` / `Self`, comma-separated (e.g. `A,C`). Provenance only — not parsed by downstream phases, but helps the user gauge coverage during phase 2 review.

## Worker results
_(filled in by orchestrator during dispatch)_
```

7. Print a compact summary — total tasks, severity breakdown, per-pass counts, path to the todo file — and **stop this turn**. Do not proceed to phase 3 yet.

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

1. Read the finalized todo file.

   **Stranded-dispatch recovery (run this check first, before collecting pending rows).** Scan for rows whose `status` is `dispatched` and that have no corresponding entry in the "Worker results" section. These are stranded from a prior crashed or interrupted session — the orchestrator marked them dispatched but never recorded a worker result.

   If any stranded `dispatched` rows are found:
   - List each one: task #, severity, files, issue.
   - Ask the user to choose one of three options:
     - **(a) Reset to `pending`** — re-dispatch them in this run (recommended default).
     - **(b) Mark as `failed`** — record reason `abandoned` and skip re-dispatch.
     - **(c) Leave as-is** — skip them silently this run (user takes responsibility).
   - If the user simply says "go again" or equivalent without specifying an option, apply **(a)** automatically and note this in your output.
   - Apply the chosen action to all stranded rows before continuing.
   - Do NOT silently skip `dispatched` rows — silent data loss is worse than an interruption prompt.

   After handling any stranded rows, collect all rows with `status: pending`.

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
