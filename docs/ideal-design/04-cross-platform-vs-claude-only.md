## 4. Cross-Platform vs Claude-Only

> **Status: passed Codex review.** This version is accepted as the current working decision.

The source layer should be **Claude-first**, not split into Claude and Codex trees.

```text
src/
  skills/
    <skill-name>/
      SKILL.md
      scripts/
      references/
      assets/
  agents/
    <agent-name>.md
```

Do not create `src/claude-only/`, `src/codex/`, or `src/cross-platform/`. Cross-platform differences belong in packaging and projection, not in duplicated source trees.

### Skills

Skills should be authored once and reused across runtimes.

The portable part of a skill is its actual workflow content:

- `SKILL.md`
- `scripts/`
- `references/`
- `assets/`

That content should be written against host capabilities, not one named runtime. So for skills, cross-platform handling is mainly a packaging concern.

### Agents

Agents should also be authored once, but they are not merely copied.

A skill is a workflow package. An agent is a runtime definition. Because runtime definitions differ across hosts, agent source stays Claude-first in `src/agents/*.md`, then gets translated into the target runtime's agent format.

So the rule is:

- **skills are shared**
- **agents are translated**

### What Not To Do

Do not solve this with:

- per-platform source trees
- per-asset `platforms:` tags
- duplicated skill bodies such as `deep-research-for-claude` and `deep-research-for-codex`
- source-level routing logic that classifies each asset as Claude-only or cross-platform

### Recommendation

The repository should be a **Claude-first source system with platform-specific projections**:

1. Author skills once under `src/skills/`.
2. Reuse skill content across Claude Code and Codex.
3. Author agents once under `src/agents/` in Claude-first markdown form.
4. Translate agent definitions into each target runtime's required format.
5. Keep platform differences in packaging, projection, and small metadata adapters.
