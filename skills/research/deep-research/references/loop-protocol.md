# Loop Protocol

You operate in discrete iterations. The workspace file is your memory between iterations. Repeat the loop until the completion gate passes or stale rounds force a PASSED state.

## The loop rule

```
EVERY ITERATION:
  1. Read   → deep-research/<prefix>.workspace.md
  2. Work   → pick one task, gather evidence, update findings
  3. Check  → evaluate the gate checklist, update counters
  4. Write  → overwrite workspace file with updated state
  5. Done?  → if gate passes: dispatch drafter, then writer, stop
            → if not: start the next iteration
```

NEVER skip step 1 (read) or step 4 (write). NEVER do all research in a single iteration. NEVER write the final report yourself outside a writer pass. NEVER skip the writer, even when the gate is forced PASSED by stale rounds.

## One-shot execution (no user pauses between iterations)

All iterations run in a **single user-facing response**. The "Turn N" labels below are internal: they are iterations of the loop, NOT user conversation turns. After Turn 1 writes the workspace, immediately continue into Turn 2 (and 3, 4, …) within the same response, dispatching roles and looping until the gate passes and the writer has produced the report file.

**Never pause to ask the user:**
- "should I continue / proceed / go on?"
- "shall I dispatch workers now?"
- "want to adjust the plan first?" / "want to review the plan board?"
- "any changes before I run iteration N?"

The user invoked deep research expecting an autonomous, multi-minute run that ends with a delivered report. Asking for permission mid-run defeats the product and forces the user to babysit the loop.

**The single allowed user-facing pause** is a Turn 1 clarification when question wording or style signals *genuinely conflict* (for example, the user asked for both a defended recommendation and comprehensive coverage). Merely *absent* signals are defaulted silently, with the assumption stated in the workspace. After clarification (or if none was needed), proceed autonomously until the writer returns `status: written`.

## Turn 1: Initialization

On the very first iteration, do ONLY these things:

1. **Clarify the research question.** Infer when obvious; state the assumption explicitly when not.
2. **Decide the investigation mode, silently**, per SKILL.md *Mode decision*. Never ask the user about it and never mention the word "mode" to them. Default `search` when signals are absent.
3. **Decide the report style** per SKILL.md *Style decision*. Default `technical-paper` when signals are absent and state the assumption in the Research Question section. Ask the user once only if signals genuinely conflict.
4. **Derive the run prefix** `YYYY-MM-DD-HHMM-<topic>` per SKILL.md *Output*.
5. **Write the workspace file** from `assets/workspace-template.md`. The chosen mode and style go in the Research Question section. If mode = `research`, also write an initial Working Thesis (a placeholder like *"TBD — needs initial evidence"* is fine; the loop will sharpen it).
6. **Do not dispatch workers in this iteration; the workspace must exist first.** This iteration is planning-only. **But do not stop here.** Once the workspace is written, immediately continue into Turn 2 in the same response and dispatch the first batch of workers per the plan board. Do not announce the plan and ask for confirmation, and do not offer to "adjust the plan board first".

## Turn 2+: The gather-check loop

### READ

Read the workspace file. Parse Loop State, Gate Checklist, and the chosen style. Do not rely on prior conversation turns; the workspace file is the source of truth.

### WORK

Pick the highest-value open task by expected information gain (`references/plan-board.md`). Let the style bias selection: a `position-paper` run weights "find the strongest opposing view" tasks higher; a `landscape-scan` run prioritizes coverage across categories; a `design-to-do` run prioritizes "prior art / alternatives considered" subquestions. Then:

- **Independent tasks exist → dispatch workers**, one per task card.
  - If you can start subagents: start each with a fresh context (not a fork of this conversation), give it the full text of `roles/worker.md`, then its task card. Start them all at once if your host allows parallel subagents; otherwise one after another. Grant web search and page fetching; no file writes.
  - If you cannot: do each worker pass yourself, one after another. Re-read `roles/worker.md`, work only from that task card, and produce exactly the output it specifies.
- **A claim needs verification → dispatch the verifier**, same shape, with `roles/verifier.md` and a verification card.
  - If you can start subagents: fresh context, full text of `roles/verifier.md`, then the card. Grant web search and page fetching; no file writes.
  - If you cannot: do the verification yourself as a separate pass from `roles/verifier.md`, working only from the card. Try hard to disprove the claim, as the role says.
- **Otherwise** (a single-URL fetch or a single-fact confirmation) → search or fetch directly.

Worker task card:

```
Objective: [one sentence — the subquestion to answer]
Seed queries: [2–3 starting queries]
Acceptance criteria: [what counts as "done"]
Depth ceiling: [optional — default is depth 2]
```

Verifier task card:

```
Claim to verify: [the specific claim or data point]
Current sources: [existing sources that support the claim]
Verification type: contradiction-seeking | numeric-check | timeline-check | source-crossref
```

### UPDATE

Merge new evidence into the Findings section as terse bullets. Update the Plan Board: mark completed subquestions, promote follow-ups discovered during investigation, demote tasks that turned out lower-value than predicted.

**Thesis revision (research mode only).** If mode = `research`, after updating Findings, re-read the current Working Thesis and explicitly answer: *does this iteration's evidence sharpen, weaken, or invalidate the thesis?* Then act on the answer:

