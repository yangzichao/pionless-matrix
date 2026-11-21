# Task Card

Built by the orchestrator for each task at dispatch time (phase 3, step 3) and passed to the worker right after the full text of `roles/worker.md`. When the host runs the fix itself, it works from this card the same way.

```text
task_id: {row #}
severity: {high | med | low}
files: {JSON array of paths parsed from the Files column, line suffixes kept, e.g. ["src/auth/login.py:42", "src/auth/session.py"]}
issue: {Issue column verbatim}
verification_hint: {optional extra context the orchestrator wants the worker to consider}
worktree_path: {absolute path of the worktree created for this task}
branch: {branch checked out in that worktree, e.g. parallel-fix/<queue-file-stem>/task-<#>}
base_branch: {Branch from the queue header; the worktree was branched from its HEAD}
```

## Notes

- `files` is the set of files the worker may modify. If the fix needs anything outside it, the worker returns `status: failed` with reason `out_of_scope` instead of editing.
- `verification_hint` is optional. Include it when you already know what kind of check fits (e.g., "the issue is in the test file — run only the affected test module").
- `worktree_path` and `branch` must match the `git worktree add` you just ran. You use them for cleanup even if the worker's output is unparseable.
- The worker owns its self-check before returning `status: fixed`.
