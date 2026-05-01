---
name: deep-research
description: Use this skill for a bounded but thorough research workflow — literature reviews, market or technical landscape scans, source-backed reports, position papers, executive briefings, engineering design-and-task plans, and long-horizon investigations that need plan-board decomposition, iterative deepening, and verified citations. The skill auto-classifies each request as `search` mode (comprehensive coverage) or `research` mode (thesis-driven convergence) at Turn 1.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: research
  pionless.suggests-delegation: "subquestion-investigation contradiction-seeking verification drafting writing"
---

# Deep Research

Use this skill when the user asks for deep research, a literature review, a market or technical landscape scan, a source-backed report, a position paper, an executive briefing, an engineering design-and-task plan, or a long-horizon investigation.

## What this skill is

This skill is the orchestrator brain. It owns:

- decomposing the question into a plan board,
- **deciding the investigation mode** (Turn 1, see *Mode decision* below) — `search` (coverage) or `research` (thesis-driven),
- **deciding the report style** (Turn 1, see *Style decision* below),
- dispatching workers and verifiers,
- maintaining workspace state across iterations (terse bullets, not prose — see *Findings discipline* below),
- deciding when the gate has passed,
- dispatching the **drafter** to synthesize the workspace into a draft,
- handing the draft to the **writer** for craft polish, with the chosen style.

It does **not** own retrieval craft, source-tier rules, verification independence rules, draft synthesis prose, the report templates, or writing-style content. Those live with the worker, verifier, drafter, writer, and `report-style-*` skills respectively. Do not duplicate that knowledge here.

## Findings discipline (Opus stays out of long prose)

The orchestrator runs on a heavy model; its tokens are expensive. To keep cost in check, the orchestrator never produces long-form prose:

- The Findings section in the workspace holds **terse bullets only** — one claim per line, with source link and confidence — not running prose paragraphs.
- Cross-finding observations ("X and Y agree on Z; W contradicts both") also go in as bullets.
- The full prose draft is produced by the `deep-research-drafter` (Sonnet) at gate-pass time, not by the orchestrator.
- The escape hatch in the WORK step ("search and read directly") is reserved for **single-URL fetches and single-fact confirmations** that are too small to justify a worker dispatch — not for open-ended retrieval. Open-ended retrieval always goes through `deep-research-worker`.

This discipline is what keeps Opus on planning/decision/dispatch and lets Sonnet carry the long output.

## Mode decision (Turn 1)

Pick exactly one investigation mode at Turn 1, alongside the report style. Mode controls *how the loop runs*; style controls *how the report reads*. Record the mode in the workspace's Research Question section.

- `search` (default) — the question decomposes into independent subquestions and the goal is comprehensive coverage. The plan board is the master plan; iterations close subquestions; synthesis happens at the end. Use when the user signals "what's out there", "review", "scan", "summarize the state of", or otherwise wants coverage rather than a defended answer.
- `research` — the question centers on an answer that needs to be discovered or refined. The orchestrator maintains a **Working Thesis** in the workspace that gets sharpened, weakened, or invalidated as evidence arrives; subquestions partly serve to stress-test the current thesis. Use when the user signals "should we…", "is X true", "why does Y happen", "what's actually going on with Z", or otherwise wants a converged answer.

Mode and style are orthogonal axes, but signals usually correlate:

- `landscape-scan` style → almost always `search` mode.
- `position-paper` style → almost always `research` mode.
- `technical-paper`, `executive-briefing`, `design-to-do` → either; pick from question shape.

If signals are absent, default to `search` and state the assumption in the workspace's Research Question section. The only mechanical difference between modes: `research` mode requires a Working Thesis section in the workspace and a thesis-revision check at the end of every UPDATE step (see `references/loop-protocol.md`). Everything else — workers, verifier, plan board, gate — is unchanged.

