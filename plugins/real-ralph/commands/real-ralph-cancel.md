---
description: Stop a running real Ralph Loop. Asks it to exit cleanly after the current iteration; falls back to SIGTERM if it doesn't respond.
allowed-tools: Bash
---

Cancel any real Ralph Loop running in this directory.

Steps:

1. Create the stop file so the loop exits between iterations (clean):
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/ralph-loop.sh" --cancel
   ```

2. If `.ralph.pid` exists and the process is still alive after a short wait, send SIGTERM:
   ```bash
   if [ -f .ralph.pid ]; then
     pid=$(cat .ralph.pid)
     for _ in 1 2 3 4 5; do
       kill -0 "$pid" 2>/dev/null || break
       sleep 1
     done
     if kill -0 "$pid" 2>/dev/null; then
       echo "loop still alive after 5s, sending SIGTERM to pid=$pid"
       kill "$pid"
     fi
     rm -f .ralph.pid
   fi
   ```

3. Report final status: how many iterations ran (last `=== ralph iter N` line in `.ralph-progress.log`), and confirm the process is gone.
