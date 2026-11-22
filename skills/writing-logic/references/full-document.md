# Document level

A full document is a stack of paragraphs, each of one type, held together by one main claim. These rules apply on top of the paragraph-type rules.

## The main claim

Before outlining, write one sentence that the whole document exists to deliver. For a design proposal it is the decision ("Move session storage from Redis to Postgres by March"). For an architecture doc it is the rule the system keeps and how it keeps it ("Card numbers never reach the app database, because only the payment service holds the decryption key"). For a report it is the finding. For a tutorial it is what the reader will be able to do. It passes the same test as an argument claim: one sentence, takes a position, someone could disagree, no hedge.

If you cannot write it, the document is not ready to draft. Say what is blocking it (a missing fact, an undecided choice) and ask the user.

## Design docs

For a design doc, also read `references/design-doc.md`. It sets the two kinds (proposal and architecture), the section structure, and the concrete content a design doc needs. Where it differs from this file, such as on headings, section count, and what stays out of detail documents, it wins.

## Sections

- **Every section supports the main claim.** For each section, finish the sentence "This section shows the main claim holds because..." A section that cannot finish it is cut, or moved to an appendix.
- **Sections do not overlap.** If two sections make the same point with different material, merge them.
- **Sections leave no obvious hole.** Imagine the most skeptical reader of the main claim. Their first objection must be answered somewhere, usually in an argument or critique section.
- **Each section relates to the one before it.** Name the relation with the same words as paragraphs: because, therefore, but, for example, then. Sections that each only point back to the main claim read as a list of topics; reorder or merge them until each one follows from, supports, or limits an earlier one. Sibling sections are fine when the text before them announces them as a counted list ("two paths: first ..., second ...").
- **Two to five sections** at the top level. More usually means the main claim is too broad or the sections are at mixed levels of detail. A section can be as long as its point needs.
- **Each section names its type.** Decide whether it answers, argues, explains, or critiques. A section can hold paragraphs of different types, but its first paragraph says what the section establishes.

## Order

- The main claim goes first, in the opening paragraph, as an answer paragraph. This is the answer-first shape, the default. Two exceptions:
  - A case study, where the case is the subject, may open with the case and state the main claim by the end of the first section.
  - A guided document, for a reader who cannot understand the claim yet, opens with the question and states the main claim at the end. It has its own rules.
- Then sections in the order the reader needs them: what they must believe before they can follow the next part comes first.
- Within a section, the most important paragraph first.

## Headings and first sentences

- A heading states the section's point or the question it answers: "Why card numbers never reach the app database", not "Payment pipeline". Avoid topic labels and empty labels like "Overview", "Discussion", "Thoughts".
- The first sentence of every section states its point and its relation to the section before: "Card numbers never reach the app database, but their last four digits do, through two paths."
- The first sentence of every paragraph carries its point. Reading only first sentences, top to bottom, should give the whole argument in short form.

## Detail documents

Technical detail that a reader needs to work on the system, but not to accept the main claim, goes into a separate detail document. Examples: a step-by-step walk through a pipeline with code links, a protocol or schema reference, a full list of providers or settings.

- In the main document, keep one sentence that states what the detail shows, and link the detail document at that point.
- Each detail document is its own document, with its own main claim (usually an explanation), skeleton, and budget. It opens with one line saying which main document links to it.
- Propose detail documents in the skeleton. Write one only when the user asks, or when the main document cannot stand without the link target.

## Length

- Cut any paragraph whose removal leaves the main claim just as supported.
- Do not end with a summary that repeats the opening. End when the last section's point is made; add a closing paragraph only if it carries a next step or a decision the reader owns.

## Check

1. Write out the main claim and the first sentence of every section. Does that list stand on its own as the argument?
2. For each section, name its type and the sentence it adds to the case. Any section without one goes.
3. For each section after the first, name its relation to an earlier section. If you can only say "also about the main claim", reorder, merge, or announce the siblings as a counted list.
4. Find any paragraph that a reader needs only to change the code, not to accept the main claim. Move it to a detail document.
