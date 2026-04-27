## 5. Agent-Orchestrates-Agent

**Decision: all agents are siblings under `src/agents/`.** No nesting, no separate pools.

The orchestrator/worker distinction is a *relationship*, not a *type* — the same agent definition may act as orchestrator in one invocation and as worker in another. Encoding that relationship in folder structure (e.g. `agents/orchestrator/workers/worker.md`, or split pools `agents/orchestrators/` vs `agents/workers/`) bakes a transient role into a permanent layout and forces duplication the moment a second orchestrator wants to reuse a worker.

Orchestration topology is therefore expressed in the orchestrator's frontmatter, not in folder structure.

### Naming convention

Two shapes of subagent exist in this layout, distinguished by intent at creation time and by filename pattern.

**Bonded subagent.** Created for one specific *originating context* — its prompt assumes that context's task shape, input format, or output contract. The originating context is either an **orchestrator agent** in `src/agents/` or an **orchestrating skill** in `src/skills/` that drives delegation as part of its workflow (per chapter 01, agentic skills may describe delegation patterns even though the host owns the actual spawn). Filename takes the form `<originating-context>-worker` or `<originating-context>-verifier`.

**Utility subagent.** Created as a self-contained capability — its prompt does not depend on which orchestrator invokes it. Filename is the capability itself (e.g. `code-reviewer`, `web-fetcher`, `claim-checker`); it does not carry the `-worker` or `-verifier` suffix.

| Role | Naming pattern | Example |
|---|---|---|
| Orchestrator agent | `<domain>` | `deep-research` |
| Bonded worker (agent-driven) | `<originating-agent>-worker` | `deep-research-worker` |
| Bonded verifier (agent-driven) | `<originating-agent>-verifier` | `deep-research-verifier` |
| Bonded worker (skill-driven) | `<originating-skill>-worker` | `parallel-fix-worker` |
| Utility subagent | `<capability>` | `code-reviewer` |

**The prefix on a bonded subagent declares provenance, not exclusivity.** `deep-research-worker` is read as "originally built for the `deep-research` orchestrator's flow" — not as "only `deep-research` may invoke it." A second orchestrator is free to include a bonded subagent in its own `Agent(...)` allowlist; the filename simply warns that caller it is reusing a definition tuned for the original context's needs and may need to adapt its inputs accordingly. If the second orchestrator finds the prompt no longer fits, the right move is to fork (create its own bonded copy) rather than rename or hoist the original.

The provenance signal also tells maintainers the converse: when modifying `deep-research-worker`, the originating context's contract is the primary one to honor. Other callers reuse at their own cost.

Two further rules round out the convention:

- Reject generic names like `worker.md` or `verifier.md` with no prefix at all. The `-worker` / `-verifier` suffixes are reserved for the bonded shape and require a `<originating-context>-` prefix that points to a real orchestrator agent or orchestrating skill.
- Do not append `-orchestrator` to the orchestrator filename. The domain name is already its identity; the children's `-worker` / `-verifier` suffixes are what mark the relationship.

### Orchestrators are main-session-only

An orchestrator definition — any agent whose `tools` allowlist contains `Agent(...)` — is launched directly as a specialized main session via `claude --agent <name>`. It must never appear inside another agent's `Agent(...)` allowlist.

The reason is structural: per chapter 02, Claude Code subagents are leaf nodes that cannot spawn further subagents. If an orchestrator were invoked via the `Agent` tool, the spawning capability it depends on would be unavailable in that role — its `Agent(...)` allowlist would silently degrade to a no-op. Orchestration therefore happens only when an agent definition is entered as the top of a session, never as someone else's subagent.

The two postures that together make every agent's role unambiguous:

- An orchestrator declares its allowed children via `tools: Agent(...)`. It does not appear inside any other `Agent(...)` allowlist.
- A leaf — bonded worker, bonded verifier, or utility subagent — declares `disallowedTools: Agent`, confirming it terminates the spawn chain.

### Topology in frontmatter

The orchestrator's frontmatter is the single source of truth for the spawn graph. Everything in the file is interpreted in its main-session role:

```yaml
---
name: deep-research
description: Use when a research task needs parallel decomposition into focused subquestions and synthesis of worker outputs into a unified report.
model: opus
maxTurns: 40
tools: Agent(deep-research-worker, deep-research-verifier), Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch
---
```

Read this as: when launched as a main session, this agent may spawn `deep-research-worker` or `deep-research-verifier` as subagents, and no other agent types. There is no separate `spawns-agents` field — the same `tools` field that gates ordinary tool access also gates subagent spawning, via the `Agent(...)` constructor. The `description` is phrased as a routing hint per chapter 02, so a host deciding whether to launch this orchestrator can match on the "Use when …" form. The worker and verifier filenames follow the naming convention above (`<originating-domain>-worker`, `<originating-domain>-verifier`), so the spawn graph is legible without opening any file.

### Leaf hardening

The leaf side of the topology is encoded with a denylist:

```yaml
disallowedTools: Agent
```

Any leaf definition — bonded worker, bonded verifier, or utility subagent — should declare this so that, even if the file is ever launched as a main session itself, it still cannot spawn anything. The field is what the validation rules below check for.

### Validation invariants

A build step over `src/agents/` should:

1. Verify every agent named inside `Agent(...)` exists.
2. Warn when an agent listed in some orchestrator's `Agent(...)` allowlist does not declare `disallowedTools: Agent` — that leaf could in principle be invoked as a main session itself and create unbounded spawn topologies.
3. **Refuse if an orchestrator (any agent whose `tools` contains `Agent(...)`) is referenced inside another agent's `Agent(...)` allowlist.** Orchestrators are main-session-only; appearing as a subagent silently disables their spawn capability.
4. **Refuse if a filename of the form `<X>-worker` or `<X>-verifier` exists where `<X>` is neither the name of an actual orchestrator agent in `src/agents/` nor the name of an orchestrating skill in `src/skills/`.** The bonded-subagent suffixes are reserved and must point to a real originating context — either an orchestrator agent that names the leaf in its `Agent(...)` allowlist, or an orchestrating skill whose workflow drives delegation to that leaf (per chapter 01, agentic skills may describe delegation patterns, while the host owns the actual spawn). This is a *provenance* check, not an *exclusivity* check: a bonded subagent may legitimately appear in multiple orchestrators' `Agent(...)` allowlists, but its filename must always trace back to the originating context it was first built for.
5. **Refuse if a filename ends in `-worker` or `-verifier` without any prefix** (i.e. a bare `worker.md` or `verifier.md`, or names where the `<X>` segment is empty). Bonded subagents must declare provenance.
6. **Defense-in-depth cycle detection.** Walk the directed graph induced by `Agent(...)` allowlists and refuse any cycle. Under rule (3) this graph cannot contain another orchestrator at all, so it is acyclic by construction; this rule exists as a guard in case rule (3) is ever relaxed or bypassed.
