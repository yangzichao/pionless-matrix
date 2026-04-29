# Workspace

The Loop State and Gate Checklist sections are mandatory and must be updated every iteration.

```markdown
# Workspace

## Loop State
- Iteration: 1
- Gate: NOT PASSED
- Stale rounds: 0

## Gate Checklist
- [ ] Main question answered directly
- [ ] Major claims backed by 2+ sources
- [ ] Contradictions investigated
- [ ] Uncertainty called out explicitly
- [ ] Report organized for decision-making

## Research Question
- {exact question}
- {decision context}
- {constraints}
- Mode: {search | research}
- Report style: {technical-paper | position-paper | executive-briefing | landscape-scan | design-to-do}

## Working Thesis
*(Only present when Mode = research. Omit this entire section in search mode.)*
- Current best answer: {1–3 sentences capturing the working answer}
- Confidence: {low | medium | high}
- Last revised: iteration {N}

## Plan Board
| # | Subquestion | Priority | Assigned To | Status |
|---|-------------|----------|-------------|--------|

## Findings
*Terse bullets only — one claim per line, with source and confidence. Do not write prose paragraphs here. The `deep-research-drafter` agent expands these bullets into running prose at gate-pass time; this section is the orchestrator's working notes, not the report. Format suggestion: `- {claim}: {evidence summary} — source: [Title](url) — confidence: {high|medium|low}`. Cross-finding observations ("X and Y agree on Z; W contradicts both") also go in as bullets, not paragraphs.*
- ...

## Next Action
- ...
```
