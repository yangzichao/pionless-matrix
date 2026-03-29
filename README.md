# gluon-agent

`gluon-agent` is a universal plugin scaffold for Claude Code and OpenAI Codex.
This repository now contains:

- shared plugin assets in `shared/`
- Claude-specific manifest in `claude/.claude-plugin/`
- Codex-specific manifest in `codex/.codex-plugin/`
- `build.sh` to assemble runnable distributions under `dist/`
- `.agents/plugins/marketplace.json` so Codex can discover the plugin from this repo
- install scripts under `scripts/`

## Structure

```text
shared/
  skills/
  scripts/
  .mcp.json
claude/
  .claude-plugin/plugin.json
codex/
  .codex-plugin/plugin.json
plugins/
  gluon-agent/
.agents/plugins/marketplace.json
scripts/
build.sh
```

## Build

```bash
bash build.sh
```

This generates:

- `dist/claude-plugin/`
- `dist/codex-plugin/`
- `plugins/gluon-agent/` for the repo-local Codex marketplace

## Install From GitHub

Repository:

- [https://github.com/yangzichao/gluon-agent](https://github.com/yangzichao/gluon-agent)

Claude Code:

```bash
git clone https://github.com/yangzichao/gluon-agent.git
cd gluon-agent
bash scripts/install-claude.sh
```

Codex:

```bash
git clone https://github.com/yangzichao/gluon-agent.git
cd gluon-agent
bash scripts/install-codex.sh
```

If someone opens this repo directly in Codex, the repo marketplace at `.agents/plugins/marketplace.json` exposes `gluon-agent` from `./plugins/gluon-agent`.

## Test

Claude Code:

```bash
claude --plugin-dir dist/claude-plugin
```

Codex:

1. Run `bash scripts/install-codex.sh`, or
2. Open this repo in Codex and use the repo marketplace.

## Local Commands

```bash
make build
make install-claude
make install-codex
```

## Reference

The detailed design and platform comparison live in:

- `gluon-agent-开发完全指南.md`
