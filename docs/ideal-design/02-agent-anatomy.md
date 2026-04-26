## 2. Agent Anatomy

An agent is a standalone prompt configuration that can be invoked as a subagent. Unlike a skill, an agent is typically narrower (one job, one output shape) and is intended to be called by another agent or skill rather than by the end user.

### File or folder?

**Default: a single markdown file.** An agent that is just a system prompt plus frontmatter is a file, not a folder. Folders impose cognitive overhead; do not pay that cost without reason.

**Promote to folder when any of these become true:**

1. The agent ships its own scripts (analogous to `scripts/` in a skill).
2. The agent ships its own references or fixtures.
3. The agent has more than one variant (e.g., `strict.md` and `lenient.md`) that share a prompt body.
4. The agent has tests.

### Canonical tree (file form)

```
agents/
  research-worker.md
  code-reviewer.md
  test-writer.md
```

### Canonical tree (folder form)

```
agents/
  research-orchestrator/
    AGENT.md            # required: frontmatter + body, named AGENT.md for symmetry with SKILL.md
    scripts/
      merge-reports.py
    references/
      delegation-patterns.md
    tests/
      test_merge_reports.py
```

### Frontmatter

```yaml
---
name: research-orchestrator
description: Coordinates parallel research-worker subagents and merges their outputs.
platforms: [claude-code, codex]
allowed-tools: [Bash, Read, Write, Task]
spawns-agents: [research-worker]
invokable-by: [skill, agent]      # who is allowed to call this
---
```

### What does NOT go in an agent

- Skill-style on-demand `assets/` — agents output text or structured JSON, not template-filled artifacts. If you need templates, the work is a skill.
- Configuration that varies per invocation — that is the caller's job to supply.
- Cross-agent shared prompt fragments — those go in `shared/` and are included at build time.
