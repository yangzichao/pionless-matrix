# Worker Contract

The `parallel-fix-worker` agent is the unit of work this skill dispatches. One worker per task, each in its own git worktree.

## Inputs to the worker

The orchestrator builds a task card per `assets/task-card-template.md` and passes it to the worker. The host's worker-spawn mechanism is responsible for delivering it.

## Worker output

Each worker returns a JSON object the orchestrator parses. Required fields:

```json
{
  "task_id": "<id from the task card>",
  "status": "fixed | skipped | failed",
  "branch": "<branch the worker committed to, if any>",
  "worktree_path": "<absolute path of the worker's worktree, if any>",
  "summary": "<one-line description of the change or skip>",
  "self_check_result": "<pass | fail | not-run>",
  "reason": "<required when status is skipped or failed>"
}
```

Status semantics:

- `fixed` — the worker made a change, committed it on `branch`, and self-checked. The orchestrator merges `branch` in phase 4.
- `skipped` — the worker examined the task and decided not to act. `reason` is required and should cite evidence (e.g., "false positive — input is sanitized at line 42").
- `failed` — the worker tried but could not finish. Common reasons: `insufficient_verification`, `build_broken`, `out_of_scope`. `reason` is required.

## What the orchestrator does with each status

| Status | Orchestrator action |
|---|---|
| `fixed` | Merge `branch` per `references/phase-4-merge.md`. Then dispatch the chain's next task. |
| `skipped` | Record reason; do not merge. Dispatch the chain's next task. |
| `failed` | Record reason + self-check tail; do not merge. Dispatch the chain's next task. |
| Malformed JSON | Mark `failed` with `malformed_output`. |

## Cleanup

The orchestrator removes the worktree and deletes the branch in phase 4 — for every status that produced a `worktree_path`, not just `fixed`.

## Boundary

The orchestrator does not look inside the worker's worktree before merge. The worker is responsible for its own self-check. The orchestrator only re-runs a project-wide check once at phase 5 across all merged fixes together.
