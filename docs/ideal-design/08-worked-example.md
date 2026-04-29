## 8. Worked Example

This chapter walks through the actual `pionless-matrix` repository as a single worked example. It exists to show how the rules in chapters 01–07 compose, not to introduce new ones. Everything below points back to a finalized chapter; nothing here overrides them.

The example is deliberately not minimal. A toy "one orchestrator, one worker" example would not exercise the most subtle parts of the design — most importantly, the *two* flavors of orchestration that chapter 05 calls out. The repo demonstrates both:

- **Agent-driven orchestration** — `deep-research` (and `deep-research-pro`) is an orchestrator agent file launched as a main session; its `tools: Agent(...)` allowlist is the spawn graph.
- **Skill-driven orchestration** — `parallel-fix` is a skill loaded into a host session; the skill is the playbook, the host is the orchestrator at runtime, and `parallel-fix-worker` is bonded to the skill.

Plus one dual-use agent (`quick-research`) that runs as a standalone main session and is also referenced as a worker capability by other agents.

### Source tree

```text
repo-root/
  CLAUDE.md
  build.sh
  src/
    skills/
      deep-research/
        SKILL.md
        references/                  # plan-board.md, ralph-loop.md, source-policy.md, ...
        assets/                      # report-template.md, workspace-template.md
      deep-research-pro/             # peer skill — content duplicated per ch.03
        SKILL.md
        references/
        assets/
      quick-research/
        SKILL.md
        references/
        assets/
        scripts/                     # ch.06: deterministic helpers invoked via Bash
      parallel-fix/
        SKILL.md
        references/                  # phase-1-scan.md, phase-3-dispatch.md, worker-contract.md, ...
        assets/                      # task-card-template.md, queue-file-template.md
    agents/
      deep-research.md               # orchestrator agent — agent-driven flow
      deep-research-pro.md           # orchestrator agent — agent-driven flow
      deep-research-worker.md        # bonded worker (agent-driven)
      deep-research-verifier.md      # bonded verifier (agent-driven)
      parallel-fix-worker.md         # bonded worker (skill-driven)
      quick-research.md              # standalone main session + reusable as a leaf
  platforms/
    claude-code/.claude-plugin/
    codex/.codex-plugin/
  shared/
    skills/                          # GENERATED — published skills (ch.07)
  dist/
    claude-plugin/                   # GENERATED
    codex-plugin/                    # GENERATED
  plugins/
    pionless-agent/                  # GENERATED — repo-local installable bundle
```

The shape follows chapter 07: `src/skills/` and `src/agents/` as siblings; `platforms/`, `shared/`, `dist/`, `plugins/` as derived outputs outside `src/`.

### Agent-driven orchestration: `deep-research`

The orchestrator is a single agent file. The whole spawn graph lives in its frontmatter.

`src/agents/deep-research.md` (frontmatter only):

```yaml
---
name: deep-research
description: Use when a research task needs plan-board decomposition, parallel evidence gathering via deep-research-worker, claim verification via deep-research-verifier, and synthesis into a citation-backed final report.
model: opus
tools: Agent(deep-research-worker, deep-research-verifier), Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, Skill
skills:
  - deep-research
  - quick-research
---
```

What this demonstrates:

- **ch.02** — single `.md` file, no folder form. Required keys are only `name` and `description`. `model`, `tools`, `skills` are second-class surfaces this orchestrator engages. Tuning knobs (`maxTurns`, `effort`, …) are omitted; defaults suffice.
- **ch.05** — `tools: Agent(deep-research-worker, deep-research-verifier)` is the spawn allowlist. There is no separate `spawns-agents` field. The same `tools` field that gates ordinary tool access also gates subagent spawning.
- **ch.05** — the `description` is a routing hint ("Use when …"), so a host deciding whether to launch this orchestrator can match on it.

The bonded leaves:

```yaml
# src/agents/deep-research-worker.md
---
name: deep-research-worker
description: Use when the deep-research orchestrator needs evidence gathered for one narrow subquestion and returned as structured findings (no synthesis, no spawning).
model: sonnet
disallowedTools: Agent
skills:
  - quick-research
---
```

