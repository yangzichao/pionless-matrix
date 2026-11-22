---
name: unknown-unknowns
description: "Find what the user does not know they do not know about a plan, a decision, or an unfamiliar field, outside of code. Holds the user's picture of the task against outside references (how practitioners break the task down, how attempts like this usually fail, what similar cases took) and turns the user's unstated assumptions into either-or choices they can recognise. Returns a short ranked list of gaps, each with evidence and the cheapest way to close it. Use only when the user asks for this, for example: \"what don't I know that I don't know\", \"what am I missing\", \"what are my blind spots\", \"I'm new to this, what should I know first\", \"unknown unknowns\", \"我不知道我不知道什么\", \"我有什么盲点\", \"我漏了什么\", \"刚接触这个领域，我该先知道什么\". For a coding plan about to be built in a codebase, call the skill named code-unknowns instead."
metadata:
  version: "1.0.0"
---

# Unknown Unknowns

Thinking harder does not list unknown unknowns. The user's picture of the task leaves things out, and yours tends to leave out the same things. A gap shows up only when that picture is held against something outside it. This skill makes two moves:

1. **Contrast.** Compare the user's picture with outside references: how a practitioner breaks the task down, how attempts like this usually fail, what similar cases took. What the references have and the picture lacks is a candidate gap.
2. **Recognition.** The user cannot list their unstated assumptions, but they recognise one when shown a concrete choice. Turn each assumption into an either-or question, or a small sample they can react to.

| Kind | What it is | How this skill finds it |
|---|---|---|
| Known unknowns | Open questions the user already named | Not the job here. List them in one line so they are not lost. |
| Unknown knowns | Things the user knows or assumes but never said | Recognition: either-or questions with a recommended answer |
| Unknown unknowns | Things neither of you has thought of | Contrast against outside references |

## Scope

This skill finds gaps and hands them back. It ends when the user has the list and says which ones land.

It does not:

- write the plan or make the decision;
- teach the field in depth (call the skill named socratic-tutor if it is available);
- write a research report (call the skill named deep-research if it is available);
- check whether the user's question is the right one (call the skill named question-the-question if it is available);
- look for gaps between a coding plan and a codebase (call the skill named code-unknowns).

## Step 1: Write down the user's picture

From the conversation and anything the user points at, write five short lines, in the user's own words where possible:

- **Goal:** what they want to end up with.
- **Plan:** what they intend to do, or the options they are deciding between.
- **Already known:** what they clearly know about the field.
- **Constraints:** time, money, skill, people, anything they cannot change.
- **Already open:** questions they have named themselves.

Then name the field and the practitioner who does this for a living ("a relocation agent", "a self-published author", "a colorist"). A task can span two fields; name both.

If you cannot say what the goal is, ask the user one question and wait. Ask nothing else at this step.

## Step 2: Gather outside references

Three probes:

- **Insider frame.** How the practitioner breaks the task down: the stages in order, the five to eight terms the work turns on, and what they check before calling it done.
- **Failure record.** How attempts like this usually go wrong: common mistakes, post-mortems, things people say they wish they had known. First-hand accounts beat listicles.
- **Base rates.** What similar cases actually took: time, cost, success rate, the usual order of steps.

Run all three unless one plainly does not apply, and say which one you skipped.

Dispatch the outside scout. It works from the picture alone, without your reasoning so far, so it is not anchored on what you already think matters.

- If you can start subagents: start one with a fresh context (not a fork of this conversation). Give it the full text of `roles/outside-scout.md`, then a task card with the five lines from step 1, the field and practitioner, any probe to skip, and the user's language. It needs web search and read-only access.
- If you cannot: run the probes yourself as a separate pass. Re-read `roles/outside-scout.md`, work only from the task card, and produce exactly the output it specifies.

Search the web if you can. If you cannot, say that the references come from your own knowledge only, mark each finding "unsourced", and name one place the user could check.

## Step 3: Hold the picture against the references

Go through the scout's output item by item: each stage, term, done-check, failure, and base rate. For each, ask whether the user's picture covers it (they mentioned it, their plan implies it, or they plainly know it). An item the picture does not cover is a candidate gap. An item the picture contradicts ("two weeks" against a typical three months) is a candidate gap too, usually a strong one.

Then list the unknown knowns: assumptions the plan rests on that the user never stated. Common ones are who it is for, what "done" means, what they will not give up, how much it may cost, and what happens if it fails.

## Step 4: Keep only the gaps that matter

Every candidate must pass all five:

1. **Evidenced.** It traces to a reference the scout returned, or to the user's own words. When you say something is missing from their picture, quote what they did say.
2. **Changes something.** If the user knew it, they would change the plan, its order, its budget, or the decision. A gap that is interesting but changes nothing gets dropped.
3. **Specific.** It would not fit every plan. "Budget extra time" and "consider the risks" are banned.
4. **New to the user.** It is not already in their picture. If you are unsure, phrase it as a check: "you may know this already: ...".
5. **Facts are yours, decisions are theirs.** If a fact can be looked up, look it up. Ask the user only what only they know or decide.

Keep at most seven gaps and at most five assumption questions. Three sharp gaps beat ten padded ones. If nothing passes, say that the picture holds up against the references, name the references you used, and stop. That is a finding, not a failure.

## Step 5: Make each one recognisable

Read `references/output-and-examples.md` before writing the reply. It has the output shape and worked examples, including one where nothing is found.

- **Each gap** gets: what the user may not know, in plain words; why it matters for this plan; the evidence; and the cheapest next move to close it (something to read, a question to put to someone named by role, a small test). Do not design a full solution. Knowing the gap comes first.
- **Each assumption** becomes an either-or question with your recommended answer, so the user can reply with a letter. Put first the question whose answer can change the others.
- **If the field is new to the user,** add the terms from the insider frame they did not use, each with a one-line meaning and the user's request restated the way a practitioner would say it.
- **If the open question is how something should look, sound, or behave,** words usually fail. Offer two to four short contrasting versions, or a rough mock if your host can show one, and ask which is closest.

## Step 6: Hand it back and stop

Reply in the user's language. Lead with the single gap that matters most. Then give the rest, the assumption questions, the terms if any, and one line on what you could not check.

Ask which gaps land. They know their situation better than any reference. Then stop: revising the plan or making the decision is a new request.

## Rules

- Never present your own knowledge as researched. Mark it "unsourced".
- No forced fixes for every gap, no bonus ideas the user did not ask for, no generic risk lists.
- Gaps are about the task, not the person. No psychoanalysis, no flattery, no pep talk.
- A short list from a real contrast beats a long list from imagination.
