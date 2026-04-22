---
description: Show real Ralph Loop status — running PID, iteration count, last log lines.
allowed-tools: Bash
---

Report the status of the real Ralph Loop in this directory.

```bash
echo "=== process ==="
if [ -f .ralph.pid ]; then
  pid=$(cat .ralph.pid)
  if kill -0 "$pid" 2>/dev/null; then
    echo "running pid=$pid"
  else
    echo "stale pid file (pid=$pid is dead)"
  fi
else
  echo "no .ralph.pid (not started, or already cleaned up)"
fi

echo
echo "=== last 20 progress lines ==="
[ -f .ralph-progress.log ] && tail -n 20 .ralph-progress.log || echo "no .ralph-progress.log yet"

echo
echo "=== last 30 stdout/stderr lines ==="
[ -f .ralph.out ] && tail -n 30 .ralph.out || echo "no .ralph.out yet"
```

Then summarize for the user: is it running? what iteration? any obvious errors in the tail?
