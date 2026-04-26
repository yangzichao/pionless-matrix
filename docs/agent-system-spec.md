# Agent System Spec

Status: Draft
Date: 2026-04-26

## Purpose

This project is not just a skills package. It is an agent system package with shared agent contracts, shared skills, and multiple orchestration implementations.

The core design goal is:

> Maintain one source of truth for agent roles, skills, and contracts, while allowing different orchestration implementations to call those agents.

Claude Code, Codex, and Python/LangGraph should not each own a full duplicated copy of the system. They should consume the same agent source and adapt it to their own execution model.

## Conceptual Model

The project has four distinct concepts:

| Concept | Responsibility | Example |
|---|---|---|
| Skill | Reusable knowledge, rules, templates, and reference material | research rules, writing guidelines, report templates |
| Agent | A role with behavior, tool assumptions, model preferences, and boundaries | deep-research, research-worker, research-verifier |
| Agent contract | The stable interface for calling an agent | input fields, output fields, delegation rules, artifact rules |
| Orchestration | The implementation that decides who calls whom and when | Claude native subagents, Codex custom agents, LangGraph code |

Skills are not enough for this project because the important behavior often comes from agent orchestration:

- The orchestrator decomposes work.
- Workers investigate isolated tasks.
- Verifiers check claims and contradictions.
- The orchestrator synthesizes final output.
- Some flows need persistence, state, retries, or deterministic control.

Therefore, orchestration must be treated as a first-class concern, but the contract shared by orchestration implementations should remain single-sourced.

## Source Ownership

The repository should separate agent source from generated platform outputs.

Recommended ownership model:

```text
agent-source/
  agents/
  skills/
  contracts/
  protocols/

platforms/
  claude-code/
  codex/

packages/
  langgraph-orchestrator/
  review-agent/

dist/
plugins/
```

Current repository names may differ during migration, but the ownership principle should stay the same:

- `agent-source/` or `src/` owns the reusable agent system.
- `platforms/` owns thin platform adapters.
- `packages/` owns separately runnable Python or LangGraph products.
- `dist/` and generated plugin folders are outputs, not editing surfaces.

## Agent Source

Agent source defines the reusable roles and their contracts.

It should include:

- Agent identity and description.
- Model preferences per platform.
- Tool assumptions per platform.
- Skills the agent may load.
- Delegation permissions.
- Input contract.
- Output contract.
- Artifact conventions.
- Failure reporting rules.

Example contract:

```yaml
name: research-worker
role: evidence-gathering worker

input_contract:
  objective: string
  seed_queries: list[string]
  acceptance_criteria: list[string]
  context: optional string

output_contract:
  findings: list[Finding]
  sources: list[Source]
  uncertainties: list[string]
  contradictions: list[string]
  next_questions: list[string]

delegation:
  may_spawn_subagents: false

artifacts:
  may_write_files: false
  returns_final_answer_to: caller
```

The contract is more important than the runtime-specific prompt format. Claude native orchestration, Codex native orchestration, and LangGraph orchestration should all be able to call `research-worker` through this same conceptual interface.

## Skills

Skills should contain reusable reference material, not the full orchestration system.

Good skill content:

- Research rules.
- Source quality rules.
- Writing style.
- Report templates.
- Math notation rules.
- Completion gates.
- Domain-specific references.

Avoid putting platform-specific orchestration assumptions directly into shared skills. For example, a shared skill can describe what a verifier should check, but should not assume a particular platform mechanism for spawning that verifier.

## Native Agent Orchestration

Native agent orchestration is the implementation where the platform's own agent mechanism coordinates work.

Examples:

- Claude Code plugin agents and subagents.
- Codex custom agents and subagents.

This mode is suitable when:

- The task is exploratory.
- The plan cannot be fully known upfront.
- Subtasks benefit from isolated context windows.
- The orchestrator should dynamically choose when to call workers.
- The user is already operating inside Claude Code or Codex.

