---
name: unknown-unknowns
description: "Find what the user does not know they do not know about a plan, a decision, or an unfamiliar field, outside of code. Names the box the user is thinking inside (field, goal, people, time span, premises) and searches three layers: inside the box (what the field knows and the user does not), outside the box (what the frame itself leaves out, found by stepping across each of its walls), and unknown to everyone (what only contact with reality shows, surfaced by a small early probe and tripwires). Returns a short ranked list of gaps with evidence, either-or questions for unstated assumptions, and one probe. Use only when the user asks for this, for example: \"what don't I know that I don't know\", \"what am I missing\", \"what are my blind spots\", \"think outside the box about this\", \"I'm new to this, what should I know first\", \"unknown unknowns\", \"我不知道我不知道什么\", \"我有什么盲点\", \"我漏了什么\", \"跳出框架想想\". For a coding plan, call the skill named code-unknowns instead."
metadata:
  version: "1.1.0"
---

# Unknown Unknowns

Thinking harder inside a frame does not reach unknown unknowns. The user thinks inside a box: a field, a goal, the people they have in mind, a time span, and premises they take as given. Your thinking starts inside the same box, because it starts from their words. A gap the field already knows about is the shallowest kind; a checklist finds it. The deeper gaps sit outside the box, or are unknown to everyone until reality shows them.

| Layer | What it is | How this skill reaches it |
|---|---|---|
| 1. Inside the box | The field knows it; the user does not | Contrast the user's picture with insider references |
| 2. Outside the box | The frame itself leaves it out | Step across each wall of the box on purpose |
| 3. Unknown to everyone | Nobody can know it until they try | A small early probe, and tripwires that say when to stop and rethink |

Unknown knowns (things the user knows or assumes but never said) show up in all three layers. They come back as either-or questions, because people cannot list their own assumptions but recognise one when shown a concrete choice.

## Scope

This skill finds gaps and hands them back. It ends when the user has the list and says which ones land.

It does not:

- write the plan or make the decision;
- teach the field in depth (call the skill named socratic-tutor if it is available);
- write a research report (call the skill named deep-research if it is available);
- check whether the user's question is the right one (call the skill named question-the-question if it is available);
- look for gaps between a coding plan and a codebase (call the skill named code-unknowns).

## Step 1: Write down the picture and draw the box

From the conversation and anything the user points at, write the picture in five short lines, in the user's own words where possible:

- **Goal:** what they want to end up with.
- **Plan:** what they intend to do, or the options they are deciding between.
- **Already known:** what they clearly know about the field.
- **Constraints:** time, money, skill, people, anything they cannot change.
- **Already open:** questions they have named themselves.

Then draw the box: its five walls, as the picture implies them.

- **Field:** the field the task is in, and the practitioner who does it for a living.
- **Goal:** the goal as stated, and what it seems to be for, if the user said.
- **People:** who the picture includes.
- **Time:** the span it covers, from where it starts to where it stops.
- **Premises:** what the plan takes as given without saying so.

If you cannot say what the goal is, ask the user one question and wait. Ask nothing else at this step.

## Step 2: Search inside and outside the box

Dispatch two roles at once if your host allows parallel subagents; otherwise run them one after another. Both work from a task card alone, without your reasoning so far, so neither is anchored on what you already think matters.

- **Outside scout** (`roles/outside-scout.md`), layer 1: how the practitioner breaks the task down, how attempts like this go wrong, what similar cases took, and first-hand accounts of what surprised the people who did it. Needs web search.
- **Box breaker** (`roles/box-breaker.md`), layer 2: steps across each wall of the box and reports what lies just outside it. Web search helps.

For each role:

- If you can start subagents: start one with a fresh context (not a fork of this conversation). Give it the full text of its role file, then a task card with the picture, the box, and the user's language. Ask for read-only work if your host lets you restrict tools.
- If you cannot: run it yourself as a separate pass. Re-read its role file, work only from the task card, and produce exactly the output it specifies. Run the box breaker before reading the scout's output, so the field's view does not narrow it.

Search the web if you can. If you cannot, say that the references come from your own knowledge only, mark each finding "unsourced", and name one place the user could check.

## Step 3: Turn the returns into candidates

- From the scout: every item the picture does not cover is a candidate. An item the picture contradicts ("two weeks" against a typical three months) is a candidate too, usually a strong one. A surprise that people who did it report is a strong candidate, because guides rarely say it.
- From the box breaker: every item it ties to the user's own words or to a source is a candidate. An item that depends on a fact about the user you do not know is not a gap yet; make it an assumption question.
- Unknown knowns: add the assumptions the plan rests on that the user never stated.

## Step 4: Keep only the gaps that matter

Every candidate must pass all five:

1. **Evidenced.** It traces to a source, or to the user's own words. When you say something is missing from their picture, quote what they did say.
2. **Changes something.** If the user knew it, they would change the plan, its order, its budget, the goal, or the decision. A gap that is interesting but changes nothing gets dropped.
3. **Specific.** It is about this user's situation and would not fit every plan. "Budget extra time", "consider the risks", and "think about your health" are banned.
4. **New to the user.** It is not already in their picture. If you are unsure, phrase it as a check: "you may know this already: ...".
5. **Facts are yours, decisions are theirs.** If a fact can be looked up, look it up. Ask the user only what only they know or decide.

Keep at most seven gaps, at least one from outside the box if any passed, and at most five assumption questions. Three sharp gaps beat ten padded ones. If nothing passes, say that the picture holds up, name what you checked, and still give the probe from step 5: layer 3 is never empty in advance.

## Step 5: Design the probe and the tripwires

Layer 3 cannot be found by searching. Design one probe: the smallest, cheapest real contact with the task that would surface surprises early. It is a slice of the real thing, done soon: a trial run, a small version, a week living with the constraint, a conversation with someone who did it and stopped. Say what it costs and what it could reveal.

Add two to four tripwires. Each is a signal the user can observe, and what to reconsider when it appears ("the same pain three days in a row: drop the weekly distance before anything else").

## Step 6: Hand it back and stop

Read `references/output-and-examples.md` before writing the reply. It has the output shape and worked examples, including one where nothing is found.

- **Each gap:** what the user may not know, in plain words; which layer it is from; why it matters for this plan; the evidence; and the cheapest next move to close it. Do not design a full solution. Knowing the gap comes first.
- **Each assumption:** an either-or question with your recommended answer, so the user can reply with a letter. Put first the question whose answer can change the others.
- **If the field is new to the user,** add the terms from the scout they did not use, each with a one-line meaning.
- **If the open question is how something should look, sound, or behave,** offer two to four short contrasting versions, or a rough mock if your host can show one, and ask which is closest.

Reply in the user's language. Lead with the single gap that matters most, then the rest, the questions, the probe and tripwires, and one line on what you could not check.

Ask which gaps land. They know their situation better than any reference. Then stop: revising the plan or making the decision is a new request.

## Rules

- Never present your own knowledge as researched. Mark it "unsourced".
- Leaving the box is not licence to speculate. An outside-the-box gap still needs the user's words or a source behind it.
- No forced fixes for every gap, no bonus ideas the user did not ask for, no generic risk lists.
- Gaps are about the task and the situation, not the person. No psychoanalysis, no flattery, no pep talk.
