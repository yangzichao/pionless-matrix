---
name: solo-ralph
description: Drive a vague coding goal through user-approved hard requirements, a spec, and a high-level todo list, then launch a detached Ralph loop that runs a fresh non-interactive agent subprocess (claude -p or codex exec) per iteration until every todo item is done. Use when the user wants to start a Ralph loop or solo-ralph on a goal, turn a fuzzy feature idea into a spec-driven autonomous loop that keeps working after this session ends, check the status or progress of a running solo-ralph loop, or stop or cancel one.
compatibility: Needs shell access (bash, nohup, pgrep) and a non-interactive agent CLI on PATH, either claude (claude -p) or codex (codex exec).
metadata:
  version: "1.0.0"
---

# Solo-Ralph

Take a feature from a vague goal to a running fresh-context Ralph loop. Phases 1–3 each gate on **explicit user approval** before advancing. Phase 4 launches the loop in the background and ends your part; the loop keeps going after this session ends.

The input is the goal the user gave. If they asked about a loop that is already running, skip to [Check status](#check-status) or [Stop a loop](#stop-a-loop).

**Concision rule for everything you write**: prefer fewer words, but never at the cost of clarity. Every artifact (`hard-req.md`, `spec.md`, `plan.md`, `PROMPT.md`) is re-read every iteration by a fresh agent with no memory of this conversation. If something needs more words to be unambiguous to that reader, write more words. Confusion compounds.

All paths below are relative to the user's project directory (normally the current working directory), not to this skill's folder. The loop driver is `scripts/ralph-loop.sh` inside this skill's folder; call it by its absolute path.

---

## Phase 0 — goal check + slug

If the goal is missing, or so thin you cannot imagine drafting a hard-req list (one or two ambiguous words, no actionable verb), stop and ask the user for a clearer goal. Do not invent one. Wait for the reply, then continue.

Generate `<slug>` from the goal: lowercase, kebab-case, only `[a-z0-9-]`, at most 30 chars.

If `solo-ralph/<slug>/` already has any of `hard-req.md`, `spec.md`, `plan.md`, ask the user: overwrite, or pick a different slug. Never overwrite silently.

Create `solo-ralph/<slug>/` if absent.

---

## Phase 1 — hard requirements

Draft a numbered list of hard requirements implied by the goal. Short markdown bullets, grouped by topic if useful. Mark items you are **certain** of with ✓ and **assumptions** with **?** so the user can correct them.

Show the draft. End the message with exactly:

> Reply with "OK" (or equivalent approval) to lock these hard-reqs and advance to spec, or tell me what to change.

Iterate as many rounds as the user wants. On clear approval, write the locked numbered list to `solo-ralph/<slug>/hard-req.md` and go to Phase 2.

---

## Phase 2 — spec

Read `solo-ralph/<slug>/hard-req.md`. Draft a spec covering:

- one-line summary of what gets built
- user-visible flow (what they invoke, what happens, what they see)
- artifacts on disk (filenames + lifecycle)
- key design decisions with brief rationale

The spec describes design, not implementation. A few-line illustrative snippet is fine when it makes a decision unambiguous; large code blocks belong in the loop.

Show the draft. End with:

> Reply "OK" to lock the spec and advance to todo, or tell me what to change.

Iterate. On approval, write `solo-ralph/<slug>/spec.md` and go to Phase 3.

---

## Phase 3 — todo

Read `solo-ralph/<slug>/spec.md`. Draft `plan.md` as a flat checklist of **high-level** items. Each item is a self-contained chunk of work that **one fresh-context iteration can finish end-to-end**: possibly a substantial block of code, a whole subsystem, or one cohesive feature slice.

- Name **which file(s) or area** and **what gets built or changed**, at a level the loop can reason about (e.g. "Implement the auth middleware in `src/middleware/auth.ts` per spec §3", not "add line 42 of auth.ts").
- **No code.** The loop writes the code.
- **Size items by judgment, not by quota.** A small feature might be 2–3 items, a bigger one 5–8. Never split a cohesive change into trivial sub-items to fill the list. Every iteration is a cold start with real cost; over-atomized todos cause dozens of spawns doing trivial work, with worse results than fewer, larger items.
- When unsure whether to split an item, keep it whole. The loop subdivides internally if it needs to.

Add this **last item verbatim** (only substitute `<slug>`):

```
- [ ] Self-review: re-read every changed file and check it against `solo-ralph/<slug>/hard-req.md` and `solo-ralph/<slug>/spec.md`. Fix any drift. Repeat until 3 consecutive passes find zero drift.
```

Show the draft. End with:

> Reply "OK" to lock the todo and start the loop, or tell me what to change.

Iterate. On approval, write `solo-ralph/<slug>/plan.md` and go to Phase 4.

---

## Phase 4 — launch

**1. Write `PROMPT.md`** in the project root with this body (substitute `<slug>`). If a `PROMPT.md` already exists there and was not written by solo-ralph, ask the user before replacing it.

````markdown
You are running inside a Solo Ralph Loop. Each iteration is a fresh, non-interactive agent subprocess with no prior conversation history. Everything you need is on disk.

Read in this order:

1. `solo-ralph/<slug>/hard-req.md` — what the user actually needs
2. `solo-ralph/<slug>/spec.md` — the agreed design
3. `solo-ralph/<slug>/plan.md` — the todo list

Pick the **first** `[ ]` item in `plan.md`. Implement it. When it works (build/tests pass if applicable), mark it `[x]` and append a one-line note on the same line describing what changed.

If every item is `[x]`, run `touch .ralph-stop` and exit. The loop driver will detect the stop file and stop.

If the current item is blocked (needs user input, missing dependency, ambiguous spec), leave it `[ ]` and exit. Do not invent. Do not skip ahead. The next iteration will retry from a fresh context. If 3 iterations in a row exit with a non-zero code, the loop driver stops on its own.
````

**2. Pick the runner.** Use the CLI the user asked for (`claude` or `codex`). If they did not say, pass the one matching the host you are running in when it is one of those two; otherwise omit `--runner` and the script uses `$RALPH_RUNNER`, else the first of `claude`, `codex` found on PATH. Anything after `--` is passed through to the runner (for example `-- --model <model>`).

**3. Launch.** If you have shell access, run from the project directory:

```bash
bash <skill-folder>/scripts/ralph-loop.sh start --runner <claude|codex>
```

`start` takes the lock atomically (refuses if a loop is already running here), launches the loop detached with `nohup`, waits a second, and confirms it is still alive. It prints the PID and the exact status/cancel commands. If it fails, show the user its error and the `.ralph.out` tail it prints; do not retry blindly.

Without shell access, give the user that exact command (with the real absolute skill path) to run in their own terminal from the project directory.

**4. Report to the user**, then stop. The loop never asks the user anything.

- slug
- artifacts written: `solo-ralph/<slug>/{hard-req,spec,plan}.md`, `PROMPT.md`
- loop PID and runner
- monitor: ask for the loop status, or `tail -f .ralph-progress.log`
- stop: ask to cancel the loop, or run the `cancel` command `start` printed
- suggest committing `solo-ralph/<slug>/` and git-ignoring `.ralph.pid`, `.ralph.out`, `.ralph-progress.log`, `.ralph-stop`
- the loop survives this session ending

The inner runner does not stop for permission prompts. With claude it skips them entirely (`claude -p --dangerously-skip-permissions`); with codex it auto-approves inside the workspace-write sandbox (`codex exec --approve-for-me`). A Ralph loop is autonomous by definition; mention this once so the user knows what they launched.

---

## Check status

When the user asks how a loop is doing, read `references/status.md` and follow it.

## Stop a loop

When the user asks to stop, cancel, or kill a loop, read `references/cancel.md` and follow it.

---

## How the loop works

```
solo-ralph/<slug>/{hard-req,spec,plan}.md + PROMPT.md   (phases 1–4, interactive)
  └─ ralph-loop.sh start  →  nohup ralph-loop.sh run  (detached)
       ├─ iter 1: fresh runner subprocess, PROMPT.md on stdin
       ├─ iter 2: fresh runner subprocess, PROMPT.md on stdin
       └─ ... until an iteration finds every item [x] and touches .ralph-stop
```

The driver is dumb on purpose. It never inspects the agent's output for "done". It exits only when:

- `.ralph-stop` exists between iterations (written by the loop when all items are `[x]`, or by cancel)
- it receives a signal (cancel, Ctrl-C)
- 3 consecutive iterations exit non-zero (broken-loop detector, not a budget cap)

There is no iteration, wall-time, or spend cap by default. `--max N` and `--max-minutes N` exist if the user asks for one.

Files in the project directory:

| File | Purpose | Lifetime |
| --- | --- | --- |
| `solo-ralph/<slug>/hard-req.md` | Locked hard requirements | Frozen after phase 1 |
| `solo-ralph/<slug>/spec.md` | Locked design spec | Frozen after phase 2 |
| `solo-ralph/<slug>/plan.md` | Todo checklist | Updated by the loop each iteration |
| `PROMPT.md` | Loop seed read every iteration | Frozen after phase 4 |
| `.ralph.pid` | Driver PID; also the start lock (`INIT` while starting) | Removed when the driver exits |
| `.ralph-progress.log` | `=== ralph iter N @ TS (runner) ===` and `--- iter N done rc=R ---` per iteration | Append-only |
| `.ralph.out` | Full stdout/stderr of the driver and every runner call | Append-only |
| `.ralph-stop` | Asks the loop to exit between iterations | Removed by the loop on detection |

Run `bash <skill-folder>/scripts/ralph-loop.sh --help` for every option.
