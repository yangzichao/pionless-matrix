# Length budget

Write every text against a number, not against the word "concise". Asking a model to be brief rarely brings the text down to the target length; a fixed budget that the writer counts against does. The unit is the slide: one claim per paragraph, with only the evidence that claim needs, as in an assertion-evidence slide where the headline is a full-sentence claim and the body only supports it.

## The budgets

- **Paragraph: one claim sentence plus at most three supporting sentences.** The claim sentence is the paragraph's first sentence, the one that appears in the logic skeleton. A numbered or bulleted list inside a paragraph counts one sentence per item, and each item is one full sentence. In a guided document, the one plain question that opens a step does not count; the claim sentence is the first sentence after it.
- **Document: the number of paragraphs in the approved logic skeleton.** Write the budget in the skeleton's first line, for example `Budget: 6 paragraphs, about 450 words`. Estimate words as paragraphs times 75. For Chinese, estimate characters as paragraphs times 200.
- **Document with a target length from the user: allocate first, then count paragraphs.** Split the target across sections before writing any paragraph lines, so the total is within 10% of the target. Each section then gets its words divided by 75, or its Chinese characters divided by 200, rounded, as its paragraph count. A section that cannot make its point in its share is a sign the main claim is too broad; say so instead of stretching the total.
- **Long document: the planned count must earn itself.** The budget only stops overruns; it does not stop a plan that is too big from the start. Every planned paragraph must pass the cut test in the skeleton check before the user sees the skeleton.
- **Chat reply: at most 150 English words, or 300 Chinese characters,** in at most three paragraphs. Go longer only when the user asks for detail or the reply carries a document they asked for.

Sentences stay complete. The budget comes from cutting, not from dropping articles, verbs, or relation words such as because and therefore.

Code blocks, equations, tables, figures, and quoted source text do not count as sentences or words. Each one needs one prose sentence that says what it shows, and that sentence counts.

## Count

Count twice: after drafting, and again after fixing the logic critic's findings, because fixes usually add text.

1. Count the sentences in each paragraph. A paragraph over four sentences is over budget.
2. Count the paragraphs. More than the skeleton planned is over budget.
3. Count the words, or characters for Chinese. More than the budget by over 20% is over budget. With a user-given target, the limit is 10%, and each section is checked against its own share.

## Fix an overrun

Try these in order:

1. **Cut.** Remove the supporting sentence that adds least to the claim: background the reader has, a second example of the same point, a sentence that restates the claim.
2. **Merge.** Two supporting sentences that make one point become one sentence.
3. **Split.** If every sentence is needed, the paragraph holds two claims. Make two paragraphs, give each its own claim sentence, and add the new line to the skeleton.

Splitting adds a paragraph, so the document budget grows by one. Tell the user when the final paragraph count differs from the approved skeleton.
