# Finding the point with the author

Use this file when the user wants to write something but has no main claim yet, or has one too vague to write as one sentence: "I want to write about our Kafka migration", "a post about what we learned", a pile of notes. This is common. Most authors know a lot about the topic and have not yet decided which part is the point.

The author owns the point. Your job is to ask until the author says it in their own words, not to supply it. A point you hand over gets accepted because it sounds fine, and the author cannot defend it later. Offer your own candidates only when the author is stuck (see the steps below).

## Why this works

A main claim is the answer to a question the reader has. Authors usually get stuck because they are trying to answer "what should I write about X", which has no answer. Once the reader's question is concrete, most authors can answer it in a sentence. So first find the right question, then let the author answer it.

## Steps

1. **Collect the author's own words.** Take everything they gave you: the request, notes, a draft, a chat log, a design doc. Look up the facts you can check yourself (code, docs, numbers) so you do not ask for them.
2. **Read which way the author is stuck,** and pick one direction:
   - **Up: a topic with no question.** "Write about the migration." Turn it into a few concrete questions, in dependency order: who must read this, what they will do differently afterward, what surprised you, what you would tell a peer team in one minute.
   - **Down: many points, no center.** The author lists cost, latency, tooling, and the people side with equal weight. Find the one the others hang off: the one they came back to most (quote them), the one they would keep if only one survived, the one that explains the others.
   - **Back: a solution or announcement as the topic.** "A post about our new tool." Trace it to the problem it solves, for whom, and whether this reader has that problem. The point is usually about the problem, not the tool.
   - **Reverse: you already drafted a skeleton for them.** List the assumptions you made without asking (who the reader is, how strong the claim is, which result matters most) as questions for the author.
3. **Sharpen the question.** If a skill named question-the-question is available, call it with the direction from step 2. Give it the author's words as the material, and the question "what should this document tell its reader?" as the question to improve. It hands back a better question, or a short list, and stops. If it is not available, run the direction yourself as described in step 2.
4. **Ask the author to answer it in one sentence.** Ask one question at a time and wait. Use their answer as written; tighten it only for grammar.
5. **Test the sentence with the author.** Ask each test as a question, not as a verdict:
   - "Could a reader you respect disagree with this?" If not, it is a topic, not a claim.
   - "After reading, what does the reader do differently?" If nothing, the point is not yet for this reader.
   - "Say it to a peer in one breath. Is that what you would say?" If they add "but really...", what follows the "but" is usually the point.
6. **When the author is stuck after two tries,** offer two or three candidate sentences that differ in a real way: different readers, different strength, or a different finding. Build each candidate only from the author's words and the facts you checked, and say which words each one came from. Ask the author to pick one, combine them, or reject them all. Never pick for them.
7. **Stop when the author confirms one sentence** that passes the main-claim test in `references/full-document.md`. Say it back in their words, then go on to the skeleton.

If the author still has no point after this, say what is blocking it: a missing fact, an undecided choice, or a topic with no position yet. That is a finding, not a failure. The next step may be to gather the fact or make the choice, not to write.

## Rules

- One question per message, each answerable in a minute: a fact, a name, or a choice between options you name.
- Quote the author's words as evidence. Never restate them stronger than they said them.
- Never ask for something you could look up yourself.
- No flattery and no coaching talk. Ask the question and wait.
- For an engineering blog post, ask the first two questions of the inventory in `references/engineering-blog.md` (the trigger and the reader) before step 2. They often settle the point by themselves.
