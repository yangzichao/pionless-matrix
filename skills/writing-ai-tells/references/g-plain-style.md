# G. Plain style

People break these rules too, but model drafts break them constantly, and each one makes the reader work harder for the same fact. Apply them to reference, technical, and explanatory text. In informal text, and wherever the writer's sample does otherwise, the Voice rules win.

## 27. Fancy words, filler, and empty adverbs

**Watch for:** utilize, leverage, facilitate, commence, endeavor, due to the fact that, the fact that, at this point in time, it is important to note that, it is worth noting that; significantly and dramatically where the text has the number. "Very", "really", and "in order to" are not tells: the best pre-2023 engineering posts use them more often than AI drafts do. Cut them only when they add nothing in a sentence you are already rewriting.

**Problem:** A long word or a filler phrase costs the reader more for the same meaning. Use the plain word: *use*, *help*, *start*, *try*, *to*, *because*, *now*. Cut the adverb, use a stronger verb, or give the number the adverb stands for when the text has it. *Significantly* keeps its statistical sense.

**Before:**
> In order to leverage the cache, it is important to note that latency improved significantly, dropping from 120 ms to 40 ms.

**After:**
> With the cache, latency dropped from 120 ms to 40 ms.

## 28. Metaphor nouns and figurative verbs

**Watch for:** substrate, wedge, nexus, scaffolding, paradigm, ratchet, north star, flywheel, lever, and vector, primitive, harness, or surface used figuratively; unlock, unleash, supercharge, empower; code that "fights" or "lies". Everyday technical phrasing such as a network that "knows" a route or a tool that "surfaces" errors is fine.

**Problem:** The metaphor names the thing indirectly, so the reader has to translate it back. Use the concrete word, and say what the code does instead of what it feels. Keep established technical terms: a math vector, a test harness, an API's attack surface.

**Before:**
> The retry queue is the substrate for every webhook. The parser wants a closing tag, and this change unlocks faster deploys.

**After:**
> Every webhook goes through the retry queue. The parser fails without a closing tag, and this change makes deploys faster.

## 29. Rotating synonyms

**Problem:** The text calls one thing by several names (the CLI, the tool, the utility, the program) to avoid repeating a word. The reader then wonders whether these are different things, and in technical text a different word usually does mean a different thing. Pick one name and repeat it, or use a pronoun when the referent is clear.

**Before:**
> Install the CLI. Once the tool is on your PATH, the utility reads its config from `~/.foo`, and the program caches results there.

**After:**
> Install the CLI. Once the CLI is on your PATH, it reads its config from `~/.foo` and caches results there.

## 30. False ranges

**Watch for:** from X to Y, everything from X to Y, ranging from X to Y

**Problem:** "From X to Y" claims a span that covers everything between two points. When X and Y do not sit on one scale, the range is a list in disguise that implies more coverage than the text supports. Name the items. Keep a real range: from 1990 to 2000, from small teams to large ones.

**Before:**
> The platform handles everything from log ingestion to team morale.

**After:**
> The platform ingests logs. (Cut "team morale" unless the text says how the platform affects it.)

## 31. Drumroll colons

**Watch for:** The answer is simple:, Here's the catch:, One problem:, The result:, The fix?

**Problem:** A colon in mid-sentence sets up a reveal instead of introducing a list, an example, or an elaboration. It is the punctuation form of §4. State the point. A colon before a list, an example, a definition, or a clause that explains the one before it is fine. *Weak alone.*

**Before:**
> The answer is simple: cache the response. The catch: it goes stale.

**After:**
> Cache the response, but expect it to go stale.

## 32. Overloaded sentences

**Problem:** Clauses pile up with *which*, *while*, *and*, and semicolons until the reader has to reread the sentence. Give each idea its own sentence, and split any sentence a reader would reread. Keep a long sentence that reads in one pass. Splitting must not drop a clause.

**Before:**
> The migration, which runs nightly and which moved off the main cluster last quarter while the team rewrote the scheduler, now takes 40 minutes, which is within budget.

**After:**
> The migration runs nightly. It moved off the main cluster last quarter, while the team rewrote the scheduler. It now takes 40 minutes, which is within budget.

## 33. Telegraphic notes

**Watch for:** dropped articles and verbs ("Config loaded, cache warm, ready"), arrows used as verbs (A → B), unexplained abbreviations (w/, b/c, impl, cfg), and slash pairs standing in for a relationship (read/write path)

**Problem:** The text is notes the drafter wrote for themselves. Write whole sentences with their articles and verbs, and spell out arrows and abbreviations. Leave fragments where the format expects them: commit subjects, table cells, changelogs, tutorial step lists, and informal chat.

**Before:**
> Auth → token svc, cfg w/ env vars b/c secrets.

**After:**
> The auth service calls the token service. Its config comes from environment variables because it holds secrets.

## 34. Sentences that fit anyone's document

**Watch for:** is a key consideration, offers flexibility and scalability, provides a seamless experience, makes it easy to, feels faster, best practices

**Problem:** The sentence could appear unchanged in another project's docs, so it says nothing about this one. It often describes how the thing feels instead of what it does. Name the mechanism or the number from the text, or cut the sentence. Do not invent the specifics.

**Before:**
> The new design is more flexible and makes the system feel faster.

**After:**
> (Name what the design changed and by how much, if the source says. Otherwise cut the sentence.)
