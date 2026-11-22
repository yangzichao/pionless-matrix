# Skill anatomy

A skill is a folder with a `SKILL.md` file. It follows the open [Agent Skills](https://agentskills.io) format, so the same folder works in Claude Code, Codex, Cursor, Gemini CLI, Copilot, OpenCode and the other hosts that read `SKILL.md`.

A skill teaches the host agent a workflow. It does not own the runtime. The host decides the model, the tools, the permissions, whether subagents exist, and is responsible for the final answer.

## Folder

```text
<skill-name>/
  SKILL.md        # required: frontmatter + the workflow
  references/     # optional: long material read only when a step needs it
  roles/          # optional: prompts for subagents (see subagent-roles.md)
  assets/         # optional: templates, schemas, static files the workflow fills in or copies
  scripts/        # optional: deterministic steps the host runs (see scripts.md)
```

The folder is self-contained. Nothing in it may read files outside its own directory. No `../` paths, no absolute paths, no links into another skill. If two skills need the same text, each keeps its own copy.

## Frontmatter

```yaml
---
name: deep-research
description: Use when the user wants a source-backed research report ... (what it does + when to use it)
metadata:
  version: "2.0.0"
---
```

- `name`: required. Lowercase letters, digits and hyphens, at most 64 characters, and identical to the folder name.
- `description`: required, at most 1024 characters. Say what the skill does and when to use it. Hosts route on this text, so put the trigger phrases here, not in the body.
- `compatibility`: optional. One line naming what the skill needs at runtime (for example `Needs shell access, git, and Chrome`).
- `metadata`: optional. Only `version` is used in this repo. Bump the patch number for behavior fixes, the minor number for new capabilities.

Host-specific fields (`disable-model-invocation`, `allowed-tools`, `model` and similar) are allowed only when another host ignoring them is harmless. Never put a field that claims runtime authority, such as which agents it spawns or which model it runs on.

## Body

- Keep `SKILL.md` under about 300 lines. It is the index plus the steps the host needs to start correctly.
- Write steps the host can follow in order. Say what to produce at the end.
- Move anything that only one branch of the workflow needs into `references/`, and point to it from the step that needs it: `Read references/plan-board.md before step 3.`
- Point one level deep. `SKILL.md` names every file the host should open. A reference file should not send the host on to a third file.
- Use relative paths from the skill root with forward slashes.

## Prose

Every sentence in a skill becomes an instruction the host follows, so the bar is higher than for docs a person reads.

- When in doubt, delete. Keep a sentence only if it changes what the host does.
- Say what to do. Give the reason only when the rule is confusing without one.
- Write a rule in one line when it fits. Move examples and long explanations into `references/`.
- Don't restate what a file in the folder already says, such as a template, schema, or script. Point at it.
- Don't restate another skill. Call it by name.
- When you write the same rule a second time, turn it into a script or a validator check instead of more prose.

Adapted from the authoring-a-skill playbook in pstack (backnotprop/pstack).

## Host-neutral wording

The goal is format portability: any host that reads Agent Skills can load the folder and follow it. Identical behaviour across hosts is not a goal. Behaviour is checked on Claude Code and Codex only, so test there, and accept that other hosts may route, trigger, or run subagents differently.

Write against capabilities, not product names.

| Write this | Not this |
|---|---|
| `If you can start subagents, ...` | `Use the Agent tool with subagent_type=...` |
| `If you have shell access, run scripts/build.sh` | `Use the Bash tool` |
| `Search the web` | `Call WebSearch` |
| `Ask the user` | `Use AskUserQuestion` |
| `Call the skill named markdown-to-pdf` | `/markdown-to-pdf` or `../markdown-to-pdf/SKILL.md` |

Every step that needs a capability the host might not have says what to do without it. A host with no shell still gets a manual path; a host with no subagents runs the role itself.

A product name is fine when it is the subject of the workflow (for example, a skill that diagnoses a Claude Code MCP setup), not when it is just the host running the skill.

## What does not go in a skill folder

- Agent definitions for one specific host (`.claude/agents/*.md`, Codex `.toml` agents). Use `roles/` prompts instead.
- Per-host copies of the same skill.
- Generated files, caches, run output.
- A second `SKILL.md`.
