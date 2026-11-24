# Engineering blog posts

An engineering blog post is read by engineers outside the team who choose to keep reading or leave within the first screen. They stay for something they can reuse: a design they can copy, a failure they can avoid, a number they can compare against. Use this file for "how we built X" posts, migration retrospectives, incident write-ups, how-it-works explainers, and research summaries written for engineers. These rules apply on top of `references/full-document.md`; where the two differ, this file wins.

These rules come from a study of about 2,000 company engineering posts from before 2023 and after, with close reads of the easiest and the most-upvoted ones. Every rule below was seen across several blogs.

## Raw material comes first

Most of what makes a post good is facts that only the person who did the work has: what ran before, the order things were tried in, the step that went wrong, the number before the fix, what is still broken. A post written without them falls back on adjectives ("significantly faster", "more reliable"), which is the most common failure in weak posts. So gather the raw material before the skeleton, and treat a missing fact as a gap to fill, never as a sentence to write around.

Two kinds of questioning happen here. The inventory below gets the facts. If the author does not yet know what the post is for, find the point with them first, as in `references/finding-the-point.md`; then ask the rest of the inventory for the facts that point needs.

- **Talk to the person who did the work.** If the user is editing or ghostwriting for someone else, say that the answers must come from the engineer who built or ran it, and give the user the questions to forward.
- **Find out the checkable facts yourself first.** Before asking, look at what you can reach: the code, commits, design docs, tickets, dashboards or logs the user shared, public docs and release notes. Ask only for what you could not find, and say what you found.
- **Ask one question at a time, in the order of the inventory below.** Offer your best guess from what you found, so the user can confirm or correct it. Ask for facts, not opinions: "What was p99 the week before the change?", not "How much did it improve?"
- **Stop asking when the minimum set is filled,** unless the user wants to keep going. Mark every other missing item as a gap in the draft: `[need: number of rows migrated]`.
- **Write the constructible parts yourself.** A toy example built from real names, a count of the parts, the order of sections, and an analogy are the writer's job. Label an invented example as an example.

### The inventory

Ask in this order. Each answer shapes the next question.

| # | Raw material | Ask | Feeds |
|---|---|---|---|
| 1 | The trigger | What happened the week you decided to do this? Who was blocked, on what, and how did you find out? | the opening; why before how |
| 2 | The reader | Name one real person who should read this. What do they already know, and what is the first thing they don't? | which terms to define; where to start |
| 3 | The before state | What ran in its place before, and what one number described it then? | the setup the reader already runs; the before number |
| 4 | The attempts, in order | What did you try or seriously consider first? For each, what fact or measurement made you drop it? | rejected options; the chain of fixes |
| 5 | One real instance | Pick one real request, file, or incident that touches every part. Walk me through it end to end. | the running example; tracing one unit |
| 6 | The surprise | Where did things stop going the way you expected? What did you believe before that turned out wrong? | the turn of the story; the reader's wrong model |
| 7 | The result | What is the number now, against what baseline, measured how and over what period? What value would have made you stop? | before and after; reading the number against a need |
| 8 | The cost | What got worse because of this, for whom, by how much, and why did you accept it? | the priced tradeoff |
| 9 | What is left | What is still broken, switched off, or deferred? What could still cause the same problem? | the unfinished list; an honest ending |
| 10 | The skeptic | What did reviewers or colleagues ask first? Which part of the strongest objection is right? | answering doubt where it arises |
| 11 | The names | What does the team call each part day to day, and which name should the reader see? | one name per thing; naming early, calling back later |
| 12 | The lesson's conditions | When would you not do it this way? | a lesson that says where it holds |

**Minimum to draft:** 1, 3, 5, 7, and at least one of 4, 6, or 9. Without the trigger (1) or a real instance (5), the post is not ready; say which fact is missing, as step 2 of the workflow says for a missing point.

### Facts to check before returning

- Every number has the same value, unit, and date wherever it appears.
- Every number names where it came from: a dashboard, a benchmark, a query, an estimate with its assumptions.
- Every claim is scoped to where the evidence comes from: which setups, loads, or customers it covers.
- Code and commands run as pasted, if you can run them. Otherwise list them for the user to check.
- Each part keeps one name throughout.

## Shape

The main claim is what the reader can take away and reuse: the design that worked and the condition it depends on, or the cause of the failure and how to avoid it. A product announcement is not a main claim.

