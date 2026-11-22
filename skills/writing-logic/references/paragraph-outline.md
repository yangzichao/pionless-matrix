# Paragraph form: outline

Any of the four paragraph types can be written in one of two forms: as prose, or as an outline. An outline is a lead sentence followed by a bullet list with sub-bullets, so the structure is visible on the page instead of carried by relation words. The type does not change. An argument written as an outline is still an argument: a claim, its reasons, their evidence.

## When to use it

Use the outline form when both hold:

- **The structure is a tree.** The point splits into two to five parts of the same kind (reasons, components, options, risks), and each part has its own support.
- **The reader scans.** Reviewers of a design doc, a status report, a comparison, or a review read the top level first and drop into a part only when it matters to them.

Use prose when the point is a chain: A, therefore B, therefore C. In a list, nesting can only say "this supports that"; it cannot say "therefore" or "but", so a chain written as bullets loses its logic. Use prose also when there are fewer than three items, or when an item makes sense only after the one before it.

## Shape

1. **The lead sentence, as prose.** It states the paragraph's point and how many parts follow: "The summary is stored on the meeting record, for three reasons."
2. **Top-level bullets: the parts.** Each is one full sentence that states its part, not a fragment or a topic label. All top-level bullets are the same kind of thing and have the same form.
3. **Sub-bullets: support for their own parent only.** Evidence, an example, a condition, or a consequence of the bullet directly above. A sub-bullet never refers to a sibling of its parent.
4. **A closing sentence, as prose, when something follows.** What the list adds up to, or where the next part picks up. Leave it out when the lead already says it.

## Rules

- **Two levels at most.** If a part needs a third level, it is big enough to be its own paragraph or subsection.
- **Two to five bullets per level.** More than five usually mixes kinds; regroup them under a new level or split the paragraph.
- **Nesting means "because" or "for example".** Any other relation must be written out. A sub-bullet that limits its parent starts with "but" or "except"; one that follows from its parent starts with "so".
- **Bold labels are optional and short.** A bullet may open with a bold label of one to four words, followed by the full sentence. The label names the part; the sentence still carries the point.
- **Same budget as prose.** An outline paragraph counts every word of its lead, bullets, and closing against the paragraph budget in `references/length-budget.md`. If it runs over, split it into two outline paragraphs or make each top-level bullet its own paragraph.
- **One outline does not follow another.** Two outline paragraphs in a row read like slides. Put a prose paragraph, or at least a prose lead that links back, between them.

## Check

- Read only the lead and the top-level bullets. Do they state the whole point?
- For each sub-bullet, name its relation to its parent. If it is not "because" or "for example" and the bullet does not say which relation it is, rewrite it.
- Would the paragraph lose a "therefore" or a "but" if it stayed a list? Then write it as prose.

## Example

Before, as prose that hides a tree: "We store the summary on the meeting record. Reusing the rewritten-text field would avoid a schema change, but two other features read that field first. A note would also avoid a schema change, but deleting the meeting would leave the note behind. The new fields are optional, so old records need no migration step, and deleting a meeting deletes its summary."

After, as an outline:

The summary is stored in two new optional fields on the meeting record. Two other places are cheaper but break something:

- **The rewritten-text field** needs no schema change, but two features read it first and would treat the summary as the transcript.
  - Paste-last-transcription and agent-access search both prefer that field.
- **A separate note** needs no schema change either, but it outlives its meeting.
  - Deleting a meeting would leave the note behind, and the two would disagree.

The new fields avoid both problems at the cost of one schema change, which SwiftData handles as an automatic lightweight migration.
