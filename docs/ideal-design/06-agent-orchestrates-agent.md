## 6. Agent-Orchestrates-Agent

When an orchestrator agent spawns worker agents, three structural options exist:

| Option | Layout | Verdict |
|---|---|---|
| **Worker as child of orchestrator** | `agents/orchestrator/workers/worker.md` | Reject. Couples the worker to one orchestrator; if a second orchestrator wants to use it, you either duplicate or hoist. |
| **Worker as sibling of orchestrator** | `agents/orchestrator.md`, `agents/worker.md` | Accept. Both are agents; both live in `agents/`. |
| **Workers in a separate pool** | `agents/orchestrators/`, `agents/workers/` | Reject. The orchestrator/worker distinction is a relationship, not a type — an agent can be both depending on context. |

### Recommendation: sibling

All agents live as siblings under `src/agents/`. Orchestration is expressed in frontmatter, not in folder structure:

```yaml
---
name: research-orchestrator
description: Spawns parallel research-worker subagents, merges their outputs into a single report.
platforms: [claude-code, codex]
allowed-tools: [Bash, Read, Write, Task]
spawns-agents: [research-worker]
---
```

The `spawns-agents` field is the source of truth for orchestration relationships. The build can:

1. Validate that every agent listed in `spawns-agents` exists.
2. Generate a dependency graph for documentation.
3. Detect cycles.
4. Ensure the orchestrator's allowed-tools includes the tool used to invoke subagents (e.g., `Task`).

If an orchestrator's worker is so private that it must never be called by anyone else, encode that with `invokable-by: [agent:research-orchestrator]` in the worker's frontmatter rather than by hiding it in a subfolder.
