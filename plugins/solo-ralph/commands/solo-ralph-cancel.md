---
description: Stop a running Solo Ralph Loop. Asks it to exit cleanly between iterations; falls back to walking the process tree and SIGTERMing each descendant, then the loop driver itself.
allowed-tools: Bash
---

Cancel any Solo Ralph Loop running in this directory.

Steps:

1. Create the stop file so the loop exits between iterations (clean):
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/ralph-loop.sh" --cancel
   ```

2. If `.ralph.pid` exists and the process is still alive after a short wait, walk the process tree and SIGTERM every descendant before SIGTERMing the loop driver itself. This avoids orphaning a `claude -p` subprocess that would otherwise keep burning tokens after the parent dies.
   ```bash
   if [ -f .ralph.pid ]; then
     pid=$(cat .ralph.pid)
     for _ in 1 2 3 4 5; do
       kill -0 "$pid" 2>/dev/null || break
       sleep 1
     done
     if kill -0 "$pid" 2>/dev/null; then
       echo "loop still alive after 5s, killing process tree of pid=$pid"
       # Post-order walk: kill descendants first so the loop driver dying does not orphan a live claude subprocess.
       kill_descendants() {
         local p=$1
         local kids
         kids=$(pgrep -P "$p" 2>/dev/null)
         for k in $kids; do kill_descendants "$k"; done
         kill -TERM "$p" 2>/dev/null || true
       }
       kill_descendants "$pid"
     fi
     rm -f .ralph.pid
   fi
   ```

3. Report final status: how many iterations ran (last `=== ralph iter N` line in `.ralph-progress.log`), and confirm no descendants of the loop are still alive (`pgrep -P "$pid"` returns nothing).
