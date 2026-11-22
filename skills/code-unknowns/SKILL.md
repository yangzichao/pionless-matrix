---
name: code-unknowns
description: "Find the gap between a coding plan (a prompt, spec, or plan in the user's head) and the real codebase, at three moments. Before implementation: read the code the plan touches and one step past it, surface ambiguities, unchecked assumptions, undefined behavior, what the plan's frame leaves out, and the user's unstated decisions, run a small spike where reading is not enough, then hand back a plan sorted by what is most likely to change. During implementation: log every place the code forced a departure from the plan. Before merge: check what the diff really changed against the plan, list who inherits it, and quiz the user on it. Use only when the user asks for this, for example: \"what am I missing before I build this\", \"blindspot pass\", \"poke holes in this plan\", \"what would you ask me before coding\", \"log deviations as you go\", \"quiz me before I merge\", \"do I understand this diff\", \"动手前我漏了什么\", \"这个实现有什么盲点\", \"合并前考考我\". For unknowns outside code, call the skill named unknown-unknowns instead."
compatibility: Needs read access to the repository; shell and git make it much stronger.
metadata:
  version: "1.1.0"
---

# Code Unknowns

The plan is a map; the code is the territory. The gap between them is the unknowns. Found before code is written, a gap costs one question. Found after merge, it costs a bug or a rewrite. Gaps are found by reading the code against the plan, not by imagining what might go wrong.

Reading only the files the plan names keeps you inside the plan's box. The deepest gaps sit outside it: in the systems, people, and time the plan never mentions, or in behaviour nobody sees until the code runs. So the reading always goes one step past the plan's frame, and before implementation a small spike touches reality.

| Moment | When | What you produce |
|---|---|---|
| Before | A plan, spec, or prompt is about to drive real work | Findings grounded in files, up to five decision questions, and the plan sorted by what is most likely to change |
| During | You are implementing an agreed plan | A deviation log, written as each deviation happens |
| Before merge | The change is done, especially a large or mostly agent-written one | Plan against diff, who inherits the change, and a short quiz for the user |

## Scope

It does not:

- write the feature, except During, where the log rides alongside your normal implementation;
- review the code for bugs or style (call a code review skill if one is available);
- find gaps in a plan that has no codebase behind it (call the skill named unknown-unknowns).

## Step 1: Pick the moment

If the user names one, use it. Otherwise: no code written yet means Before; you are in the middle of implementing means During; a finished diff the user is about to merge, or a question about whether they understand it, means Before merge.

## Step 2: Write down the map

State the plan in a few lines, in the user's words where possible: the goal, what will change and where, and what "done" means. A plan file or spec, if there is one, is the map.

If you wrote the plan yourself earlier in this conversation, say so. Your own plan is the one you are worst at checking, which is why step 3 uses a fresh reader.

## Step 3: Read the territory with a fresh reader

Skip this step for During; there you are already reading the code as you change it.

Dispatch the territory reader.

- If you can start subagents: start one with a fresh context (not a fork of this conversation). Give it the full text of `roles/territory-reader.md`, then a task card with the map from step 2, the moment, the repository root and the paths or diff range in play, and any reference code the plan says to copy or port. Ask for read-only work if your host lets you restrict tools; it needs file reads, and shell with git and search if available.
- If you cannot: do the reading yourself as a separate pass. Re-read `roles/territory-reader.md`, work only from the task card, and produce exactly the output it specifies.

While it reads, you may read too. You merge its findings with yours.

## Step 4: Run the moment

Read the matching reference before you start, and follow it:

- Before: read `references/before-implementation.md`
- During: read `references/during-implementation.md`
- Before merge: read `references/before-merge.md`

Each one has its procedure, its output shape, and an example.

## Step 5: Test every finding

1. **Grounded.** It cites a file and line, a symbol, a commit, a command's output, or the line of the plan it concerns. A finding you cannot ground gets deleted, not hedged.
2. **Changes the work.** It changes the architecture, the scope, a data shape, a public interface, a test, or what "done" means. Otherwise drop it.
3. **Not generic.** "Add tests", "consider security", and "handle errors" are banned unless tied to a specific path in this code.
4. **Facts are yours, decisions are theirs.** If reading a file or running a command would answer it, do that. Ask the user only about intent, priorities, and decisions.
5. **Nothing found is a finding.** If the plan holds up against the code, say so and stop. Do not invent gaps.

Three sharp findings beat ten padded ones.

## Step 6: Deliver

Reply in the user's language. Lead with the riskiest unknown and the cheapest way to resolve it, then follow the output shape in the reference.

Put the result where the next agent will see it: into the plan file if one exists, or into a notes file the user names. Do not create new files in the repository unless the user asks. Without a file, the reply carries it.

## Rules

- Quote real code. Never describe code as doing more than it does.
- Recognition beats description. When an open question is how a screen looks or behaves, offer a throwaway mock or two to four variants, if you can run or render one, instead of asking in words. Keep mock code out of the real codebase.
- Before and Before merge report; they do not fix. During makes the conservative call and logs it.
- If you cannot read the territory (wrong repository, missing service, no access), give the pass from the plan text, mark every finding "plan-only", and name the missing territory as the riskiest unknown.
