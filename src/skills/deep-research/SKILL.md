---
name: deep-research
description: Use this skill for a bounded but thorough research workflow — literature reviews, market or technical landscape scans, source-backed reports, and long-horizon investigations that need plan-board decomposition, iterative deepening, and verified citations.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: research
  pionless.tier: standard
  pionless.suggests-delegation: "subquestion-investigation contradiction-seeking verification"
---

# Deep Research

Use this skill when the user asks for deep research, a literature review, a market or technical landscape scan, a source-backed report, or a long-horizon investigation.

This skill balances depth with efficiency through iterative evidence gathering and workspace reconstruction.

## When to activate

Activate when the host needs:

- a multi-faceted question decomposed into 3–7 subquestions,
- a citation-backed final report,
- iterative deepening with contradiction checks,
- a bounded budget on searches, fetches, and iterations.


## Operating principles

This skill rests on three principles. Apply all three throughout the workflow.

1. **Orchestrator-worker.** One lead thread manages the plan and delegates each investigation thread as an isolated task. See `references/delegation-patterns.md`.
2. **Ralph loop.** Repeat research → synthesis → verification until the completion gate passes or a real blocker remains. See `references/ralph-loop.md`.
3. **Workspace reconstruction.** After every meaningful step, rebuild only the minimal working state from a persisted file rather than dragging in the full transcript. See `references/workspace-reconstruction.md`.

## Workflow

Guide the host agent through these five steps.

1. **Initialize the research contract.** Pin down the question, decision, output format, time sensitivity, and constraints. If the user did not specify, infer the smallest sensible contract and state the assumption.
2. **Build the plan board.** 3–7 subquestions with priority, expected evidence type, and dependencies. See `references/plan-board.md`.
3. **Run worker-style investigations.** Treat each subtask as a focused worker assignment with a narrow objective and explicit deliverable. Apply `references/source-policy.md`, `references/verification-policy.md`, `references/retrieval-policy.md`, and `references/depth-policy.md`.
4. **Reconstruct the workspace after each step.** Use `assets/workspace-template.md`; persist to a file per `references/workspace-reconstruction.md`.
5. **Execute the Ralph loop until the completion gate passes.** Gate criteria in `references/completion-gate.md`. Termination triggers in `references/budget.md`.

## Output convention

Write workspace and final report to the project's `deep-research/` directory using the prefix `YYYY-MM-DD-HHMM-<topic>`. See `references/output-conventions.md`.

## Resources

- `references/output-conventions.md` — `deep-research/` directory and filename rules.
- `references/plan-board.md` — how to construct the 3–7 subquestion board.
- `references/ralph-loop.md` — the iteration loop.
- `references/workspace-reconstruction.md` — file-backed state protocol.
- `references/source-policy.md` — primary, secondary, weak tiers.
- `references/verification-policy.md` — 2-source rule and conflict handling.
- `references/retrieval-policy.md` — query angles per subquestion.
- `references/depth-policy.md` — iterative deepening (depth 0–3+).
- `references/budget.md` — query, fetch, subagent, and step budgets; termination triggers.
- `references/completion-gate.md` — what "done" means.
- `references/delegation-patterns.md` — how a host with spawn capability can parallelize tracks.
- `references/writing-guidelines.md` — answer-first structure, source vs inference.
- `references/math-notation-rules.md` — preserve formulas and code through Markdown.
- `assets/report-template.md` — final report skeleton.
- `assets/workspace-template.md` — workspace file skeleton (mandatory Loop State + Gate Checklist).

## Tool usage

Skills do not grant tools. The host runtime decides what is permitted. Apply the rules below conditionally on what the host actually exposes.

- If a web-search tool is available, use it for discovery; generate 2–3 query variants per subquestion (exact-match, semantic, contradiction-seeking).
- If a web-fetch tool is available, deep-read promising sources after search identifies them.
- If a file-write tool is available, persist the workspace to `deep-research/<prefix>.workspace.md` and the report to `deep-research/<prefix>.md`.
- If a file-read tool is available, reload the workspace at the start of each iteration rather than relying on prior conversation turns.
- If a shell tool is available, use it for data processing, format conversion, or computation when needed.
- If the host supports spawning worker agents, follow `references/delegation-patterns.md` to parallelize independent tracks. If not, run the same worker-style passes sequentially in this thread.

## What this skill does not do

- No code edits, deploys, or external side effects beyond file writes into `deep-research/`.
