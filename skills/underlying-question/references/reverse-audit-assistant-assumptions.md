# Reverse: audit the assistant's assumptions

The other three directions check the user's questions. This one checks the assistant's answers. It looks back over answers already given and finds what they quietly assumed about things only the user knows: their goal, audience, constraints, taste, priorities. The user's questions may have been perfectly concrete; the gap is in what the assistant never asked.

This is a look back, not a check before starting. If a question is too vague to start on, that is Up.

## Procedure

1. **Reread your own answers.** Go through the answers you gave in the material, especially the ones that made a choice for the user (a design, a default, a wording, a recommendation).

2. **Find the assumptions.** For each choice, write the assumption it rests on that the user never stated ("I assumed this is for a public audience", "I assumed it should run automatically"). Watch for places where the user pushed back or asked for another round on the same thing; repeated rounds often mean a criterion was never asked for.

3. **Remove the facts.** If an assumption is a fact you can check yourself (a file, a config, a schema, a doc), check it now and drop it from the list. Keep only what only the user can answer.

4. **Keep the ones that matter.** An assumption matters if a different answer would change something you already produced. Drop the rest.

5. **Turn each into a question.** Make it concrete and give your best guess as the recommended answer, so the user can reply "yes". Order by dependency: ask first what changes the other questions.

## Output shape

1. **What you have been assuming.** One or two sentences, plainly: "My answers so far assumed X and Y; you never said either."
2. **What each assumption affected.** One line each: which earlier answer would change.
3. **The questions, numbered,** each with your recommended answer. Ask only those that do not depend on unanswered ones.

Then stop. Revising the earlier answers is a new request.

## Examples

### Naming a skill

The user asked for a skill name three times ("what should it be called", "how about meta-question?", "is there a better name?"), and each time the assistant offered new candidates.

- **Assumption:** that the name must help the host route to the skill. In fact routing reads the description; only the user reads the name.
- **Affected:** every round of candidates was judged on the wrong criterion.
- **Question:** "Who is the name for: you browsing the repo and typing it as a command? Recommended: yes; so the test is whether you'd recognise it in a month."

### A skill's trigger

While writing a skill, the assistant filled its description with broad signals ("when the user asks something too broad", "when the user repeats a question") so it would fire on its own.

- **Assumption:** the user wants it to trigger automatically.
- **Affected:** the description, and how often the skill would interrupt ordinary conversations.
- **Question:** "Should it run only when you ask for it? Recommended: yes, and drop the broad signals."

### Generated code

Over several turns the assistant wrote a data script using pandas, Python 3.12 syntax, and output to CSV.

- **Facts to check yourself, not ask:** the project's Python version and dependencies (read the lockfile or config).
- **Questions only the user can answer:**
  1. Who consumes the output? (Recommended: you, in a spreadsheet; so CSV is fine.)
  2. Will this run once, or on a schedule? (Recommended: once; so no retries or logging.)

### Nothing to audit

The assistant converted units with all values given, and made no choices on the user's behalf.

- **Finding:** no hidden assumption. Say so.
