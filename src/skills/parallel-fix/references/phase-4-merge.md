# Phase 4 — Merge Back

Called per task as it completes within its chain (not as a big batch at the end).

## For a task with `status: fixed`

1. `git merge --no-ff <branch>` against the current working branch.
2. **On conflict** (rare now that overlapping tasks are chained — if it still happens, the chain algorithm missed something or the worker touched a file outside its declared set):
   - `git status` to list conflicted paths.
   - Read each, resolve sensibly (prefer the worker's change; keep both if intents do not overlap; never silently drop changes).
   - `git add <files>` and `git commit` (default merge message is fine).
   - Mark the row `conflict-resolved` in the queue file.
3. If merge fails for any other reason, mark `failed` with the error and continue.
4. If `git merge` reports "Already up to date" (worker claimed `fixed` but the worktree had no commits), mark `failed` with reason `empty_commit`.

## Per-worker cleanup — always, not just on `fixed`

After processing any worker result that reported a non-empty `worktree_path` — regardless of status (`fixed`, `conflict-resolved`, `failed`, even some `skipped` workers that accidentally committed something):

1. `git worktree remove <path>` — add `--force` if the path has uncommitted leftover changes.
2. `git branch -D <branch>` — `-D` is safe because the merge is already done (for `fixed`) or the changes are being discarded (for `failed`).
3. If any cleanup step errors (worktree already gone, branch not found), log it and continue — do not block.

Workers with `status: skipped` that reported **no** `worktree_path` were auto-cleaned by the harness; skip their entry.

## After all chains complete

1. Sanity check: `git worktree list` — should show no leftover parallel-fix-worker worktrees. If any remain, list them for the user and attempt force-remove.
2. Print a summary table: task #, final status, files touched.
