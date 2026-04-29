---
name: report-style-landscape-scan
description: Use for survey / "what's out there" reports — categorized inventory of options or items, comparable depth on each, cross-cutting themes, and notable outliers. The right style when readers need a mental map of a space, not a recommendation.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: writing-style
---

# Report Style — Landscape Scan

An encyclopedic survey style. The goal is to map a space comprehensively, with comparable depth on each item, so the reader walks away with a mental taxonomy and can decide for themselves.

## When this style fits

- "What are all the X out there?"
- Market or technical landscape scans (vendors, frameworks, approaches, jurisdictions).
- Pre-procurement reviews where the reader needs to know what exists before deciding.
- Trend reports that require visible coverage of a space — incomplete coverage makes the report misleading.

## Tone

- Even-handed. No item should obviously be favored unless the evidence overwhelmingly justifies it (and even then, name the favoritism explicitly).
- Each item described in roughly the same shape and same depth — readers will compare, and uneven depth signals authorial bias.
- Cite the **primary source** for each item: vendor docs, official site, RFC, paper, repo. Secondary commentary is fine for context but never the only source.

## Section template

```markdown
# {Landscape Subject}

## Scope and Taxonomy

{How the landscape is divided. Why this taxonomy and not another. What is in scope; what is adjacent and explicitly out of scope.}

## {Category 1}

### {Item 1.1}

- **What it is:** {one-sentence definition}
- **Notable for:** {distinguishing feature(s)}
- **Trade-offs:** {strengths and weaknesses, balanced}
- **Maturity / status:** {age, adoption signals if known}
- **Primary source:** `[N]`

### {Item 1.2}

{... same shape, same depth ...}

## {Category 2}

{...}

## Cross-Cutting Themes

{Patterns visible across items: shared design choices, common failure modes, alignment trends, gaps the whole space shares.}

## Outliers and Notable Absences

{Items that don't fit the taxonomy but matter. Gaps in the space — categories one might expect to be filled but aren't, and what that suggests.}

## Open Questions

{What further research would resolve. What the scan deliberately could not answer.}

## References
```

## Length norm

2500–6000 words. Longest format — comparable depth on many items adds up. If the space has 20+ items, expect to push the upper end.

## Anti-patterns

- **Uneven depth.** If one item gets 500 words and another gets 50, readers correctly conclude the deep-dived one is favored. Match depth across items in the same category, even if it means trimming the favorite.
- **Empty categories in the taxonomy.** Either drop them or explicitly mark them as gaps with the comment "no representative items found in this category as of {date}".
- **Recency bias.** Don't over-weight items from the last 6 months at the expense of well-established options. Time-balance the coverage.
- **Vendor-quote summaries.** Don't lean on marketing language. Describe each item from neutral third-party evidence where possible; when only first-party evidence exists, label it.
- **Sneaking in a recommendation.** If readers leave with a clear "X is best" impression, this should be `position-paper` style instead. Landscape scans help the reader form their own view.
- **Skipping the taxonomy section.** A landscape scan without an explicit taxonomy is a list, not a map.