- **How we built it, or a migration:** trigger, then the old way, then each attempt. Open each attempt by saying what the previous one fixed and what it left broken. Then the design, traced with the one real instance. Then results before and after, the cost and what is still broken, and the lesson with its conditions.
- **Incident write-up:** impact first, with one number. Then the timeline as a causal chain, one link per sentence. Then why it was not caught, and the fixes, split into done and planned.
- **How it works:** the guided shape. Start from the setup the reader already runs. Simplify first, say out loud what you left out, and add it back later.
- **Research summary for engineers:** the result first. Then the measurement problem, the method shown on one example, and each limit placed next to the claim it limits.

**Opening.** The first screen gives either the outcome with one number, or what breaks for whom. It may give the end state first and then go back with a marked turn ("It did not start this way."). It never explains the mechanism before the reader knows the problem. Do not open on the company's mission, the market, or how exciting the space is.

**Ending.** Finish the argument before the logistics. The last section carries results against the original goals in their original order, the cost, the unfinished list, or the lesson with its conditions. Thanks, hiring, and calls to action come after that, one line each.

## Moves

- **Start from what the reader already runs.** Introduce the new system as a concrete change to an old one the reader knows.
- **Follow each definition with one instance in the next sentence.** Whether the name or the case comes first matters less than the case coming right away.
- **Define by the nearest known neighbor plus the one difference.** "Like a load balancer, except it never terminates the connection."
- **Keep one real example and return to it** in every section, so the reader builds one picture instead of several.
- **Trace one unit through the mechanism:** one request, one packet, one job, from the first component to the last.
- **Park a complication out loud, then come back for it.** "Assume for now that every node has a public IP; we drop that assumption below."
- **Open each stage by naming what the last fix left broken.** The new section's first sentence has the previous fix as its subject and ends on the gap.
- **Let the flaw of each rejected option define the next one,** so the final design reads as derived, not announced.
- **Name an idea early and call it back by that name later,** so later sentences can start from something known.
- **Put the before number next to the after number,** and add one sentence that says what the change means against a need or threshold: "200 jobs a minute, against a need of 50, so throughput is not the bottleneck."
- **Do the arithmetic in the open:** "10 nodes need 90 tunnels, so the cost grows with the square of the fleet."
- **Lay out a causal chain one link per sentence,** each with because or so, so the reader can check each step.
- **Break the expected story with a But sentence that gives the reason.** That sentence is usually where the reader learns the most.
- **Report a misstep and how you noticed it.** The paragraphs readers remember are often the failure stories.
- **Price the tradeoff:** what got worse, for whom, by how much, and why that was acceptable.
- **Answer the reader's doubt where it arises,** using the question a colleague actually asked.

## Sentences and words

These refine `references/sentence-style.md` for blog posts.

- **Known before new, measured.** In the easiest posts, about seven in ten sentences have a subject the reader has already met: the previous sentence's result, a name planted earlier, or "this" plus a noun. A paragraph's first sentence picks up what the previous paragraph left.
- **Actions as verbs.** Write "we sharded the table", not "the sharding of the table was performed". The hardest posts used about 40% more nominalizations (-tion, -ment, -ity) than the easiest.
- **"We" for what the team did, "you" for what the reader can do.** Use "I" only for a personal account.
- **Plain words.** Prefer to get, try, easy, hard to, make sure, can't. When drafting, avoid the words that mark weaker recent posts: enhanced, advanced, evolve, proactive, driven, tailored, foundational, crucial, broader, a range of, seamless, leverage. When reviewing, one of them is not a finding; flag two in one paragraph, or about 3 per 1,000 words. Technical terms (advanced persistent threat) are never findings.
- **One analogy, if it carries weight.** An everyday analogy is allowed when it is set up once, reused, and its limit is stated where it would mislead; this overrides the no-metaphor rule. Jokes and pop-culture references never carry an explanation.
- **Voice is allowed.** A question that voices the reader's next question, a short aside, light humor, and first person are normal in good posts and override the no-rhetoric rule. Flag rhetoric only when it stands in for a claim or for evidence.
- **Question headings are fine** when they are the question this reader has at that point and the section's first sentence answers it.
- **Every number gets a reading.** A number without a baseline, a threshold, or a sentence saying what it means does not count as evidence.
- **Do not chase short sentences.** Good posts sit around 19 words per sentence, with real variation. What makes them easy is the order of information, not the length.

## Reviewing a published or finished post

Blind tests ran this skill on 122 posts: the best pre-2023 engineering posts, weak ones, and posts from 2023 on. Applied literally, the general rules flagged the best posts as often as the weak ones. The findings that separated them were about evidence and argument, not form, and only the ones that break the post: findings that merely weaken it showed up two to four times in nearly every post, good or weak. When reviewing, apply these overrides and this order.

