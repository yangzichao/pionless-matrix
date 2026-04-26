# pionless-agent

This repository maintains a cross-platform research agent package for Claude Code and OpenAI Codex.

## Architecture

Agents are the brains (orchestration logic, turn protocol, Ralph loop enforcement). Skills are reference material (research rules, writing rules, report templates).

## Single Source of Truth

All agent definitions live in `src/agents/` as Claude-format .md files with an extended `codex:` frontmatter section. Build.sh generates both platforms:

- `platforms/claude-code/agents/*.md` — Claude Code agents (codex section stripped)
- `platforms/codex/agents/*.toml` — Codex agents (converted format)

## Modular Skills

Skill content is decomposed into small modules in `src/skills/includes/`. Source SKILL.md files use `<!-- include: includes/filename.md -->` markers that build.sh expands at build time.

## Working Rules

- Edit agents in `src/agents/` — never hand-edit `platforms/claude-code/agents/` or `platforms/codex/agents/`
- Edit skill modules in `src/skills/includes/` — never hand-edit `shared/skills/`
- Run `bash build.sh` to assemble all outputs
- All research output goes to `deep-research/` using `YYYY-MM-DD-HHMM-topic.md` naming

## Agents

| Agent | Role | Claude Model | Codex Model | Max Turns |
|-------|------|-------------|-------------|-----------|
| deep-research | Orchestrator (standard) | opus | gpt-5.4 | 40 |
| deep-research-pro | Orchestrator (exhaustive) | opus | gpt-5.4 | 60 |
| quick-research | Standalone lightweight | sonnet | gpt-5.4-mini | 12 |
| research-worker | Evidence-gathering worker | sonnet | gpt-5.4-mini | 18 |
| research-verifier | Contradiction-seeking worker | sonnet | gpt-5.4-mini | 18 |