```yaml
# src/agents/deep-research-verifier.md
---
name: deep-research-verifier
description: Use when the deep-research orchestrator needs a single claim adversarially checked — contradiction-seeking, numeric/date validation, or source cross-reference — and a verdict returned.
model: sonnet
disallowedTools: Agent
skills:
  - quick-research
---
```

Why these names — chapter 05's bonded-subagent rule: the prefix `deep-research-` declares provenance. These leaves were originally built for the `deep-research` flow. `deep-research-pro` reuses them, which the rule explicitly permits ("provenance, not exclusivity"); the filename simply tells maintainers that the contract to honor first is the originating one.

Why `disallowedTools: Agent` — chapter 05's leaf hardening. Even if either leaf is ever launched as a main session itself, it still cannot spawn anything. This is what the validation invariants check for.

### Skill-driven orchestration: `parallel-fix`

The same orchestration *relationship* (one driver, many bonded workers) but the driver is a skill, not an agent. The skill carries the playbook; the host loads the skill and plays the orchestrator role at runtime.

`src/skills/parallel-fix/SKILL.md` (frontmatter only):

```yaml
---
name: parallel-fix
description: Use when the user wants to find and fix many independent code issues in one sweep — scan, pause for user review, then spawn one worker per issue in isolated git worktrees and merge branches back.
metadata:
  pionless.suggests-delegation: "scan-multiple-angles dispatch-per-issue parallel-merge"
---
```

What this demonstrates:

- **ch.01** — a skill carries no `tools`, no `Agent(...)`, no `model`, no `disallowedTools`. The skill body phrases delegation as guidance ("the host should spawn one `parallel-fix-worker` per pending task in an isolated worktree"), and flags the dependency in the optional `pionless.suggests-delegation` metadata defined by chapter 01. Spawn permission lives on the host's frontmatter at runtime, not in the skill.
- **ch.05** — this is the skill-driven variant covered in *Orchestration via skills*. It exists because an orchestrator *agent* is main-session-only and cannot be activated from any host session via skill discovery. A workflow that needs to be triggerable from a slash command in any host has to live in a skill.

The bonded leaf:

```yaml
# src/agents/parallel-fix-worker.md
---
name: parallel-fix-worker
description: Use when the parallel-fix skill needs one reported code issue verified, minimally fixed, and self-checked inside an isolated git worktree, returning structured JSON for the orchestrating host to merge.
model: sonnet
disallowedTools: Agent
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---
```

The naming follows chapter 05's relaxed bonded-prefix rule: `<originating-context>-worker` where the context is allowed to be either an orchestrator agent or an orchestrating skill. Here the context is the `parallel-fix` skill. Anyone reading the filename or the task card immediately knows where the contract is defined.

### Dual-use leaf: `quick-research`

```yaml
# src/agents/quick-research.md
---
name: quick-research
description: Use when a focused question needs a fast single-agent pass with a concise sourced answer — no plan board, no subagent decomposition, one or two retrieval rounds and stop.
model: sonnet
disallowedTools: Agent
skills:
  - quick-research
---
```

`quick-research` is launchable two ways:

1. **Standalone main session** — invoked directly by the user for a single fast lookup. The agent body branches on this case to write a final report file.
2. **Reused as a worker capability** — listed by another agent's frontmatter `skills:` to bring the fast-research playbook into that agent's session.

Both modes are safe because the agent declares `disallowedTools: Agent`. Per chapter 05, this is a hard leaf in either role — it terminates the spawn chain regardless of how it is launched. The filename has no `-worker` / `-verifier` suffix because the agent is utility-shaped (capability-named), not bonded to one originating context.

### Validation invariants on this repo

Walking chapter 05's six invariants against `src/agents/`:

