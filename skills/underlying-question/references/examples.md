# Worked examples

Six made-up cases. Each lists the surface questions, the underlying question this skill should find, the pattern from Step 3 that led there, and what changes once it is answered. The last case has no underlying question, on purpose.

Notice what the good answers share: each underlying question is concrete and can be acted on right away ("where is it slow" can be profiled; "the one-sentence contribution" can be written down). That is what the Workable test in Step 4 protects.

## 1. One question: "Can an irrational number be a denominator?" (无理数能做分母吗？)

- **Underlying question:** Are a fraction and a division the same thing?
- **Pattern:** a concept never pinned down. The question assumes "denominator" carries one rule. As a fraction in the definition of the rationals, numerator and denominator are integers. As a division expression, √2/2 is perfectly valid. The question mixes the two.
- **Once answered:** the original question dissolves; the answer depends on which of the two you mean.

## 2. Engineering, four questions in one week

"Redis or Memcached?", "What TTL should the cache use?", "How do I prevent cache stampede?", "Should I add a local second-level cache?"

- **Underlying question:** Where exactly is this endpoint slow?
- **Pattern:** "how" before "whether". All four ask how to cache, assuming caching is the fix. Nobody has profiled it.
- **Once answered:** if the time goes to one SQL query without an index, all four questions are moot.

## 3. Job search

"How do I make this project sound more impactful on my resume?", "How should I answer 'why are you leaving'?", "Is a 20% raise worth switching for?", "Will the reorg on my team affect me?"

- **Underlying question:** Do I want to leave this team, or do I just want a higher price?
- **Pattern:** a decision being deferred. Each question gathers information, but none of it can settle anything; the blocker is a choice not yet made.
- **Once answered:** if the user wants to leave, whether 20% is worth it barely matters. If they only want more pay, the move is to take the offer back and negotiate.

## 4. Writing a paper

"How do I make the intro more compelling?", "Should related work go before or after?", "Should the abstract include numbers?", "A reviewer says the contribution is unclear; how do I respond?"

- **Underlying question:** What is this paper's contribution, in one sentence?
- **Pattern:** a concept never pinned down. All four are symptoms of that missing sentence; the reviewer named it outright.
- **Once answered:** the intro, the abstract, and the rebuttal each become an expansion of that one sentence.

## 5. Learning

"Why does attention divide by √d?", "Why subtract the max before softmax?", "What changes if LayerNorm goes before or after the block?"

- **Underlying question:** Why does numerical scale matter so much in training, and what exactly breaks when it goes out of control?
- **Pattern:** the same question in new words. All three tricks keep values in range, to avoid overflow, vanishing gradients, or a saturated softmax.
- **Once answered:** the three stop being separate tricks to memorize, and the next similar one (variance scaling at init, say) can be derived instead of looked up.

## 6. No underlying question

"How do I read a CSV in Python?", "How do I change the font in matplotlib?", "How do I undo a git commit?"

- **Finding:** these share no deeper question. They are three unrelated questions; answer each on its own and say so.
