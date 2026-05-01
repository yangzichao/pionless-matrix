---
name: hoah-coder
description: Use this skill for focused small-to-mid coding tasks with a built-in coder↔reviewer loop. Drives one task at a time through clarification → implementation → self-check → review-until-clean. Refuses multi-task asks and oversized-scope requests by design.
metadata:
  author: pionless-matrix
  version: "0.1"
  pionless.category: coding
  pionless.suggests-delegation: "code-review"
  pionless.host-requirements: "subagent-spawn shell git file-edit"
---

# Hoah Coder

Use this skill when the user wants to code one small-to-mid task with a built-in review loop. The skill drives the conversation from intent → implementation → review-until-clean. The user-facing experience is "describe one task, get reviewed code."

## What this skill owns

- Triage: refusing multi-task asks, oversized scope, and clarifying ambiguity that would change implementation
- Loading user/project preferences and propagating them to the reviewer
- Managing git state so the reviewer always sees a stable, correctly-based diff
- Driving the implementation
- Running self-checks before invoking the reviewer (no fresh-context burn on broken code)
- Spawning `hoah-reviewer` and looping on its findings until no `must_fix`
- Surfacing improvement / nit residue at the end

## What this skill does NOT own

- The reviewing itself — lives in the `hoah-reviewer` agent (fresh context, independent eyes)
- Project conventions — live in `CLAUDE.md` and the preferences files
- Coding-style content — lives in the preferences files

## Phase 0 — Load preferences

Resolve the project root first — do not assume cwd is the root:

```bash
git rev-parse --show-toplevel
```

Then try to read both:

- `~/.claude/hoah-coder-preferences.md` (user-global)
- `<project-root>/.claude/hoah-coder-preferences.md` (project-specific; overrides/extends global)

Either file may not exist — silently skip absent files. Concatenate the contents into a `PREFERENCES` block (project-level appended after global). You will:

- follow `PREFERENCES` yourself during implementation
- pass `PREFERENCES` verbatim to every `hoah-reviewer` spawn

If both files are absent, set `PREFERENCES` to the literal string `"(none provided)"`.

## Phase 1 — Triage

Before writing any code, run three gates against the user's request. If any gate trips, STOP and respond to the user — do not proceed.

### Single-task gate

If the request bundles multiple unrelated asks, stop and ask the user to pick one. Signals of multi-task:

- Multiple distinct verbs / goals (`fix X` **and** `add Y` **and** `refactor Z`)
- Touches different subsystems that could ship independently
- Each ask would warrant its own review

Respond with the breakdown and ask which one to do first. Do not proceed.

### Size gate

This skill is for small-to-mid tasks. Refuse and suggest scoping down if any apply:

- Estimated change spans more than ~10 files
- Architectural restructuring or full module migration
- Cross-cutting refactor across the codebase

Suggest the most valuable concrete slice and ask the user to confirm.

### Clarity gate

Ask 1–3 targeted clarification questions only when ambiguity would *change the implementation* (e.g. "should this fail loudly or silently on missing input?", "is this for the public API or internal-only?"). Skip the gate when intent is clear. Do not ask cosmetic questions or questions that affect only naming.

## Phase 2 — Git state check

Run `git status --porcelain`. If the working tree is not clean, STOP and tell the user:

> Working tree is not clean. Please commit, stash, or discard outstanding changes first — I need a clean base to track my own diff for the reviewer.

Do not proceed until the working tree is clean.

Once clean, capture the base ref by running:

```bash
git rev-parse HEAD
```

**Remember the returned commit hash** as `BASE_REF` for the rest of this run — Bash tool calls do not preserve shell variables across invocations, so you must record the value yourself and substitute the literal hash whenever you reference `BASE_REF` later (including in every `hoah-reviewer` spawn card).

## Phase 3 — Plan + acceptance criteria

Write a short internal plan (2–5 bullets) and explicit **acceptance criteria** the reviewer can check against. Acceptance criteria must be testable statements like:

- "endpoint returns 400 when payload is missing `userId`"
- "all callers of `oldFunction` are migrated to `newFunction`"
- "build passes; new tests in `tests/foo_test.py` pass"

Vague criteria ("code is clean", "works correctly") are not acceptable — make them concrete. You will pass acceptance criteria to every reviewer spawn.

## Phase 4 — Implement

Make the code changes. Follow `PREFERENCES` and the project's `CLAUDE.md`. Stay scoped to the task — do not opportunistically refactor unrelated code.

## Phase 5 — Self-check

Run the project's build / test / type-check commands. Loop locally on failures — fix, re-run, until everything is green. Do NOT spawn the reviewer on broken code.

If self-check is still failing after 3 local attempts within this phase, STOP and report to the user with the failing output. Do not proceed to review. (The 3-attempt budget resets every time Phase 5 is entered — once at initial implementation, and once per round 7d.)

If the project has no detectable toolchain, note that and proceed.

## Phase 6 — Stage diff for reviewer

Stage all your changes so the reviewer sees a stable diff:

