# Document level

A full document is a stack of paragraphs, each of one type, held together by one main claim. These rules apply on top of the paragraph-type rules.

## The main claim

Before outlining, write one sentence that the whole document exists to deliver. For a design doc it is the decision ("Move session storage from Redis to Postgres by March"). For a report it is the finding. For a tutorial it is what the reader will be able to do. It passes the same test as an argument claim: one sentence, takes a position, someone could disagree, no hedge.

If you cannot write it, the document is not ready to draft. Say what is blocking it (a missing fact, an undecided choice) and ask the user.

## Sections

- **Every section supports the main claim.** For each section, finish the sentence "This section shows the main claim holds because..." A section that cannot finish it is cut, or moved to an appendix.
- **Sections do not overlap.** If two sections make the same point with different material, merge them.
- **Sections leave no obvious hole.** Imagine the most skeptical reader of the main claim. Their first objection must be answered somewhere, usually in an argument or critique section.
- **Two to five sections** at the top level. More usually means the main claim is too broad or the sections are at mixed levels of detail.
- **Each section names its type.** Decide whether it answers, argues, explains, or critiques. A section can hold paragraphs of different types, but its first paragraph says what the section establishes.

## Order

- The main claim goes first, in the opening paragraph, as an answer paragraph. This is the answer-first shape, the default. Two exceptions:
  - A case study, where the case is the subject, may open with the case and state the main claim by the end of the first section.
  - A guided document, for a reader who cannot understand the claim yet, opens with the question and states the main claim at the end. It has its own rules.
- Then sections in the order the reader needs them: what they must believe before they can follow the next part comes first. In a design doc that is usually decision, why, how it works, risks.
- Within a section, the most important paragraph first.

## Headings and first sentences

- A heading names the content: "Why Postgres", "Failure handling", "Rollout". Avoid empty labels like "Overview", "Discussion", "Thoughts".
- The first sentence of every section and every paragraph carries its point. Reading only first sentences, top to bottom, should give the whole argument in short form.

## Length

- Cut any paragraph whose removal leaves the main claim just as supported.
- Do not end with a summary that repeats the opening. End when the last section's point is made; add a closing paragraph only if it carries a next step or a decision the reader owns.

## Check

1. Write out the main claim and the first sentence of every section. Does that list stand on its own as the argument?
2. For each section, name its type and the sentence it adds to the case. Any section without one goes.
