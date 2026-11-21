# Stage 5.5: Cross-check & Conflict Playbook

After Stage 5 produces `<company>-<role-slug>-by-problem.draft.md`, this stage adds conflict annotations and produces the final `<company>-<role-slug>-by-problem.md`.

## Why this stage exists

Reading 30 posts about the same Coinbase OA, you often find contradictions:
- Post A: "input is an array of size 10^5" · Post B: "input up to 10^7"
- Post A: "must use min-heap" · Post B: "interviewer didn't let me use heap, had to use bucket sort"
- Post A (2024-01): "round was 60 min" · Post B (2025-03): "round is now 75 min"
- Post A: "follow-up was to optimize memory" · Post B: "no follow-up, just basic solution"

Silently merging these into one "canonical" description **destroys signal**. A candidate prepping for VO needs to see the spread, not a flattened average — they may face either version of the question.

## Scope: which clusters to check

Only clusters with **2+ source posts**. Single-post clusters have nothing to cross-check.

## Four conflict types to surface

### 1. 题面分歧 (problem statement divergence)

Different input/output specs, different problem framings that suggest the interviewer may ask either form.

Flag format (inserted at top of cluster body):

```
⚠️ **题面分歧**:
- [tid_a] 描述: <one-line summary of post A's framing>
- [tid_b] 描述: <one-line summary of post B's framing>
**Likely interpretation**: <your best guess + 1-sentence why>
```

### 2. 解法冲突 (solution conflict)

One post says "must use X", another says "X was forbidden". One claims O(N log N), another O(N).

```
⚠️ **解法冲突**:
- [tid_a]: <claim about solution / constraint>
- [tid_b]: <contradicting claim>
**Prep advice**: <prepare both approaches | clarify with interviewer at start | the strict variant is safer>
```

### 3. 约束差异 (constraint divergence)

Array size limits, time limits, language restrictions vary across posts.

Action: take the **strictest reasonable union** as the canonical constraint, but note the spread.

```
⚠️ **约束差异**:
- 数组上限: 10^5 [tid_a] vs 10^7 [tid_b] — prepare for the stricter bound (10^7)
- 时间限制: 45 min [tid_a] vs 60 min [tid_b] — assume 45 min
```

### 4. 时效性矛盾 (recency conflict)

Older post and newer post disagree on round structure / round count / interviewer style.

Action: prefer the **newer** post for current-state info, footnote the older one in case the round reverted.

```
⚠️ **时效性**:
- 当前流程参考 [tid_b, 2025-03]
- 早期 [tid_a, 2024-01] 流程不同 (see footnote below)
- Footnote: <one-sentence describing the older variant in case the round reverts>
```

## Where to insert flags

In the cluster body, insert the `⚠️ Cross-check notes` subsection **at the top**, immediately after the cluster header line and before the `### 题面（最完整版本）` section:

```
## <Problem name>
**出现次数**: N  |  **类型**: ... |  **出处帖子**: ...

⚠️ **Cross-check notes**
- [conflict entries here]

### 题面（最完整版本）
...
```

## Rules

- **Clusters with no conflict get no `⚠️` section.** Do NOT write "no conflicts found" — just omit.
- **Don't invent conflicts** — only flag what is actually present in the sources.
- **Don't merge silently** — if two posts give different solutions and you collapse to one in the body, you've destroyed prep signal. Either keep both with attribution, or flag the conflict.
- **Don't over-flag** — minor wording differences are not conflicts. A conflict has **different actionable prep implications**: if the candidate would prepare differently after reading the flag, it's worth flagging.

## Process

1. Read `<company>-<role-slug>-by-problem.draft.md`.
2. For each cluster with 2+ posts, scan all source `[tid]` entries for the four conflict types.
3. Build conflict annotations.
4. Write the final `<company>-<role-slug>-by-problem.md` with annotations inserted.
5. Delete the `.draft.md` intermediate.
6. Report: total clusters checked, clusters with conflicts, conflict count by type.

## Anti-patterns

- **Padding clusters with empty cross-check sections** — the absence of `⚠️` is itself signal ("this problem has consensus across sources"). Don't dilute it.
- **Inventing prep advice** — if you can't articulate why the conflict matters for prep, don't flag it.
- **Cross-checking single-post clusters** — there's nothing to check against. Skip.
- **Treating tid order as authority** — newer tid is more recent but not necessarily more accurate. Use post-stated dates from `**发帖日期**:` fields when comparing recency.
