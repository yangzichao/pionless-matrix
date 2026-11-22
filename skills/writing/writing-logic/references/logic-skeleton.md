# Logic skeleton

The logic skeleton shows the argument of a text without its prose, so the user can check the logic in under a minute. It lists the main claim, the point of each paragraph, and how each point relates to the one before it.

## Format

```markdown
Main claim: <one sentence>

1. [<paragraph type>] <the paragraph's point, in one sentence>
2. [<paragraph type>] (<relation> 1) <point>
3. [<paragraph type>] (<relation> 2) <point>
...
```

- Number every paragraph. For a document with sections, put the section heading on its own line above its paragraphs and keep one numbering through the whole document.
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

## Check

A skeleton that passes:

- Reads as a complete argument with the prose removed.
- Gives every paragraph one relation from the list. A paragraph that needs "and also" or no relation at all does not belong, or belongs in another place.
- Has no two points that say the same thing.
- Leaves no point unconnected to the main claim through some chain of relations.

## Example

```markdown
Main claim: Use Postgres for the ledger, not DynamoDB.

Why Postgres
1. [answer] Use Postgres for the ledger.
2. [argument] (because 1) Every write changes two balances that must change together, and Postgres does this in one transaction.
3. [argument] (but 2) DynamoDB scales further.
4. [argument] (but 3) Our peak of 400 writes per second fits one Postgres primary with 70% CPU headroom.

Risks
5. [critique] (but 1) The headroom figure comes from one load test on last month's traffic mix.
```
