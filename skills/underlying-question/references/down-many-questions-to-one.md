# Down: many questions to one

The user has asked several surface questions that orbit a deeper one they have not put into words. The more precisely you answer each surface question, the less it helps with the deeper one. Find that one question.

There are two inputs:

- **Many questions.** A long discussion where related questions keep coming back.
- **One question.** A single specific question that rests on a premise worth checking, like "Can an irrational number be a denominator?".

## Procedure

1. **List the surface questions.** Write each question or worry in the user's own words, short, with a pointer to where it came from. Include implied ones ("I still don't get why...", "maybe I should just..."). For a single question, list what it takes for granted instead: the terms it uses, the rule it assumes exists, the goal it serves. Keep this list internal unless the user asks for it.

2. **Look for what they share.** Common patterns:
   - **Same question, new words.** Several questions are one question from different angles.
   - **An assumption never examined.** Every question takes the same premise for granted, and the premise is the weak part.
   - **"How" before "whether".** The user asks how to do something while it is still open whether they should. (If the "how" is about a specific solution, the Back direction may fit better.)
   - **A missing criterion.** The user compares options but never says what "better" means for them.
   - **A decision being deferred.** The questions gather information that cannot settle anything, because the blocker is a choice.
   - **A concept never pinned down.** A surface confusion traces to one definition the user never had clearly.
   - **A conflict between two goals.** The questions swing between two aims that cannot both be met.

   Most cases match one or two. Do not force a pattern that is not there.

3. **Draft one to three candidates and test them.** On top of the shared tests in SKILL.md, a Down candidate must **explain**: if the user answered it, most surface questions would be settled or stop mattering. Count them. Keep the strongest; drop the rest.

## Output shape

1. **The question.** One sentence. Lead with it.
2. **Why this one.** The two to four surface questions it explains, quoted briefly, and what links them.
3. **Why it stayed unasked.** Only if the material shows it (for example, every question assumed X). Mark it as your reading.
4. **What changes if it is answered.** Which surface questions dissolve or change shape.
5. **Runner-up.** If a second candidate was close, one line, so the user can say "no, it's that one".

One question, not a list. A list means you have not found it yet.

## Examples

Notice what the good answers share: each underlying question is concrete and can be acted on right away ("the one-sentence contribution" can be written down).

### One question: "Can an irrational number be a denominator?" (无理数能做分母吗？)

- **Underlying question:** Are a fraction and a division the same thing?
- **Pattern:** a concept never pinned down. The question assumes "denominator" carries one rule. As a fraction in the definition of the rationals, numerator and denominator are integers. As a division expression, √2/2 is perfectly valid.
- **Once answered:** the original question dissolves; the answer depends on which of the two you mean.

### Job search

"How do I make this project sound more impactful on my resume?", "How should I answer 'why are you leaving'?", "Is a 20% raise worth switching for?", "Will the reorg on my team affect me?"

- **Underlying question:** Do I want to leave this team, or do I just want a higher price?
- **Pattern:** a decision being deferred. Each question gathers information, but none can settle anything.
- **Once answered:** if the user wants to leave, whether 20% is worth it barely matters. If they only want more pay, the move is to take the offer back and negotiate.

### Writing a paper

"How do I make the intro more compelling?", "Should related work go before or after?", "Should the abstract include numbers?", "A reviewer says the contribution is unclear; how do I respond?"

- **Underlying question:** What is this paper's contribution, in one sentence?
- **Pattern:** a concept never pinned down. All four are symptoms of that missing sentence; the reviewer named it outright.
- **Once answered:** the intro, the abstract, and the rebuttal each become an expansion of that sentence.

### Learning

"Why does attention divide by √d?", "Why subtract the max before softmax?", "What changes if LayerNorm goes before or after the block?"

- **Underlying question:** Why does numerical scale matter so much in training, and what exactly breaks when it goes out of control?
- **Pattern:** the same question in new words. All three tricks keep values in range, to avoid overflow, vanishing gradients, or a saturated softmax.
- **Once answered:** the three stop being separate tricks, and the next one (variance scaling at init, say) can be derived instead of looked up.

### Nothing found

"How do I read a CSV in Python?", "How do I change the font in matplotlib?", "How do I undo a git commit?"

- **Finding:** no deeper question. Three unrelated questions; answer each and say so.
