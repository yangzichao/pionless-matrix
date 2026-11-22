---
name: underlying-question
description: "Check whether the user is asking the right question, and replace it with a better one. Four directions: down (many surface questions circle one deeper question never asked), up (one vague question needs a series of concrete ones), back (the user already holds an answer, so recover the question it answers and check that question is worth answering), and reverse (the questions the assistant should have asked the user). Use when the user asks \"among everything we discussed, is there a deeper question I keep circling\", \"what am I really asking\", \"am I asking the wrong question\", \"this question is too vague, break it down\", \"what problem does this solution actually solve\", \"what should you ask me\", \"在我们反复讨论过的所有问题中，有没有一个更深层次的问题\", \"我真正想问的是什么\", \"这个问题太虚了\", or when the user asks the same thing several ways without progress, asks something too broad to answer, or keeps asking how to apply a solution nobody has justified."
metadata:
  version: "1.1.0"
---

# Underlying Question

A question can be wrong in four ways, and each needs a different fix:

| Direction | What is wrong | What you produce |
|---|---|---|
| Down | Many surface questions orbit a deeper one nobody asked | One deeper question |
| Up | One question is too vague to answer | A short, ordered series of concrete questions |
| Back | The user already holds an answer and asks how to apply it | The question that answer answers, and whether it is worth answering |
| Reverse | The assistant has been answering on guesses | The questions the assistant should ask the user |

This skill finds the right question first and answers second. It does not run a long interview to settle every decision in a plan; once the right question is found and a whole plan needs settling, call the skill named grilling if it is available.

## Step 1: Collect the material

Use everything you can actually read: this conversation, past conversations or memory the host can show you, notes or files the user points at. Say which sources you used. If the user brings a single question, that question and the assumptions inside it are the material.

Do not invent a history you cannot see. If the material is too thin for the direction you pick (for example, fewer than three related questions for Down), say so and ask the user to paste or list what they have been asking.

## Step 2: Pick the direction

Read the material for these signals:

- **Down.** The user asked several questions that feel related, or asked the same thing in new words without progress. Or a single specific question that rests on a shaky premise.
- **Up.** One broad question that any direct answer would turn into generic advice: "how should I plan my career", "is this architecture good", "how do I get better at English".
- **Back.** The questions name a solution and ask how to use it, compare it, or sell it to others ("Redis or Memcached", "how do I convince my team to adopt Kubernetes"), but nobody has said what problem it fixes.
- **Reverse.** Your answers so far depend on facts only the user knows (goals, constraints, taste, deadlines), and you have been guessing them. Or the user asks what you should ask them.

Pick one primary direction. If a second one clearly applies too, run the primary and name the second in one line at the end. Up often ends in Reverse, because some concrete questions can only be answered by the user; that is part of Up, not a second direction.

If the user explicitly asks for a direction, use it.

## Step 3: Run the direction

Read the matching reference before you start, and follow it:

- Down: read references/down-many-questions-to-one.md
- Up: read references/up-vague-question-to-concrete-ones.md
- Back: read references/back-answer-to-its-question.md
- Reverse: read references/reverse-what-to-ask-the-user.md

Each reference has its procedure, its output shape, and worked examples, including cases where the direction finds nothing.

## Step 4: Test what you produced

Every question you hand the user must pass these, whatever the direction:

1. **Evidenced.** You can point to the user's own words, or to a concrete assumption in their question, that leads to it.
2. **Workable.** It is a question the user can act on soon (profile this, write that sentence, decide between two named options), not a verdict on the user ("you are afraid of failure") and not a line that fits anyone ("what do you really want in life").
3. **Not already answered.** The user has not already asked and settled it. If they have, the gap is elsewhere.
4. **Facts are yours, decisions are theirs.** Never ask the user for something you could look up yourself (a file, a schema, a doc, a log). Look it up first. Ask only what only the user can decide or knows.

Drop what fails. If nothing passes, say so plainly: maybe the questions are simply separate, or the vague question is fine as asked. That is a useful finding.

## Step 5: Answer

Reply in the user's language, in short prose, in the output shape the reference gives. Lead with the result (the question, or the list), then the evidence. Mark inferences as your reading ("I read this as..."), not as fact.

Then check with the user whether it lands. They know their situation better than the transcript does.

## Step 6: Work on the better question

Once the user accepts the result, answer it or help them work through it. This is the "answer not as asked" move: address the better question even though nobody asked it in those words. If it is a concept the user wants to work out themselves, call the skill named socratic-tutor if it is available.

## Rules

- Quote the user's real words as evidence. Never paraphrase a quote into something stronger than what they said.
- No psychoanalysis, no flattery, no motivational close.
- Down gives one question, not five. Up and Reverse give a short list, ordered so each question can be answered with what is already settled.
- If the material is thin, say what you could not see instead of filling the gap.
