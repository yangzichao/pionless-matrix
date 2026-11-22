# Before implementation: the blindspot pass

No code is written yet. This is the cheapest moment to find a gap.

## Procedure

1. **Take the territory reader's output** and add what you read yourself. Every claim it marked false is a finding. Every claim it marked unverifiable becomes either a command you run now or a question for the user.

2. **Sort the candidates into four buckets:**
   - **Ambiguity.** A term or requirement with two plausible readings in this code ("user" meaning the account or the team member).
   - **Missing context.** Code the plan never looked at but will touch: other callers, jobs, caches, flags, generated code.
   - **Weak assumptions.** Claims the plan rests on that nobody checked. Check each now. A confirmed one drops out; a false one is a finding.
   - **Undefined behaviour.** What happens on empty input, duplicates, concurrent writes, partial failure, existing data, rollback, when the plan says nothing.

3. **If the plan copies or ports reference code,** use the semantics map. Each row where the semantics differ is a finding.

4. **Ask about the unknown knowns.** These are what only the user knows: conventions, constraints, taste, prior attempts that failed, who uses the feature. Ask at most five questions in one round. Order them by blast radius: first the one whose answer would change the architecture. Give each a recommended answer and say what it changes. Never ask what the code could tell you.

5. **If an open question is about how a screen looks or behaves,** offer a throwaway mock or two to four variants instead of asking in words, if you can run or render one.

6. **Rewrite the plan as a tweakable plan.** Put the decisions most likely to change first, each with the option chosen and the alternative. Fold in the findings already resolved. Put the mechanical steps last, collapsed to one line each.

## Output shape

1. **Riskiest unknown** and its cheapest resolution, one line each.
2. **Questions for you,** at most five, numbered, each with a recommended answer and what it changes.
3. **Findings,** grouped by bucket. Each: what, evidence (file and line), why it matters here, cheapest resolution (a question, a file to read, a command, a small spike).
4. **Revised plan,** decisions first, mechanical steps last.
5. **Not read:** what you could not reach.

## Example

**Map.** "Add soft delete to comments: add a `deleted_at` column and filter it out in `CommentRepository.list`."

**Riskiest unknown.** `posts.comment_count` is a stored count kept up by a trigger (`migrations/0042_comment_count_trigger.sql:3`). Setting `deleted_at` does not fire the delete branch, so counts would drift. Cheapest resolution: decide whether a soft-deleted comment counts.

**Questions for you.**

1. When a comment with replies is deleted, should the replies (a) stay visible under a "[deleted]" placeholder, or (b) disappear too? Recommended: (a). Changes: whether `list` filters rows or masks them.
2. Is moderator removal (a) the same as a user deleting, or (b) separate and shown differently? Recommended: (b). Changes: one column or two.

**Findings.**

- Missing context: `jobs/search_index.py:58` reads `comments` directly, not through the repository, so deleted comments would stay searchable.
- Weak assumption: the plan says `list` is the only read path. False: `api/export.py:112` builds its own query.
- Undefined behaviour: re-deleting an already deleted comment. The plan does not say whether `deleted_at` is overwritten.

**Revised plan.** Decisions first: count rule (chosen: deleted comments do not count; alternative: they do), reply display (placeholder), moderator removal (separate column). Then: migration, trigger update, repository filter, export query, search job, tests.

## When nothing is found

The plan names every read path, the territory reader verified each claim, and the user's earlier messages already settled the one design choice. Say the plan holds, list what was checked, and stop.
