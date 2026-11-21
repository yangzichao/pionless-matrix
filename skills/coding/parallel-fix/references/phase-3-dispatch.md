# Phase 3 — Dispatch with File-Overlap Serialization

Every fix runs in its own git worktree, on its own branch, branched from the working branch as it is at dispatch time. You (the orchestrator) create the worktree, hand the task to a worker, and merge the result. Workers follow `roles/worker.md`.

## 1. Read the queue file and recover stranded rows

Before collecting pending rows, look for rows whose status is `dispatched` but that have no entry in the `Worker results` section. These are stranded from an earlier run that crashed or was interrupted.

If any stranded `dispatched` rows are found:

- List each one (task #, severity, files, issue).
- Ask the user to choose:
  - **(a)** Reset to `pending` and re-dispatch in this run (recommended default).
  - **(b)** Mark `failed` with reason `abandoned` and skip re-dispatch.
  - **(c)** Leave as-is and skip it this run (the user takes responsibility).
- If the user just says "go again" without choosing, apply **(a)** and say so in the output.
- Apply the chosen action to all stranded rows before continuing.
- For rows reset to `pending`, remove any leftover worktree and branch for that task first (`git worktree list`, `git branch --list 'parallel-fix/*'`, then the cleanup in phase 4). Otherwise `git worktree add` fails on the reused branch name.
- Never silently skip `dispatched` rows. Silent data loss is worse than an interruption prompt.

Then collect every row with status `pending`.

## 2. Compute file-overlap chains

Parse each task's `Files` column into a set of paths (split on commas, strip whitespace and `:line` suffixes, compare at file level). Build connected components: two tasks are in the same chain if their file sets intersect. A task that overlaps nobody is a chain of one.

**Why.** Two workers editing the same file in separate worktrees can each "succeed" and then silently lose intent at merge time. Running them one after another within a chain means the second task starts from a base that already has the first fix.

## 3. Prepare each task right before it is dispatched

Do this per task, at the moment that task is dispatched, not for all tasks up front. A chain's next task must branch from the working branch after the previous task was merged.

1. Once per run, create a temporary directory outside the main working tree (for example `mktemp -d`) to hold this run's worktrees. Keeping worktrees out of the main tree keeps them out of scans, test runs and `git status`.
2. Create the task's worktree from the main working tree, which is on the working branch:

   ```bash
   git worktree add -b parallel-fix/<queue-file-stem>/task-<#> <run-dir>/task-<#> HEAD
   ```

   `<queue-file-stem>` is the queue file name without `.md`, for example `20261121-1423-auth-security`. If the command fails, mark the row `failed` with the git error and move on to the chain's next task.
3. Build the task card from `assets/task-card-template.md`, filling `worktree_path` and `branch` from the command above.

## 4. Dispatch across chains, serially within each chain

At most `--max` chains are active at once (default 4). Each active chain has exactly one task in flight: its first not-yet-done task. Mark a row `dispatched` in the queue file as you dispatch it.

- If you can start subagents: for each task, start one subagent with a fresh context (not a fork of this conversation). Give it the full text of `roles/worker.md`, then the task card. The worker needs shell access, git, and file edits inside its `worktree_path`. Start the first tasks of all active chains at once if your host allows parallel subagents; otherwise start them one after another.
- If you cannot: run each fix yourself, one at a time, in its own worktree. Before each task, re-read `roles/worker.md`, work only from that task's card, do every edit and command inside its `worktree_path`, and produce exactly the JSON the role specifies. Then process and merge it (steps 5 and 6) before starting the next task. Only parallelism is lost; the per-task worktree, verification and self-check stay the same.

## 5. Process each worker result

The worker returns one fenced JSON block (format in `roles/worker.md`). Read `status`, `branch`, `worktree_path`, `summary`, `self_check_result`, `self_check_output_tail` and `verification_notes`. For `failed`, the reason keyword is the prefix of `summary`.

Update the row and append an entry to the `Worker results` section:

| Worker status | Row status | Append to `Worker results` | Then |
|---|---|---|---|
| `fixed` | `fixed` (or `conflict-resolved` after phase 4) | branch, summary, files_modified, self_check_result | merge per phase 4 |
| `skipped` | `skipped` | summary and the evidence from `verification_notes` | clean up per phase 4, do not merge |
| `failed` (any reason, including `insufficient_verification` and `out_of_scope`) | `failed` | reason, `verification_notes`, `self_check_output_tail` if present | clean up per phase 4, do not merge |
| no parseable JSON | `failed` with reason `malformed_output` | what came back, trimmed | clean up per phase 4 using the path and branch from the task card |

Do not inspect or re-test the worker's worktree before merging. The worker owns its self-check; phase 5 runs one project-wide check over all merged fixes together.

## 6. Merge back before the chain's next task

Run the phase 4 merge and cleanup for the finished task **before** preparing and dispatching the next task in the same chain.

## 7. Loop

Keep up to `--max` chains in flight. When a chain's task reaches a terminal state (merged, skipped or failed, and cleaned up), prepare and dispatch that chain's next task, or start a new chain if this one is done. Loop until every chain is done.
