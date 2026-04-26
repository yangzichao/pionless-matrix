## 3. Top-Level Layout

Three patterns are viable for organizing skills, agents, and shared fragments at the repo root.

### Pattern A: Flat siblings

```
src/
  skills/
    deep-research/
    code-review/
    test-generation/
  agents/
    research-worker.md
    research-orchestrator/
    test-writer.md
  shared/
    fragments/
    templates/
```

| Pros | Cons |
|---|---|
| Skills and agents are independently discoverable. | Cross-cutting domains (e.g., "research") spread across two trees. |
| Build can target `src/skills/` and `src/agents/` independently. | Ownership/domain grouping is invisible. |
| Matches the Anthropic runtime mental model (skills and agents are different concepts). | |

### Pattern B: Agent-as-skill-component

```
src/
  skills/
    deep-research/
      SKILL.md
      agents/
        research-worker.md
      scripts/
    code-review/
      SKILL.md
      agents/
        critic.md
  shared/
```

| Pros | Cons |
|---|---|
| Co-locates an agent with the skill that owns it. | Breaks down the moment two skills share an agent. |
| Single ownership boundary per skill. | Agents that exist independently of any skill have no home. |
| | Forces a shared agent to be either duplicated or hoisted, creating two conventions. |

### Pattern C: Domain-grouped

```
src/
  research/
    skills/
      deep-research/
    agents/
      research-worker.md
      research-orchestrator/
  testing/
    skills/
      test-generation/
    agents/
      test-writer.md
  shared/
```

| Pros | Cons |
|---|---|
| Groups by business domain; ownership is obvious. | Requires a domain taxonomy up front; refactors are painful when domains shift. |
| Scales to large repos. | Cross-domain agents (e.g., a generic "summarizer") have no clear home. |
| | Duplicates the `skills/` and `agents/` convention inside every domain. |

### Recommendation: Pattern A (flat siblings)

Pattern A is the recommendation. Skills and agents are distinct runtime concepts and deserve sibling top-level trees; co-locating an agent inside a skill (B) breaks as soon as two skills share that agent, and domain grouping (C) forces a taxonomy decision before the repo has earned one. Flat siblings stay correct as the project grows and require no migration when a worker agent becomes shared.

### Full top-level layout (recommended)

```
repo-root/
  src/
    skills/             # source skills, one folder per skill
    agents/             # source agents, mostly files, occasionally folders
    shared/             # prompt fragments, templates, schemas reused across skills/agents
  build/
    build.sh            # the only entry point that mutates dist/
    include-expander.py # resolves <!-- include: --> directives
    manifest-router.py  # reads platforms: frontmatter and routes outputs
  dist/                 # GENERATED, gitignored or committed-but-never-edited
    claude-code/
    codex/
  docs/                 # design notes, contributor guide
  tests/                # repo-level integration tests
  manifest.yaml         # declares platform targets, build outputs, version
```

`src/` is the only place humans edit. `build/` is the only place that writes to `dist/`. `dist/` is the only place runtimes read from.
