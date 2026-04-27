# Task Card

Built by the orchestrator and passed to each `parallel-fix-worker` at dispatch time.

```text
task_id: {row #}
severity: {high | med | low}
files: {parsed list of paths from the Files column}
issue: {Issue column verbatim}
verification_hint: {optional extra context the orchestrator wants the worker to consider}
base_branch: {Branch from the queue header — the worker's worktree branches from here}
```

## Notes

- `files` is a JSON array of paths the worker is allowed to touch. Touching anything outside this set is a worker-side violation and should result in `status: failed` with reason `out_of_scope`.
- `verification_hint` is optional. Include it when the orchestrator already knows what kind of self-check the worker should run (e.g., "the issue is in the test file — run only the affected test module").
- The worker is responsible for its own self-check before returning `status: fixed`.
