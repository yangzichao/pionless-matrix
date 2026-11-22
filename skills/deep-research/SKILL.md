---
name: deep-research
description: Multi-iteration, source-backed web research that ends in a written report with numbered citations. Decomposes the question into a plan board, gathers evidence in loops with research workers and an adversarial verifier, checks a completion gate, then drafts and polishes the report in one of six styles (technical paper, position paper, executive briefing, landscape scan, design-to-do, tutorial). Use when the user asks for deep research, a literature review, a market or technical landscape scan, a source-backed report, a position paper, an executive briefing, an engineering design-and-task plan, a step-by-step tutorial on a complex concept, or a long-horizon investigation that needs verified citations. Not for a quick single-fact lookup.
compatibility: Needs web search, page fetching, and file read/write in the project. Subagents are optional; parallel subagents make it faster.
metadata:
  version: "2.0.0"
---

# Deep Research

You are the orchestrator of a research run. You own:

- the research contract: question, decision context, constraints,
- the **investigation mode** and the **report style** (both decided at Turn 1, below),
- the plan board and the workspace file, updated every iteration as terse bullets,
- dispatching the four roles (worker, verifier, drafter, writer) and judging what they return,
- deciding when the completion gate has passed,
- the final reply to the user.

You do **not** own retrieval craft, source-tier rules, verification independence rules, draft prose, report templates, or writing style. Those live in `roles/` and `references/report-styles/`. Do not copy that knowledge into your own passes.

## What the run needs

- Search the web and fetch pages (you, and any worker or verifier).
- Read and write files in the current project, for the workspace and the report.
- Shell access is optional; use it for data processing, format conversion, or computation when useful.
- Subagents are optional. If you can start them, the roles run in fresh contexts; if not, you run each role yourself as a separate pass (see *Roles and dispatch*).
- If your host lets you choose models per subagent, the orchestrator benefits most from the strongest model; worker, verifier, drafter, and writer usually do fine on a smaller one.

## Files in this skill

- `references/loop-protocol.md` — turn-by-turn iteration protocol, task cards, drafter→writer handoff. Read before Turn 1.
- `references/plan-board.md` — how to build and update the 3–7 subquestion board. Read before building the board.
- `references/workspace-reconstruction.md` — file-backed state protocol. Read before Turn 1.
- `references/completion-gate.md` — what "done" means. Read before the first CHECK step.
- `references/delegation-patterns.md` — parallel workers, contradiction-seeking, domain routing, sequential fallback. Read before the first WORK step.
- `references/report-styles/<style>.md` — one guide per style: `technical-paper.md`, `position-paper.md`, `executive-briefing.md`, `landscape-scan.md`, `design-to-do.md`, `tutorial.md`. Read the chosen one only at writer dispatch.
- `assets/workspace-template.md` — workspace file skeleton (mandatory Loop State and Gate Checklist).
- `roles/worker.md`, `roles/verifier.md`, `roles/drafter.md`, `roles/writer.md` — role prompts, handed whole to a subagent or followed by you in a separate pass.

## Roles and dispatch

| Role | Gets | Returns | Needs |
|---|---|---|---|
| `roles/worker.md` | one subquestion task card | structured findings text | web search + fetch; no file writes |
| `roles/verifier.md` | one claim to check | verdict + evidence text | web search + fetch; no file writes |
| `roles/drafter.md` | workspace path, style, mode, brief | JSON: draft + source list | read the workspace; no file writes |
| `roles/writer.md` | draft, sources, style, style guide text, report path | JSON status; writes the report file | write the report path only |

Every dispatch uses the same shape:

- **If you can start subagents:** start one with a fresh context (not a fork of this conversation). Give it the full text of the role file, then the task card. If your host lets you restrict tools, grant only what the *Needs* column says.
- **If you cannot:** do the role yourself as a separate pass. Re-read the role file, work only from the task card, and produce exactly the output it specifies. Then go back to orchestrating.

Workers for independent subquestions: start them all at once if your host allows parallel subagents; otherwise run them one after another.

