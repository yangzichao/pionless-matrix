# Delegation Patterns

This skill is fundamentally orchestrator-worker. The host's spawn capability is what makes the workflow viable.

## Patterns the host enables

### Multi-angle scan (phase 1)

Three scanning workers run in parallel over the same scope with three distinct angles (direct / adversarial / harsh-reviewer). The host decides whether to spawn three workers or run the angles sequentially.

### One worker per fix (phase 3)

Each pending task is dispatched to its own `parallel-fix-worker` in an isolated git worktree. Up to `--max` workers run in parallel across chains; tasks within a chain run serially. The host decides the actual concurrency.

### Stranded-dispatch recovery (phase 3)

When a prior run was interrupted, the orchestrator asks the host to either re-spawn workers for stranded rows or mark them as abandoned. The host never silently skips them.

## Worker contract

See `references/worker-contract.md` for the JSON shape returned by each `parallel-fix-worker`.

## Host responsibilities

The host owns:

- whether to spawn workers at all,
- worktree creation and isolation,
- which model each worker uses,
- which tools each worker is permitted,
- the merge step that integrates worker output back into the working branch.

This skill describes the workflow shape; the host enforces what is actually allowed.

## Sequential fallback

If the host cannot spawn parallel workers but can still run shell commands and git operations, the orchestrator can apply phases sequentially:

- run scan angles A → B → C in this thread,
- dispatch fix tasks one at a time, each in its own worktree,
- merge between every task instead of in chained batches.

Quality should not degrade — only parallelism is lost.

If the host cannot spawn workers at all, this skill is not applicable. Suggest a simpler workflow (manual fix queue, single-edit assistant) instead.
