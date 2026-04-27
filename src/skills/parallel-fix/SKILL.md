---
name: parallel-fix
description: Use this skill when the user wants to scan a project for a class of issues and fix them in parallel — security audits, bug hunts, lint cleanups, "fix all the TODOs", post-review fixes, type errors, or any batch of independent fixes that can be dispatched to isolated workers and merged back.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: code-maintenance
  pionless.suggests-delegation: "scan-for-issues fix-one-issue final-check"
  pionless.host-requirements: "worker-spawn git-worktree shell"
---

# Parallel Fix

Use this skill when the user wants to scan the project for a class of issues and fix them in parallel. Examples: security audits, bug hunts, lint cleanups, "fix all the TODOs", post-review fixes, type errors.

This skill drives a five-phase orchestrator-worker flow: **find → pause-for-review → dispatch → merge-back → final-check (loop if failing)**.

## When to activate

Activate when:

- the user wants a batch of independent fixes,
- the host runtime supports spawning worker agents,
- the host runtime supports git worktrees and shell access,
- the project has a working tree that workers can branch from.

If any of those is missing, see `references/host-requirements.md` for fallback guidance.

## Invocation

Typical user invocations:

- `/parallel-fix check auth module for security issues`
- `/parallel-fix find obvious bugs in src/ --max 6`
- `/parallel-fix clean up unused imports across the repo`

The host parses the argument string:

- `--max N` (optional, default **4**) — max parallel workers per batch.
- Everything else is the **description** of what to find.

If the description is empty, ask the user what to look for and stop.

## Workflow

Five phases. Each one has its own reference file with the detailed procedure.

1. **Find & draft** — aggressive multi-angle scan, write a queue file, pause. See `references/phase-1-scan.md`.
2. **User review** — wait for the user to prune, expand, or approve. See `references/phase-2-review.md`.
3. **Parallel dispatch** — chain tasks by file overlap, dispatch in parallel across chains, serial within each chain. See `references/phase-3-dispatch.md`.
4. **Merge back** — per-task merge into the working branch, conflict resolution, worktree cleanup. See `references/phase-4-merge.md`.
5. **Final self-check** — run the project's test suite; loop into a follow-up round on failure (max 3 rounds). See `references/phase-5-final-check.md`.

## Resources

- `references/host-requirements.md` — what the host runtime must support.
- `references/phase-1-scan.md` — the multi-angle scan procedure.
- `references/phase-2-review.md` — the user-review pause.
- `references/phase-3-dispatch.md` — chain computation and parallel dispatch.
- `references/phase-4-merge.md` — merge-back and worktree cleanup.
- `references/phase-5-final-check.md` — final test and follow-up loop.
- `references/checklist-by-category.md` — seed checklists for security / bugs / performance / types / lint / tests / docs.
- `references/worker-contract.md` — what the parallel-fix-worker agent returns and how the orchestrator parses it.
- `references/queue-file-conventions.md` — the queue file location, naming, and Files-column parser rules.
- `references/safety-rules.md` — never push, never force-push, stranded-dispatch recovery.
- `references/delegation-patterns.md` — how this skill leans on host worker-spawn capability.
- `assets/queue-file-template.md` — the queue-file Markdown skeleton.
- `assets/task-card-template.md` — the per-task card the orchestrator builds for each worker.

## Tool usage

Skills do not grant tools. The host runtime decides what is permitted. This skill's flow assumes the host exposes the following:

- a worker-spawn tool with git-worktree isolation,
- shell access for git operations and the project's test runner,
- file read/write/edit/grep/glob tools for the orchestrator's scanning and queue management.

If any of these is unavailable, see `references/host-requirements.md`. The skill is not designed to run without worker-spawn — degradation modes are limited.

## Output

The queue file is the user's live log. Path: `<project>/.claude/fix-queue/YYYYMMDD-HHMM-<slug>.md`. The orchestrator updates the queue file's status column at every transition. See `references/queue-file-conventions.md` and `assets/queue-file-template.md`.

## Related

- `parallel-fix-worker` agent — the single-fix worker the host spawns once per task. See `references/worker-contract.md` for the orchestrator/worker boundary.
