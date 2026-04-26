## 1. Skill Anatomy

This chapter is finalized and should not be revised unless the underlying definition of a skill changes.

A skill is a **portable workflow package**.

It teaches a host agent how to perform a reusable capability: when to start, what procedure to follow, what decisions to make, what references to read, what scripts to run, and what artifact to produce. A skill may feel agentic when activated because it can drive the host through a complete workflow.

But a skill is not itself a runtime. The host agent owns the live conversation, model choice, tool permissions, memory, turn protocol, approval policy, execution boundary, and final responsibility for the answer.

### Core Distinction

| Concept | Owns Runtime? | What It Does |
|---|---:|---|
| **Skill** | No | Packages reusable workflow knowledge, references, scripts, templates, and optional usage guidance. |
| **Agent** | Yes | Executes work in a live runtime with a model, tools, permissions, memory, and responsibility for output. |
| **Orchestrator** | Usually | Coordinates multi-step or multi-agent work. It can be implemented as an agent, Python code, or another runtime. |

The simplest rule:

> An agent executes. A skill instructs.

This does not mean skills are passive reference material. A skill can kick off a workflow, guide a multi-step procedure, call for scripts, and describe delegation patterns. The distinction is authority: the agent decides what is actually allowed and is responsible for execution.

### What a Skill Is

A skill can contain:

- A procedure or workflow.
- Decision rules.
- Domain knowledge.
- Tool-use instructions.
- Script entrypoints.
- Templates, schemas, examples, and output formats.
- References to load only when needed.
- Optional guidance for how a stronger host agent could delegate parts of the work.

Good skills are portable across host agents because they avoid assuming one specific runtime unless that limitation is explicit.

### What a Skill Is Not

A skill does not own:

- The active model.
- The tool sandbox.
- Permission to use tools.
- Permission to spawn agents.
- The turn loop.
- Memory.
- Invocation rights.
- Final output responsibility.

Those are runtime concerns. They belong to agents, orchestrators, host applications, or platform policy.

### Agentic Skills

Some skills are intentionally agentic. They do not merely provide facts; they teach a host agent how to run a complete procedure.

Examples:

- A research skill can teach source discovery, source triage, evidence extraction, contradiction checks, and report synthesis.
- A code review skill can teach a review loop, severity ranking, patch inspection, and final finding format.
- A document skill can teach intake, transformation, rendering, visual QA, and export.
- An occupator skill can teach how to inspect a space, identify work surfaces, apply occupation rules, and emit structured claims.

This is valid skill design. The boundary is that the skill describes the workflow; the host agent executes it.

A useful wording pattern:

```markdown
When this skill is activated, guide the host agent through the following workflow...
```

Avoid wording that makes the skill sound like it directly owns the runtime:

```markdown
This skill spawns three agents...
This skill uses model X...
This skill grants access to tool Y...
```

Prefer:

```markdown
If the host agent supports delegation, it may assign source collection, verification, and synthesis to separate workers.
```

### Canonical Tree

```text
my-skill/
  SKILL.md              # required: frontmatter + activation instructions
  scripts/              # optional: executable entrypoints invoked by SKILL.md
    run_analysis.py
    lib/                # optional: internal helpers used by scripts
      normalizer.py
  references/           # optional: long-form material loaded on demand
    domain-glossary.md
    api-conventions.md
  assets/               # optional: static resources used by the workflow
    report-template.md
    schema.json
  requirements.txt      # optional: skill-local Python deps when scripts need them
  tests/                # optional: author-side validation, not runtime instructions
    fixtures/
    test_run_analysis.py
```

The published skill package should be self-contained. Source repositories may use shared fragments or build-time composition, but the installed skill should not require runtime reads outside its own directory unless the skill explicitly documents that dependency.

### SKILL.md

`SKILL.md` is the skill's entrypoint. It has two jobs:

1. Tell the host when the skill should activate.
2. Give the host enough workflow guidance to start correctly and discover the rest of the skill's resources.

Keep `SKILL.md` short, procedural, and action-oriented. It should be an index plus the essential operating instructions, not a dumping ground for every reference detail.

### Frontmatter

Use standard Agent Skills frontmatter. At minimum, every skill needs:

```yaml
---
name: source-triage
description: Use this skill to evaluate source credibility, extract evidence, and organize citations for research workflows.
---
```