- **First check whether the blog rules apply.** They fit how-we-built posts, migrations, incident write-ups, how-it-works explainers, and research summaries. A personal story, an opinion or forecast essay, a funding, hiring, grant, or award announcement, a policy notice, or a product launch is something else. For those, say so and review only the evidence and the claims: unsupported or wrong facts, claims broader than their evidence, and adjectives where a reader would expect a measurement. A launch with a real how-it-works section gets that section reviewed as an explainer. A post that mixes genres gets the blog rules for its engineering sections only. Saying the blog rules do not apply is a note, not a finding.
- **Lead with the findings that separate good posts from weak ones,** in this order: a fact that does not check out (a wrong code output, arithmetic that does not add up); a key number with no baseline or reading; an adjective where a measurement should be; the strongest objection or the obvious alternative left unanswered; a conclusion broader than its evidence; an opening that explains the mechanism or the mission before the problem, or an ending with no argument. A hook (an analogy, a scene, the end state) is fine when the problem follows within the first screen. A "Limitations" section counts as stating limits. A key number is one the main claim rests on; numbers in background, side notes, and examples are not findings. An adjective is a finding only when the claim is central and measurable; a benefit that resists measurement (safer, clearer) is not. Time, cost, speed, and size can be measured, so "saves a tremendous amount of time" is a finding when the post depends on it. A post in a series may end on what the next part covers. A how-to or demo with no result to measure is not missing evidence; review its steps and claims.
- **Do not report these as findings in a blog post.** They fired on almost every good post:
  - headings that are topic labels ("Background", "How it works"), and more than five sections;
  - a paragraph longer than four sentences, unless it carries two points;
  - list items longer than one sentence, and step lists over the outline word budget;
  - announced items without "first, second, third" (wrong or mismatched markers are still a finding);
  - questions, asides, humor, and first person (see Voice above);
  - a single word from the avoid list, or one word repeated;
  - code names as subjects when the post is about that code;
  - other wording and sentence rules from `references/sentence-style.md`, unless a reader would misread the sentence. List wording fixes separately as optional;
  - the Shape templates (such as impact first in an incident write-up), the anti-moves, the Check list below, and the critic's cut test and sentence-relation check, unless the problem also matches an item in the ordered list above. They are for drafting.
- **Grade each finding by what the reader would lose, then grade the post by its worst finding.**
  - `breaks`: a reader would believe something false, or could not check the main result. A wrong fact or wrong arithmetic in a result the post relies on, a claim the main result depends on with no evidence, or a headline number with no baseline at all.
  - `weakens`: a supporting claim or a secondary number lacks support, but the main claim still stands. A wrong fact outside the main result (a date, a side example) is `weakens`, or `minor` when it is typo-level. Three or more wrong facts together are `breaks`: the reader can no longer trust the rest.
  - `minor`: wording and polish.
- **Verdict:**
  - Publish as is: no finding breaks anything. List up to three `weakens` findings as "would strengthen", and wording fixes as optional. Most good posts land here.
  - Light revision: one or two `breaks` findings, each fixable by adding a sentence, a number, or a caveat.
  - Heavy revision: the main claim is unsupported, a key result is wrong in a way that changes the conclusion, the reader never learns what problem the post solves, or there are three or more `breaks` findings.

## Anti-moves

Before returning, check the draft for these, each with its usual fix:

1. **Adjectives instead of measurements.** Replace each with the number and its baseline, or mark a gap.
2. **A mechanism with no real instance.** Trace the one real example through it.
3. **A number that drifts between sections.** Make it the same everywhere, with one source.
4. **The design without the decision.** Add the second-best option and the fact that ruled it out.
5. **The hard part hidden.** Add what broke or surprised the team.
6. **A tour of prerequisites before the point.** Move background to where it is first needed, and mark the way back.
7. **A catalogue instead of an argument.** Say which item matters most and what goes wrong without it.
8. **Selling inside the explanation.** Move the product mention to the end, as one line.
9. **A summary repeated instead of advanced.** Each restatement must add a detail, or it goes.
10. **A figure carrying the claim alone.** Write the one sentence, with a number, that the reader should take from it.

## Check

1. Read the first screen. Does it give the outcome with a number, or what breaks for whom?
2. Before the first mechanism paragraph, does the reader know what breaks without it?
3. Is there one real instance, and does it come back in the later sections?
4. Does every key number have a baseline or threshold and a sentence saying what it means?
5. Is there at least one rejected option with the fact that ruled it out, and at least one cost or unfinished item?
6. Does the last section carry the argument, not just thanks, hiring, or a call to action?
7. Are all inventory gaps marked in the draft and listed for the user?
