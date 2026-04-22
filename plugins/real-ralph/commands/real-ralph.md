---
description: Start a real Ralph Loop in the background. Args forwarded to ralph-loop.sh, e.g. `--prompt PROMPT.md --max 20 --cmd claude`.
allowed-tools: Bash, Read
---

The user wants to start a **real** Ralph Loop — a fresh `claude -p` (or `codex exec`) subprocess per iteration, detached from this Claude session.

User args: `$ARGUMENTS`

Do this in order:

1. Parse `$ARGUMENTS` to find `--prompt PATH` (default: `PROMPT.md` in cwd). If the prompt file does not exist, STOP and tell the user to create it first — show them an example PROMPT.md body. Do not start the loop.

2. Check that another loop is not already running:
   ```bash
   if [ -f .ralph.pid ] && kill -0 "$(cat .ralph.pid)" 2>/dev/null; then
     echo "ralph loop already running (pid=$(cat .ralph.pid)). Use /real-ralph-cancel first."
     exit 1
   fi
   ```
   If one is running, STOP and tell the user.

3. Launch the loop **detached** so it survives this Claude session ending:
   ```bash
   nohup bash "${CLAUDE_PLUGIN_ROOT}/scripts/ralph-loop.sh" $ARGUMENTS \
     > .ralph.out 2>&1 &
   echo $! > .ralph.pid
   disown
   ```

4. Wait ~1 second, then verify the process is alive (`kill -0`). If it died immediately, cat `.ralph.out` so the user sees the error.

5. Report to the user:
   - PID (from `.ralph.pid`)
   - Log file: `.ralph-progress.log` (per-iteration markers) and `.ralph.out` (full subprocess output)
   - Monitor: `tail -f .ralph-progress.log`
   - Stop: `/real-ralph-cancel`

Do NOT run the loop in the foreground. Do NOT block this session waiting on it.
