# Up: one vague question to concrete ones

The user asked a question so broad that any direct answer would be generic advice. The fix is not a deeper question but a short series of concrete ones, each answerable on its own, that together cover what the vague question was after.

## Procedure

1. **Find what makes it vague.** Usually one or more of:
   - **An undefined judgment word.** "Good", "better", "right", "worth it", with no criterion.
   - **No goal.** "How do I get better at English" without saying better for what.
   - **No scope.** "Plan my career" covers ten years and every option.
   - **No current state.** The question skips where the user is now.
   - **No constraint.** Time, money, team, deadline are missing.

2. **Turn each gap into a concrete question.** A concrete question names its object and can be answered in minutes, by a fact, a number, or a choice between named options. "What is peak QPS?" is concrete. "What are your requirements?" is not.

3. **Split facts from decisions.** For each question, ask who can answer it.
   - If you can find the answer yourself (in the code, files, docs, or a quick search), find it now and fill it in. Do not hand it to the user.
   - If only the user can answer (goals, taste, constraints, priorities), it stays on the list. These are the questions you should be asking the user, which is the Reverse direction folded into this one.

4. **Order by dependency.** Put first the questions whose answers change what the later questions should even be. Usually the goal or criterion comes first.

5. **Cut to what matters.** Keep three to seven. If a question would not change the eventual answer, drop it.

## Output shape

1. **Why the question cannot be answered as asked.** One sentence naming the gap ("'good' has no criterion here").
2. **The concrete questions, numbered, in order.** For each one the user must answer, give your recommended or most likely answer, so they can just say yes. Mark the ones you already answered from the material, with the answer.
3. **Ask the first one, or the first round.** Ask only the questions that do not depend on unanswered ones. Wait for the answers before the next round.

When enough is answered, go back and answer the original vague question, now concretely.

## Examples

### "Is this architecture good?"

- **Gap:** "good" has no criterion.
- **Concrete questions:**
  1. What load must it handle: peak requests per second, data size, growth over the next year?
  2. Which failure is unacceptable: losing data, being down for a minute, slow pages?
  3. Who maintains it, and what do they already know?
  4. What changes in the next six months that it must absorb?
- **Facts vs decisions:** load numbers may be in metrics or config; look first. Which failure is unacceptable is the user's call.

### "How should I plan my career?"

- **Gap:** no scope, no goal, no constraint.
- **Concrete questions:**
  1. What is the next real decision you face, and by when (an offer, a review, a move)?
  2. Which part of your current work do you finish with the most energy?
  3. What do you want to be doing in three years: a title, a kind of problem, a place?
  4. What constrains you now: money, city, visa, family?
- **Note:** almost all of these are the user's to answer. Ask question 1 first; it scopes the rest.

### "How do I get better at English?"

- **Gap:** no goal, no current state.
- **Concrete questions:**
  1. Better for what: meetings, papers, interviews, daily life?
  2. Where does it break now: listening, speaking, writing, vocabulary?
  3. How many hours a week can you actually spend?

### Nothing to break down

"How do I undo the last git commit but keep the changes?"

- **Finding:** already concrete. Answer it directly.
