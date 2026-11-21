# Delegation Patterns

This skill is built around an orchestrator plus four roles. Whether the roles run as real subagents depends on the host. The dispatch shape (fresh context, full role file, then the task card; otherwise a separate pass by you) is in SKILL.md *Roles and dispatch* and is the same for every pattern below.

## Patterns

### Parallel subquestion workers

When the plan board has independent subquestions, dispatch one worker per subquestion with `roles/worker.md`. Start them all at once if your host allows parallel subagents; otherwise run them one after another. Each returns structured findings.

Use when subquestions share no evidence and order does not matter.

### Contradiction-seeking verifier

When a working thesis or a load-bearing finding is in place, dispatch the verifier with `roles/verifier.md` and `Verification type: contradiction-seeking`, tasked with **disproving** it. It returns counter-evidence or confirms none was found, which feeds the next iteration.

Use when the thesis is decision-critical, or when sources have been mostly aligned (a sign that contradiction-seeking has been weak).

### Domain-specialist routing

If subquestions cross domains (for example legal + technical), give each worker card the domain context it needs: the authoritative source types for that domain, key terms, and seed queries aimed at domain sources. The worker cannot see anything outside its card.

Use when domain conventions diverge enough that one generic card cannot serve both.

### Drafter → writer (terminal)

When the completion gate passes, dispatch **two roles in sequence**:

1. Drafter (`roles/drafter.md`) — reads the workspace, synthesizes a substantively-complete draft with inline `[Title](url)` citations, returns draft + source list.
2. Writer (`roles/writer.md`) — takes the draft, the source list, and the pasted style guide, and writes the final report file.

Synthesis lives in the drafter; craft lives in the writer. You do not produce long-form prose. The split keeps your context on planning and judgment, and lets a cheaper model carry the long output when the host lets you choose one.

Use on every run. Card formats and failure branches are in `references/loop-protocol.md` under *Drafting handoff*. Without subagents, you run both as separate passes; do not merge them into one.

## Worker contract

Every worker returns, in the exact text format defined in `roles/worker.md`:

- findings, each with source URL and confidence,
- contradictions between sources,
- unresolved questions,
- an overall status and confidence,
- recommended follow-ups, including whether the result changes the working thesis.

## Host responsibilities

The host decides:

- whether subagents exist at all,
- how many run and at what concurrency,
- which model each uses,
- which tools each is permitted.

This skill states only what each role needs (SKILL.md *Roles and dispatch*). You own merging role outputs into the workspace.

## Sequential fallback

If you cannot start subagents, run the same role passes yourself, one after another. Rebuild state from the workspace file between passes (`references/workspace-reconstruction.md`) so each pass starts from compact state, not the full transcript. Work only from the task card in each pass. Parallelism is lost, and the verifier and writer are less independent than designed; say so once in the final reply.
