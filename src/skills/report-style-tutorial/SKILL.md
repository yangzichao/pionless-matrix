---
name: report-style-tutorial
description: Use for textbook-style step-by-step explanations of a complex concept — building intuition first, then worked examples, then formal definition, then connections and common pitfalls. The right style when the user wants to *understand* a concept gradually, not just be informed about it.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: writing-style
---

# Report Style — Tutorial

A pedagogical, build-up-the-reader's-understanding style. Use when the user wants to learn a complex concept step by step ("explain X to me", "walk me through Y", "help me understand Z", "tutorial on W", "教科书风格"). **Not** for landscape surveys, decision memos, or argued positions — those have their own styles.

## When this style fits

- "Explain X step by step / from first principles."
- "I'm trying to understand <complex concept> — walk me through it."
- "Tutorial on X" / "primer on X" / "introduction to X".
- The user signals they are *learning*, not deciding or surveying.

## Tone

- Patient, pedagogical, reader-first.
- Use **second person** ("you'll see…", "imagine…") and **inclusive first person plural** ("let's start with…", "we now have…"). Avoid the impersonal academic voice this style is meant to make accessible.
- Acknowledge confusion proactively. "This is the part that trips people up" beats glossing.
- Build, don't dump. Each section should depend on the previous one. The reader should never need to scroll back to follow.
- Concrete before abstract. Always. Even one sentence of intuition ("think of it as a generalized X") beats a paragraph of formal setup.

## Section template

```markdown
# {Concept Title}

## Why this matters

{2–4 sentences. Motivate the concept: what does understanding it unlock? What problem does it solve? Hook the reader before any formalism.}

## The intuition

{Informal, no-jargon, often with an analogy. The goal is to plant a mental picture so that when the formalism arrives, the reader already has a place to put it. If a one-line analogy works, lead with it.}

## A worked example

{A concrete, small, fully-walked-through case. Numbers, not symbols, when possible. Show every step the reader would otherwise have to reconstruct in their head. This is the bridge between intuition and formalism — never skip it.}

## The formal version

{Now, with intuition and a worked example in hand, introduce the formal definition / equation / framework. Inline LaTeX for math (`$...$` / `$$...$$`). Connect each formal piece back to its intuition counterpart: "the $\lambda$ from the formula is what we called *the rate* in the worked example."}

## More examples / variations

{2–4 short follow-up cases. Each should illustrate a different facet — edge case, a parameter regime, a common variant. Keep them short; the long walk-through was section 3.}

## Common pitfalls

{Misconceptions, sign errors, "looks-similar-but-isn't" confusions. Frame as "you might think X — actually it's Y, because…". This is a high-value section: most readers carry at least one of these into the topic.}

## Connections

{How this concept relates to other things the reader probably knows or will encounter. One short paragraph or grouped bullets per connection. Helps the concept stick by integrating it into the reader's existing mental network.}

## Where to go next

{2–4 next-step pointers. Be specific: "to see how this generalizes, read X"; "for the rigorous proof, see Y chapter Z"; "the historical paper that introduced this is W". Cite as `[Title](url)` / numbered references like the other styles.}

## References
```

Section names are guidance, not law. Rename them to fit the topic ("The intuition" might become "What is a manifold, intuitively?") but keep the *order* — motivation → intuition → worked example → formalism → variations → pitfalls → connections → next steps. The order is what makes the style work.

## Length norm

2000–6000 words typical. Tutorials are longer than landscape scans because building intuition takes space, and worked examples take more space than formal definitions. **Do not compress** — compressing a tutorial back into the formal-definition-first shape defeats its purpose.

If the orchestrator's `draft_brief` requests a hard length cap below 2000 words, push back via the writer's `notes` field rather than silently strip the worked example or the pitfalls section.

## Anti-patterns

- **Definition-first.** Leading with `Definition: X is …` before any motivation or intuition is the academic-paper style; this style explicitly inverts that. The formal version arrives in section 4, not section 1.
- **No worked example.** Skipping the concrete walkthrough is the single biggest tutorial failure. The reader's understanding is built on the bridge of a worked example; if it's missing, the formalism floats.
- **Jargon dumps.** Introducing five new terms in one paragraph kills pedagogical flow. Introduce terms one at a time, define on first use, and reuse the same term consistently.
- **Listing facts without connection.** A bulleted list of properties is not a tutorial; it's a cheat sheet. Every section in this style should build on the previous one.
- **Imitating a research paper.** No abstract, no Open Risks & Unknowns, no neutral hedging tone. This style is teaching, not surveying.
- **Skipping pitfalls.** Common pitfalls is where the reader catches the misunderstanding they were about to walk away with. Removing it for length is a false economy.
- **No references / "read the literature".** Even pedagogical writing needs concrete next-step pointers. Vague "see further reading" is a cop-out; name the specific source and what it covers.