**Mode is internal — never ask the user about it.** Mode names (`search`, `research`) are orchestrator mechanics; they are confusing to a user invoking a product called "deep research". Do NOT enumerate mode options in clarification prompts, do NOT ask the user to pick between `search` and `research`, do NOT mention the word "mode" in user-facing text. Classify silently from the user's wording (verbs like "review / scan / summarize / what's out there" → `search`; verbs like "should we / is X true / why does Y / figure out" → `research`). Record the classification in the workspace's Research Question section and move on. The user-facing Turn 1 clarification, if any, asks only about the question itself, constraints, and (optionally) report style.

## Style decision (Turn 1)

The orchestrator picks **exactly one** style at Turn 1, records it in the workspace, and passes it to the writer at dispatch time. Pick from user signals; otherwise pick a default and explicitly state the assumption.

- `technical-paper` (default) — neutral, source-backed, multi-pillar findings. Use when the user wants to understand a topic without a recommendation pre-committed.
- `position-paper` — argument-driven, thesis up front, counter-arguments addressed. Use when user asks "should we…?", "argue for", "make the case", or otherwise wants a defended recommendation.
- `executive-briefing` — short decision memo, BLUF, ≤1000 words. Use when user signals brevity ("brief", "TL;DR", "one-pager") or names a stakeholder needing a fast read.
- `landscape-scan` — categorized survey with comparable depth per item. Use when user asks "what's out there", "what are the X options", or wants a comparable map of a space.
- `design-to-do` — engineering design + topologically-sorted task list. Use when user asks "design X", "how should we build Y", "plan the implementation of Z", or wants an engineering kickoff artifact.
- `tutorial` — textbook-style step-by-step explanation building intuition → worked example → formalism → connections → pitfalls. Use when the user wants to *understand* a complex concept ("explain X step by step", "walk me through Y", "help me understand Z", "tutorial on W", "教科书风格").

If signals genuinely conflict, ask the user once. If signals are absent, default to `technical-paper` and state the assumption in the workspace's Research Question section.

The full per-style template, tone, length norms, and anti-patterns live in each `report-style-*` skill. The orchestrator does not need that detail — only enough to pick.

## Operating principles

1. **Orchestrator-worker.** This thread is the lead; isolated investigation, verification, and writing happen as Agent dispatches. See `references/delegation-patterns.md`.
2. **Iteration loop.** Repeat gather → record → check until the gate passes or stale rounds force a PASSED state. See `references/loop-protocol.md`.
3. **One-shot execution — no user pauses between iterations.** The entire run from clarification to final report happens in a single user-facing response. Iteration boundaries are internal; they are NOT user conversation turns. After the workspace is written, never stop to ask the user "should I continue", "shall I dispatch workers now", or "want to adjust the plan first" — the user invoked deep research expecting an autonomous run that ends with a delivered report. The only legitimate user-facing pause is a single Turn 1 clarification when question/style signals *genuinely conflict* (see Mode/Style decision sections); absent signals default silently. See `references/loop-protocol.md` for the explicit rule.
4. **Workspace reconstruction.** After every meaningful step, rebuild only the minimal working state from a persisted file rather than dragging in the full transcript. See `references/workspace-reconstruction.md`.
5. **Synthesis and craft both go elsewhere.** When the gate passes, dispatch `deep-research-drafter` with the workspace path; the drafter returns a draft + source list. Then dispatch `deep-research-writer` with that draft for craft polish. The orchestrator does not write the draft and does not write the report file.

## Workflow

The full operational protocol lives in `references/loop-protocol.md`. High-level shape:

1. **Initialize the research contract** (including the investigation mode and the report style — see *Mode decision* and *Style decision* above). Pin down the question, decision, mode, style, output format, time sensitivity, and constraints. If the user did not specify, infer the smallest sensible contract and state the assumption.
2. **Build the plan board.** 3–7 subquestions with priority, expected evidence type, and dependencies. The chosen style should bias plan-board emphasis (e.g., `position-paper` requires a "find the strongest opposing view" subquestion; `landscape-scan` organizes by category; `design-to-do` includes a "prior-art / alternatives" subquestion). See `references/plan-board.md`.
3. **Run the iteration loop.** Each turn: read workspace → pick highest-value task → dispatch `deep-research-worker` / `deep-research-verifier` (or use the escape hatch for a single-URL fetch) → append terse bullets to Findings → update gate → write workspace → decide continue or finish. See `references/loop-protocol.md`.
4. **Pass the completion gate.** Criteria in `references/completion-gate.md`. The only forced-termination path is stale rounds ≥ 2 (diminishing returns) — see the loop protocol's CHECK step.
5. **Dispatch the drafter, then the writer.** When the gate passes, dispatch `deep-research-drafter` with the workspace path, mode, chosen style, and any draft brief (limitations, length target). The drafter reads the workspace and returns a substantively-complete draft + source list. Then dispatch `deep-research-writer` with that draft for craft polish. See the *Drafting handoff* section in `references/loop-protocol.md`.

