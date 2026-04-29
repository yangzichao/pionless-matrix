# Plan Board

Turn the research contract into a compact task board.

## Required fields

- The main question.
- 3–7 subquestions.
- Priority for each subquestion (high / med / low).
- Expected evidence type (primary doc, benchmark, market data, regulatory filing, etc.).
- Blocking dependencies between subquestions.
- Execution mode (parallel via worker spawn when host supports it; sequential otherwise).

## Selecting the next task

Pick by **expected information gain**, not convenience. Prefer tasks that:

- close a major knowledge gap,
- test a risky assumption,
- add a new primary-source angle,
- resolve a contradiction.

## Updating the board

The plan board is part of the persisted workspace file. Update it after every step:

- mark completed subquestions with their finding and confidence,
- promote follow-up tasks discovered during investigation,
- demote tasks that turned out to be lower-value than predicted.

The board is alive; it is not a one-shot plan.

## Subquestion range

Aim for **3–7 subquestions**. Fewer means the question is too narrow for this skill. More means scope creep — split into multiple research jobs.
