# real-ralph

A **real** Ralph Loop for Claude Code.

Each iteration spawns a **fresh** `claude -p` subprocess. Zero conversation history carries across iterations — all state lives on disk (your prompt file, the repo, git, logs). This is the original Geoffrey Huntley pattern, not the in-session stop-hook variant.

## Why this exists

The widely-installed `ralph-loop` plugin uses a Claude Code Stop hook to intercept session exit and re-feed the same prompt back into the **same** session. Context, tool state, and message history accumulate across "iterations" — which is the opposite of what Ralph Loop is designed to do.

This plugin runs the real thing:

```bash
while :; do
  cat PROMPT.md | claude -p --dangerously-skip-permissions
done
```

Driven by a shell loop, detached from the Claude session that started it.

## Install

This plugin lives inside the [pionless-agent](../../) repo. Add the repo as a Claude Code marketplace and install:

```
/plugin marketplace add <this-repo>
/plugin install real-ralph
```

Or run the bundled script directly without installing:

```
bash plugins/real-ralph/scripts/ralph-loop.sh --help
```

## Quickstart

1. In your working repo, create `PROMPT.md`. Example:

   ```markdown
   Read AGENTS.md. Pick ONE unchecked task. Implement it.
   Run the tests. If they pass, mark the task [x] and commit.
   If every task is [x], write DONE to STATUS.md and stop.
   ```

2. From inside Claude Code, in that working repo:

   ```
   /real-ralph --max 20
   ```

   The loop launches in the background and survives this session ending.

3. Monitor:

   ```
   /real-ralph-status
   # or in a shell:
   tail -f .ralph-progress.log
   ```

4. Stop:

   ```
   /real-ralph-cancel
   ```

## Commands

| Command | What it does |
| --- | --- |
| `/real-ralph [args]` | Start the loop, detached via `nohup`+`disown`. Forwards `args` to `ralph-loop.sh`. Refuses to start if `.ralph.pid` already points to a live process. |
| `/real-ralph-cancel` | Asks the loop to exit cleanly between iterations (creates `.ralph-stop`), then SIGTERMs the process if it doesn't exit within 5s. |
| `/real-ralph-status` | Prints the PID (alive or stale), last 20 lines of `.ralph-progress.log`, last 30 lines of `.ralph.out`. |

### `ralph-loop.sh` flags (forwarded via `/real-ralph`)

```
-p, --prompt PATH              Prompt fed to each iteration (default: PROMPT.md)
-n, --max N                    Stop after N iterations (0 = infinite, default: 0)
-s, --stop-file PATH           Stop signal file (default: .ralph-stop)
-c, --cmd NAME                 claude | codex (default: claude)
-l, --log PATH                 Per-iteration log (default: .ralph-progress.log)
-f, --max-consecutive-failures N
                               Exit after N consecutive iterations with rc!=0
                               (0 = disabled, default: 3)
-t, --max-minutes N            Exit once wall-clock runtime exceeds N minutes
                               (0 = disabled, default: 0)
    --dry-run                  Print what would run, don't invoke
    --cancel                   Create the stop file and exit
```

## How it works

```
/real-ralph
  └─ nohup bash $CLAUDE_PLUGIN_ROOT/scripts/ralph-loop.sh --max 20 &
       └─ iter 1: cat PROMPT.md | claude -p ...    (fresh subprocess)
       └─ iter 2: cat PROMPT.md | claude -p ...    (fresh subprocess)
       └─ iter 3: cat PROMPT.md | claude -p ...    (fresh subprocess)
       └─ ...
```

Files in your working directory:

| File | Purpose |
| --- | --- |
| `PROMPT.md` | The task. Re-read at the start of every iteration. **You write this.** |
| `.ralph.pid` | PID of the loop driver. Checked by `/real-ralph` to refuse double-start. |
| `.ralph-progress.log` | One line per iteration: `=== ralph iter N @ TIMESTAMP (claude) ===` and `--- iter N done rc=R ---`. |
| `.ralph.out` | Full stdout/stderr of every `claude -p` subprocess. |
| `.ralph-stop` | Touch to ask the loop to exit cleanly between iterations. Removed by the loop on detection. `/real-ralph-cancel` creates it for you. |

The loop never auto-detects "done" — it stops when:

- `--max N` iterations is reached, or
- `--max-minutes N` wall-time is reached (checked between iterations), or
- `--max-consecutive-failures N` is hit (default: 3 — exits if rc!=0 three times in a row), or
- `.ralph-stop` exists (clean exit between iterations), or
- The process is killed (`/real-ralph-cancel` SIGTERM, Ctrl-C, etc.).

