# F. Writing for the wrong reader

A model writes for a reader who shares no context, because that fits the widest range of cases. A reply in a thread has a reader who already knows the background. Act on this pattern when you can see the surrounding conversation or when the text is clearly a reply; otherwise ask or leave it alone.

## 26. Re-explaining what the reader knows

**Watch for:** a short reply that restates the problem, walks through the diagnosis, and lays out the evidence before it reaches the decision; a query, command, or set of numbers included to prove a plan will work; background the other person wrote or already agreed to; the answer itself sitting in the last line.

**Problem:** In a reply the reader already has the context, so rebuilding it adds nothing and buries the point. Lead with the decision and keep only the reasoning that would change whether the reader agrees: usually one fact they lack and any link they need to act. Leave the diagnosis and the proof for the ticket or document that follows; a reviewer raising a topic is not asking for the full write-up. Each sentence can read fine on its own, so this survives sentence-level cleanup.

**Before:**
> Yeah, you're right, this works around the issue rather than fixing it. The real fix is in `MergeService`: when we move a child under a new parent, it should update `pipeline_id` along with `parent_id`. We can backfill the bad rows from the audit log with `Change.where(field: "pipeline_id", source: "merge")`. I checked QA: 123 past merges, only 6 rows wrong now, so the cleanup is small.
>
> Since `MergeService` is shared and not specific to this account, I'd rather open a separate ticket than widen this PR. The fallback here is fine to keep until then.

**After:**
> Agreed, this is a workaround. I'd rather keep this PR account-specific and open a separate ticket for the `MergeService` fix and the backfill.
>
> `MergeService` is shared code, so fixing it here means checking the merge flow for every account and backfilling the rows that are already wrong.
