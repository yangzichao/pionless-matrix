---
name: onepoint3acres-interview-scraper
description: "Scrape, filter, cross-check, and organize 一亩三分地 (1point3acres.com) interview experiences (面经) for a target company and job profile (SWE, MLE, Research Scientist, DS, and so on) into a topic-clustered, conflict-annotated markdown 题库 driven by a user-confirmed scrape profile. Use when the user wants to collect a company's 面经, build a 面试题库, or organize 1point3acres interview posts."
compatibility: Needs a browser automation tool that can run JavaScript in the page (for example Playwright MCP) and file write access; subagents optional
metadata:
  version: "0.3.0"
---

# 一亩三分地 面经爬取 + 题库整理

End-to-end workflow for turning the noisy 一亩三分地 interview-experience forum into a clean, deduplicated, cross-checked, topic-clustered 面经 study doc for a target company and job profile.

## When to use

- "帮我爬一下 1point3acres 上 <公司> 的面经"
- "整理一下地里的 <公司> 面试题"
- "我想准备 <公司> 的 VO，去地里找题"
- "把地里 <公司> 的 MLE / RS / DS 面经整理一下"
- 任何提到 一母三分地 / 一亩三分地 / 1point3acres / 地里 + 面经 / 面试题 / interview 的任务

## Pipeline overview

```
[0]   Pre-flight Q&A          →  scrape-profile.md  (drives every downstream filter)
[1]   Playwright 爬取          →  raw scraped posts (one big md)
[2]   拆分 + 备份              →  per-post files + backup
[3]   Profile-driven filter   →  pre-filtered post set matching profile
[4]   提取核心内容             →  per-post extracted entries (master file)
[5]   按题目聚类 + 多源融合     →  topic-clustered draft
[5.5] Cross-check & 冲突标注   →  conflict-annotated final 题库
[6]   清理工作区               →  delete intermediates, keep only final
```

Each stage produces a file the next stage consumes — never hold all 300+ raw posts in main context at once.

---

## Stage 0: Pre-flight scrape profile (REQUIRED)

Before any scraping, gather the user's preferences. These drive Stages 3, 4, 5, and output filenames. **Never assume defaults silently** — even if the user said "爬 Coinbase 面经", still confirm titles / levels / rounds / time window.

Full field definitions: `references/scrape-profile-schema.md`.

