# Stop a solo-ralph loop

Use this when the user asks to stop, cancel, or kill a running loop.

## With shell access

From the project directory the loop runs in:

```bash
bash <skill-folder>/scripts/ralph-loop.sh cancel
```

Add `-C <project-dir>` if you are not in that directory. What it does:

1. Creates `.ralph-stop`, so the loop exits cleanly at the next iteration boundary.
2. Waits 5 seconds. If the driver is still alive (it usually is, because an iteration is in flight), it walks the process tree post-order and sends SIGTERM to every descendant first, then the driver. Killing only the driver would orphan the in-flight runner subprocess, which would keep running and spending tokens.
3. Sends SIGKILL to anything that ignored SIGTERM after another 5 seconds.
4. Removes `.ralph.pid` and `.ralph-stop`, and prints the last iteration line from `.ralph-progress.log`.

If there is no loop, or `.ralph.pid` is stale, it clears the stale files and says so.

If the user wants the current iteration to finish first, run `cancel --soft` instead. That only creates `.ralph-stop`; the loop exits after the iteration in flight ends, which can take as long as that item takes.

## Without shell access

Give the user the exact `cancel` command above, with the real absolute skill path, to run in their own terminal from the project directory. Creating an empty `.ralph-stop` file in the project directory is the soft-cancel equivalent if you can write files.

## Report

Tell the user how many iterations ran (the last `=== ralph iter N` line), which plan items are `[x]`, and whether cancel reported any process still alive.
