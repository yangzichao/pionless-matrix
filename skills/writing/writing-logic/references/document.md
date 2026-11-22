# Document level

A full document is a stack of paragraphs, each doing one move, held together by one top line. These rules apply on top of the move rules.

## The top line

Before outlining, write one sentence that the whole document exists to deliver. For a design doc it is the decision ("Move session storage from Redis to Postgres by March"). For a report it is the finding. For a tutorial it is what the reader will be able to do. It passes the same test as an argument claim: one sentence, takes a position, someone could disagree, no hedge.

If you cannot write it, the document is not ready to draft. Say what is blocking it (a missing fact, an undecided choice) and ask the user.

## Sections

- **Every section supports the top line.** For each section, finish the sentence "This section shows the top line holds because..." A section that cannot finish it is cut, or moved to an appendix.
- **Sections do not overlap.** If two sections make the same point with different material, merge them.
- **Sections leave no obvious hole.** Imagine the most skeptical reader of the top line. Their first objection must be answered somewhere, usually in an argument or critique section.
- **Two to five sections** at the top level. More usually means the top line is too broad or the sections are at mixed levels of detail.
- **Each section names its move.** Decide whether it concludes, argues, explains, or critiques. A section can hold paragraphs of different moves, but its first paragraph says what the section establishes.

## Order

- The top line goes first, in the opening paragraph, as a conclusion move. Exception: a case study, where the case is the subject, may open with the case and state the top line by the end of the first section.
- Then sections in the order the reader needs them: what they must believe before they can follow the next part comes first. In a design doc that is usually decision, why, how it works, risks.
- Within a section, the most important paragraph first.

## Headings and first sentences

- A heading names the content: "Why Postgres", "Failure handling", "Rollout". Avoid empty labels like "Overview", "Discussion", "Thoughts".
- The first sentence of every section and every paragraph carries its point. Reading only first sentences, top to bottom, should give the whole argument in short form.

## Length

- Cut any paragraph whose removal leaves the top line just as supported.
- Do not end with a summary that repeats the opening. End when the last section's point is made; add a closing paragraph only if it carries a next step or a decision the reader owns.

## Check

1. Write out the top line and the first sentence of every section. Does that list stand on its own as the argument?
2. For each section, name its move and the sentence it adds to the case. Any section without one goes.
