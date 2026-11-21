---
name: hoah-coder
description: Drives one focused small-to-mid coding task through triage, clarification, implementation, self-check, and an independent review loop that repeats until the reviewer reports no must_fix, then hands back a staged diff plus non-blocking residue. Use when the user wants one coding task done with built-in review, e.g. "fix this bug", "add this endpoint", "implement X with review", "code this and have it reviewed", or when a session is dedicated to a single coding task. Refuses multi-task asks and oversized scope (more than ~10 files, architectural rewrites) by design; not for pure explanation or design discussion with no intended code change.
compatibility: Needs shell access and git, plus file editing. Subagents are optional (the review runs as a separate pass without them).
metadata:
  version: "1.0.0"
---

# Hoah Coder

Use this skill when the user wants to code one small-to-mid task with a built-in review loop. The user-facing experience is "describe one task, get reviewed code": you drive it from intent to implementation to review-until-clean, and hand back a staged diff.

When a whole session is dedicated to this skill, run every coding request through this workflow from the start; do not begin coding outside it. If the user asks for something that is not a coding task (a general explanation, a debugging conversation with no intended code change, an architecture discussion), answer directly without running the workflow.

## What this skill owns

- Triage: refusing multi-task asks and oversized scope, and clarifying ambiguity that would change the implementation
- Loading user and project preferences and passing them to the reviewer
- Managing git state so the reviewer always sees a stable, correctly based diff
- The implementation and the self-checks before review (no fresh-context review of broken code)
- Dispatching the reviewer and looping on its findings until there is no `must_fix`
- Triaging each `must_fix` as accept or dispute, and escalating disputes to the user as tiebreaker
- Surfacing improvement / nit / overturned residue at the end

