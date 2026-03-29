#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
CLAUDE_DIST="$DIST_DIR/claude-plugin"
CODEX_DIST="$DIST_DIR/codex-plugin"
REPO_PLUGIN_DIR="$ROOT_DIR/plugins/gluon-agent"

rm -rf "$CLAUDE_DIST" "$CODEX_DIST"

mkdir -p "$CLAUDE_DIST" "$CODEX_DIST"

cp -R "$ROOT_DIR/shared/skills" "$CLAUDE_DIST/"
cp -R "$ROOT_DIR/shared/skills" "$CODEX_DIST/"
cp "$ROOT_DIR/shared/.mcp.json" "$CLAUDE_DIST/"
cp "$ROOT_DIR/shared/.mcp.json" "$CODEX_DIST/"

if [ -d "$ROOT_DIR/shared/scripts" ]; then
  cp -R "$ROOT_DIR/shared/scripts" "$CLAUDE_DIST/"
  cp -R "$ROOT_DIR/shared/scripts" "$CODEX_DIST/"
fi

cp -R "$ROOT_DIR/claude/.claude-plugin" "$CLAUDE_DIST/"
cp -R "$ROOT_DIR/codex/.codex-plugin" "$CODEX_DIST/"

if [ -d "$ROOT_DIR/claude/agents" ]; then
  cp -R "$ROOT_DIR/claude/agents" "$CLAUDE_DIST/"
fi

if [ -d "$ROOT_DIR/claude/hooks" ]; then
  cp -R "$ROOT_DIR/claude/hooks" "$CLAUDE_DIST/"
fi

if [ -f "$ROOT_DIR/claude/.lsp.json" ]; then
  cp "$ROOT_DIR/claude/.lsp.json" "$CLAUDE_DIST/"
fi

if [ -f "$ROOT_DIR/codex/.app.json" ]; then
  cp "$ROOT_DIR/codex/.app.json" "$CODEX_DIST/"
fi

/usr/bin/python3 - "$CODEX_DIST" <<'PYTHON'
import pathlib
import re
import sys

codex_root = pathlib.Path(sys.argv[1])

for path in codex_root.rglob("SKILL.md"):
    text = path.read_text()
    match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.DOTALL)
    if not match:
        continue

    frontmatter = match.group(1).splitlines()
    body = match.group(2)
    kept = []
    keep_description_block = False

    for line in frontmatter:
        stripped = line.strip()
        if stripped.startswith("name:"):
            kept.append(line)
            keep_description_block = False
            continue

        if stripped.startswith("description:"):
            kept.append(line)
            keep_description_block = stripped in {"description: |", "description: >", "description: |-", "description: >-"}
            continue

        if keep_description_block and (line.startswith(" ") or line.startswith("\t")):
            kept.append(line)
            continue

        if stripped and not (line.startswith(" ") or line.startswith("\t")):
            keep_description_block = False

    if kept:
        path.write_text("---\n" + "\n".join(kept) + "\n---\n" + body)

print("Built:")
print(f"  Claude Code: {codex_root.parent / 'claude-plugin'}")
print(f"  Codex:       {codex_root}")
PYTHON

rm -rf "$REPO_PLUGIN_DIR"
mkdir -p "$ROOT_DIR/plugins"
mkdir -p "$REPO_PLUGIN_DIR"
cp -R "$CODEX_DIST"/. "$REPO_PLUGIN_DIR"/

echo "  Repo plugin: $REPO_PLUGIN_DIR"
