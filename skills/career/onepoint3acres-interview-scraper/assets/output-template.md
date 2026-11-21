# Output Template: `<company>-<role-slug>-by-problem.md`

Structural template for the final 题库 file. Stage 5 produces the `.draft.md`; Stage 5.5 inserts `⚠️ Cross-check notes` blocks and writes the final.

## File header (top of file)

```markdown
# <Company> <Role-slug> 面经题库

**Profile**: titles=<titles>, levels=<levels>, rounds=<rounds>, time_window=<time_window>
**Source posts**: <total> scraped → <kept> kept → <clusters> clusters + <misc> 杂项
**Generated**: <YYYY-MM-DD>
**Source profile file**: `scrape-profile.md`

## 高频题（按出现次数排序）

1. [<Problem name>](#problem-name) — N 次
2. [<Problem name>](#problem-name) — N 次
3. ...

## 单次出现 / 杂项
- VO Coding: M 题
- System Design: M 题
- OA: M 题
- ...
```

## Per-cluster section template

```markdown
## <Problem name (short, descriptive)>
**出现次数**: N  |  **类型**: <round types>  |  **时间跨度**: <oldest YYYY-MM> – <latest YYYY-MM>
**出处帖子**: [tid1], [tid2], [tid3], ...

<!-- Stage 5.5 inserts the ⚠️ block here ONLY if conflicts found.
     Clusters with no conflict have NO ⚠️ section at all. -->

⚠️ **Cross-check notes**
- 题面分歧 / 解法冲突 / 约束差异 / 时效性 — see references/cross-check-playbook.md for format.

### 题面（最完整版本）
<Fullest problem description from any source. Preserve original wording where possible.
 Note which tid this came from at the end: "(from [tid_a])">

### 变体（detailed mode — always present if cluster has 2+ posts）
- **[tid_a]**: <how this source framed it differently — input format, wrapping, follow-up structure>
- **[tid_b]**: <...>

### Follow-ups / 后续问题
- <follow-up 1> [tid_a, tid_c]
- <follow-up 2> [tid_b]

### 解法思路 / 提示
- <Approach 1 — who suggested, what complexity, any interviewer-stated constraints>
- <Approach 2>
- **Avoid**: <things explicit interviewers flagged as not-allowed, with source tid>
- **数据结构 tips**: <DS suggestions collected across sources>

### 原帖摘录（关键差异 — only entries that add prep-relevant color）
- **[tid_a]**: <one-line note about unique angle>
- **[tid_b]**: <one-line note>

---
```

## 杂项题 section (after all clusters)

```markdown
## 单次出现 / 杂项题

### VO Coding
- **[tid]** <problem name> — <1-2 line summary>
- **[tid]** <problem name> — <1-2 line summary>

### System Design
- **[tid]** <problem name> — <1-2 line summary>

### OA
- **[tid]** <problem name> — <1-2 line summary>

### Code Pair / Take-home
- **[tid]** <problem name> — <1-2 line summary>
```

## Rules

- **Cluster headers use `## `** (level-2) so TOC anchors are stable. 单次出现 group headers use `### ` (level-3).
- **Tid refs**: always `[tid]` form (square brackets). Don't link out to 一亩三分地 URLs in cluster bodies — the original URL was captured in Stage 4's master file. The deliverable is for offline VO prep.
- **中文 preserved**: section headers can be 中文 or English; the cluster *content* preserves the source's original language.
- **No ⚠️ pad**: a cluster with no conflict has no `⚠️` section. The absence is signal — it means consensus across sources.
- **No empty 变体**: if a cluster has only 1 source post, omit the 变体 section entirely.
- **No links to scraped posts**: post URLs are in `<company>-<role-slug>-interview-core.md` (intermediate). The final by-problem doc is self-contained for the candidate.
