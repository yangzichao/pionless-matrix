# Stage 5: Cluster Fusion Subagent Prompt

Prompt template for the topic-clustering subagent (Stage 5). Output template lives at `assets/output-template.md`. Conflict surfacing is Stage 5.5's job, not this prompt's.

## Prompt template

```text
Read <company>-<role-slug>-interview-core.md (manageable size, ~30-60KB). Cluster all entries by underlying interview problem. Write a NEW draft file <company>-<role-slug>-by-problem.draft.md.

═══ Inputs ═══

- Master file:    <company>-<role-slug>-interview-core.md
- Profile:        scrape-profile.md           (for the header metadata)
- Output template: <skill-root>/assets/output-template.md

═══ Process ═══

1. Read every entry in the master file.
2. Group entries by problem identity, NOT surface wording:
   - Same algorithmic problem with different wrappers (e.g. "currency exchange" and "FX conversion graph" are likely the same)
   - Same SD prompt across posts (e.g. "design Coinbase order matching" appears as "design exchange order book", "design crypto orderbook")
   - Same OA across posts
3. Order clusters by 出现次数 desc (most-frequent first).
4. Build each cluster following the template at assets/output-template.md.
5. After all clusters, single section ## 单次出现 / 杂项题 grouped by 类型 (VO Coding / SD / OA / CodePair / TakeHome).
6. Prepend the file header (TOC + profile metadata) per the template.

═══ Detailed mode (this skill always uses detailed mode) ═══

- KEEP multiple variants of a problem statement if they differ substantively — do NOT collapse to one canonical version.
- KEEP source-specific notes (which interviewer asked what, which hints were given).
- KEEP candidate-reported difficulty / time spent / follow-up patterns.
- Per cluster: include the *fullest* problem statement from any source under "题面（最完整版本）", then a "变体" section listing how other sources framed it differently.

═══ Rules ═══

- Every claim traceable to a listed tid (no hallucinated content — if you can't cite, don't include).
- Don't pad — short cluster sections are fine for one-post clusters.
- Preserve 中文 in the original wording.
- Aim for a doc a candidate would actually read for VO prep — depth > polish.
- Output filename ends with `.draft.md` — Stage 5.5 reads this draft and produces the non-draft final.

═══ What this prompt does NOT do ═══

Cross-check / conflict surfacing (⚠️ 题面分歧 / ⚠️ 解法冲突 / etc.) is Stage 5.5's job. In THIS stage:
- Just merge with attribution. Note conflicting claims with a `[tid]` reference but do NOT flag with ⚠️.
- Stage 5.5 will read your draft, identify ⚠️-worthy conflicts, and write the annotated final.

═══ Reply ═══

Report:
- File path written
- Cluster count
- Top 5 clusters by 出现次数
- Clustered-vs-杂项 split (e.g. "120 entries → 38 clusters + 23 杂项")
- Any entries you could not cluster confidently (with tid + reason)
```