If you want the loop to self-terminate, tell `PROMPT.md` to `touch .ralph-stop` when its acceptance criteria are met.

## Codex variant

```
/real-ralph --cmd codex --max 20
```

Each iteration runs `codex exec --full-auto "$(cat PROMPT.md)"` instead. Requires `codex` on `PATH`.

## Comparison

| | `ralph-loop` (in-session) | **`real-ralph`** |
| --- | --- | --- |
| Loop driver | Claude Code Stop hook | OS shell loop |
| Per iteration | Same session, prompt re-fed | Fresh `claude -p` subprocess |
| History across iterations | Accumulates | None — disk only |
| Survives session exit | No (loop is the session) | Yes (detached via nohup) |
| Stop signal | `<promise>` tag in output | `.ralph-stop` file, SIGTERM, `--max` |

## Design notes

**Detached by default.** `/real-ralph` launches with `nohup … & disown`. The launching Claude session is a starter, not the host — close it, the loop keeps going. This is what makes Ralph practical: you start it, walk away, come back hours later.

**The loop is dumb on purpose.** It only knows three exit conditions: `--max`, `.ralph-stop`, signal. There is **no** completion detection (no `<promise>` tag scanning, no exit-code regex, no AI judgement). All "are we done?" logic lives in `PROMPT.md` — if the task is complete, the prompt itself instructs Claude to `touch .ralph-stop`. This keeps the loop driver under 100 lines of bash and impossible to fool with hallucinated completion claims.

**Two log files, not one.** `.ralph-progress.log` gets only the iteration markers (`=== ralph iter N ===`). `.ralph.out` gets full subprocess output. Tailing the progress log gives you a clean heartbeat; tailing `.ralph.out` shows what Claude is actually doing. Separating them avoids `grep`-ing iteration boundaries out of megabytes of tool output.

**`.ralph.pid` is the lock.** `/real-ralph` refuses to start if the PID is alive. This prevents the easy mistake of `/real-ralph` twice and ending up with two loops fighting over the same files.

**Plugin script is canonical; repo-root is a symlink.** The plugin at `plugins/real-ralph/scripts/ralph-loop.sh` ships inside the plugin so it's self-contained when installed via marketplace into `~/.claude/plugins/`. The repo-root [scripts/ralph-loop.sh](../../scripts/ralph-loop.sh) is a relative symlink to the plugin copy — edit the plugin copy, the repo-root path picks it up automatically. No drift risk.

**`--dangerously-skip-permissions` is on.** Ralph is autonomous by definition. If you want a permission prompt on every tool call, you do not want Ralph — you want a normal Claude session.

## Future work

Roughly ordered by usefulness:

- **`/real-ralph-tail`** — convenience command that runs `tail -f .ralph-progress.log` in the foreground so users don't drop to a shell.
- **Exponential sleep between failures.** `--max-consecutive-failures` already exits on N failures; adding a sleep (e.g. `1s, 2s, 4s, …`) between them would make transient errors (rate limits, flaky network) more likely to recover before hitting the cap.
- **Spend cap.** `--max-cost USD` (read from Claude CLI's usage output if available). Complements `--max-minutes`; cheaper failure mode for expensive tasks.
- **Structured metadata log.** A `.ralph-progress.jsonl` alongside the human log: `{iter, started_at, ended_at, rc, duration_s}` per line. Easier to plot and to detect stalls.
- **Multi-directory concurrent loops.** Already works (state is cwd-scoped), but `/real-ralph-status` only sees the cwd. A `--all` flag could scan known PID files.
- **Pionless-agent integration.** A `/real-ralph-research "<question>"` command that auto-writes a `PROMPT.md` driving the existing `deep-research` agent, then starts the loop. Bridges Ralph (real, fresh process per iter) with this repo's research operating model.
- **Marketplace publish.** Currently only installable from this repo. Ship as a standalone marketplace entry once the design settles.
- **Codex parity audit.** `--cmd codex` is implemented but less battle-tested than `--cmd claude`; verify rc semantics, prompt-size limits, and that `--full-auto` is the right flag long-term.
- **Windows support.** Bash-only today. A PowerShell port or a thin Python driver would broaden reach (but adds a dependency).
- **Optional completion detector** as a *strict opt-in* (`--done-when-file STATUS.md` or `--done-when-grep PATTERN LOG`). Resist temptation to add AI-based detection — it defeats the "loop is dumb" property.
