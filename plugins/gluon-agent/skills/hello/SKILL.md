---
name: hello
description: Greet the user and explain that gluon-agent can expose shared skills across Claude Code and Codex.
---

# Hello

Greet the user briefly, then explain that `gluon-agent` is set up as a shared plugin scaffold for Claude Code and Codex.

If the user asks what is included, mention:

1. shared skills in `shared/skills/`
2. shared MCP config in `shared/.mcp.json`
3. platform manifests under `claude/` and `codex/`
4. `build.sh` for producing `dist/claude-plugin` and `dist/codex-plugin`
