# Delegation Patterns

This skill is built around an orchestrator-worker shape. Whether actual workers are spawned depends on the host runtime.

## Patterns

### Parallel subquestion workers

When the plan board contains independent subquestions, the host may spawn one worker per subquestion. Each worker runs a focused research pass and returns structured findings.

Use when subquestions share no shared evidence and order does not matter.

### Contradiction-seeking verifier

After the orchestrator drafts the evolving report, the host may spawn a verifier worker tasked with **disproving** the current thesis. The verifier returns counter-evidence (or confirms none was found), which feeds back into the next iteration.

Use when the thesis is decision-critical or sources have been mostly aligned (a sign that contradiction-seeking has been weak).

### Domain-specialist routing

If subquestions cross domains (e.g., legal + technical), the host may route each to a worker primed on the relevant references and templates.

Use when domain conventions diverge enough that one prompt cannot serve both.

### Writer dispatch (terminal)

When the completion gate passes, the orchestrator drafts in its own context window and dispatches `deep-research-writer` to produce the final report file. Synthesis stays with the orchestrator; craft (style, math notation, template, file write) belongs to the writer. Dispatch protocol lives in `loop-protocol.md` under *Drafting handoff*.

Use on every successful run. Skip only in degraded mode (host without Agent dispatch), where the orchestrator writes the report directly and flags the degradation to the user.

## Worker contract

Every worker should return:

- findings,
- evidence with provenance (URL, date, source tier),
- unresolved questions,
- confidence level,
- whether the result changes the overall thesis.

Workers should return findings in the structured format defined in `deep-research-worker`'s output contract.

## Host responsibilities

The host owns:

- whether to spawn workers at all,
- how many workers and at what concurrency,
- which model each worker uses,
- which tools each worker is permitted,
- the synthesis step that merges worker outputs.

This skill does not declare any of those.

## Sequential fallback

If the host runtime does not support spawning workers, run the same worker-style passes sequentially in this thread. Use workspace reconstruction between passes to keep context isolated. Quality should not degrade — only parallelism is lost.
