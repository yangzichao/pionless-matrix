# Guided document

A guided document leads the reader to the main claim step by step, instead of stating it first. Use it when the reader cannot understand the claim yet: a tutorial, a concept explainer, a teaching article, or the "how it works" part of a larger document written for newcomers. Do not use it for decisions, design docs, status, or reviews; those readers need the answer first.

The logic is as strict as in an answer-first document. The order changes; the rules for claims, evidence, paragraph types, and the length budget do not.

## Shape

1. **Opening: the question and the payoff.** State the question the reader can recognise, as a concrete problem, a surprising result, or a task they cannot do yet. Then say what they will be able to do or explain by the end. Do not give the answer here. One paragraph.
2. **Steps.** Each step answers exactly one question, and that question comes from the step before it. A step is one paragraph, or one section in a long document. Order the steps by prerequisite: anything a step relies on was taught in an earlier step.
3. **Concrete before abstract.** Inside the arc, show a worked example before the general rule, and state the rule only after the reader has seen it work. When a formal version follows, tie each symbol or term back to the example: "the λ in the formula is the rate we measured in step 2".
4. **The likely wrong conclusion.** Before the end, close the misunderstanding a reader is most likely to leave with: "It looks like X; it is Y, because ...".
5. **Ending: the main claim, stated.** Answer the opening question in one sentence. This sentence is the main claim from the skeleton, and it must appear in words, not be left for the reader to infer. Add the reader's next action if there is one.

## Rules

- **Real questions only.** Every step answers a question this reader would actually ask at that point. Do not invent a question to create suspense.
- **One question per step, asked plainly.** A step may open by stating its question once, as a direct question or as a statement ("The next problem is where the jitter comes from."). Never stack questions, and never ask one you answer in the same sentence.
- **Every step is needed.** Remove a step in your head. If no later step breaks, cut it.
- **Bridge, do not recap.** In a long document, after every three or four steps, one sentence may state what is now established and which question remains. It must name the next question; a recap that only repeats is cut.
- **Mark invented examples.** An example you made up to illustrate is labelled as an example, not presented as evidence.
- **Build pictures in stages.** For a mechanism with three or more parts, add one part per step. A full diagram up front is reference material, not teaching.

## Skeleton

The skeleton uses the usual logic skeleton format, with three changes:

- The second line is `Shape: guided`.
- The first numbered line is the opening: `1. [answer] Question: <the opening question>`.
- Each step line starts with the question it answers: `3. [explanation] (then 2) Q: <question> → <point>`.

The main claim still goes in the skeleton's first line, so the user can check where the document is heading. The reader sees it at the end.

## Check

1. Read the opening question, then the last paragraph's first sentence. Does the last one answer the first?
2. Read each step's question. Does it arise from the step before it?
3. Is any term used before the step that teaches it?
