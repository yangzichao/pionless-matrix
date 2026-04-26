#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_NAME="pionless-agent"
TARGET_PLUGIN_DIR="${HOME}/.codex/plugins/${PLUGIN_NAME}"
TARGET_AGENT_DIR="${HOME}/.codex/agents"
MARKETPLACE_DIR="${HOME}/.agents/plugins"
MARKETPLACE_FILE="${MARKETPLACE_DIR}/marketplace.json"

bash "$ROOT_DIR/build.sh"

mkdir -p "${HOME}/.codex/plugins" "$TARGET_AGENT_DIR" "$MARKETPLACE_DIR"
rm -rf "$TARGET_PLUGIN_DIR"
cp -R "$ROOT_DIR/dist/codex-plugin" "$TARGET_PLUGIN_DIR"

/usr/bin/python3 - "$ROOT_DIR/platforms/codex/agents" "$TARGET_AGENT_DIR" "$TARGET_PLUGIN_DIR" <<'PYTHON'
import pathlib
import sys

source_dir = pathlib.Path(sys.argv[1])
target_dir = pathlib.Path(sys.argv[2])
plugin_root = sys.argv[3]

for path in source_dir.glob("*.toml"):
    content = path.read_text()
    content = content.replace("__PIONLESS_PLUGIN_ROOT__", plugin_root)
    (target_dir / path.name).write_text(content)
PYTHON

/usr/bin/python3 - "$MARKETPLACE_FILE" "$PLUGIN_NAME" <<'PYTHON'
import json
import pathlib
import sys

marketplace_file = pathlib.Path(sys.argv[1])
plugin_name = sys.argv[2]

data = {
    "name": "pionless-agent",
    "interface": {
        "displayName": "pionless-agent"
    },
    "plugins": []
}

if marketplace_file.exists():
    data = json.loads(marketplace_file.read_text())

data.setdefault("name", "pionless-agent")
data.setdefault("interface", {})
data["interface"].setdefault("displayName", "pionless-agent")
data.setdefault("plugins", [])

entry = {
    "name": plugin_name,
    "source": {
        "source": "local",
        "path": f"./.codex/plugins/{plugin_name}"
    },
    "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
    },
    "category": "Productivity"
}

plugins = [plugin for plugin in data["plugins"] if plugin.get("name") != plugin_name]
plugins.append(entry)
data["plugins"] = plugins

marketplace_file.write_text(json.dumps(data, indent=2) + "\n")
PYTHON

echo "Installed Codex plugin to:"
echo "  $TARGET_PLUGIN_DIR"
echo ""
echo "Installed Codex custom agents to:"
echo "  $TARGET_AGENT_DIR"
echo ""
echo "Updated personal marketplace:"
echo "  $MARKETPLACE_FILE"
echo ""
echo "Restart Codex, then use the named agents:"
echo "  deep-research, deep-research-pro, quick-research, research-worker, research-verifier"