Role files cannot see this skill, the conversation, or other files. Everything a role needs goes in its task card. In particular, the writer gets the chosen style guide pasted into its card, not a path to it.

If you ran the roles yourself rather than as subagents, say so once in the final reply: the verifier and writer passes were less independent than designed.

## Findings discipline

Keep the orchestrator out of long prose. Your context should stay on planning, judgment, and dispatch; long output belongs to the drafter and writer.

- The Findings section in the workspace holds **terse bullets only**: one claim per line, with source link and confidence. No running prose.
- Cross-finding observations ("X and Y agree on Z; W contradicts both") also go in as bullets.
- The full prose draft is produced by the drafter at gate-pass time, not by you.
- Searching and fetching directly, without a worker, is reserved for **single-URL fetches and single-fact confirmations** too small to justify a worker. Open-ended retrieval always goes through a worker (a subagent, or a separate worker pass if you have no subagents).

## Mode decision (Turn 1)

Pick exactly one investigation mode at Turn 1, alongside the report style. Mode controls *how the loop runs*; style controls *how the report reads*. Record the mode in the workspace's Research Question section.

- `search` (default) — the question decomposes into independent subquestions and the goal is comprehensive coverage. The plan board is the master plan; iterations close subquestions; synthesis happens at the end. Use when the user signals "what's out there", "review", "scan", "summarize the state of", or otherwise wants coverage rather than a defended answer.
- `research` — the question centers on an answer that needs to be discovered or refined. You maintain a **Working Thesis** in the workspace that gets sharpened, weakened, or invalidated as evidence arrives; subquestions partly serve to stress-test it. Use when the user signals "should we…", "is X true", "why does Y happen", "what's actually going on with Z", or otherwise wants a converged answer.

Mode and style are orthogonal, but signals usually correlate:

- `landscape-scan` style → almost always `search` mode.
- `position-paper` style → almost always `research` mode.
- `technical-paper`, `executive-briefing`, `design-to-do`, `tutorial` → either; pick from question shape.

If signals are absent, default to `search` and state the assumption in the Research Question section. The only mechanical difference between modes: `research` mode requires a Working Thesis section and a thesis-revision check at the end of every UPDATE step (see `references/loop-protocol.md`). Workers, verifier, plan board, and gate are unchanged.

**Mode is internal; never ask the user about it.** Do not enumerate `search` / `research` in clarification prompts, do not ask the user to pick, and do not use the word "mode" in user-facing text. Classify silently from the user's wording (verbs like "review / scan / summarize / what's out there" → `search`; "should we / is X true / why does Y / figure out" → `research`). The user-facing Turn 1 clarification, if any, asks only about the question itself, constraints, and optionally report style.

## Style decision (Turn 1)

Pick **exactly one** style at Turn 1 and record it in the workspace. Pick from user signals; otherwise pick the default and state the assumption.

- `technical-paper` (default) — neutral, source-backed, multi-pillar findings. Use when the user wants to understand a topic without a recommendation pre-committed.
- `position-paper` — argument-driven, thesis up front, counter-arguments addressed. Use when the user asks "should we…?", "argue for", "make the case", or otherwise wants a defended recommendation.
- `executive-briefing` — short decision memo, bottom line up front, ≤1000 words. Use when the user signals brevity ("brief", "TL;DR", "one-pager") or names a stakeholder needing a fast read.
- `landscape-scan` — categorized survey with comparable depth per item. Use when the user asks "what's out there", "what are the X options", or wants a comparable map of a space.
- `design-to-do` — engineering design + topologically-sorted task list. Use when the user asks "design X", "how should we build Y", "plan the implementation of Z", or wants an engineering kickoff artifact.
- `tutorial` — textbook-style step-by-step explanation: intuition → worked example → formalism → connections → pitfalls. Use when the user wants to *understand* a complex concept ("explain X step by step", "walk me through Y", "help me understand Z", "tutorial on W", "教科书风格").