## Output

Workspace and final report go to `deep-research/<prefix>.workspace.md` and `deep-research/<prefix>.md` respectively. See `references/output-conventions.md` for prefix derivation. The orchestrator owns the workspace file; the writer owns the report file (dispatched with the path and the chosen style).

## Resources

- `references/loop-protocol.md` — turn-by-turn iteration protocol and drafter→writer handoff.
- `references/plan-board.md` — how to construct the 3–7 subquestion board.
- `references/workspace-reconstruction.md` — file-backed state protocol.
- `references/completion-gate.md` — what "done" means.
- `references/delegation-patterns.md` — parallel worker, contradiction-seeking, domain-specialist, and drafter→writer dispatch patterns.
- `references/output-conventions.md` — `deep-research/` directory and filename prefix rules.
- `assets/workspace-template.md` — workspace file skeleton (mandatory Loop State + Gate Checklist).

## Tool usage

Skills do not grant tools. The host runtime decides what is permitted. Apply the rules below conditionally on what the host actually exposes.

- If a web-search tool is available, the orchestrator may use it for quick triage before deciding to dispatch a worker. For deep retrieval, prefer dispatching `deep-research-worker`.
- If a web-fetch tool is available, the orchestrator may deep-read a source to settle a synthesis question without spawning a worker.
- If a file-write tool is available, persist the workspace to `deep-research/<prefix>.workspace.md` every iteration (terse bullets only — see *Findings discipline* above). Do **not** write the draft or the final report from this thread — dispatch `deep-research-drafter` for the draft and `deep-research-writer` for the file.
- If a file-read tool is available, reload the workspace at the start of each iteration rather than relying on prior conversation turns.
- If a shell tool is available, use it for data processing, format conversion, or computation when needed.
- If the host supports spawning worker agents, follow `references/delegation-patterns.md`. If not, do worker-style passes sequentially in this thread, synthesize the draft directly, and write the final report using the chosen style's template (degraded mode — flag this to the user, since both the drafter's synthesis layer and the writer's craft layer are lost).

## What this skill does not do

- No code edits, deploys, or external side effects beyond file writes into `deep-research/`.
- No retrieval-craft, prose-synthesis, writing-style, or report-template content lives here. If you find yourself wanting to copy in source-tier rules, draft synthesis prose, writing style guidance, or per-style templates, you are about to re-bloat this skill — push it down to the worker, verifier, drafter, writer, or `report-style-*` skill instead.

## Related agents and skills

- `deep-research-worker` agent — handles one focused subquestion, owns retrieval / source / depth craft.
- `deep-research-verifier` agent — adversarially verifies a single claim, owns verification policy.
- `deep-research-drafter` agent — takes the workspace at gate-pass time and produces a substantively-complete draft with inline citations; owns prose synthesis from terse findings.
- `deep-research-writer` agent — takes the drafter's draft and produces the final report file using the chosen style; owns universal writing craft, math notation, paper-style citation formatting.
- `report-style-technical-paper` skill — neutral source-backed analytical style (default).
- `report-style-position-paper` skill — argument-driven style.
- `report-style-executive-briefing` skill — short decision memo.
- `report-style-landscape-scan` skill — categorized survey.
- `report-style-design-to-do` skill — engineering design + task plan.
- `report-style-tutorial` skill — textbook-style step-by-step concept walkthrough.
