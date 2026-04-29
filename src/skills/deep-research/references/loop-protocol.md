# Loop Protocol

You operate in discrete iterations. Every turn is one iteration. The workspace file is your memory between turns. Repeat the loop until the completion gate passes (`completion-gate.md`) or stale rounds force a PASSED state.

## The loop rule

```
EVERY TURN:
  1. Read   → deep-research/<prefix>.workspace.md
  2. Work   → pick one task, gather evidence, update findings
  3. Check  → evaluate the gate checklist, update counters
  4. Write  → overwrite workspace file with updated state
  5. Done?  → if gate passes: draft and dispatch deep-research-writer, stop
            → if not: state what next iteration will do, continue
```

NEVER skip step 1 (read) or step 4 (write). NEVER do all research in a single turn. NEVER write the final report from this thread — dispatch `deep-research-writer`. NEVER skip the writer, even when the gate is forced PASSED by stale rounds.

## Turn 1: Initialization

On the very first turn, do ONLY these things:

1. **Clarify the research question.** Infer when obvious; state the assumption explicitly when not.

2. **Decide the investigation mode (silently).** Pick exactly one of:

   - `search` (default) — comprehensive coverage; the plan board is the master plan; no thesis to refine. Pick when the user wants a review, scan, or summary.
   - `research` — thesis-driven convergence; the orchestrator maintains a Working Thesis that evolves with evidence. Pick when the user wants an answer to a hard question ("should we", "is X true", "why does Y happen", "what's actually going on with Z").

   **Do NOT ask the user about mode.** Do NOT enumerate `search` / `research` in any clarification prompt, do NOT mention the word "mode" in user-facing text. Mode names are confusing under a product called "deep research"; classify silently from the user's wording. If signals are absent, default to `search`. Record the classification in the workspace's Research Question section and continue. Full picker rules live in SKILL.md's *Mode decision* section.

3. **Decide the report style.** Pick exactly one of:

   - `technical-paper` (default) — neutral source-backed analysis. Use when the user wants to understand a topic without a recommendation pre-committed.
   - `position-paper` — argument-driven. Use when the user asks "should we…?", "argue for", "make the case", or wants a defended recommendation.
   - `executive-briefing` — short decision memo (≤1000 words). Use when the user signals brevity ("brief", "TL;DR", "one-pager") or names a stakeholder needing a fast read.
   - `landscape-scan` — categorized survey. Use when the user asks "what's out there", "what are the X options", or wants a comparable map of a space.
   - `design-to-do` — engineering design + topologically-sorted task list. Use when the user asks "design X", "how should we build Y", "plan the implementation of Z".
   - `tutorial` — textbook-style step-by-step concept walkthrough (intuition → worked example → formalism → pitfalls). Use when the user wants to *understand* a complex concept ("explain X step by step", "walk me through Y", "help me understand Z", "教科书风格").

   Pick from user signals. If signals are absent, default to `technical-paper` and **state the assumption explicitly** in the workspace's Research Question section. If signals genuinely conflict (e.g., user wants both a recommendation AND comprehensive coverage), ask the user once before proceeding.

4. **Derive a run prefix** `YYYY-MM-DD-HHMM-<topic>` (see `output-conventions.md`).

5. **Write the workspace file** using `assets/workspace-template.md`. The chosen mode and style go in the Research Question section. If mode = `research`, also write an initial Working Thesis (a placeholder like *"TBD — needs initial evidence"* is fine; the loop will sharpen it).

6. **Do NOT search or spawn workers on turn 1.** Planning only.

## Turn 2+: The gather-check loop

Each subsequent turn:

### READ

Read the workspace file. Parse Loop State, Gate Checklist, and the chosen style. Do not rely on prior conversation turns — the workspace file is the source of truth.

### WORK

Pick the highest-value open task by expected information gain (`plan-board.md`). The chosen style should bias selection — e.g., a `position-paper` run weights "find the strongest opposing view" tasks higher; a `landscape-scan` run prioritizes coverage across categories; a `design-to-do` run prioritizes "prior art / alternatives considered" subquestions. Then:

- Independent tasks exist → spawn `deep-research-worker` workers in parallel via the Agent tool.
- A claim needs verification → spawn `deep-research-verifier`.
- Otherwise → search and read directly.

Task card format for workers:

```
Objective: [one sentence — the subquestion to answer]
Seed queries: [2–3 starting queries]
Acceptance criteria: [what counts as "done"]
```

### UPDATE

Synthesize new evidence into the Findings section. Update the Plan Board: mark completed subquestions, promote follow-ups discovered during investigation, demote tasks that turned out lower-value than predicted.

**Thesis revision (research mode only).** If mode = `research`, after updating Findings, re-read the current Working Thesis and explicitly answer: *does this iteration's evidence sharpen, weaken, or invalidate the thesis?* Then act on the answer:

- **Sharpens** → tighten the wording, raise confidence, or narrow the claim. Note the iteration in `Last revised`.
- **Weakens** → soften the claim, lower confidence, and add a follow-up subquestion that targets the weakening evidence.
- **Invalidates** → rewrite the thesis to match what the evidence now supports; add a follow-up subquestion to confirm the new direction.
- **No change** → write `thesis unchanged this round` in the section and move on. Two consecutive unchanged rounds in research mode is a signal that you may have effectively converged (or that workers are not stress-testing hard enough — consider a contradiction-seeking verifier dispatch next turn).

