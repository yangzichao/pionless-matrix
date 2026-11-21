# Phase 4 — Merge Back

Run this per task as soon as it finishes within its chain, not as one big batch at the end. Run every command from the main working tree, on the working branch.

## For a task with `status: fixed`

1. `git merge --no-ff <branch>` into the current working branch.
2. **On conflict** (rare once overlapping tasks are chained; if it happens, the chain computation missed something or the worker touched a file outside its declared set):
   - `git status` to list conflicted paths.
   - Read each, resolve sensibly (prefer the worker's change; keep both if the intents do not overlap; never silently drop changes).
   - `git add <files>` and `git commit` (the default merge message is fine).
   - Mark the row `conflict-resolved` in the queue file.
3. If the merge fails for any other reason, mark the row `failed` with the error and continue.
4. If `git merge` reports "Already up to date" (the worker claimed `fixed` but its branch has no new commits), mark the row `failed` with reason `empty_commit`.

## Per-task cleanup — always, for every status

You created a worktree and branch for every dispatched task, so clean up after every terminal result: `fixed`, `conflict-resolved`, `skipped`, `failed` and `malformed_output`. Use the `worktree_path` and `branch` from the task card; they match what the worker reports.

1. `git worktree remove <worktree_path>`. Add `--force` if it has uncommitted leftovers.
2. `git branch -D <branch>`. `-D` is safe here: the branch is either already merged (`fixed`) or being discarded.
3. If a cleanup step errors (worktree already gone, branch not found), log it and continue. Do not block on it.

## After all chains complete

1. Sanity check: `git worktree list` should show no worktrees on `parallel-fix/*` branches. If any remain, list them for the user and try `git worktree remove --force`, then `git worktree prune`.
2. Remove the run's temporary worktree directory if it is empty.
3. Print a summary table: task #, final status, files touched.
