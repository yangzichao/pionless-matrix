---
name: deep-research
description: Run a deep research workflow using orchestrator-worker task decomposition, Ralph-loop iteration, workspace reconstruction, evidence verification, and answer-first report synthesis.
allowed-tools: Read, Write, Bash, WebSearch, WebFetch, Agent
---

# Deep Research

Use this skill when the user asks for deep research, a literature review, a market or technical landscape scan, a source-backed report, or a long-horizon investigation.

This is the **standard** tier of the research system. It balances depth with efficiency through budgeted iterations and workspace reconstruction. For exhaustive, unbounded research, see `deep-research-pro`. For fast, focused lookups (or to use as a subagent worker), see `quick-research`.

## Objective

Produce a high-confidence report without letting the working context bloat. Operate as a bounded deep-research agent built on three rules:

1. **Orchestrator-worker**: one lead thread manages the plan and delegates each investigation thread as an isolated task.
2. **Ralph loop**: repeat research, synthesis, and verification until the quality gate passes or a real blocker remains.
3. **Workspace reconstruction**: after every meaningful step, throw away noisy history and rebuild only the minimal working state.

## Tool usage guide

Each allowed tool serves a distinct role in the research workflow:

- **WebSearch**: discover sources. Use for broad queries, finding primary documents, and contradiction-seeking searches. Generate 2-3 query variants per subquestion (exact-match, semantic, negation).
- **WebFetch**: deep-read a specific URL. Use after WebSearch identifies a promising source. Extract key facts, data, and quotes with provenance.
- **Write**: persist state to files. Use to save the workspace file (`workspace.md`) after each reconstruction step, and to write the final report. This is critical—without writing state to a file, workspace reconstruction is only conceptual.
- **Read**: reload persisted state. Use at the start of each new iteration to read `workspace.md` back into context, replacing stale conversation history.
- **Bash**: data processing, format conversion, or computation (e.g., calculating statistics, converting units, sorting tables).
- **Agent** (if available): spawn isolated subagent workers for parallel investigation tracks. Each subagent receives only its task objective, relevant workspace context, and allowed tools. Budget: up to 10 subagent spawns per research job; prefer batching independent subquestions into parallel subagents over spawning one per query.

### Subagent delegation

Use subagents to parallelize independent investigation tracks within the budget:

- Each subagent gets a narrow objective, a list of seed queries, and acceptance criteria.
- Subagents return structured findings: claims, evidence with provenance, confidence level, and unresolved questions (use the `quick-research` subagent output format).
- The orchestrator synthesizes subagent results, resolves contradictions, and updates the evolving report.
- Best uses for subagents: independent domain angles, contradiction-seeking verification, and data-heavy analysis.
- Do not spawn subagents for tasks that depend on each other—run those sequentially.

**Platform fallback**: if the Agent tool is not available on the current platform, fall back to sequential worker-style execution. Run each subtask in sequence within the orchestrator's own context, using workspace reconstruction between tasks to maintain isolation. The research quality should not degrade—only parallelism is lost.

### File-backed workspace reconstruction

Workspace reconstruction only works if the workspace lives in a file, not just in conversation context. Follow this discipline:

1. At project start, `Write` an initial `workspace.md` with the four-block template (see section 4).
2. After each meaningful step (search, read, synthesis), `Write` the updated `workspace.md`.
3. Before each new iteration, `Read` only `workspace.md`—do not rely on earlier conversation turns for research state.
4. The final report should be written to a separate file (e.g., `report.md`).

This ensures that old search results, raw page content, and intermediate reasoning are genuinely discarded from working context.

## Operating model

### 1. Initialize the research contract

Before searching deeply, pin down:

- the exact research question
- the decision the user is trying to make
- required output format
- time sensitivity
- constraints such as geography, budget, stack, or audience

If the user did not specify these, infer the smallest sensible contract and state the assumption briefly.

### 2. Build a Plan Board

Turn the problem into a compact task board with:

- the main question
- 3-7 subquestions
- priority for each subquestion
- expected evidence type for each subquestion
- blocking dependencies
- execution mode (parallel via subagent when available, otherwise sequential in the orchestrator)

Pick the next task by expected information gain, not by convenience. Prefer tasks that:

- close a major knowledge gap
- test a risky assumption
- add a new primary-source angle
- resolve a contradiction

### 3. Run worker-style investigations

Treat every subtask as a focused worker assignment with a narrow objective and explicit deliverable.

Each worker pass should return:

- findings
- evidence with provenance
- unresolved questions
- confidence level
- whether the result changes the overall thesis

Keep worker contexts isolated. Use the Agent tool to spawn subagents for independent tracks when available; otherwise run the same worker-style passes sequentially in the orchestrator. Do not drag the entire prior transcript into each subtask.

### 4. Reconstruct the workspace after each step

After each search, read, or synthesis step, rewrite the working state into only four blocks:

