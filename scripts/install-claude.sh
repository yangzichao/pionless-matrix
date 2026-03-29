#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${HOME}/.claude/plugins/gluon-agent"

bash "$ROOT_DIR/build.sh"

mkdir -p "${HOME}/.claude/plugins"
rm -rf "$TARGET_DIR"
cp -R "$ROOT_DIR/dist/claude-plugin" "$TARGET_DIR"

echo "Installed Claude Code plugin to:"
echo "  $TARGET_DIR"
echo ""
echo "For development you can also run:"
echo "  claude --plugin-dir $ROOT_DIR/dist/claude-plugin"