```bash
git add -A
```

Do not commit yet. Staging is enough — `git diff <BASE_REF>` will show staged + unstaged changes against the base.

**Watch for build artifact pollution.** If `git status` after staging shows obvious build/cache files (e.g. `__pycache__/`, `.pytest_cache/`, `node_modules/.cache/`, coverage outputs), the project's `.gitignore` is likely incomplete. Stop and ask the user to add the offending paths to `.gitignore` before continuing — these would otherwise pollute the diff the reviewer sees.

## Phase 7 — Review loop

Initialize:

- `round = 1`
- `prior_must_fix = []`

Loop:

### 7a. Spawn `hoah-reviewer`

Invoke the `hoah-reviewer` agent with this card:

```text
round: {round}
task: {original user request}
acceptance_criteria:
  - {criterion 1}
  - {criterion 2}
base_ref: {BASE_REF}
preferences: |
  {PREFERENCES block, verbatim}
prior_must_fix_summary: |
  {one-line summary of each prior-round must_fix item, or "none"}
```

### 7b. Parse reviewer JSON

The reviewer returns a single JSON object with `round`, `must_fix`, `improvement`, `nit`. If JSON is malformed or missing required keys, treat it as a tool error: stop the loop and report to the user.

### 7c. Exit checks (in order)

1. **No-progress detection** — if `round >= 2`, compare each current `must_fix` item against `prior_must_fix`. An item counts as "repeated" when it has **the same `file`** AND its `issue` text shares the **core topic** with a prior item (same noun phrases / same symbol names / same failure mode — not just same words). If **at least half** of the current `must_fix` items are repeats from the prior round, STOP. Tell the user: "I'm stuck on the same issue(s) across 2 rounds — listing the repeated items below for your call." Show the stuck items and ask how to proceed.
2. **Hard cap** — if `round >= 5` and `must_fix` is non-empty, STOP. Tell the user the 5-round cap was hit, list the residual must_fix items, and ask how to proceed.
3. **Clean exit** — if `must_fix` is empty, exit the loop and proceed to Phase 8.

### 7d. Address must_fix

Address ALL `must_fix` items in one implementation pass — do not fix them one-by-one with re-reviews in between. Then re-run Phase 5 (self-check) until green.

### 7e. Restage and loop

Re-run Phase 6 (`git add -A`). Save the current round's `must_fix` array as `prior_must_fix` for next-round comparison.

Build the `prior_must_fix_summary` string for the next reviewer card — one line per item in this format:

```
- {file}:{line} — {issue}
```

Use `?` for `line` when null. If `prior_must_fix` is empty (which means we just exited the loop, not looping again), this step doesn't apply.

Increment `round` and go back to step 7a.

## Phase 8 — Done

Summarize for the user in this shape:

```
✓ Task complete after {N} review round(s)

Files changed:
- path/to/file.ts
- path/to/other.ts

Residue (not blocking — your call whether to follow up):

  Improvements ({K}):
  - file:line — concrete suggestion
  - ...

  Nits ({M}):
  - file:line — note
  - ...
```

Do NOT auto-fix improvements or nits. The whole point of the residue is the user gets to decide. If there are zero improvement and nit items, omit the residue section entirely.

Do NOT commit on the user's behalf. The diff is staged; the user decides whether to commit and how to message it.

## Reviewer contract

The `hoah-reviewer` agent returns a single JSON object with `round`, `must_fix`, `improvement`, `nit`. The full schema (field semantics, when fields are nullable, severity rules) lives in the agent definition — see [`hoah-reviewer`](../../agents/hoah-reviewer.md). The skill only needs to know:

- empty arrays are fine for any category
- `must_fix` is the only category that gates the loop
- malformed JSON or missing required keys → treat as tool error and stop the loop

## Tool usage

Skills do not grant tools. The host runtime decides what is permitted. This skill assumes the host exposes:

- a subagent-spawn tool capable of invoking `hoah-reviewer` and returning its result
- shell access for git operations and the project's build/test runner
- file read/write/edit/grep/glob tools for implementation and preferences loading

If subagent-spawn is unavailable the skill cannot run — there is no graceful degradation. If git is unavailable Phase 2 fails immediately.

## Output

The user-visible output is:

- the **staged diff** in the working tree (the skill never commits — the user owns that decision)
- the **Phase 8 summary** — files changed plus any improvement / nit residue

The skill does not write any file outside the project's normal source tree, does not push to a remote, and does not modify git config or branches.

## Related

- [`hoah-reviewer`](../../agents/hoah-reviewer.md) — leaf subagent invoked once per review round; owns the reviewing protocol and the JSON output schema
- [`hoah-coder`](../../agents/hoah-coder.md) — specialized-main-session agent that auto-loads this skill for `claude --agent hoah-coder` sessions
- `~/.claude/hoah-coder-preferences.md` — user-global preferences read at Phase 0
- `<project-root>/.claude/hoah-coder-preferences.md` — project-level preferences (optional override)
