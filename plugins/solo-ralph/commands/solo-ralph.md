---
description: Drive a vague goal through hard-req → spec → todo, then launch a fresh-subprocess Ralph loop to execute it. Args: optional `<goal>` describing what to build.
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Solo-Ralph

The user wants to take a feature from a vague goal to a running fresh-context Ralph loop. You will run them through 4 phases. Each of phases 1–3 gates on **explicit user approval** before advancing. Phase 4 launches the loop and ends this session; the loop continues in the background.

User goal (raw): `$ARGUMENTS`

**Concision rule for everything you write below**: prefer fewer words, but never at the cost of clarity. If something needs more words to be unambiguous to a fresh-context Claude reading it later, write more words. Every artifact (`hard-req.md`, `spec.md`, `plan.md`, `PROMPT.md`) will be re-read every loop iteration by a fresh subprocess — confusion compounds.

---

## Phase 0 — goal check + slug

If `$ARGUMENTS` is empty, or so thin you cannot imagine drafting a hard-req list (one or two ambiguous words, no actionable verb), STOP and ask the user to provide a clearer goal. Do not invent. Wait for their reply, then continue.

Generate `<slug>` from the goal: lowercase, kebab-case, only `[a-z0-9-]`, ≤30 chars.

Check if `solo-ralph/<slug>/` already has any of `hard-req.md`, `spec.md`, `plan.md`. If yes, ask the user: overwrite, or pick a different slug. Do not silently overwrite.

Create `solo-ralph/<slug>/` if absent.

---

## Phase 1 — hard requirements

Draft a numbered list of hard requirements implied by the goal. Format: short markdown bullets, grouped by topic if useful. Mark items you are **certain** of with ✓ and items that are **assumptions** with **?** — user will correct the assumptions.

Show the draft to the user. End the message with exactly:

> Reply with "OK" (or equivalent approval) to lock these hard-reqs and advance to spec, or tell me what to change.

Iterate as many rounds as the user wants. On clear approval, write the locked numbered list to `solo-ralph/<slug>/hard-req.md` and proceed to Phase 2.

---

## Phase 2 — spec

Read `solo-ralph/<slug>/hard-req.md`. Draft a spec covering:

- one-line summary of what gets built
- user-visible flow (what they invoke, what happens, what they see)
- artifacts on disk (filenames + lifecycle)
- key design decisions with brief rationale

Spec describes design, not full implementation. Small illustrative snippets (a few lines) are fine if they make a design decision unambiguous; large code blocks belong in the loop, not the spec.

Show the draft. End with:

> Reply "OK" to lock the spec and advance to todo, or tell me what to change.

Iterate. On approval, write to `solo-ralph/<slug>/spec.md` and proceed to Phase 3.

---

## Phase 3 — todo

Read `solo-ralph/<slug>/spec.md`. Draft `plan.md` as a flat checklist. Each item:

- exactly one sentence
- says **which file(s)** and **what change** (e.g. "Add function `foo` in `src/bar.ts` that does X")
- contains **no code** — the loop will write the code

Add this **last item verbatim** (do not paraphrase):

```
- [ ] Self-review: re-read every changed file and check it against `solo-ralph/<slug>/hard-req.md` and `solo-ralph/<slug>/spec.md`. Fix any drift. Repeat until 3 consecutive passes find zero drift.
```

Show the draft. End with:

> Reply "OK" to lock the todo and start the loop, or tell me what to change.

Iterate. On approval, write to `solo-ralph/<slug>/plan.md` and proceed to Phase 4.

---

## Phase 4 — launch

Write `PROMPT.md` at the repo root with this body (substitute `<slug>`):

````markdown
You are running inside a Solo Ralph Loop. Each iteration is a fresh `claude -p` subprocess with no prior conversation history. Everything you need is on disk.

Read in this order:

1. `solo-ralph/<slug>/hard-req.md` — what the user actually needs
2. `solo-ralph/<slug>/spec.md` — the agreed design
3. `solo-ralph/<slug>/plan.md` — the todo list

Pick the **first** `[ ]` item in `plan.md`. Implement it. When it works (build/tests pass if applicable), mark it `[x]` and append a one-line note on the same line describing what changed.

If every item is `[x]`, run `touch .ralph-stop` and exit. The loop driver will detect the stop file and stop.

If the current item is blocked (needs user input, missing dependency, ambiguous spec), leave it `[ ]` and exit. Do not invent. Do not skip ahead. The next iteration will retry from a fresh context. If the same item fails 3 iterations in a row (rc ≠ 0), the loop driver exits on its own.
````

Acquire the PID lock atomically (TOCTOU-safe):

```bash
if ! ( set -o noclobber; printf 'INIT\n' > .ralph.pid ) 2>/dev/null; then
  pid=$(cat .ralph.pid 2>/dev/null)
  if [ "$pid" = "INIT" ] || kill -0 "$pid" 2>/dev/null; then
    echo "solo-ralph: already running or starting (pid=$pid). /solo-ralph-cancel first." >&2
    exit 1
  fi
  rm -f .ralph.pid
  if ! ( set -o noclobber; printf 'INIT\n' > .ralph.pid ) 2>/dev/null; then
    echo "solo-ralph: race acquiring lock" >&2
    exit 1
  fi
fi
```

Launch the loop detached:

```bash
nohup bash "${CLAUDE_PLUGIN_ROOT}/scripts/ralph-loop.sh" -p PROMPT.md > .ralph.out 2>&1 &
echo $! > .ralph.pid
disown
```

Verify it stayed alive:

```bash
sleep 1
kill -0 "$(cat .ralph.pid)" 2>/dev/null || { echo "loop died at startup:"; cat .ralph.out; exit 1; }
```

Report to the user:

- slug
- artifacts written: `solo-ralph/<slug>/{hard-req,spec,plan}.md`, `PROMPT.md`
- loop PID
- monitor: `/solo-ralph-status` or `tail -f .ralph-progress.log`
- stop: `/solo-ralph-cancel`
- the loop survives this session ending; you will not interrupt the user again

End the session.
