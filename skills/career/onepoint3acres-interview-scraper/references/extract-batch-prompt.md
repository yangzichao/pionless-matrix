# Stage 4: Extract Batch Subagent Prompt

Prompt template for the per-batch extract-and-append subagent (Stage 4). The host fills in `<...>` placeholders before dispatch.

## Prompt template

```text
Process N scraped 面经 posts. Apply the profile-driven filter, extract core content, append to the master file, delete source files.

═══ Profile context (read first) ═══

Read these files before processing any post:
- <working-dir>/scrape-profile.md       — the user's preferences (titles, levels, rounds, time_window, tid_threshold)
- <skill-root>/references/filter-rules.md — KEEP/SKIP rules parameterized by the profile

Apply rules in order: hard SKIP → time SKIP → per-title KEEP → per-level KEEP → per-round KEEP → universal SKIP. When in doubt, lean SKIP.

DO NOT inline-paste the rule text into your reasoning. Reference filter-rules.md directly each batch.

═══ Inputs ═══

- File list:     /tmp/batch_<batch_id>          (one filename per line)
- Source dir:    <company>-posts/
- Append target: <company>-<role-slug>-interview-core.md
  (or: <company>-<role-slug>-interview-core.<batch_id>.md if running parallel — see Anti-patterns)

═══ Output format (per KEPT post) ═══

Append each kept post in exactly this format:

    ## [<tid>] <title>
    **原帖**: <url>
    **类型**: <comma-separated round types matched, e.g. "VO Coding, System Design">
    **Title信号**: <SWE | MLE | ResearchScientist | ... | Unspecified>
    **Level信号**: <NewGrad | Mid | Senior | Staff | Unspecified>
    **发帖日期**: <YYYY-MM extracted from post body, or "Unknown">

    <Extracted core content:
     - Problem statement(s) verbatim where possible (preserve code blocks)
     - Constraints, follow-ups, key insights
     - Interviewer-specific signals ("不让用 heap", "要求 O(N)", etc.) — these matter for Stage 5.5
     - Trim: greetings, signatures, 求米, off-topic chat, unrelated round summaries>
    ---

═══ Process ═══

1. Read the batch file list.
2. For each file: Read → apply filter rules → KEEP/SKIP decision.
3. Build all KEPT sections in memory.
4. Append ALL KEPT sections at once via a single heredoc — never append one section at a time (slow + race-prone).
5. `rm` all source files in this batch (user has authorized — cleanup workflow).

═══ Reply format (terse — DO NOT echo post contents) ═══

    Batch <batch_id>:
      Total: <N>
      Kept: <K> — tids: <comma-separated>
      Skipped: <S>
        Pre-time-window: <c> — tids: ...
        Wrong-title:     <c> — tids: ...
        Wrong-level:     <c> — tids: ...
        Wrong-round:     <c> — tids: ...
        No-substance:    <c> — tids: ...
        Other:           <c> — tids: ... — 1-word reason each (e.g. "ghost", "duplicate", "permission")

═══ Anti-patterns ═══

1. **Inlining filter rules** — do NOT paste the rule list into your context. Read filter-rules.md fresh each batch; rules may have been updated.

2. **Wrong append target** — confirm the target path includes the parent dir, not nested inside <company>-posts/. A past run silently lost ~50 entries to this bug. After writing, verify the file exists at the expected path AND the entry count matches your Kept tally.

3. **Parallel batches against the same master file** — append races corrupt data. If running batches concurrently, each batch must write its own <company>-<role-slug>-interview-core.<batch_id>.md and the host concatenates at end of Stage 4. Otherwise run batches sequentially.

4. **Echoing post contents in the reply** — the master file is the artifact. The reply is a Total/Kept/Skipped summary only. Echoing contents blows up the host's context window.

5. **Soft-keeping uncertain posts** — Stage 5.5 cross-check cannot rescue signal from noise that made it through here. When uncertain, SKIP and let it go.
```