- **Sharpens** → tighten the wording, raise confidence, or narrow the claim. Note the iteration in `Last revised`.
- **Weakens** → soften the claim, lower confidence, and add a follow-up subquestion that targets the weakening evidence.
- **Invalidates** → rewrite the thesis to match what the evidence now supports; add a follow-up subquestion to confirm the new direction.
- **No change** → write `thesis unchanged this round` in the section and move on. Two consecutive unchanged rounds in research mode is a signal that you may have converged (or that workers are not stress-testing hard enough; consider a contradiction-seeking verifier dispatch next iteration).

The thesis is the spine of a research-mode run; if it never moves across the loop, you were really in `search` mode and should say so to the user. Skip this substep in `search` mode.

### CHECK

Walk through every Gate Checklist item (criteria in `references/completion-gate.md`):

- Check `[x]` if satisfied; uncheck `[ ]` if not.
- If all are checked → set Gate to PASSED.
- If no new evidence this iteration → increment Stale rounds.
- If Stale rounds ≥ 2 → set Gate to PASSED (forced: diminishing returns).

### WRITE

Overwrite the workspace file with the updated state per `references/workspace-reconstruction.md`. Increment Iteration.

### DECIDE

- Gate PASSED → run the *Drafting handoff* below, then stop.
- Gate NOT PASSED → **immediately start the next iteration in the same response** (READ → WORK → UPDATE → CHECK → WRITE). Do not emit a user-facing "next iteration will target X" message and stop; that is a pause masquerading as a status update.

## Drafting handoff

Once the gate passes (organically or forced by stale rounds), you do not write the draft and you do not write the report file. Your job is dispatch and glue: hand the workspace to the drafter, then hand the drafter's output to the writer.

1. **Dispatch the drafter** with this card:

   ```text
   workspace_path: deep-research/<prefix>.workspace.md
   style: <technical-paper | position-paper | executive-briefing | landscape-scan | design-to-do | tutorial>
   mode: <search | research>
   draft_brief: <optional — emphasize X, target ~Y words, audience Z; if the gate was force-terminated by stale rounds, name the unresolved subquestions here so the drafter emits a Limitations section>
   ```

   - If you can start subagents: fresh context, full text of `roles/drafter.md`, then the card. It needs to read the workspace file; no file writes. If it cannot read project files, paste the workspace text as `workspace:` instead of `workspace_path:`.
   - If you cannot: do the drafter pass yourself. Re-read `roles/drafter.md`, work only from the workspace file and the card, and produce exactly its JSON output.

   The drafter returns JSON with `status`, `draft` (prose with inline `[Title](url)` citations), `sources` (deduped, tiered), `style_targeted`, `mode`, and `notes`.

2. **Handle the drafter's response.**

   - `status: drafted` → go to step 3 with the returned `draft` and `sources`.
   - `status: failed` → branch on the reason keyword in `notes`:
     - `malformed_card` → a required field is missing; rebuild the card.
     - `unknown_style` → correct the style name and re-dispatch.
     - `tool_error` → the drafter could not read the workspace; check the path (or paste the workspace text) and re-dispatch, or tell the user if the workspace itself is corrupted.
     - `inconsistent_input` → the workspace is missing a required section; fix the workspace and re-dispatch.

3. **Dispatch the writer** with this card, passing through what the drafter produced:

   ```text
   output_path: deep-research/<prefix>.md
   draft: <the drafter's draft prose verbatim>
   sources: <the drafter's sources list verbatim>
   style: <same style you passed to the drafter>
   style_guide: <the full text of references/report-styles/<style>.md, pasted unchanged>
   craft_brief: <optional — pass through notes from the drafter, audience, length target, force-terminated flag>
   ```

   - If you can start subagents: fresh context, full text of `roles/writer.md`, then the card. It needs write access to `output_path` only.
   - If you cannot: do the writer pass yourself. Re-read `roles/writer.md`, work only from the card, write the file, and produce exactly its JSON output.

4. **Confirm and stop.** When the writer returns `status: written`, the loop is done. If it returns `failed`, branch on the reason keyword in `notes`:

   - `inconsistent_input` → the draft cited a URL not in the source list (or vice versa). Re-dispatch the drafter to fix it; do not paper over the gap yourself.
   - `malformed_card` → a required field is missing (often `style_guide`); rebuild the card and re-dispatch.
   - `unknown_style` → correct the style name and re-dispatch.
   - `tool_error` → the writer could not write the file (permissions, missing directory). Tell the user; do not silently retry.

5. **Surface notes.** If the writer's or the drafter's `notes` is non-empty (unattributed claims, sections it could not place, table or ASCII conversions, style-mismatch warnings), include those notes verbatim in your final reply. Do not swallow them.

   If the writer flags a style mismatch (for example, the draft was thesis-shaped but dispatched as `technical-paper`), consider re-running drafter and writer with the suggested style, at most once per run.

Do not bypass the drafter or the writer. You own plan-board state and dispatch; the drafter owns synthesis; the writer owns craft.

## Which role for what

- Worker: independent subquestions, domain exploration, parallel evidence gathering.
- Verifier: single-sourced claims, contradictions, numeric / date / benchmark checks.
- Drafter: once, at gate-pass, to synthesize the workspace into a draft.
- Writer: once, at the end, to turn the draft into the final report file.

Workers and the verifier return structured findings; the drafter weaves them into prose; the writer applies craft. You never produce long-form prose yourself, except inside a drafter or writer pass when you have no subagents.

## Stopping rule

Do not stop just because there is enough text. Stop when the report is **substantively supported**; see `references/completion-gate.md`.

If stale rounds force a PASSED state with subquestions still unresolved, still dispatch the drafter for a best-effort draft and name the unresolved subquestions in `draft_brief` so the drafter emits a `Limitations` section. The drafter writes that prose; you decide what goes in it.