- `Research question`
- `Evolving report`
- `Immediate context`
- `Open tasks`

Definitions:

- `Research question`: the exact objective and constraints
- `Evolving report`: the best current draft, already cleaned and deduplicated
- `Immediate context`: only the facts, tensions, and next-step cues needed right now
- `Open tasks`: the remaining frontier on the Plan Board

Do not keep full raw history in the reasoning workspace. Full history can exist externally for audit, but the active context should stay compact.

### 5. Execute the Ralph loop

Repeat this loop until done:

1. Inspect the current workspace.
2. Choose the highest-value open task (or batch independent tasks for parallel subagents when available).
3. Gather or verify evidence (directly, or via subagent workers when supported).
4. Update the evolving report.
5. Run quality checks.
6. Reconstruct the workspace.

Do not stop just because there is enough text. Stop when the report is substantively supported.

## Budget and termination

### Query budget

Aim for 15–25 total WebSearch calls per research job. If you reach 30, pause and reassess: are you deepening the right questions, or are you thrashing?

For WebFetch (deep reads), budget 8–15 page fetches. Prioritize primary sources and high-signal pages over skimming many low-value results.

### Subagent budget

Up to 10 subagent spawns per research job. Each subagent should handle an independent subquestion or a verification task. Do not spawn a subagent for trivial lookups that the orchestrator can handle directly.

### Step budget

A typical research job should complete in 4–8 Ralph loop iterations. If you reach 10 iterations without the completion gate passing, switch to wrap-up mode: finalize the best-effort report and clearly mark what remains unverified.

### Termination triggers

Stop the Ralph loop and produce a final report when ANY of the following is true:

- The completion gate (see below) passes.
- You have reached the step budget (10 iterations).
- Two consecutive iterations produced no new evidence or changed no claims in the evolving report (diminishing returns).
- All remaining open tasks are blocked with no viable search strategy left.
- The user's time sensitivity constraint is about to be exceeded.

When terminating before the completion gate passes, the report must include a "Limitations" section explaining what was not resolved and why.

## Research rules

### Source policy

- Prefer primary sources first: official docs, papers, standards, filings, first-party announcements, vendor docs, benchmark authors.
- Use secondary sources to add synthesis or market framing, not as the sole support for important claims.
- For time-sensitive topics, verify current facts rather than relying on memory.
- Always distinguish sourced facts from your own inference.

### Verification policy

- Important claims need at least two independent supporting sources when feasible.
- Numeric claims, timelines, version claims, legal claims, and benchmark claims should be checked directly at the source.
- If sources conflict, surface the contradiction explicitly and explain which source you trust more and why.
- If evidence is weak, say so. Do not smooth over uncertainty.

### Retrieval policy

For each important subquestion, search from multiple angles:

- exact-match queries for names, versions, dates, APIs, regulations, or identifiers
- semantic/paraphrase queries for broader recall
- contradiction-seeking queries that try to disprove the current thesis

### Depth policy

Use iterative deepening:

- Depth 0: frame the problem and outline the answer shape
- Depth 1: establish main claims with sources
- Depth 2: verify contested or decision-critical claims
- Depth 3+: only if the remaining uncertainty justifies the extra cost

## Writing rules

Write the final output in answer-first structure. Use the following default template (adjust sections as needed, but always keep the skeleton):

```markdown
# [Report Title]

## Executive Summary
[2-4 sentences: direct answer or recommendation, then the top 2-3 reasons why.]

## Key Findings

### [Finding / Pillar 1]
[Evidence-backed narrative. Inline citations as [Source Title](url).]

### [Finding / Pillar 2]
...

### [Finding / Pillar N]
...

## Comparison Table (if applicable)
| Dimension | Option A | Option B | ... |
|-----------|----------|----------|-----|

## Open Risks & Unknowns
[What remains unverified, contested, or dependent on future events.]

## Limitations (if terminated before completion gate)
[What was not resolved and why.]

## Assumptions
[Explicit assumptions made during research.]

## Sources
- [Source Title](url) — brief note on what it contributed
```

Additional writing guidelines:

- Lead every section with the conclusion, then support it.
- Distinguish sourced facts from inference. Use phrases like "based on [source]" vs "this suggests that".
- Keep the report actionable: a reader should be able to make a decision after the Executive Summary alone.

## Default working template

Use this internal structure while researching:

```text
Research question:
- ...

Plan Board:
- [priority] subquestion -> expected evidence -> assigned to (orchestrator/subagent) -> status

Evolving report:
- current thesis
- confirmed findings
- contested findings

Immediate context:
- what changed in the last step
- what still blocks confidence
- next best action

Open tasks:
- ...
```

## Completion gate

The task is complete only when all of the following are true:

- the main question is answered directly
- major claims are backed by evidence
- important contradictions were checked
- uncertainty is called out explicitly
- the report is organized for decision-making rather than as a raw dump

If blocked, end with:

- what you verified
- what remains uncertain
- the minimum next action required
