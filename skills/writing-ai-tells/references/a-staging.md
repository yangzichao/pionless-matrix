# A. Staging instead of stating

These are the strongest and most frequent tells in current model prose. Act on one sighting.

## 1. Not X but Y

**Watch for:** not X but Y; not just, not only, or not merely X, but Y; it's not X, it's Y; the reversed form X rather than Y; the same contrast split across sentences ("This does not mean X. It means Y."); a clipped negative tail ("..., no guessing"). The formula appears in every language; treat the equivalent construction the same way.

**Problem:** The negative half names something no one claimed, so the positive half sounds larger. It adds weight without adding a claim. State the point directly. Keep a contrast only when the negative half corrects a belief the reader actually holds, or when both halves carry information.

**Before:**
> It's not just about the beat riding under the vocals; it's part of the aggression and atmosphere. It's not merely a song, it's a statement.

**After:**
> The heavy beat makes the song sound more aggressive.

**Before (split across sentences):**
> This does not mean every choice is equal. It means there is no external system that confirms which choice is right.

**After:**
> The choices differ, but no outside system will tell you which one is right.

**Before (clipped tail):**
> The options come from the selected item, no guessing.

**After:**
> The options come from the selected item, so the user does not have to guess.

## 2. One-line closers and dramatic fragments

**Watch for:** a one-sentence paragraph that restates the paragraph before it; "That is the real win."; "That distinction matters."; "Read that again."; "Let that sink in."; the same closer after several sections; a sentence after an example, scene, or number that names what it showed ("This shows the importance of...", "The message was clear:", "It was a lesson in patience."); a row of fragments ("No aesthetic prior. No nostalgia."); one word in ALL CAPS or with periods between words (every. single. day.); a closing "Overall" or "Ultimately" sentence that restates a verdict the paragraph already gave.

**Problem:** The line asks the reader to pause on a claim instead of adding to it. One short sentence can carry emphasis when it carries a new fact. Cut a closer that repeats, including one that explains an example the reader just saw. Keep it when it adds a fact or consequence the example does not show. Merge a row of fragments into a sentence with a specific claim. A short sentence that moves a story forward ("This slowed us down.", "This poses a problem.") is ordinary narration, not a closer.

**Before:**
> Then AlphaEvolve arrived. It had no preference for symmetry. No aesthetic prior. No nostalgia for human taste. The old rules were gone.

**After:**
> AlphaEvolve had no preference for symmetry or for designs that look human-made, so the old rules stopped applying.

**Before (repeated closer):**
> Caching cuts repeat work.
>
> That is the real win.
>
> Retries hide brief outages.
>
> That is the real win.

**After:**
> Caching cuts repeat work.
>
> Retries hide brief outages.

## 3. Sayings that sound deep

**Watch for:** the real question is, at its core, in reality, what really matters, fundamentally, the deeper issue, the heart of the matter, X is the Y of Z, X becomes a trap, X is not a tool but a mirror, the language of, the currency of, the architecture of

**Problem:** An ordinary point is dressed as a hidden truth or an aphorism, and the dressing adds no detail. Replace the saying with the specific claim.

**Before:**
> The real question is whether teams can adapt. At its core, what really matters is organizational readiness.

**After:**
> The question is whether teams can adapt. That mostly depends on whether the organization is ready to change its habits.

**Before (aphorism):**
> Symmetry is the language of trust. Efficiency becomes a trap when teams forget the human layer.

**After:**
> Symmetric layouts often feel more predictable to users. Teams can over-optimize workflows and miss how people use them.

## 4. Staged run-up before the point

**Watch for:** Let's dive in, let's explore, let's break this down, here's what you need to know, without further ado, heads up, quick note, Honestly?, Look, Here's the thing, The thing is, Let's be honest, Real talk, and casual versions such as "one thing that bit me, so pay attention"; "the part" in place of a named thing: the hard part is, the new part is that, the part that matters is, the part worth X

**Problem:** The writer announces the point or stages a moment of candor instead of making the point. Remove the run-up, not just its tone. A tutorial step such as "Let's look at the source" or "Let's start with an example" that goes straight into the thing is not a run-up; leave it. "Honestly" or "look" inside a casual sentence is ordinary; the tell is the standalone opener before a routine claim. "The part" does the same work: "the hard part is X" stages X, and "the part worth sharing" points at something the text never names. Name the thing, or state X directly. Leave a literal part alone, such as one part of a multipart upload.

**Before:**
> Let's dive into how caching works in Next.js. Here's what you need to know.

**After:**
> Next.js caches data at multiple layers, including request memoization, the data cache, and the router cache.

**Before (staged candor):**
> Is it worth the price? Honestly? It depends on how often you'll use it.

**After:**
> Whether it's worth the price depends on how often you'll use it.

**Before ("the part"):**
> Sharing one build folder nearly works. This post is about the part that doesn't. The slow part is the dependencies.

**After:**
> Sharing one build folder saves space, but one checkout can end up running another checkout's code. Most of the build time goes to the dependencies.

## 5. Arguing with no one

**Watch for:** This isn't (mainly) about, I'm not saying, To be clear, Don't get me wrong, This is not to say, Some might say... but, A tempting approach would be, One might be tempted to, An obvious approach would be, You might think... but, It would be easy to just

**Problem:** The text answers an objection or rejects an option that appears nowhere else, usually a leftover from an earlier draft. Remove the defense; if it holds a real claim, state the claim. Keep an objection the text attributes or answers in full, and keep an option a reader would actually weigh. Several unrelated rejections in a row are a stronger sign than one.

**Before:**
> This isn't mainly about prompt length, and I'm not arguing that documentation doesn't matter. You could categorize the problem another way, but the issue is whether the agent can use the instruction when it acts.

**After:**
> The issue is whether the agent can use the instruction when it acts.

**Before (fake alternative):**
> Session tokens are rotated every 24 hours. A tempting approach would be to rotate them by restarting the auth service on a cron job, but that would drop every active session. Rotation happens in place, and clients refresh transparently.

**After:**
> Session tokens rotate in place every 24 hours, and clients refresh transparently.
