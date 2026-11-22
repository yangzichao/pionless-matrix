---
name: question-the-question
description: "Check whether a question in this conversation is the right one, and hand back a better one. Four directions: down (many surface questions circle one deeper question never asked), up (one vague question becomes a short series of concrete ones), back (a solution the user already holds is traced to the problem it solves, to check they have it), and reverse (audit the assumptions the assistant made in its own answers without asking). Stops once the user confirms the better question; it does not go on to answer it. Use only when the user asks for this, for example: \"is there a deeper question I keep circling\", \"what am I really asking\", \"am I asking the wrong question\", \"this question is too vague, break it down\", \"what problem does this solution actually solve\", \"what have you been assuming about me\", \"在我们反复讨论过的所有问题中，有没有一个更深层次的问题\", \"我真正想问的是什么\", \"这个问题太虚了\", \"我是不是问错了\", \"你一直在假设什么\"."
metadata:
  version: "1.1.2"
---

# Question the Question

A question can be wrong in four ways, and each needs a different fix:

| Direction | What is wrong | What you produce |
|---|---|---|
| Down | Many surface questions orbit a deeper one nobody asked | One deeper question |
| Up | One question is too vague to answer | A short, ordered series of concrete questions |
| Back | The user already holds an answer and asks how to apply it | The question that answer answers, and whether the user has it |
| Reverse | The assistant's earlier answers rest on assumptions the user never confirmed | Those assumptions, as questions for the user |

## Scope

This skill does one thing: it checks whether a question is the right one and hands back a better one. It ends when the user confirms the better question (or says none fits). The conversation then carries on as normal.

It does not:

- answer the better question, or work through it with the user;
- settle every decision in a plan, one round after another;
- teach a concept;
- research a topic and write a report;
- gather requirements before starting a task. A question too vague to start on is Up; Reverse only looks back at answers already given.

## Step 1: Collect the material

Use everything you can actually read: this conversation, past conversations or memory the host can show you, notes or files the user points at. Say which sources you used. If the user brings a single question, that question and the assumptions inside it are the material.

Do not invent a history you cannot see. If the material is too thin for the direction you pick (for example, fewer than three related questions for Down), say so and ask the user to paste or list what they have been asking.

## Step 2: Pick the direction

If the user names a direction, use it. Otherwise read the material for these signals:

- **Down.** The user asked several questions that feel related, or asked the same thing in new words without progress. Or a single specific question that rests on a shaky premise.
- **Up.** One broad question that any direct answer would turn into generic advice: "how should I plan my career", "is this architecture good", "how do I get better at English".
- **Back.** The questions name a solution and ask how to use it, compare it, or sell it to others ("Redis or Memcached", "how do I convince my team to adopt Kubernetes"), but nobody has said what problem it fixes.
- **Reverse.** The user's questions were concrete, but your own earlier answers quietly assumed things only the user knows (their goal, audience, constraints, taste), and you never asked.

Pick one primary direction. If a second one clearly applies too, run the primary and name the second in one line at the end. Some of Up's concrete questions can only be answered by the user; asking them is part of Up, not Reverse.

## Step 3: Run the direction

Read the matching reference before you start, and follow it:

- Down: read references/down-many-questions-to-one.md
- Up: read references/up-vague-question-to-concrete-ones.md
- Back: read references/back-answer-to-its-question.md
- Reverse: read references/reverse-audit-assistant-assumptions.md

Each reference has its procedure, its output shape, and worked examples, including cases where the direction finds nothing.

## Step 4: Test what you produced

Every question you hand the user must pass these, whatever the direction:

1. **Evidenced.** You can point to the user's own words, or to a concrete assumption in their question or your answers, that leads to it.
2. **Workable.** It is a question the user can act on soon (profile this, write that sentence, decide between two named options), not a verdict on the user ("you are afraid of failure") and not a line that fits anyone ("what do you really want in life").
3. **Not already answered.** The user has not already asked and settled it. If they have, the gap is elsewhere.
4. **Facts are yours, decisions are theirs.** Never ask the user for something you could look up yourself (a file, a schema, a doc, a log). Look it up first. Ask only what only the user can decide or knows.

Drop what fails. If nothing passes, say so plainly: maybe the questions are simply separate, or the vague question is fine as asked. That is a useful finding.

## Step 5: Hand it back and stop

Reply in the user's language, in short prose, in the output shape the reference gives. Lead with the result (the question, or the list), then the evidence. Mark inferences as your reading ("I read this as..."), not as fact.

Ask whether it lands. They know their situation better than the transcript does. If they reject it, offer the runner-up or say nothing else fits. Once they confirm, the skill is done: do not go on to answer the better question unless the user asks for that as a new request.

## Rules

- Quote the user's real words as evidence. Never paraphrase a quote into something stronger than what they said.
- No psychoanalysis, no flattery, no motivational close.
- Down gives one question, not five. Up and Reverse give a short list, ordered so each question can be answered with what is already settled.
- If the material is thin, say what you could not see instead of filling the gap.
