# Check a solo-ralph loop's status

Use this when the user asks whether a loop is running, how far it got, or why it stopped.

## With shell access

From the project directory the loop runs in:

```bash
bash <skill-folder>/scripts/ralph-loop.sh status
```

Add `-C <project-dir>` if you are not in that directory. The command prints three blocks:

1. **process**: `running pid=N`, `not running`, `stale pid file` (the driver died without cleanup), or `lock held by a starting loop` (a start is in progress; if it persists, the start crashed and `cancel` clears it). A line saying a stop file is present means the loop will exit after its current iteration.
2. **last 20 progress lines** from `.ralph-progress.log`: one `=== ralph iter N @ TS (runner) ===` and one `--- iter N done rc=R ---` per iteration, plus the driver's exit reason.
3. **last 30 output lines** from `.ralph.out`: the runner's own output.

Also read `solo-ralph/<slug>/plan.md` and count `[x]` against `[ ]` items.

## Without shell access

Read the same files directly: `.ralph.pid`, the tail of `.ralph-progress.log`, the tail of `.ralph.out`, and `solo-ralph/<slug>/plan.md`. You cannot confirm the PID is alive; say so.

## What to tell the user

- Running or not, and the PID.
- Current iteration number and how many plan items are done.
- Why it stopped, if it stopped: stop file (work finished, or cancelled), signal, `N consecutive failures`, or a cap.
- Obvious errors in the output tail (auth failure, unknown flag, missing CLI). Repeated non-zero `rc` on the same plan item usually means that item is blocked; suggest the user read it and adjust `plan.md` or `spec.md`.