The thesis is the spine of a research-mode run; if it never moves across the loop, you were really in `search` mode and should say so to the user. Skip this entire substep in `search` mode.

### CHECK

Walk through every Gate Checklist item:

- Check `[x]` if satisfied; uncheck `[ ]` if not.
- If all are checked → set Gate to PASSED.
- If no new evidence this turn → increment Stale rounds.
- If Stale rounds ≥ 2 → set Gate to PASSED (forced: diminishing returns).

### WRITE

Overwrite the workspace file with the updated state per `workspace-reconstruction.md`. Increment Iteration.

### DECIDE

- Gate PASSED → dispatch `deep-research-drafter` then `deep-research-writer` (see *Drafting handoff* below), stop.
- Gate NOT PASSED → state what next iteration targets, continue.

## Drafting handoff

Once the gate passes (organically or forced by stale rounds), you do **not** write the draft and you do **not** write the final report file. Your job at this point is dispatch + glue: hand the workspace to the drafter, then hand the drafter's output to the writer. Synthesis lives in the drafter; craft lives in the writer.

1. **Dispatch the drafter.** Spawn `deep-research-drafter` via the Agent tool with this card:

   ```text
   workspace_path: deep-research/<prefix>.workspace.md
   style: <the style chosen at Turn 1 — technical-paper | position-paper | executive-briefing | landscape-scan | design-to-do>
   mode: <search | research>
   draft_brief: <optional — emphasize X, target ~Y words, audience Z; if the gate was force-terminated by stale rounds, name the unresolved subquestions here so the drafter emits a Limitations section>
   ```

   The drafter reads the workspace and returns a JSON block with `status`, `draft` (prose with inline `[Title](url)` citations), `sources` (deduped, tiered list), `style_targeted`, `mode`, and `notes`.

2. **Handle the drafter's response.**

   - `status: drafted` → proceed to step 3 with the returned `draft` and `sources`.
   - `status: failed` → branch on the reason keyword in `notes`:
     - `malformed_card` → you forgot a required field; rebuild the dispatch.
     - `unknown_style` → correct the style name and re-dispatch.
     - `tool_error` → the drafter could not read the workspace; check the path and re-dispatch, or surface to user if the workspace itself is corrupted.
     - `inconsistent_input` → the workspace is missing a required section; fix the workspace and re-dispatch.

3. **Dispatch the writer.** Spawn `deep-research-writer` via the Agent tool with this card, passing through what the drafter produced:

   ```text
   output_path: deep-research/<prefix>.md
   draft: <the drafter's draft prose verbatim>
   sources: <the drafter's sources list verbatim>
   style: <same style you passed to the drafter>
   craft_brief: <optional — pass through any notes from the drafter, audience, length target, etc.>
   ```

4. **Confirm and stop.** When the writer returns `status: written`, the loop is done. If it returns `failed`, branch on the reason prefix in `notes`:

   - `inconsistent_input` → drafter's draft cited a URL not in the source list (or vice versa). Re-dispatch the drafter to fix, do not paper over the gap yourself.
   - `malformed_card` → required field missing from your dispatch; rebuild and try again.
   - `unknown_style` → you passed a style not in the supported set; correct it and re-dispatch.
   - `tool_error` → the writer could not write the file (permissions, missing directory). Surface to the user — do not silently retry.

5. **Surface notes if non-empty.** If `status: written` but the writer's `notes` is non-empty (e.g., draft cited a source not in the list, sections it could not place, ASCII / table content it had to convert, or style-mismatch warnings), include the notes verbatim in your final reply to the user. Do not silently swallow them. Same for any non-empty `notes` from the drafter step — pass those through to the user too.

   If the writer flags a style mismatch (e.g., draft was thesis-shaped but dispatched as `technical-paper`), consider whether to re-dispatch the drafter+writer with the suggested style — but do this once at most per run.

Do NOT bypass the drafter or the writer. The orchestrator skill owns plan-board state and dispatch; the drafter owns synthesis; the writer owns craft. Mixing them collapses the role split that keeps Opus token cost in check.

## Spawning rules

Use `deep-research-worker` for: independent subquestions, domain exploration, parallel evidence gathering.

Use `deep-research-verifier` for: single-sourced claims, contradictions, numeric/date/benchmark checks.

Use `deep-research-drafter` once at gate-pass time to synthesize the workspace into a draft.

Use `deep-research-writer` once at the end to polish the drafter's output into the final report file.

Workers return structured findings; the drafter weaves them into prose; the writer applies craft. The orchestrator never produces long-form prose itself.

See `delegation-patterns.md` for parallel worker, contradiction-seeking, and domain-specialist patterns.

## Stopping rule

Do not stop just because there is enough text. Stop when the report is **substantively supported** — see `completion-gate.md` for the precise criteria.

If stale rounds force a PASSED state with subquestions still unresolved, still dispatch the drafter for a best-effort draft; in the `draft_brief` field, name the unresolved subquestions so the drafter emits a `Limitations` section. The drafter writes that section's prose; you decide what goes in it.
