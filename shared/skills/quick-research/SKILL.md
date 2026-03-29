---
name: quick-research
description: Run a fast, single-agent research pass for focused questions. No subagent decomposition. Designed to be invoked as a worker by other workflows or used standalone for time-sensitive lookups.
allowed-tools: Read, Write, Bash, WebSearch, WebFetch
---

# Quick Research

Use this skill for focused research questions that need a sourced answer fast: fact-checking a claim, finding the current state of a technology, getting a quick competitive snapshot, answering a specific technical question, or feeding findings into a larger workflow.

This is the **lightweight** tier of the research system. No subagent decomposition, no elaborate plan board, no multi-pass verification. One agent, one focused loop, fast turnaround.

## Objective

Produce a concise, sourced answer to a focused question within a tight budget. Operate as a single-agent research loop:

1. **Clarify** the question (infer if obvious).
2. **Search** from 2-3 angles.
3. **Verify** key claims with a second source when feasible within budget.
4. **Synthesize** into a compact answer with citations.

## Tool usage guide

- **WebSearch**: primary discovery tool. Generate 2-3 query variants per question (exact-match + semantic + one alternative angle).
- **WebFetch**: deep-read 2-4 high-value pages. Don't skim many pages—read the best ones.
- **Write**: save final output to a file when invoked standalone. When running as a subagent, return findings in the structured format below instead.
- **Read**: if workspace state was provided by a parent orchestrator, read it to understand context.
- **Bash**: quick data processing or computation if needed.

No Agent tool. This skill does not spawn subagents. It is designed to **be** a subagent.

## Operating model

### 1. Frame the question (30 seconds)

Pin down:

- the exact question to answer
- what "good enough" looks like (a number? a yes/no? a 3-item comparison?)
- any constraints (recency, geography, domain)

If invoked as a subagent, these should come from the parent orchestrator's task card. If standalone, infer from the user's request.

### 2. Search (the core loop)

Run a tight search loop:

1. Execute 2-3 WebSearch queries from different angles.
2. Scan results for the most authoritative sources.
3. WebFetch the top 2-4 pages.
4. Extract key facts with provenance.
5. If a critical claim has only one source, do one more targeted search to verify.

Do not iterate beyond this. If the answer is still unclear after one pass, report what you found and what remains uncertain.

### 3. Synthesize

Produce output in the structured format below.

## Budget and termination

### Hard budget

- **WebSearch**: 5-10 calls maximum.
- **WebFetch**: 2-5 page reads maximum.
- **Iterations**: 1-2 passes. No Ralph loop. If the first pass doesn't answer the question, do one verification pass, then stop.

### Termination triggers

Stop and produce output when ANY of the following is true:

- The core claim is answered with at least two independent supporting sources (matching the verification step in the objective). If only one source was found within budget, report the answer but mark confidence as "low — single source only".
- You've exhausted the query budget.
- The question is unanswerable with web sources (say so explicitly).

## Research rules

### Source policy

- Prefer primary sources: official docs, papers, first-party announcements.
- For time-sensitive topics, verify current facts rather than relying on memory.
- Always distinguish sourced facts from your own inference.

### Verification policy

- Key claims should have at least one supporting source; two if feasible within budget.
- If sources conflict, note the conflict and state which source seems more reliable.
- If evidence is weak, say so. Do not smooth over uncertainty.

### Retrieval policy

For each question, search from at least two angles:

- exact-match query for specific terms
- semantic/paraphrase query for broader recall

## Output format

### Standalone mode (invoked directly by user)

When invoked directly, write a concise answer:

```markdown
# [Question as Title]

## Answer
[2-5 sentences: direct answer with inline citations as [Source Title](url).]

## Supporting Evidence
- **[Claim 1]**: [evidence summary] — [Source](url)
- **[Claim 2]**: [evidence summary] — [Source](url)

## Confidence & Caveats
[One-liner on confidence level and any important caveats.]

## Sources
- [Source Title](url)
```

### Subagent mode (invoked by a parent orchestrator)

When invoked as a worker by another skill (deep-research, deep-research-pro, or any other workflow), return findings in this structured format so the parent can consume them:

```text
Task: [the subquestion assigned]
Status: answered | partially-answered | unanswerable
Confidence: high | medium | low

Findings:
- [claim]: [evidence summary] | source: [url] | confidence: [high/medium/low]
- ...

Contradictions:
- [if any sources disagreed, note it here]

Unresolved:
- [what couldn't be answered and why]

Recommended follow-up:
- [if partially answered, what the parent should investigate next]
```

This format is designed to be directly ingestible by the evolving report of a parent deep-research orchestrator.

## What this skill does NOT do

- No Plan Board construction (that's the orchestrator's job).
- No Ralph loop (one pass, maybe two).
- No subagent spawning (this IS the subagent).
- No workspace reconstruction (context stays small naturally due to tight budget).
- No exhaustive verification (that's deep-research-pro territory).

This keeps the skill fast, predictable, and composable.
