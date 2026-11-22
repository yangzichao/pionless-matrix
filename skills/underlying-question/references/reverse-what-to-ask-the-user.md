# Reverse: what the assistant should ask the user

The other three directions look for the question the user has not asked. This one looks for the questions the assistant has not asked. The sign is that the answers so far rest on guesses about things only the user knows: their goal, constraints, taste, audience, deadline. Better answers will not fix that; asking will.

## Procedure

1. **Find the guesses.** Reread your own recent answers. For each, note the assumption it rests on that the user never stated ("I assumed this is for a public audience", "I assumed you can change the schema"). Also note any point where the user pushed back or asked for another round on the same thing; repeated rounds often mean a criterion was never asked for.

2. **Remove the facts.** If an assumption is a fact you can check yourself (a file, a config, a schema, a doc, a quick search), check it now and drop it from the list. The user should only be asked what only the user can answer.

3. **Turn each remaining guess into a question.** Make it concrete and give your best guess as the recommended answer, so the user can reply "yes". Offer named options where they exist.

4. **Order by dependency.** Ask first what changes the other questions. Keep the list to what would change your answer; drop the rest.

## Output shape

1. **What you have been assuming.** One or two sentences, plainly: "My answers so far assumed X and Y; you never said either."
2. **The questions, numbered.** Each with your recommended answer.
3. **Ask the first round only.** The questions that do not depend on unanswered ones. Wait for the answers before going on.

This is not an open-ended interview. Stop as soon as you can give a much better answer than before. If the user needs every decision in a plan settled one by one, call the skill named grilling if it is available.

## Examples

### Naming a skill

The user asked for a skill name three times ("what should it be called", "how about meta-question?", "is there a better name?"), and each time the assistant offered new candidates.

- **Assumption:** that the name must help the host route to the skill. In fact routing reads the description; only the user reads the name.
- **Question the assistant should have asked:** "Who is the name for: you browsing the repo and typing it as a command, or something else? Recommended: you; so the test is whether you'd recognise it in a month."
- **Effect:** one question replaces three rounds of candidates.

### "Optimize this SQL query"

- **Facts to check yourself, not ask:** the schema, existing indexes, the query plan (run EXPLAIN if you can), the database version.
- **Questions only the user can answer:**
  1. What counts as fast enough? (Recommended: under 100 ms at today's data size.)
  2. Can the table structure change, or only the query?
  3. Is this query run once a day or on every page load?

### "Write me a resignation letter"

- **Questions only the user can answer:**
  1. Do you want to keep a good relationship with this manager? (Recommended: yes.)
  2. Do you want to give a reason, or keep it to the facts?
  3. What is your last working day?

### Nothing to ask

The user asked for a unit conversion with all values given.

- **Finding:** no hidden assumption. Answer it.
