# Design docs

A design doc is read by people who must approve, build, review, or maintain a system. It has to do three things for them. They can grasp the decision in thirty seconds. They see the design concretely enough to spot a wrong choice. They know exactly what is still theirs to decide. Most design docs fail the second test: they argue for a change without showing it. These rules apply on top of `references/full-document.md`, and where the two differ, this file wins.

## Two kinds

Settle the kind before outlining; if the request does not say, ask.

- **Proposal:** the change is not built yet. The main claim is the decision: what to build, chosen over the strongest alternative.
- **Architecture:** the system is already built. The main claim is the rule the system keeps and how it keeps it.

## What the best design docs do

- **Show the design, do not only argue for it.** The design is the body of the document, usually the longest section, about half of it. "Why", alternatives, and risks support the design; they never replace it.
- **Make it concrete.** Show one worked example end to end: a real input, what the system does with it, and the output the user gets. Show the shape of every new request, record, or setting in a code block. List every state the user can see, not only the happy path.
- **Give every choice its reason and its price.** Wherever the design picks one option over another a competent reader might pick, give the choice, the reason, and what it gives up, in one or two sentences, beside the choice itself.
- **Derive every number you chose.** A limit, price, threshold, or size the design sets shows how it follows from a goal or a measured fact, and which assumption it rests on: "at most 6 actions per summary, so that three summaries leave 80% of the window". A number with no derivation reads as a guess, and the reader cannot tell when to change it.
- **Mark what changes.** For each component, say whether it is new, changed, or untouched. Mark every point where data crosses a trust boundary, such as device to cloud.
- **Read in layers.** The summary alone gives the decision. The summary plus the first sentence of each section gives the design. Detail sits below that. A reader can stop at any layer and still have a true picture.
- **Describe the current design only.** No dated status notes, superseded sections, or history in the body. If past decisions matter, put a short decision log at the end.
- **Write "none" instead of leaving a topic out.** For a standard topic that does not apply, such as migration, write one line saying why. The reader then knows it was considered.

## Proposal structure

Use these top-level sections in this order. Reviewers look for them by name, so plain conventional headings are right here, not a fault. Under Design, each subsection heading states the decision it makes: "The summary is stored on the meeting, not as a separate note."

1. **Status block and summary.** One to three lines before the first paragraph: status (proposed, not built), what must happen before work starts, and links to the documents this change alters. Follow the venue's format. Then one answer paragraph: the decision, what this version leaves out, and the main cost. State the decision plainly ("We propose..."); do not write "please approve". The status block and the closing questions carry the request.
2. **Context.** The problem in the reader's words, what exists today (link the architecture doc rather than retelling it), and why now. Mark each piece of evidence as measured, estimated, or missing; a missing piece is a visible placeholder plus what changes if it never arrives.
3. **Goals and non-goals.** Numbered goals, each with how you would see it met. Non-goals name what a reader might expect and will not get.
4. **Design.** Outside in:
   - What the user sees: the main path and every state (empty, in progress, done, failed, blocked), with the worked example.
   - How it flows: one diagram or numbered flow across components, with new, changed, and untouched marked, and trust boundaries shown.
   - What changes in each component: data model and storage, requests and interfaces, settings.
   - What happens when things go wrong: a table of failure, what the user sees, and how it recovers.
5. **Alternatives considered.** Each system-level alternative, including doing nothing, with a concrete blocker: a missing dependency, a broken rule, or a measured cost. "More work" counts only if the work is estimated. Include the simpler alternative the reader will think of, such as a capability the platform already provides.
6. **Cross-cutting concerns.** Privacy and security: what data leaves, who keeps it, for how long, and everyone who bears the cost, including people outside the reader and the user. A remedy must reach the harm it answers. Then cost, limits, compatibility, and how success is measured: the number, its threshold or how the threshold will be set, and the limits of the measurement. Name each existing rule or document the change alters and say it must be updated.
7. **Rollout and rollback.** The steps to ship, the switch that turns it off, checked in the code or runbooks, and what happens to data already created. If no switch exists, say so and make adding one part of the plan.
8. **Plan.** Milestones in build order. Each can land and be verified on its own, and says what proves it done. Label estimates.
9. **Open questions.** The decisions the reader owns, numbered. Each is a question, the answer you recommend, and the real reason; if the only reason is convenience, say so. Do not list a question the text already settled. The status block's start condition must match this list. End here, with no summary.

## Architecture structure

1. **Status block and summary.** Status: describes the code as of a date or commit. Then the rule the system keeps and how it keeps it.
2. **System overview.** One diagram or numbered flow of the components and the data between them, with trust boundaries shown.
3. **Components.** Each one's job, what it owns, and how others reach it, with code links.
4. **The rules it keeps.** Each rule, the code that enforces it, and what would break it.
5. **Failure and operations.** What breaks, what the user sees, and how to recover.
6. **Where it is weak.** Known gaps, each with its consequence.
7. **Decision log.** Optional: past decisions that still constrain the design, one line each with a link.

## Detail documents in a design doc

Keep the design in the main document down to the level a reviewer needs to spot a wrong choice: user-visible behavior, the flow, data model changes, interface shapes, and failure handling. Move exhaustive reference to detail documents: the full prompt text, every field of a schema, a step-by-step code walkthrough.

## Length

A small feature runs one to three pages; a new system can run longer. Give the Design section about half the budget, and Context and Alternatives together no more than a quarter. Code blocks, tables, and diagrams do not count toward the budget, but each one must be read by the text around it.

## Check

1. Read only the summary. Does it give the decision, the scope cut, and the main cost?
2. Could an engineer start building from the Design section alone, apart from the open questions? If not, find what is missing: a state, a data shape, or a failure.
3. Is there one worked example end to end?
4. Does every non-obvious choice have its reason and its price beside it, and every chosen number its derivation? Does each remedy fix the cause the text diagnosed, not a nearby one?
5. For a proposal, find each of these: status block, scope cut, a blocker for each alternative, everyone who bears the cost, the rules it changes, the success measure, the rollback, a plan with verifiable milestones, and numbered decisions with recommendations. Add any that is missing, or say in the text that it is unknown.
6. Is there any history, dated status note, or superseded text in the body? Move it to the decision log or cut it.
