---
name: parallel-fix
description: Scan a project for one class of issues, queue the findings for user review, then fix each one in its own git worktree (in parallel when subagents are available), merge the fixes back, and run a final project-wide check. Use when the user wants a batch of independent fixes rather than one edit — security audits, bug hunts, lint or type-error cleanups, "fix all the TODOs", or applying the findings of a code review.
compatibility: Needs shell access, git with worktree support, and a writable working tree. Subagents are optional; without them the fixes run one at a time.
metadata:
  version: "2.0.0"
---

# Parallel Fix

Scan the project for a class of issues and fix them in isolated git worktrees, then merge them back. Examples: security audits, bug hunts, lint cleanups, "fix all the TODOs", post-review fixes, type errors.

Five phases: **scan → user review → dispatch → merge back → final check (loop if failing)**. You are the orchestrator: you scan, own the queue file, create every worktree, merge, and give the final answer. Workers only fix one task each and return JSON.

## Before you start

You need:

- shell access, to run git and the project's toolchain,
- git with `git worktree`, and a repository with at least one commit that fixes can branch from,
- a writable working tree.

If you have no shell or the project is not a git repository, this skill does not apply. Say so, and offer to list the issues or fix them one by one in the main tree instead.

Subagents are optional. With them, scans and fixes run in fresh contexts, in parallel if your host allows it. Without them you run each scan and each fix yourself, one at a time, following the same role file. Only parallelism is lost: every fix still gets its own worktree, verification and self-check.

## Invocation

Typical requests:

- `parallel-fix check auth module for security issues`
- `parallel-fix find obvious bugs in src/ --max 6`
- `parallel-fix clean up unused imports across the repo`

Parse the request:

- `--max N` (optional, default **4**): the most fix tasks in flight at once.
- Everything else is the **description** of what to find.

If the description is empty, ask the user what to look for and stop.

## Workflow

Read each phase's files before starting that phase.

1. **Scan and draft.** Multi-angle scan, write the queue file, then stop the turn. Read `references/phase-1-scan.md`, `roles/scanner.md`, `references/checklist-by-category.md`, `references/queue-file-conventions.md` and `assets/queue-file-template.md`.
2. **User review.** Wait for the user to prune, expand, or approve. Never dispatch on a guess. Read `references/phase-2-review.md`.
3. **Dispatch.** Recover stranded rows, chain tasks by file overlap, create one worktree per task, and hand each task to a worker following `roles/worker.md`: in parallel across chains, one at a time within a chain. Read `references/phase-3-dispatch.md`, `roles/worker.md` and `assets/task-card-template.md`.
4. **Merge back.** Merge each finished task into the working branch before its chain's next task starts, then remove its worktree and branch. Read `references/phase-4-merge.md`.
5. **Final check.** Run the project's full check in the main tree; on failure start a follow-up round (at most 3). Read `references/phase-5-final-check.md`.

Read `references/safety-rules.md` once before phase 3. It applies to every phase.

## Resources

- `references/phase-1-scan.md`: the multi-angle scan procedure.
- `references/phase-2-review.md`: the user-review pause.
- `references/phase-3-dispatch.md`: stranded-row recovery, chains, worktree creation, dispatch, result handling.
- `references/phase-4-merge.md`: merge-back and worktree cleanup.
- `references/phase-5-final-check.md`: final check and follow-up loop.
- `references/checklist-by-category.md`: seed checklists for security / bugs / performance / types / lint / tests / docs.
- `references/queue-file-conventions.md`: queue file location, naming, columns and statuses.
- `references/safety-rules.md`: never push, never rewrite history, always clean up worktrees.
- `roles/scanner.md`: prompt for one scan angle (read-only).
- `roles/worker.md`: prompt for one fix in one worktree, including its JSON return format.
- `assets/queue-file-template.md`: the queue file skeleton.
- `assets/task-card-template.md`: the per-task card passed to a worker.

## Output

The queue file is the user's live log: `<project>/.parallel-fix/queue/YYYYMMDD-HHMM-<slug>.md`. Update its status column at every transition. End the run with a one-paragraph summary: counts by final status, the final-check result, and the queue file path.
