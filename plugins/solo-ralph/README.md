# solo-ralph

A self-driving Ralph Loop for Claude Code.

`/solo-ralph "<goal>"` drives a vague goal through four phases — **hard-req → spec → todo → loop** — with explicit user review at each gate. The final phase launches a real Ralph Loop: each iteration spawns a fresh `claude -p` subprocess, no conversation history carries across, all state lives on disk.

## Why this exists

Ralph Loops only converge if the prompt is precise. A vague goal in, a token furnace out. `solo-ralph` puts a structured spec compiler in front of the loop so the loop has something to converge on.

It also fixes three latent bugs in the underlying loop driver: a TOCTOU race in the PID lock, stale `.ralph.pid` after clean exit, and `/solo-ralph-cancel` orphaning a live `claude -p` subprocess when it SIGTERMs the parent bash.

## Quickstart

```
/solo-ralph "add multi-mood pet system to MoodPet.swift"
```

You will be walked through:

1. **Hard requirements** — Claude drafts, you review and correct, you say "OK".
2. **Spec** — Claude drafts the design from the locked hard-reqs, you review, you say "OK".
3. **Todo** — Claude drafts a **high-level** checklist (each item = one substantial chunk of work for one fresh-context loop iteration; no code), you review, you say "OK".
4. **Loop** — Claude writes `PROMPT.md`, launches `ralph-loop.sh` detached, exits.

After phase 4 the loop iterates until every todo item is `[x]` and the last item (mandatory: a 3-pass self-review against the locked hard-req + spec) passes. Then Claude inside the loop runs `touch .ralph-stop` and the loop exits.

Monitor with `/solo-ralph-status`. Stop with `/solo-ralph-cancel`.

## Commands

| Command | What it does |
| --- | --- |
| `/solo-ralph [goal]` | Run all four phases. Asks for a goal if you did not pass one. Refuses to launch if a loop is already running in this directory. |
| `/solo-ralph-cancel` | Touches `.ralph-stop` for clean exit between iterations. After 5s, walks the process tree and SIGTERMs every descendant before the loop driver itself, so no orphaned `claude -p` keeps running. |
| `/solo-ralph-status` | Shows PID liveness, last 20 progress markers, last 30 stdout/stderr lines. |

## Files

In your working directory after `/solo-ralph`:

| File | Purpose | Lifetime |
| --- | --- | --- |
| `solo-ralph/<slug>/hard-req.md` | Locked hard requirements | Frozen after phase 1 |
| `solo-ralph/<slug>/spec.md` | Locked design spec | Frozen after phase 2 |
| `solo-ralph/<slug>/plan.md` | Todo checklist | Mutated by the loop each iteration |
| `PROMPT.md` | Loop seed read every iteration; points at the three files above | Frozen after phase 4 |
| `.ralph.pid` | Loop driver PID. Atomic-create lock (`set -o noclobber`). Auto-removed on script exit via `trap`. | Loop runtime |
| `.ralph-progress.log` | One line per iteration: `=== ralph iter N @ TS (claude) ===` and `--- iter N done rc=R ---` | Append-only |
| `.ralph.out` | Full stdout/stderr of every `claude -p` subprocess | Append-only |
| `.ralph-stop` | Touch to ask the loop to exit cleanly between iterations | Removed by the loop on detection |

`solo-ralph/<slug>/` is your design-doc folder; commit it. `.ralph.*` are runtime files; gitignore them.

## How it works

```
/solo-ralph "<goal>"
  │
  ├─ Phase 1 (interactive)  → solo-ralph/<slug>/hard-req.md
  ├─ Phase 2 (interactive)  → solo-ralph/<slug>/spec.md
  ├─ Phase 3 (interactive)  → solo-ralph/<slug>/plan.md
  └─ Phase 4 (launch)
       └─ nohup bash $CLAUDE_PLUGIN_ROOT/scripts/ralph-loop.sh -p PROMPT.md &
            ├─ iter 1: cat PROMPT.md | claude -p ...    (fresh subprocess)
            ├─ iter 2: cat PROMPT.md | claude -p ...    (fresh subprocess)
            ├─ ...
            └─ (in some iteration) all plan.md items [x] → touch .ralph-stop → loop exits
```

## Loop exit conditions

The loop never auto-detects "done" by inspecting Claude's output — all completion logic lives in `PROMPT.md`. The loop exits when:

- `.ralph-stop` exists (clean exit between iterations — set by Claude when all todo `[x]`, or by `/solo-ralph-cancel`)
- the process is killed (SIGTERM via `/solo-ralph-cancel`, Ctrl-C, etc.)
- 3 consecutive iterations exit with rc ≠ 0 (broken-loop detector; not a budget cap)

By design, there is **no** iteration cap, **no** wall-time cap, and **no** spend cap. The loop runs until the work is done. If you want to stop it, `/solo-ralph-cancel`.

## Codex variant

`/solo-ralph` itself is claude-only in v0 — extra args are not forwarded to `ralph-loop.sh`. If you want a codex-driven loop, run the script directly after phase 4 has produced `PROMPT.md`:

```
bash plugins/solo-ralph/scripts/ralph-loop.sh -p PROMPT.md --cmd codex
```

## Design notes

**The loop is dumb on purpose.** It only knows three exit conditions: `.ralph-stop`, signal, consecutive failures. There is no `<promise>` tag scanning, no exit-code regex, no AI judgement. All "are we done?" logic lives in `PROMPT.md`. This keeps the loop driver under 150 lines of bash and impossible to fool with hallucinated completion claims.

**The spec compiler is in front, not inside.** Phases 1–3 are a single interactive Claude session that gates each transition on explicit user approval. Once phase 4 hands off, the loop never asks the user anything; it either finishes or hits the broken-loop detector.

**`.ralph.pid` is the lock and the auto-cleanup.** `/solo-ralph` claims the lock atomically with `set -o noclobber`. `ralph-loop.sh` removes `.ralph.pid` on exit via `trap EXIT`, so a clean exit does not leave a stale PID file behind for the next start to misread.

**Cancel walks the process tree.** SIGTERMing only the loop driver bash leaves the in-flight `claude -p` orphaned and still spending tokens. `/solo-ralph-cancel` runs a post-order tree walk (`pgrep -P` recursively) and SIGTERMs every descendant before the driver itself.

**`--dangerously-skip-permissions` is on for the inner loop.** The loop is autonomous by definition. If you want a permission prompt on every tool call, you do not want a Ralph loop — you want a normal Claude session.
