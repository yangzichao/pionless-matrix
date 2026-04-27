# Phase 3 — Parallel Dispatch with File-Overlap Serialization

## 1. Read the queue file and recover stranded rows

Before collecting pending rows, scan for rows whose `status` is `dispatched` and that have no corresponding entry in the `Worker results` section. These are stranded from a prior crashed or interrupted session.

If any stranded `dispatched` rows are found:

- List each one (task #, severity, files, issue).
- Ask the user to choose:
  - **(a)** Reset to `pending` — re-dispatch in this run (recommended default).
  - **(b)** Mark `failed` with reason `abandoned` and skip re-dispatch.
  - **(c)** Leave as-is — skip silently this run (user takes responsibility).
- If the user simply says "go again" without specifying, apply **(a)** automatically and note this in the output.
- Apply the chosen action to all stranded rows before continuing.
- Do **not** silently skip `dispatched` rows — silent data loss is worse than an interruption prompt.

After handling any stranded rows, collect all rows with `status: pending`.

## 2. Compute file-overlap chains

Parse each task's `Files` column into a set of paths (strip `:line` suffixes — compare file-level). Build connected components: two tasks are in the same chain if their file sets intersect. Tasks with no file overlap with anyone become singleton chains.

**Why.** Two workers touching the same file in separate worktrees can each "succeed" independently and then silently lose intent at merge time. Serializing them within a chain means the second task sees the first's fix already applied — eliminating that class of merge bug.

## 3. Build a task card per pending task

See `assets/task-card-template.md`. Minimum fields:

```text
task_id: <#>
severity: <severity>
files: <files column, parsed to list>
issue: <issue column verbatim>
verification_hint: <optional extra context>
base_branch: <branch from the queue header>
```

## 4. Dispatch across chains, serial within each chain

At most `--max` chains active simultaneously (default 4). Launch the **first pending task of each active chain** in one assistant message: a single batch of up to `--max` parallel worker spawns with worktree isolation, using the `parallel-fix-worker` agent.

Mark each dispatched row `dispatched`.

## 5. Process worker results

When a worker returns, parse its JSON output (`references/worker-contract.md`). Update the row:

- `status: fixed` → mark `fixed`; append result to the `Worker results` section (branch, worktree_path, summary, self_check_result).
- `status: skipped` → mark `skipped`; append the skip reason and evidence the worker cited.
- `status: failed` (incl. reason `insufficient_verification`) → mark `failed`; append the failure reason and self-check output tail if present.
- Malformed JSON → mark `failed` with `malformed_output`.

## 6. Merge-back per chain, before dispatching the chain's next task

Run the phase-4 merge procedure for the just-completed task **before** dispatching the chain's next task. Only after the branch is merged into the working branch do you dispatch the next task in this chain — the new worker will then see the previous fix already in its base worktree.

## 7. Loop

Keep up to `--max` chains in flight. When any chain's task completes (merged or terminal), dispatch that chain's next task or pick up a new chain if this one is finished. Loop until every chain is done.
