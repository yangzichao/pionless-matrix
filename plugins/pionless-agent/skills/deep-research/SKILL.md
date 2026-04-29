---
name: deep-research
description: Use this skill for a bounded but thorough research workflow — literature reviews, market or technical landscape scans, source-backed reports, position papers, executive briefings, engineering design-and-task plans, and long-horizon investigations that need plan-board decomposition, iterative deepening, and verified citations.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: research
  pionless.suggests-delegation: "subquestion-investigation contradiction-seeking verification writing"
---

# Deep Research

Use this skill when the user asks for deep research, a literature review, a market or technical landscape scan, a source-backed report, a position paper, an executive briefing, an engineering design-and-task plan, or a long-horizon investigation.

## What this skill is

This skill is the orchestrator brain. It owns:

- decomposing the question into a plan board,
- **deciding the report style** (Turn 1, see *Style decision* below),
- dispatching workers and verifiers,
- maintaining workspace state across iterations,
- deciding when the gate has passed,
- synthesizing findings into a draft,
- handing the draft to the writer for craft polish, with the chosen style.

It does **not** own retrieval craft, source-tier rules, verification independence rules, the report templates, or writing-style content. Those live with the worker, verifier, writer, and `report-style-*` skills respectively. Do not duplicate that knowledge here.

## Style decision (Turn 1)

The orchestrator picks **exactly one** style at Turn 1, records it in the workspace, and passes it to the writer at dispatch time. Pick from user signals; otherwise pick a default and explicitly state the assumption.

- `technical-paper` (default) — neutral, source-backed, multi-pillar findings. Use when the user wants to understand a topic without a recommendation pre-committed.
- `position-paper` — argument-driven, thesis up front, counter-arguments addressed. Use when user asks "should we…?", "argue for", "make the case", or otherwise wants a defended recommendation.
- `executive-briefing` — short decision memo, BLUF, ≤1000 words. Use when user signals brevity ("brief", "TL;DR", "one-pager") or names a stakeholder needing a fast read.
- `landscape-scan` — categorized survey with comparable depth per item. Use when user asks "what's out there", "what are the X options", or wants a comparable map of a space.
- `design-to-do` — engineering design + topologically-sorted task list. Use when user asks "design X", "how should we build Y", "plan the implementation of Z", or wants an engineering kickoff artifact.

If signals genuinely conflict, ask the user once. If signals are absent, default to `technical-paper` and state the assumption in the workspace's Research Question section.

The full per-style template, tone, length norms, and anti-patterns live in each `report-style-*` skill. The orchestrator does not need that detail — only enough to pick.

## Operating principles

1. **Orchestrator-worker.** This thread is the lead; isolated investigation, verification, and writing happen as Agent dispatches. See `references/delegation-patterns.md`.
2. **Iteration loop.** Repeat gather → check → synthesize until the gate passes or stale rounds force a PASSED state. See `references/loop-protocol.md`.
3. **Workspace reconstruction.** After every meaningful step, rebuild only the minimal working state from a persisted file rather than dragging in the full transcript. See `references/workspace-reconstruction.md`.
4. **Synthesis stays here, craft goes elsewhere.** When the gate passes, draft in this context window, then dispatch `deep-research-writer` with the draft and the chosen style. Do not write the report file directly.

## Workflow

The full operational protocol lives in `references/loop-protocol.md`. High-level shape:

1. **Initialize the research contract** (including the report style — see *Style decision* above). Pin down the question, decision, style, output format, time sensitivity, and constraints. If the user did not specify, infer the smallest sensible contract and state the assumption.
2. **Build the plan board.** 3–7 subquestions with priority, expected evidence type, and dependencies. The chosen style should bias plan-board emphasis (e.g., `position-paper` requires a "find the strongest opposing view" subquestion; `landscape-scan` organizes by category; `design-to-do` includes a "prior-art / alternatives" subquestion). See `references/plan-board.md`.
3. **Run the iteration loop.** Each turn: read workspace → pick highest-value task → dispatch `deep-research-worker` or `deep-research-verifier` (or research directly) → synthesize findings → update gate → write workspace → decide continue or finish. See `references/loop-protocol.md`.
4. **Pass the completion gate.** Criteria in `references/completion-gate.md`. The only forced-termination path is stale rounds ≥ 2 (diminishing returns) — see the loop protocol's CHECK step.
5. **Draft and dispatch the writer.** Synthesize the draft from the workspace, assemble the source list, dispatch `deep-research-writer` **with the chosen style**. See the *Drafting handoff* section in `references/loop-protocol.md`.

## Output

Workspace and final report go to `deep-research/<prefix>.workspace.md` and `deep-research/<prefix>.md` respectively. See `references/output-conventions.md` for prefix derivation. The orchestrator owns the workspace file; the writer owns the report file (dispatched with the path and the chosen style).

## Resources

- `references/loop-protocol.md` — turn-by-turn iteration protocol and writer handoff.
- `references/plan-board.md` — how to construct the 3–7 subquestion board.
- `references/workspace-reconstruction.md` — file-backed state protocol.
- `references/completion-gate.md` — what "done" means.
- `references/delegation-patterns.md` — parallel worker, contradiction-seeking, domain-specialist, and writer dispatch patterns.
- `references/output-conventions.md` — `deep-research/` directory and filename prefix rules.
- `assets/workspace-template.md` — workspace file skeleton (mandatory Loop State + Gate Checklist).

## Tool usage

Skills do not grant tools. The host runtime decides what is permitted. Apply the rules below conditionally on what the host actually exposes.

- If a web-search tool is available, the orchestrator may use it for quick triage before deciding to dispatch a worker. For deep retrieval, prefer dispatching `deep-research-worker`.
- If a web-fetch tool is available, the orchestrator may deep-read a source to settle a synthesis question without spawning a worker.
- If a file-write tool is available, persist the workspace to `deep-research/<prefix>.workspace.md` every iteration. Do **not** write the final report from this thread — dispatch `deep-research-writer`.
- If a file-read tool is available, reload the workspace at the start of each iteration rather than relying on prior conversation turns.
- If a shell tool is available, use it for data processing, format conversion, or computation when needed.
- If the host supports spawning worker agents, follow `references/delegation-patterns.md`. If not, do worker-style passes sequentially in this thread and then write the final report directly using the chosen style's template (degraded mode — flag this to the user, since the writer's craft layer is lost).

## What this skill does not do

- No code edits, deploys, or external side effects beyond file writes into `deep-research/`.
- No retrieval-craft, writing-style, or report-template content lives here. If you find yourself wanting to copy in source-tier rules, writing style guidance, or per-style templates, you are about to re-bloat this skill — push it down to the worker, verifier, writer, or `report-style-*` skill instead.

## Related agents and skills

- `deep-research-worker` agent — handles one focused subquestion, owns retrieval / source / depth craft.
- `deep-research-verifier` agent — adversarially verifies a single claim, owns verification policy.
- `deep-research-writer` agent — takes the orchestrator's draft and produces the final report file using the chosen style; owns universal writing craft, math notation, paper-style citation formatting.
- `report-style-technical-paper` skill — neutral source-backed analytical style (default).
- `report-style-position-paper` skill — argument-driven style.
- `report-style-executive-briefing` skill — short decision memo.
- `report-style-landscape-scan` skill — categorized survey.
- `report-style-design-to-do` skill — engineering design + task plan.