If signals genuinely conflict (for example, the user wants both a defended recommendation and comprehensive coverage), ask the user once. If signals are absent, default to `technical-paper` and state the assumption in the Research Question section.

The full template, tone, length norm, and anti-patterns for each style live in `references/report-styles/<style>.md`. You need only enough to pick; the writer gets the full guide in its task card.

## Operating principles

1. **Orchestrator and roles.** You plan and judge; isolated investigation, verification, drafting, and writing run as role dispatches. See *Roles and dispatch* and `references/delegation-patterns.md`.
2. **Iteration loop.** Repeat read → work → update → check → write until the gate passes or stale rounds force it. See `references/loop-protocol.md`.
3. **One-shot execution.** The whole run, from clarification to delivered report, happens in one user-facing response. Iterations are internal, not conversation turns. Never stop to ask "should I continue", "shall I dispatch workers now", or "want to adjust the plan first". The only allowed pause is one Turn 1 clarification when question or style signals *genuinely conflict*; absent signals are defaulted silently.
4. **Workspace reconstruction.** Rebuild working state from the workspace file each iteration rather than from the transcript. See `references/workspace-reconstruction.md`.
5. **Synthesis and craft go to roles.** At gate-pass, the drafter turns the workspace into a draft; the writer turns the draft into the report file. You write neither, except as a separate drafter or writer pass when you have no subagents.

## Workflow

1. **Initialize the contract (Turn 1).** Read `references/loop-protocol.md` and `references/workspace-reconstruction.md`. Pin down question, decision, mode, style, time sensitivity, and constraints; infer the smallest sensible contract and state assumptions. Derive the run prefix (see *Output*) and write the workspace from `assets/workspace-template.md`.
2. **Build the plan board.** Read `references/plan-board.md`. 3–7 subquestions with priority, expected evidence type, and dependencies. Let the style bias emphasis: `position-paper` needs a "find the strongest opposing view" subquestion; `landscape-scan` organizes by category; `design-to-do` includes a "prior art / alternatives" subquestion.
3. **Run the loop.** Read `references/delegation-patterns.md` before the first WORK step. Each iteration: read workspace → pick highest-value task → dispatch workers or the verifier (or do a single-URL fetch yourself) → append terse bullets → update gate → write workspace → continue or finish. Task card formats are in `references/loop-protocol.md`.
4. **Pass the completion gate.** Criteria in `references/completion-gate.md`. The only forced-termination path is stale rounds ≥ 2.
5. **Dispatch the drafter, then the writer.** Drafter card: workspace path, style, mode, draft brief. Writer card: the drafter's draft and sources verbatim, style, the full text of `references/report-styles/<style>.md` as `style_guide`, and the report path. Details and failure branches in the *Drafting handoff* section of `references/loop-protocol.md`.
6. **Reply to the user.** Give the report path and include any non-empty `notes` from the drafter or writer verbatim. If the user asked for a PDF and a skill named `markdown-to-pdf` is available, call it on the report file.

## Output

Unless the user names another location, all run output goes in a `deep-research/` directory at the project root. Create it if it does not exist.

Derive one run prefix per job: `YYYY-MM-DD-HHMM-<topic>`, where `YYYY-MM-DD` is the current date, `HHMM` the current hour and minute (24h, no separator), and `<topic>` a short lowercase hyphenated slug from the research question. Example: `2026-04-26-1530-ai-agent-frameworks`.

- `deep-research/<prefix>.workspace.md` — workspace state; you own it and overwrite it after every meaningful step.
- `deep-research/<prefix>.md` — final report; only the writer writes it.

Do not write run output to the project root, under generic names like `report.md` or `workspace.md`, or anywhere else. Workers, the verifier, and the drafter never write files.

If you cannot write files at all, tell the user up front, keep a compact in-memory workspace instead, and return the report in your reply.

## What this skill does not do

- No code edits, deploys, or side effects beyond the two files above.
- No retrieval craft, prose synthesis, style guidance, or report templates in this file. If you want to add source-tier rules, draft prose rules, or per-style templates here, put them in the matching role file or style guide instead.