Frontmatter should stay small because hosts use it for discovery and routing. The `description` is especially important: it should say both what the skill does and when to use it.

Good description shape:

```yaml
description: Use this skill when the user needs to compare conflicting sources, extract evidence, and produce a citation-backed synthesis.
```

Weak description shape:

```yaml
description: Helps with research.
```

### Private Metadata

Private metadata is acceptable when needed for packaging, indexing, or authoring workflows, but it should not turn the skill into a runtime definition.

Reasonable:

```yaml
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: research
  pionless.suggests-delegation: "source-collection verification synthesis"
```

Avoid:

```yaml
metadata:
  pionless.spawns-agents: "research-worker research-verifier"
  pionless.model: "gpt-5.4"
  pionless.allowed-runtime-tools: "shell browser spawn-agent"
```

Why: those fields imply runtime authority. A skill may suggest a delegation pattern, but an agent or orchestrator owns the authoritative spawn topology.

### Tool Guidance

Skills may describe tool usage, but they do not grant tool permissions.

Valid:

```markdown
If shell access is available, run `python scripts/extract_claims.py INPUT.md` to produce structured claims.
If shell access is unavailable, manually extract the claims using the schema in `assets/claims.schema.json`.
```

Invalid:

```markdown
This skill is allowed to run shell commands.
```

The host runtime decides whether a tool exists, whether it is permitted, and whether approval is required.

### Progressive Disclosure

Design every skill around progressive disclosure:

| Layer | What Loads | Purpose |
|---|---|---|
| **Metadata** | `name` + `description` | Lets the host discover and route the skill. |
| **Instructions** | `SKILL.md` body | Gives the essential workflow and resource map. |
| **Resources** | `scripts/`, `references/`, `assets/` | Loaded or executed only when needed. |

Rule of thumb:

> If the host only needs a detail in a specific branch of the workflow, move it out of `SKILL.md` and point to it.

Examples:

```markdown
For SEC-specific source rules, read `references/sec-filings.md`.
For medical-source grading, read `references/medical-evidence.md`.
For final output, use `assets/report-template.md`.
```

### Resource References

Paths referenced from `SKILL.md` should be relative to the skill root and should point to stable, shallow entrypoints:

```markdown
Read `references/domain-glossary.md`.
Run `python scripts/run_analysis.py input.json`.
Use `assets/report-template.md`.
```

Internal implementation files may be nested, such as `scripts/lib/normalizer.py`, but `SKILL.md` should usually reference the public entrypoint instead of internal helpers.

Avoid:

- Absolute paths.
- Runtime dependencies on files outside the skill directory.
- Deep reference chains where `SKILL.md` points to a file that points to another file that points to another file.
- Duplicate explanations spread across `SKILL.md` and references.

### What Does Not Belong In A Skill Folder

Do not put these in a skill package:

- Agent definitions.
- Orchestrator definitions.
- Per-platform copies of the same `SKILL.md`.
- Generated build artifacts.
- Runtime cache files.
- Unrelated documentation.
- A second `SKILL.md`.
- Hidden policy that changes the host agent's runtime authority.

If the package needs another runtime, that runtime should be modeled as an agent, orchestrator, tool, or host integration, not as a hidden skill behavior.

### Cross-Platform Principle

The skill package should be format-portable. Platform differences should live in packaging, installation, or adapter layers, not in divergent versions of the skill's core instructions.

Good:

```text
same skill package -> installed into host-specific skill directory
```

Bad:

```text
source-triage-for-codex/
source-triage-for-claude/
source-triage-for-gemini/
```

If a platform-specific note is unavoidable, keep it explicit and isolated:

```markdown
If the host does not support script execution, follow the manual fallback in `references/manual-workflow.md`.
```

### Final Definition

A skill is a portable workflow package that can make a host agent more capable.

It may be agentic: it can initiate a workflow, guide decisions, invoke scripts, define artifacts, and suggest delegation patterns.

It is not an agent: it does not own the model, tools, memory, permissions, turn loop, execution boundary, or final responsibility.

This boundary lets the same skill be reused by many agents. A lightweight agent can apply the skill manually; a stronger orchestrator can apply the same skill with tools, workers, validation, and richer runtime support.