It does not own the review protocol itself (that is `roles/reviewer.md`, run with independent eyes), project conventions (the project's instruction files), or coding-style content (the preferences files).

## Files

- `roles/reviewer.md`: the full reviewer prompt, including its JSON output schema. Used in Phase 7.
- `assets/review-task-card.md`: the card you fill in for each review round. Read before step 7a.
- `assets/dispute-message.md`: the message shape for disputed findings. Read only when you dispute an item in 7c.
- `assets/final-summary.md`: the Phase 8 summary shape. Read before Phase 8.

## Phase 0 — Load preferences

Resolve the project root first; do not assume the current directory is the root:

```bash
git rev-parse --show-toplevel
```

Then try to read both:

- user-global: `~/.agents/hoah-coder-preferences.md`, or `~/.claude/hoah-coder-preferences.md` if the first is absent
- project: `<project-root>/.agents/hoah-coder-preferences.md`, or `<project-root>/.claude/hoah-coder-preferences.md` if the first is absent (overrides or extends global)

Either file may be missing; skip absent files silently. Concatenate what exists into a `PREFERENCES` block, project-level after global. If both are absent, `PREFERENCES` is the literal string `"(none provided)"`. You will:

- follow `PREFERENCES` yourself during implementation
- pass `PREFERENCES` verbatim in every review task card

## Phase 1 — Triage

Before writing any code, run three gates against the request. If any gate trips, stop and respond to the user. Do not proceed.

### Single-task gate

If the request bundles several unrelated asks, stop and ask the user to pick one. Signals:

- Several distinct verbs or goals (`fix X` and `add Y` and `refactor Z`)
- Touches different subsystems that could ship independently
- Each ask would warrant its own review

Reply with the breakdown and ask which one to do first.

### Size gate

This skill is for small-to-mid tasks. Refuse and suggest scoping down if any apply:

- The change is likely to span more than ~10 files
- Architectural restructuring or a full module migration
- A cross-cutting refactor across the codebase

Suggest the most valuable concrete slice and ask the user to confirm.

### Clarity gate

Ask 1–3 targeted questions only when ambiguity would change the implementation (for example "should this fail loudly or silently on missing input?", "is this public API or internal-only?"). Skip the gate when intent is clear. Do not ask cosmetic or naming-only questions.

## Phase 2 — Git state check

Run `git status --porcelain`. If the working tree is not clean, stop and tell the user:

> Working tree is not clean. Please commit, stash, or discard outstanding changes first — I need a clean base to track my own diff for the reviewer.

Do not proceed until it is clean. Then capture the base commit:

```bash
git rev-parse HEAD
```

Record the returned hash yourself as `BASE_REF` for the rest of the run. Shell variables may not survive between separate command runs, so write the literal hash wherever `BASE_REF` is used later, including every review task card.

## Phase 3 — Plan and acceptance criteria

Write a short internal plan (2–5 bullets) and explicit acceptance criteria the reviewer can check. Criteria must be testable statements, such as:

- "endpoint returns 400 when payload is missing `userId`"
- "all callers of `oldFunction` are migrated to `newFunction`"
- "build passes; new tests in `tests/foo_test.py` pass"

Vague criteria ("code is clean", "works correctly") are not acceptable. You pass the criteria in every review task card.

## Phase 4 — Implement

Make the code changes. Follow `PREFERENCES` and the project's instruction files (for example `AGENTS.md` or `CLAUDE.md`). Stay scoped to the task; do not opportunistically refactor unrelated code.

## Phase 5 — Self-check

Run the project's build, test and type-check commands. Loop locally on failures (fix, re-run) until everything is green. Do not dispatch the reviewer on broken code.

If self-check still fails after 3 attempts in this phase, stop and report the failing output to the user. Do not proceed to review. The 3-attempt budget resets every time you enter Phase 5: once after the initial implementation, and once per round when 7e re-enters it.

If the project has no detectable toolchain, say so and proceed.

## Phase 6 — Stage the diff

Stage all your changes so the reviewer sees a stable diff:

```bash
git add -A
```

Do not commit. `git diff <BASE_REF>` shows staged and unstaged changes against the base.

Watch for build-artifact pollution. If `git status` after staging shows obvious build or cache files (`__pycache__/`, `.pytest_cache/`, `node_modules/.cache/`, coverage output), the project's `.gitignore` is likely incomplete. Stop and ask the user to add those paths to `.gitignore` before continuing; otherwise they pollute the reviewer's diff.

## Phase 7 — Review loop

Initialize:

- `round = 1`
- `prior_must_fix = []`
- `overturned_items = []` (cumulative across rounds: items the user explicitly dropped after a dispute)

### 7a. Dispatch the reviewer

Fill in `assets/review-task-card.md` for this round.

- If you can start subagents: start one with a fresh context (not a fork of this conversation). Give it the full text of `roles/reviewer.md`, then the task card. Ask for read-only work if your host lets you restrict tools; the reviewer still needs shell and git to read the diff and run checks.
- If you cannot: do the review yourself as a separate pass. Re-read `roles/reviewer.md`, work only from the task card and the diff, and produce exactly the JSON it specifies.

### 7b. Parse the reviewer JSON

The reviewer returns one JSON object with the keys `round`, `must_fix`, `improvement`, `nit`. Empty arrays are fine for any category. Only `must_fix` gates the loop. If the JSON is malformed or a required key is missing, treat it as a tool error: stop the loop and report to the user.

### 7c. Triage must_fix, then resolve disputes

For each `must_fix` item, form your own opinion:

- **accept**: the reviewer is right; you will fix it.
- **dispute**: you genuinely believe the reviewer is wrong (incorrect technical claim, misread diff, false positive, or contradicts a deterministic tool result). A dispute needs a one-line counter-argument saying why the finding is wrong.

Default to accept. Dispute only on a real technical disagreement, never on stylistic preference. If unsure, accept. Tool-derived findings (those citing a build, test, lint, type-check or security-scan command) should almost never be disputed; they are deterministic.

If nothing is disputed, go to 7d.

If anything is disputed, stop and send the user the message in `assets/dispute-message.md`. Wait for their verdicts:

- Items the user **upholds** join the fix list, like accepted items.
- Items the user **overturns** are dropped from `must_fix`, appended to `overturned_items`, and reported as residue in Phase 8.

If the user declines to adjudicate or asks to abort, stop the loop and report. After resolution, the working `must_fix` list holds only accepted and upheld items.

### 7d. Exit checks, in order

These run on the resolved `must_fix` list from 7c.

1. **No progress**: if `round >= 2`, compare each current `must_fix` item with `prior_must_fix`. An item is a repeat when it has the same `file` and its `issue` shares the core topic with a prior item (same noun phrases, symbol names or failure mode, not just the same words). If at least half of the current items are repeats, stop and tell the user: "I'm stuck on the same issue(s) across 2 rounds — listing the repeated items below for your call." Show them and ask how to proceed.
2. **Hard cap**: if `round >= 5` and `must_fix` is non-empty, stop. Tell the user the 5-round cap was hit, list the remaining `must_fix` items, and ask how to proceed.
3. **Clean exit**: if `must_fix` is empty, leave the loop and go to Phase 8.

### 7e. Address must_fix

Fix all remaining `must_fix` items in one implementation pass; do not fix them one at a time with re-reviews in between. Then re-run Phase 5 until green.

### 7f. Restage and loop

Re-run Phase 6. Save this round's resolved `must_fix` list as `prior_must_fix`. Build the next card's `prior_must_fix_summary` from `prior_must_fix` and its `prior_overturned_summary` from `overturned_items`, using the line format in `assets/review-task-card.md` (`"none"` when a list is empty). Increment `round` and go back to 7a.

## Phase 8 — Done

Summarize for the user in the shape given in `assets/final-summary.md`: rounds taken, files changed, and residue (improvements, nits, overturned items).

Do not auto-fix improvements or nits; the point of the residue is that the user decides. Do not commit on the user's behalf. The diff stays staged; the user decides whether to commit and how to word the message.

## Output and boundaries

What the user gets:

- the staged diff in the working tree
- the Phase 8 summary

The skill never commits, never pushes to a remote, never changes git config or branches, and writes nothing outside the project's normal source tree.