| # | Invariant | Result |
|---|---|---|
| 1 | every name in `Agent(...)` exists | ✓ `deep-research-worker.md`, `deep-research-verifier.md` exist |
| 2 | every leaf in some `Agent(...)` allowlist declares `disallowedTools: Agent` | ✓ both bonded leaves do |
| 3 | no orchestrator referenced inside another's `Agent(...)` allowlist | ✓ `deep-research` and `deep-research-pro` never appear as subagents |
| 4 | bonded `<X>-` traces to a real orchestrator agent or orchestrating skill | ✓ `deep-research-` → orchestrator agent; `parallel-fix-` → skill |
| 5 | no bare `worker.md` or `verifier.md` | ✓ |
| 6 | spawn graph acyclic | ✓ trivially, by (3) |

### What the build produces

`build.sh` (chapter 04 in action — Claude-first source, agents translated, skills shared):

1. **Claude Code agents** — each `src/agents/<name>.md` is copied to `platforms/claude-code/agents/<name>.md` with frontmatter unchanged.
2. **Codex agents** — each `src/agents/<name>.md` is translated: `name` and `description` become TOML keys, the Markdown body becomes `developer_instructions`. Output goes to `platforms/codex/agents/<name>.toml`. Skills referenced via the `skills:` frontmatter list are emitted as `[[skills.config]]` blocks.
3. **Published skills** — `src/skills/<name>/` is copied verbatim to `shared/skills/<name>/`. No include expansion happens because chapter 03 decided against shared fragments; any duplication between `deep-research/` and `deep-research-pro/` is physical.
4. **Plugin bundles** — `dist/claude-plugin/` and `dist/codex-plugin/` are assembled from `platforms/` plus `shared/skills/`. The committed `plugins/pionless-agent/` is the same shape, served as a repo-local installable.

### Where each chapter shows up

| Chapter | Demonstrated by |
|---|---|
| ch.01 — Skill anatomy | `deep-research/`, `deep-research-pro/`, `quick-research/`, `parallel-fix/`. SKILL.md plus `references/` / `assets/` / optional `scripts/`. Skills suggest delegation but own no runtime. |
| ch.02 — Agent anatomy | All six agents are single `.md` files with minimal frontmatter; no folder form. |
| ch.03 — No shared fragments | `deep-research` and `deep-research-pro` carry duplicated reference content. No `<!-- include: -->` markers exist anywhere in source. |
| ch.04 — Claude-first source | All authoring in `src/`. Codex outputs produced by translation in `build.sh`, not by a parallel `src/codex/` tree. |
| ch.05 — Agent-orchestrates-agent | Agent-driven via `deep-research.md`'s `tools: Agent(...)`. Skill-driven via `parallel-fix`'s SKILL.md driving the host. Bonded leaves named after their originating context. |
| ch.06 — Scripts in skills | `quick-research/scripts/` holds Bash-invokable helpers; SKILL.md invokes them so their source never enters context. |
| ch.07 — Top-level layout | `src/skills/` and `src/agents/` as siblings inside one source tree. `platforms/`, `shared/`, `dist/`, `plugins/` as derived outputs outside `src/`. |

### Where this stays correct under evolution

The structure does not need to be re-organized when:

- A second orchestrator wants to reuse `deep-research-worker` — it just adds the worker to its own `Agent(...)` allowlist. The filename's `deep-research-` prefix continues to mark provenance, not exclusivity.
- The `parallel-fix` skill grows a second bonded role — a `parallel-fix-verifier.md` slots in alongside `parallel-fix-worker.md`. The naming convention covers it without changes.
- A genuinely capability-shaped subagent appears — say a `web-fetcher.md` or `claim-checker.md`. It lives flat under `src/agents/` with no `-worker` suffix, per the utility shape in chapter 05.
- A new platform target is added — packaging metadata goes under `platforms/<new-target>/`, the build grows a new translation step, and `src/` is unchanged.

What does require a rename is structural: if `parallel-fix` is ever promoted from skill to agent (for example, to make orchestration launchable as a main session), the bonded worker keeps its name (the skill's name and the agent's name would be the same), but the rest of the orchestration moves from `src/skills/parallel-fix/SKILL.md` into `src/agents/parallel-fix.md`'s `tools: Agent(...)` line. That move is anticipated by chapter 05's two-flavor model — both flavors share the same naming convention precisely so the leaf does not need to change.
