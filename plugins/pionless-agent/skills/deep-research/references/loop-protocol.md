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

2. **Decide the report style.** Pick exactly one of:

   - `technical-paper` (default) — neutral source-backed analysis. Use when the user wants to understand a topic without a recommendation pre-committed.
   - `position-paper` — argument-driven. Use when the user asks "should we…?", "argue for", "make the case", or wants a defended recommendation.
   - `executive-briefing` — short decision memo (≤1000 words). Use when the user signals brevity ("brief", "TL;DR", "one-pager") or names a stakeholder needing a fast read.
   - `landscape-scan` — categorized survey. Use when the user asks "what's out there", "what are the X options", or wants a comparable map of a space.
   - `design-to-do` — engineering design + topologically-sorted task list. Use when the user asks "design X", "how should we build Y", "plan the implementation of Z".

   Pick from user signals. If signals are absent, default to `technical-paper` and **state the assumption explicitly** in the workspace's Research Question section. If signals genuinely conflict (e.g., user wants both a recommendation AND comprehensive coverage), ask the user once before proceeding.

3. **Derive a run prefix** `YYYY-MM-DD-HHMM-<topic>` (see `output-conventions.md`).

4. **Write the workspace file** using `assets/workspace-template.md`. The chosen style goes in the Research Question section.

5. **Do NOT search or spawn workers on turn 1.** Planning only.

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

### CHECK

Walk through every Gate Checklist item:

- Check `[x]` if satisfied; uncheck `[ ]` if not.
- If all are checked → set Gate to PASSED.
- If no new evidence this turn → increment Stale rounds.
- If Stale rounds ≥ 2 → set Gate to PASSED (forced: diminishing returns).

### WRITE

Overwrite the workspace file with the updated state per `workspace-reconstruction.md`. Increment Iteration.

### DECIDE

- Gate PASSED → produce a draft, dispatch `deep-research-writer` (see *Drafting handoff* below), stop.
- Gate NOT PASSED → state what next iteration targets, continue.

## Drafting handoff

Once the gate passes (organically or forced by stale rounds), you do **not** write the final report file directly. Your job at this point is synthesis; the writer's job is craft.

1. **Draft.** Read the workspace file one last time. Synthesize a draft in your context window — section-by-section, with all claims attributed and inline citations as `[Source Title](url)`. The draft should be substantively complete (every key point the report needs is in there). Don't worry about template structure or polish; the writer handles that. Don't worry about renumbering citations into `[1]` / `[2]` form either — the writer converts your semantic links into numbered references at write time.

   Loosely target the chosen style's natural shape during drafting (e.g., for `position-paper` lead with the thesis; for `executive-briefing` keep it short; for `design-to-do` produce explicit Decisions and a Task Plan). The writer will reshape any mismatch but starting close saves a re-dispatch.

2. **Assemble the source list.** Deduplicate every URL cited in the draft. Tag each as `primary` or `secondary` and add a one-line note on what it contributed.

3. **Dispatch the writer.** Spawn `deep-research-writer` via the Agent tool with this card:

   ```text
   output_path: deep-research/<prefix>.md
   draft: <the synthesized draft prose, including inline [Title](url) citation markers>
   sources: <the assembled source list>
   style: <the style chosen at Turn 1 — technical-paper | position-paper | executive-briefing | landscape-scan | design-to-do>
   craft_brief: <optional — emphasize X, target ~Y words, audience Z; flag the run as force-terminated by stale rounds if the gate didn't pass organically, so the writer keeps a Limitations section>
   ```

4. **Confirm and stop.** When the writer returns `status: written`, the loop is done. If it returns `failed`, branch on the reason prefix in `notes`:
   - `inconsistent_input` → fix the draft / sources mismatch (usually a citation in the draft has no entry in `sources`, or vice versa) and re-dispatch.
   - `malformed_card` → you forgot a required field (`output_path` or `draft`); rebuild the dispatch and try again.
   - `unknown_style` → you passed a style not in the supported set; correct it and re-dispatch.
   - `tool_error` → the writer could not write the file (permissions, missing directory). Surface to the user — do not silently retry.

5. **Surface notes if non-empty.** If `status: written` but `notes` is non-empty (writer flagged something — e.g., draft cited a source not in the input list, sections it could not place, ASCII / table content it had to convert, or style-mismatch warnings), include the notes verbatim in your final reply to the user. Do not silently swallow them.

   If the writer flags a style mismatch (e.g., draft was thesis-shaped but dispatched as `technical-paper`), consider whether to re-dispatch with the suggested style — but do this once at most per run.

Do NOT bypass the writer. The orchestrator skill owns synthesis; the writer agent owns craft. Mixing them is what bloated this skill in the first place.

## Spawning rules

Use `deep-research-worker` for: independent subquestions, domain exploration, parallel evidence gathering.

Use `deep-research-verifier` for: single-sourced claims, contradictions, numeric/date/benchmark checks.

Workers return structured findings; the orchestrator synthesizes. Workers do NOT write the final report.

See `delegation-patterns.md` for parallel worker, contradiction-seeking, and domain-specialist patterns.

## Stopping rule

Do not stop just because there is enough text. Stop when the report is **substantively supported** — see `completion-gate.md` for the precise criteria.

If stale rounds force a PASSED state with subquestions still unresolved, still produce a best-effort draft and dispatch the writer; include in `craft_brief` instructions for a `Limitations` section describing what wasn't resolved. The writer's job remains craft; you decide what `Limitations` says.