In native orchestration, the orchestration logic may live in the orchestrator agent prompt. However, it should reference shared contracts instead of redefining worker behavior from scratch.

## Python and LangGraph Orchestration

Python and LangGraph packages are not children of the agent source. They are sibling products that consume the shared agent source.

They are appropriate when:

- The workflow is complex and benefits from explicit graph control.
- The process needs durable state, checkpointing, retries, logs, or deterministic branching.
- The workflow should be testable as code.
- The system needs to call Claude, Codex, or other agents programmatically.

Important boundary:

> LangGraph owns its graph implementation. The shared source owns the agent contracts and reusable prompt/skill material.

Do not try to replace LangGraph graphs with a large generic YAML workflow language. That would duplicate LangGraph's purpose and add unnecessary complexity.

A LangGraph package should instead declare which shared agents and skills it consumes.

Example manifest:

```yaml
name: code-review
runtime: langgraph
entrypoint: pionless_graphs.review.graph:graph

uses_agents:
  - claude-reviewer
  - codex-reviewer

uses_skills:
  - review-rules
  - writing-guidelines

outputs:
  directory: code-review/
  files:
    - FINAL.md
    - claude.md
    - codex.md
```

The graph code remains the source of truth for graph control flow. The manifest only documents the product boundary and dependencies.

## Platform Adapters

Platform adapters should be thin.

Claude Code adapter responsibilities:

- Generate Claude-compatible agent markdown.
- Generate or copy Claude plugin manifest.
- Preserve Claude-specific model, tools, and plugin metadata.
- Package skills in Claude-compatible form.

Codex adapter responsibilities:

- Generate Codex-compatible agent TOML templates.
- Generate or copy Codex plugin manifest.
- Preserve Codex-specific model, reasoning effort, sandbox, and skill paths.
- Package skills in Codex-compatible form.

Adapters should not own research logic or duplicate shared skills.

## Build Outputs

Generated outputs should be clearly marked and treated as non-authoritative.

Examples:

```text
dist/claude-plugin/
dist/codex-plugin/
plugins/pionless-agent/
claude/agents/
codex/agents/
shared/skills/
```

If a generated output must be committed for marketplace or installation reasons, it should still be documented as generated and rebuilt from source.

## Recommended Direction

The project should evolve toward this dependency direction:

```text
shared agent source
  -> Claude Code adapter
  -> Codex adapter

shared agent source
  -> Python/LangGraph packages
```

Not this:

```text
Claude source <-> Codex source <-> Python source
```

And not this:

```text
one giant skill file that asks each AI to infer the whole system every time
```

The stable center should be:

- Agent contracts.
- Shared skills.
- Shared prompt material.
- Artifact and completion conventions.

The variable outer layer should be:

- Claude native orchestration.
- Codex native orchestration.
- LangGraph orchestration.
- CLI packaging.

## Migration Plan

1. Document generated directories as generated-only editing surfaces.
2. Extract explicit agent contracts from existing agent prompts.
3. Keep native orchestration prompts, but make them reference contracts instead of embedding all worker behavior.
4. Move platform manifests into platform adapter directories.
5. Keep Python/LangGraph packages as sibling packages that consume shared contracts and prompts.
6. Update build scripts to generate Claude and Codex outputs from the shared source.
7. Add checks that generated outputs are reproducible from source.

## Non-Goals

This spec does not require:

- Replacing LangGraph with YAML.
- Forcing all orchestration into prompts.
- Forcing all orchestration into Python.
- Maintaining separate full copies for Claude and Codex.
- Treating skills as the only product surface.

## Decision Summary

The project should be treated as an agent workflow package.

The central asset is not a skill and not a Python graph. The central asset is the set of shared agent contracts, skills, prompts, and artifact conventions.

Claude Code, Codex, and LangGraph are different execution seats. They may orchestrate differently, but they should call the same conceptual agents through the same contracts.