Ask the user the following (use your host's structured-question UI if it has one; otherwise ask in plain text):

1. **目标公司** (required, free text) — lowercase slug used in URLs and filenames. E.g. `coinbase`, `meta`, `google`, `databricks`.

2. **Job titles** (multi-select, default `[SWE]`):
   - `SWE` — Software Engineer / SDE / Backend / Frontend / Fullstack / Mobile
   - `MLE` — Machine Learning Engineer / Applied ML
   - `ResearchScientist` — paper-track research roles
   - `AppliedScientist` — applied research (Amazon-style)
   - `DataScientist` — DS / product analytics / experimentation
   - `DataEngineer` — pipeline / Spark / warehouse roles
   - `Other` — free text, agent asks user for keep-rules

3. **Level** (multi-select, default = all + `Unspecified` ON):
   - `NewGrad` — entry / L3 / E3
   - `Mid` — L4 / E4 / SDE2
   - `Senior` — L5 / E5 / SDE3
   - `Staff` — L6+ / E6+
   - `Unspecified` — recommend keeping ON; most posts don't state level

4. **Round types** (multi-select):
   - `VOCoding` (default ON)
   - `SystemDesign` (default ON)
   - `OA` — ASK the user. Some companies' OAs are real algorithm problems (Coinbase); others are trivial LC mediums (not worth keeping).
   - `Behavioral` (default OFF) — ask if the user wants HM/values prep included.
   - `CodePair` (default ON)
   - `TakeHome` — ASK.

5. **时间窗口** (single-select, default `2y`):
   - `6mo` — past 6 months (most recent rounds only)
   - `1y` — past 1 year
   - `2y` — past 2 years (default; good balance for VO prep)
   - `all` — all-time (not recommended — noise grows fast)

Write the user's choices to `scrape-profile.md` in the working directory using the template at `assets/scrape-profile-template.md`. **Every downstream stage reads this file.** If the user wants to change preferences mid-run, update the file and re-run from the affected stage.

This skill always operates in **detailed mode** — clusters keep multiple variants per problem and source-specific notes. There is no terse-题库 mode.

---

## Stage 1: Scrape with a browser tool

Use a browser automation tool that drives a real browser and can run JavaScript in the page (for example Playwright MCP's `browser_evaluate`). If you have none, stop and tell the user this stage needs one.

**Forum URL pattern** (sortid=311 = 面经 board, fid=145 = 工程类):
```
https://www.1point3acres.com/bbs/forum.php?mod=forumdisplay&fid=145&sortid=311&searchoption[3047][value]=<company>&filter=sortid&sortid=311&orderby=dateline&page=<N>
```

Replace `<company>` with the slug from `scrape-profile.md`. Page through `1..N` until results dry up.

**Post URL pattern**: `https://www.1point3acres.com/bbs/thread-<tid>-1-1.html`

**Listing extraction** (run in the page with your browser tool's evaluate action):
```javascript
() => {
  const threads = document.querySelectorAll('tbody[id^="normalthread_"]');
  const results = [];
  threads.forEach(t => {
    const a = t.querySelector('a.s.xst');
    if (a) {
      const tid = t.id.replace('normalthread_', '');
      results.push({ tid, title: a.innerText.trim() });
    }
  });
  return JSON.stringify(results);
}
```

**Post content extraction**:
```javascript
() => {
  const post = document.querySelector('.t_f');
  return post ? post.innerText.trim() : 'No content found';
}
```

**Handling**:
- Permission-restricted posts show `document.title === '提示信息'` → skip.
- Browse "like a human" — paginate via clicks/URL changes, not requests-style scripts.
- Save raw scraped data to `<company>-interview-experiences.md` with each post as `## <a id="<tid>"></a><title>` followed by URL + content + `---`.

⚠️ **Context risk**: Each post can be 500–14k chars. Do NOT keep all posts in main context across pages. Append each post to disk immediately and discard. If the host compacts context, raw content may still be recoverable from its session transcript (see failure mode 3).

---

## Stage 2: Backup + split

```bash
cp <company>-interview-experiences.md <company>-interview-experiences.backup.md
mkdir -p <company>-posts/
```

Python: split master file on `^## <a id=` boundary, write each section to `<company>-posts/<tid>_<sanitized-title>.md`. Build a JSON manifest of `[{tid, title, file, size}]`.

This gives the cleanup-after-processing model: process a post → delete the file.

---

## Stage 3: Profile-driven filter

First compute the **tid threshold** from `scrape-profile.md`'s `time_window`. See `references/filter-rules.md#time-window-to-tid-threshold` for the algorithm. Write the computed threshold back into `scrape-profile.md` under `tid_threshold:`.

Sort files **numerically** by tid: `sort -t_ -k1 -n` (NOT alphabetic, which mis-orders 6-vs-7-digit tids).

Apply rules in order, per `references/filter-rules.md`:
1. Hard SKIP (JSON-blob corruption, permission-restricted, ghost/求大米, etc.)
2. Time SKIP (drop tids < threshold)
3. Per-title KEEP (drives what content types match)
4. Per-level KEEP (most posts don't state level — `Unspecified` handles that)
5. Per-round KEEP (drop posts whose round types don't match `rounds`)
6. Universal SKIP (no-substance, duplicate tids, repost-of-others)

⚠️ Be strict — 10% noise across 300 posts produces 30 garbage downstream entries. When uncertain, lean SKIP.

---

## Stage 4: Extract core, append to master, delete source

Batch the work, about 50 files per batch. If you can start subagents, give each batch to a fresh-context subagent (not a fork of this conversation) whose prompt is `references/extract-batch-prompt.md` with the placeholders filled in, including the absolute path of this skill folder. If you cannot, run each batch yourself with that same prompt as your instructions, and write results to disk before starting the next batch.

The prompt instructs each subagent to read `scrape-profile.md` and `references/filter-rules.md` directly — **do NOT inline-duplicate the rules** in the prompt. This keeps a single source of truth.

Output filename: `<company>-<role-slug>-interview-core.md` where `role-slug` is derived from `titles` (see `references/scrape-profile-schema.md#role_slug`).

**Critical**:
- Subagents work in parallel ONLY if each writes to its own `<company>-<role-slug>-interview-core.<batch_id>.md` and you concat at the end. Otherwise sequential to avoid append races. A past run lost ~50 entries to a wrong-path append — verify final entry count matches kept tally.
- Each subagent returns a 200-token Total/Kept/Skipped summary — no contents echoed back.
- After all batches: verify `<company>-posts/` is empty and master file has expected entry count.

---

## Stage 5: Cluster by problem + cross-source fusion

Prompt: `references/cluster-fusion-prompt.md`, run in a fresh-context subagent if you can start one, otherwise by you as a separate pass. Output template: `assets/output-template.md`.

The subagent reads `<company>-<role-slug>-interview-core.md` (manageable size, ~30-60KB) and writes a **draft** file `<company>-<role-slug>-by-problem.draft.md`. Stage 5.5 will annotate this draft to produce the final.

Key rules:
- Cluster by underlying problem identity, not by surface wording.
- Order clusters by 出现次数 desc.
- Detailed mode (default): keep multiple variants per problem, keep source-specific notes.
- Every claim traceable to a listed tid (no hallucinated content).
- Preserve 中文.

---

## Stage 5.5: Cross-check & 冲突标注 (REQUIRED)

This is the value-add step the user specifically asked for. Silently merging 30 posts about the same problem **destroys signal** — candidates need to see the spread, not a flattened average.

Read the draft from Stage 5. For every cluster with **2+ source posts**, apply the playbook at `references/cross-check-playbook.md` to surface:
- **题面分歧** — different problem statements / input formats
- **解法冲突** — "must use heap" vs "heap forbidden", different complexities claimed
- **约束差异** — array sizes, time limits, language restrictions
- **时效性矛盾** — newer post says round structure changed

Insert a `⚠️ Cross-check notes` subsection at the **top** of each cluster body where conflicts exist. Clusters with no conflict get no `⚠️` section — don't pad.

Write the annotated result to the final file `<company>-<role-slug>-by-problem.md` and delete the `.draft.md` intermediate.

---

## Stage 6: Cleanup

Confirm with user before deleting backups. Default offer:
- browser tool snapshot dir such as `.playwright-mcp/` (often 20MB+, safe)
- `/tmp/batch_*` working files (safe)
- `<company>-<role-slug>-by-problem.draft.md` (safe — superseded by annotated final)
- `<company>-interview-experiences.md` raw scrape (medium — keep backup)
- `<company>-interview-experiences.backup.md` (ask — irreversible)
- `<company>-<role-slug>-interview-core.md` per-post intermediate (ask — superseded by by-problem)
- ✅ KEEP `<company>-<role-slug>-by-problem.md` — final deliverable
- ✅ KEEP `scrape-profile.md` — record of what was scraped, for future re-runs / diff scrapes

---

## Context-management tips

- The whole pipeline is designed around "process-then-delete" — at no point should main context hold all raw posts. Files + subagents are the spillover storage.
- Whenever a stage finishes, delete its inputs (after backup) before starting the next stage.
- Subagent replies should be Total/Kept/Skipped summaries, never post contents.
- If a stage's subagent reports doing X but the final file has < X entries, suspect: wrong-path appends, append race, or premature truncation. Verify file existence + entry counts before moving on.

## Failure modes seen in past runs

1. **Sort order**: alphabetic sort of `1003787_*.md` puts it before `833124_*.md`. Use numeric sort (`sort -t_ -k1 -n`).
2. **Wrong append target**: subagent appended to a file with the same basename **inside** `<company>-posts/` instead of the parent dir. Always re-verify entry count at the end of Stage 4.
3. **Compacted context loses scraped content**: if the host keeps a session transcript, the tool results are in it. In Claude Code it is `~/.claude/projects/<project>/<session-id>.jsonl`; parse `user` → `tool_result` → `content[]` → `text` for `### Result` blocks.
4. **Over-keeping during filter**: a first pass kept 23/50 from a batch that was 100% pre-time-window. Apply the hard time filter (tid_threshold) BEFORE any semantic filter.
5. **Hard-coded SDE assumption (pre-v0.2)**: older versions of this skill assumed SDE-only; an MLE/RS scrape would silently drop relevant content. Always run Stage 0 first.
