---
name: deep-research-pro
description: Run an unlimited deep research workflow with full orchestrator-worker decomposition, aggressive verification, and no budget constraints. Use for PhD-level investigations, comprehensive landscape scans, and high-stakes decisions requiring exhaustive evidence.
---

# Deep Research Pro

Use this skill when the user asks for exhaustive research, a comprehensive literature review, a full competitive landscape, a regulatory deep-dive, or any investigation where completeness matters more than speed.

This is the **unbounded** tier of the research system. Unlike `deep-research`, there are no soft limits on queries, page reads, or iterations. The agent should go as deep as the evidence requires.

## Objective

Produce a high-confidence, citation-dense report by running an unbounded orchestrator-worker research loop with aggressive verification. Operate on three principles:

1. **Orchestrator-worker**: one lead thread manages the plan and delegates each investigation thread as an isolated subagent task.
2. **Ralph loop**: repeat research, synthesis, and verification until the quality gate passes or a real blocker remains.
3. **Workspace reconstruction**: after every meaningful step, throw away noisy history and rebuild only the minimal working state.

## Tool usage guide

Each allowed tool serves a distinct role:

- **WebSearch**: discover sources. Generate 3-5 query variants per subquestion (exact-match, semantic, negation, site-specific, temporal).
- **WebFetch**: deep-read a specific URL. Use liberally after WebSearch identifies promising sources. Extract key facts, data, and quotes with provenance.
- **Write**: persist state to files. Save `workspace.md` after each reconstruction step. Write the final report to `report.md`.
- **Read**: reload persisted state. Read `workspace.md` at the start of each iteration—do not rely on earlier conversation turns.
- **Bash**: data processing, format conversion, computation, or table generation.
- **Agent** (if available): spawn isolated subagent workers for parallel investigation tracks. Each subagent receives only its task objective, relevant workspace context, and allowed tools. Subagent results are collected and synthesized by the orchestrator.

### File-backed workspace reconstruction

Workspace reconstruction only works if the workspace lives in a file, not just in conversation context:

1. At project start, `Write` an initial `workspace.md` with the four-block template (see section 4).
2. After each meaningful step (search, read, synthesis), `Write` the updated `workspace.md`.
3. Before each new iteration, `Read` only `workspace.md`—do not rely on earlier conversation turns for research state.
4. The final report should be written to a separate file (e.g., `report.md`).

### Subagent delegation

For complex research jobs, decompose into parallel subagent tracks:

- Each subagent gets a narrow objective, a list of seed queries, and acceptance criteria.
- Subagents return structured findings: claims, evidence with provenance, confidence level, and unresolved questions.
- The orchestrator synthesizes subagent results, resolves contradictions, and updates the evolving report.
- Use subagents especially for: independent domain angles, contradiction-seeking verification, and data-heavy analysis.

**Platform fallback**: if the Agent tool is not available on the current platform, fall back to sequential worker-style execution. Run each subtask in sequence within the orchestrator's own context, using workspace reconstruction between tasks to maintain isolation. The research quality should not degrade—only parallelism is lost.

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
- 5-12 subquestions (more granular than the standard tier)
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

Do not keep full raw history in the reasoning workspace.

### 5. Execute the Ralph loop

Repeat this loop until done:

1. Inspect the current workspace.
2. Choose the highest-value open task (or batch tasks for parallel subagents when available).
3. Gather or verify evidence.
4. Update the evolving report.
5. Run quality checks.
6. Reconstruct the workspace.

Do not stop just because there is enough text. Stop when the report is exhaustively supported.

## Budget and termination

### No hard budget

This tier has **no hard limits** on queries, page reads, or iterations. Go as deep as the evidence requires.

However, maintain efficiency discipline:

- Do not repeat searches that have already been exhausted.
- Track diminishing returns: if 3 consecutive searches on the same subquestion yield no new evidence, mark it as saturated and move on.
- Prefer depth on high-value questions over breadth on low-value ones.

### Termination triggers

Stop the Ralph loop and produce a final report when ANY of the following is true:

- The completion gate (see below) passes.
- All subquestions are either answered with high confidence or marked as genuinely unanswerable with current sources.
- The user explicitly requests completion.
- The user's time sensitivity constraint is about to be exceeded.

When terminating, the report must include a "Limitations" section for any gaps that remain.

## Research rules

### Source policy

- Prefer primary sources first: official docs, papers, standards, filings, first-party announcements, vendor docs, benchmark authors.
- Use secondary sources to add synthesis or market framing, not as the sole support for important claims.
- For time-sensitive topics, verify current facts rather than relying on memory.
- Always distinguish sourced facts from your own inference.
- Actively seek sources that **disagree** with the emerging thesis.

### Verification policy

- Important claims need at least **three** independent supporting sources when feasible (stricter than standard tier).
- Numeric claims, timelines, version claims, legal claims, and benchmark claims must be checked directly at the source.
- If sources conflict, surface the contradiction explicitly, explain which source you trust more and why, and attempt to resolve via a third source.
- If evidence is weak, say so. Do not smooth over uncertainty.
- Run a dedicated contradiction-seeking pass before finalizing.

### Retrieval policy

For each important subquestion, search from multiple angles:

- exact-match queries for names, versions, dates, APIs, regulations, or identifiers
- semantic/paraphrase queries for broader recall
- contradiction-seeking queries that try to disprove the current thesis
- site-specific queries targeting authoritative domains
- temporal queries to capture evolution over time

### Depth policy

Use iterative deepening without artificial depth caps:

- Depth 0: frame the problem and outline the answer shape
- Depth 1: establish main claims with sources
- Depth 2: verify contested or decision-critical claims
- Depth 3: cross-reference across domains, resolve contradictions
- Depth 4+: pursue remaining uncertainties, edge cases, and minority viewpoints

## Writing rules

Write the final output in answer-first structure. Use the following default template (adjust sections as needed, but always keep the skeleton):

```markdown
# [Report Title]

## Executive Summary
[3-5 sentences: direct answer or recommendation, then the top 3-5 reasons why.]

## Methodology
[Brief description of research approach, sources consulted, and any limitations in methodology.]

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

## Contradictions & Contested Claims
[Where sources disagree, what the disagreement is, and which side the evidence favors.]

## Open Risks & Unknowns
[What remains unverified, contested, or dependent on future events.]

## Limitations
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
- Include a dedicated "Contradictions & Contested Claims" section—this is mandatory for the pro tier.

## Default working template

Use this internal structure while researching:

```text
Research question:
- ...

Plan Board:
- [priority] subquestion -> expected evidence -> assigned to (orchestrator/subagent) -> status

Evolving report:
- current thesis
- confirmed findings (with source count)
- contested findings
- contradictions found

Immediate context:
- what changed in the last step
- what still blocks confidence
- next best action
- subagent status

Open tasks:
- ...
```

## Completion gate

The task is complete only when all of the following are true:

- the main question is answered directly
- major claims are backed by evidence from multiple independent sources
- important contradictions were identified and addressed
- a dedicated contradiction-seeking pass was completed
- uncertainty is called out explicitly
- the report includes methodology, contradictions, and limitations sections
- the report is organized for decision-making rather than as a raw dump

If blocked, end with:

- what you verified
- what remains uncertain
- the minimum next action required
