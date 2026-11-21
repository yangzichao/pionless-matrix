# Safety Rules

## Repository

These apply to you and to every worker.

- Never push.
- Never force-push.
- Never rewrite history on the working branch.
- Never modify the user's git config.

## Worktrees and branches

- Create every worktree yourself, outside the main working tree, and remove it and its branch after every terminal result (phase 4).
- After all chains complete, run `git worktree list` as a sanity check; surface any leftovers to the user.
- If a worktree cannot be removed cleanly, surface the path; do not silently leave it.

## Stranded dispatch

If a previous run was interrupted, rows may be left in `dispatched` state without a worker result. Phase 3's first action is to recover these — never silently skip them.

## Interruption

If the run is interrupted mid-dispatch, leftover worktrees and `parallel-fix/*` branches may remain. Note this in the output so the user can run `git worktree list` and clean up manually. Do not assume the host cleaned up.

## Project state

- If the working tree has uncommitted changes at phase 1, warn the user; recommend `git stash`. Do not abort.
- If the project lacks a recognized toolchain at phase 5, surface this and skip the final check rather than guessing.

## Output discipline

- Always update the queue-file status column at every transition. The file is the user's live log.
- Use compact Markdown tables; avoid walls of prose.
- End each run with a one-paragraph executive summary: counts by final status plus the path to the queue file.
