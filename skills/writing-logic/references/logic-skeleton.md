# Logic skeleton

The logic skeleton shows the argument of a text without its prose, so the user can check the logic in under a minute. It lists the main claim, the point of each paragraph, and how each point relates to the one before it.

## Format

```markdown
Main claim: <one sentence>
Budget: <N> paragraphs, about <N × 75> words (or <N × 200> Chinese characters)

1. [<paragraph type>] <the paragraph's point, in one sentence>
2. [<paragraph type>] (<relation> 1) <point>
3. [<paragraph type>] (<relation> 2) <point>
...
```

- Number every paragraph. For a document with sections, put a section line above its paragraphs, `S2. [<type>] (<relation> S1) <heading>: <the section's point>`, and keep one paragraph numbering through the whole document. The first section's relation points to the opening paragraph.
- The paragraph type is one of `answer`, `argument`, `explanation`, `critique`.
- The point is the paragraph's first sentence, or a plain one-sentence version of it if the first sentence is long.
- The relation names how this point connects to an earlier one. Use exactly one of these words:
  - `because`: this point supports the earlier one.
  - `therefore`: this point follows from the earlier one.
  - `but`: this point limits or qualifies the earlier one.
  - `for example`: this point is a case of the earlier one.
  - `then`: this point is the next step in an explanation and depends on the earlier one.
- A relation usually points to the paragraph just before. When it points further back, name that number: `(because 2)`.
- The first paragraph has no relation; it states or leads straight to the main claim.
- List proposed detail documents after the paragraphs, one line each: `D1. <title>: <what it covers> (linked from S1)`.

## Long documents: two levels

A skeleton with more than 12 paragraph lines is too long to check at a glance. Split it into two levels.

**Level 1, sections.** One line per section, with the same relation words, plus its share of the budget:

```markdown
Main claim: <one sentence>
Budget: <total words>, <N> sections

S1. [<type>] <section heading>: <the section's point> (<n> paragraphs, about <w> words)
S2. [<type>] (<relation> S1) <section heading>: <point> (<n> paragraphs, about <w> words)
...
```

The user approves level 1 before any drafting.

**Level 2, paragraphs.** Before drafting a section, write its paragraph lines in the normal format, numbered `S2.1`, `S2.2`, and so on. Run the check below on them. Do not stop for approval of each section; the user sees every level-2 skeleton with the final text.

## Check

A skeleton that passes:

- Reads as a complete argument with the prose removed.
- Gives every section and every paragraph one relation from the list. The section lines alone read as an argument, not as a list of topics. A paragraph that needs "and also" or no relation at all does not belong, or belongs in another place.
- Has no two points that say the same thing.
- Leaves no point unconnected to the main claim through some chain of relations.
- Passes the cut test: removing any one paragraph would leave the main claim less supported. Cut a paragraph whose removal changes nothing before the user sees the skeleton.

## Example

```markdown
Main claim: Use Postgres for the ledger, not DynamoDB.
Budget: 5 paragraphs, about 375 words

Why Postgres
1. [answer] Use Postgres for the ledger.
2. [argument] (because 1) Every write changes two balances that must change together, and Postgres does this in one transaction.
3. [argument] (but 2) DynamoDB scales further.
4. [argument] (but 3) Our peak of 400 writes per second fits one Postgres primary with 70% CPU headroom.

Risks
5. [critique] (but 1) The headroom figure comes from one load test on last month's traffic mix.
```
