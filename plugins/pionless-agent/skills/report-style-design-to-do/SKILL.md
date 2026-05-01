---
name: report-style-design-to-do
description: Use for engineering design + implementation roadmap reports — key decisions with rationale, high-level architecture with selectively cited critical low-level details, then a topologically-sorted task list with explicit parallelism fan-outs. Built for engineers, not stakeholders.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: writing-style
---

# Report Style — Design-to-Do

A code-oriented design document fused with an actionable implementation plan. Built for an engineer who needs to know *why we chose this shape*, *what the critical implementation details are*, and *what to do first*. **Not** a general business-design or stakeholder-design doc.

## When this style fits

- "How should we build X?" / "Design Y for me." / "Plan the implementation of Z."
- Engineering design discussions where the deliverable is a code-implementation roadmap.
- Refactor planning: scope, ordering, parallelism, blockers.
- Migration kickoff or new-feature kickoff where the next step is engineering work.

## Tone

- Engineering voice: terse, decision-driven, claims-with-rationale.
- High-level by default; drill into *only* the low-level details that lock in a decision or unblock a task.
- Show explicit alternatives considered for any non-trivial decision; never accept the first option silently.
- "We chose X because Y, not Z" framing for key decisions.

## Section template

````markdown
# {Design Subject}

## Goal

{1–2 sentences. What the design needs to achieve. Includes the success condition for the implementation.}

## Non-Goals

{What this design deliberately does not address. Out-of-scope items the reader might otherwise expect to see.}

## Key Decisions

### {Decision 1: Short imperative title}

- **Decision:** {what was chosen, in one sentence}
- **Why:** {evidence + reasoning, with a citation `[N]` where the rationale comes from a primary source}
- **Alternatives considered:** {1–3 alternatives, each with a one-line trade-off}
- **Critical detail:** {only when a specific low-level fact locks the decision — e.g., an API guarantee, a measured latency, a concurrency invariant. Omit otherwise.}

### {Decision 2}

{...}

## High-Level Architecture

{A Mermaid architecture diagram + prose + structured list. Engineering reports benefit most from a visual — render the component graph as a fenced ```mermaid block (flowchart works well for component-and-data-flow; sequence for interaction-heavy systems). Follow with 1–2 paragraphs describing components and interactions, then a labelled list. ASCII diagrams allowed but discouraged.}

- **{Component A}** — {purpose} — {key interface}
- **{Component B}** — {purpose} — {key interface}

## Critical Implementation Details

{Only the low-level details engineers can't infer from the high-level architecture. Examples: a specific data-format invariant, a serialization gotcha, a known platform limitation. One subsection per detail. If empty, omit — most low-level detail belongs in the code, not here.}

## Task Plan (topologically sorted)

{Implementation broken into discrete tasks ordered by dependency. Indent represents the dependency tree: tasks at the same indent under the same parent can run in parallel once the parent completes.}

```text
T1. {root task — must complete first}
    T2. {depends on T1}
    T3. {depends on T1; can run parallel to T2}
        T4. {depends on T3}
T5. {independent of T1; can start anytime}
```

For each task, record:

- **{T1 — Task name}**
  - Effort: {S / M / L}
  - Owner: {if known}
  - Unblocks: {which downstream tasks become eligible}
  - Verification: {how the task is known to be done}

## Open Questions

{Unresolved questions whose answers could change the design or the task plan.}

## References
````

## Length norm

1500–4000 words. The Task Plan can run long; everything else should stay tight.

## Anti-patterns

- **General design-doc shape.** This is not a stakeholder-facing narrative. Skip "Background", "Problem Statement", "Stakeholders", "Success Metrics". Engineers reading this want decisions and a task list, not framing.
- **Exhaustive low-level detail.** If you find yourself documenting class hierarchies or method signatures, that belongs in the code or inline comments, not in the design doc. Critical Implementation Details is for the *non-obvious* low-level facts only.
- **Decisions without alternatives.** Every Key Decision must list at least one rejected alternative. A decision with no alternatives is a tell that the writer didn't think hard enough.
- **Flat task list.** A bullet list with no dependency structure is not a plan — it's a wishlist. The topological structure *is* the value of this section.
- **Unverifiable tasks.** Every task needs a verification clause. "Implement Y" is not a task; "Implement Y, verified by Z's tests passing" is.
- **Hidden parallelism.** If two tasks can run in parallel, say so explicitly via the indentation. Implicit parallelism gets lost.
- **Burying the decision.** Key Decisions come right after Goal/Non-Goals. The reader should be able to skim them and understand the design without reading the rest.
- **Recommendation theatre.** This is not a position paper. Don't argue *whether* to build the thing — that decision was made upstream. Document *what* and *how*.
