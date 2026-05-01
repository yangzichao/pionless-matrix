---
name: report-style-technical-paper
description: Use for source-backed technical or analytical reports — neutral tone, multi-pillar findings, cited claims, no pre-committed recommendation. The default style when the user did not signal a stance.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: writing-style
---

# Report Style — Technical Paper

The default neutral, source-backed analytical style. Use when the goal is to inform a reader about a technical or analytical topic and let them draw their own conclusions, **not** when the goal is to argue a position or recommend a single course of action.

## When this style fits

- Technical landscape questions where readers will compare options themselves.
- Source-backed analyses where neutrality matters.
- "Help me understand X" research requests with no implied stance.
- The orchestrator's default when user intent is ambiguous.

## Tone

- Neutral, even-handed.
- Inference and opinion are explicitly marked vs sourced fact.
- Strong claims need strong sources; otherwise hedge.
- Impersonal voice or first-person plural — never "I".

## Section template

```markdown
# {Report Title}

## Executive Summary

{2–4 sentences. The most important finding(s), then the top 2–3 supporting reasons. The reader should be able to act on this section alone.}

## Key Findings

### {Finding / Pillar 1}

{Evidence-backed narrative with inline numbered citations.}

### {Finding / Pillar 2}

{...}

## Comparison (if applicable)

{Prefer definition list or paragraph + sub-bullets. A Markdown table is acceptable when the comparison is genuinely tabular (≥3 items × ≥3 parallel attributes) or the brief explicitly requested one.}

## Open Risks & Unknowns

{What remains unverified, contested, or dependent on future events.}

## Limitations (if loop force-terminated)

{What was not resolved and why. Required when the orchestrator's craft_brief flags an early-termination context.}

## Assumptions

## References
```

## Length norm

1500–4000 words typical. Longer for landscape-heavy topics.

## Anti-patterns

- **Don't take a strong position the evidence doesn't fully support.** If the user wants a recommendation, that's `position-paper` style, not this one.
- **Don't editorialize in Key Findings** — save commentary for `Open Risks & Unknowns`.
- **Don't bury contradictions** — surface them in Findings or Open Risks.
- **Don't compress to a TL;DR.** This style trusts the reader with full context. If the user wants brevity, that's `executive-briefing`.
