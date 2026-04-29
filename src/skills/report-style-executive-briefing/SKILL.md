---
name: report-style-executive-briefing
description: Use for short decision-oriented memos — bottom line up front, 3–5 key points, decisional implications, brief risks. Designed to be readable in under 5 minutes.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: writing-style
---

# Report Style — Executive Briefing

A short, action-oriented memo for decision-makers who don't have time to read 4000 words. The full research still happens upstream; the briefing surfaces only what matters for the decision.

## When this style fits

- User asks for a "brief", "memo", "TL;DR", "one-pager", "exec summary", or otherwise signals brevity.
- A named stakeholder with decision rights is the audience ("for the CTO", "for legal review").
- The output will be skimmed, not studied.
- The research is mature; the user needs a decision artifact, not a learning artifact.

## Tone

- Direct. No throat-clearing.
- One claim per sentence where possible.
- Imperative voice for recommendations: "Adopt X", "Reject Y", "Defer until Z".
- Numbers preferred over adjectives — "3× faster" beats "much faster".
- Cut every word that could be cut without losing meaning.

## Section template

```markdown
# {Decision Subject — phrase as the question being decided}

## Bottom Line

{2–3 sentences. The recommendation, then the single most important reason. The reader should be able to act after reading just this section.}

## Key Points

- {3–5 bullets. One claim per bullet, each with a citation `[N]`. No bullet wraps to more than two lines.}

## What This Means

{Implications for the decision: concrete actions, dependencies, sequencing, owners if known. Two short paragraphs max.}

## Risks & Caveats

- {1–3 bullets. Only the risks that could change the recommendation. Skip the boilerplate ones.}

## References
```

## Length norm

300–800 words. **Hard ceiling: 1000 words.** If the report exceeds 1000 words, this style is wrong for the content — switch to `technical-paper` or `position-paper`.

## Anti-patterns

- **Padding.** Don't expand to fill space. Shorter is better. A 400-word briefing that lands is stronger than an 800-word briefing that meanders.
- **Including methodology.** This isn't a research report; it's a decision memo. The reader trusts the upstream research; show only the conclusions and decision-relevant detail.
- **Mealy-mouthed recommendations.** "Consider exploring whether X might be worth investigating" is not a recommendation. Either recommend something or admit you can't.
- **Long bullets.** A bullet should fit on one line at typical viewport width. If a bullet wraps to three lines, split it or move it to prose.
- **Burying the recommendation.** The recommendation goes in the first sentence of `Bottom Line`. If the reader stops after the title, the second-best outcome is they read one sentence and still know the answer.
- **Multiple recommendations.** One memo, one decision. Multiple decisions need multiple memos.
