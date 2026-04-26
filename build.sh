#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$ROOT_DIR/src"
DIST_DIR="$ROOT_DIR/dist"
CLAUDE_DIST="$DIST_DIR/claude-plugin"
CODEX_DIST="$DIST_DIR/codex-plugin"
REPO_PLUGIN_DIR="$ROOT_DIR/plugins/pionless-agent"
LOCK_DIR="$ROOT_DIR/.build.lock"

while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  sleep 0.1
done

cleanup() {
  rmdir "$LOCK_DIR"
}

trap cleanup EXIT

# ---------------------------------------------------------------------------
# Step 0: Generate platform-specific agents from src/agents/ (single source)
# ---------------------------------------------------------------------------

/usr/bin/python3 - "$SRC_DIR" "$ROOT_DIR" <<'PYTHON'
import pathlib, re, sys, json

src_dir = pathlib.Path(sys.argv[1])
root_dir = pathlib.Path(sys.argv[2])

agents_src = src_dir / "agents"
claude_agents = root_dir / "platforms" / "claude-code" / "agents"
codex_agents = root_dir / "platforms" / "codex" / "agents"

claude_agents.mkdir(parents=True, exist_ok=True)
codex_agents.mkdir(parents=True, exist_ok=True)

# Clear old generated files
for f in claude_agents.glob("*.md"):
    f.unlink()
for f in codex_agents.glob("*.toml"):
    f.unlink()


def parse_frontmatter(text):
    """Parse YAML-ish frontmatter from markdown. Returns (dict, body)."""
    match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.DOTALL)
    if not match:
        return {}, text
    raw = match.group(1)
    body = match.group(2)

    fm = {}
    current_key = None
    current_list = None
    current_nested = None
    nested_key = None
    lines = raw.splitlines()

    for i, line in enumerate(lines):
        # Bare key (e.g., "skills:" or "codex:") — look ahead to decide list vs object
        if re.match(r"^(\w[\w-]*):\s*$", line):
            key = line.strip().rstrip(":")
            # Peek at next non-empty line to decide type
            next_line = ""
            for j in range(i + 1, len(lines)):
                if lines[j].strip():
                    next_line = lines[j]
                    break
            if next_line.startswith("  - "):
                # It's a list
                fm[key] = []
                current_list = fm[key]
                current_nested = None
                nested_key = None
            else:
                # It's a nested object
                fm[key] = {}
                nested_key = key
                current_nested = fm[key]
                current_list = None
            current_key = key
            continue

        # Nested key-value inside an object
        if current_nested is not None and line.startswith("  "):
            stripped = line.strip()
            m = re.match(r'^([\w_-]+):\s+(.+)$', stripped)
            if m:
                k, v = m.group(1), m.group(2)
                # Parse list values like ["a", "b"]
                if v.startswith("[") and v.endswith("]"):
                    items = [x.strip().strip('"').strip("'") for x in v[1:-1].split(",")]
                    current_nested[k] = [x for x in items if x]
                else:
                    current_nested[k] = v.strip('"').strip("'")
                continue

        # Top-level list item (continuation of a list key)
        if line.startswith("  - ") and current_list is not None:
            current_list.append(line.strip()[2:].strip())
            continue

        # Top-level key: value
        m = re.match(r'^([\w_-]+):\s+(.+)$', line)
        if m:
            key, val = m.group(1), m.group(2)
            current_nested = None
            nested_key = None
            current_list = None
            fm[key] = val
            current_key = key
            continue

    return fm, body


def escape_toml_string(s):
    """Escape a Python string for inclusion inside a TOML basic (double-quoted) string."""
    out = []
    for ch in s:
        if ch == '\\':
            out.append('\\\\')
        elif ch == '"':
            out.append('\\"')
        elif ch == '\b':
            out.append('\\b')
        elif ch == '\f':
            out.append('\\f')
        elif ch == '\n':
            out.append('\\n')
        elif ch == '\r':
            out.append('\\r')
        elif ch == '\t':
            out.append('\\t')
        elif ord(ch) < 0x20 or ord(ch) == 0x7f:
            out.append(f'\\u{ord(ch):04x}')
        else:
            out.append(ch)
    return ''.join(out)


def to_toml_value(val):
    """Convert a Python value to a TOML-compatible string."""
    if isinstance(val, list):
        items = ", ".join(f'"{escape_toml_string(str(v))}"' for v in val)
        return f"[{items}]"
    if isinstance(val, str):
        return f'"{escape_toml_string(val)}"'
    return str(val)


for md_path in sorted(agents_src.glob("*.md")):
    text = md_path.read_text()
    fm, body = parse_frontmatter(text)
    name = fm.get("name", md_path.stem)

    # --- Generate Claude .md (strip codex: section) ---
    claude_fm_lines = []
    for key, val in fm.items():
        if key == "codex":
            continue
        if isinstance(val, list):
            claude_fm_lines.append(f"{key}:")
            for item in val:
                claude_fm_lines.append(f"  - {item}")
        else:
            claude_fm_lines.append(f"{key}: {val}")

    claude_text = "---\n" + "\n".join(claude_fm_lines) + "\n---\n" + body
    (claude_agents / md_path.name).write_text(claude_text)

    # --- Generate Codex .toml ---
    codex_cfg = fm.get("codex", {})
    skills_list = fm.get("skills", [])
    if isinstance(skills_list, str):
        skills_list = [skills_list]

    toml_lines = []
    toml_lines.append(f'name = {to_toml_value(name)}')
    if "description" in fm:
        toml_lines.append(f'description = {to_toml_value(fm["description"])}')

    # Codex-specific fields
    if "model" in codex_cfg:
        toml_lines.append(f'model = {to_toml_value(codex_cfg["model"])}')
    if "model_reasoning_effort" in codex_cfg:
        toml_lines.append(f'model_reasoning_effort = {to_toml_value(codex_cfg["model_reasoning_effort"])}')
    if "sandbox_mode" in codex_cfg:
        toml_lines.append(f'sandbox_mode = {to_toml_value(codex_cfg["sandbox_mode"])}')
    if "nickname_candidates" in codex_cfg:
        toml_lines.append(f'nickname_candidates = {to_toml_value(codex_cfg["nickname_candidates"])}')

    # Developer instructions = body text
    body_escaped = body.strip().replace('\\', '\\\\').replace('"""', '\\"\\"\\"')
    toml_lines.append(f'developer_instructions = """\n{body_escaped}\n"""')

    # Skills config
    for skill_name in skills_list:
        toml_lines.append("")
        toml_lines.append("[[skills.config]]")
        toml_lines.append(f'path = {to_toml_value(f"__PIONLESS_PLUGIN_ROOT__/skills/{skill_name}/SKILL.md")}')
        toml_lines.append("enabled = true")

    (codex_agents / f"{md_path.stem}.toml").write_text("\n".join(toml_lines) + "\n")

print("  Agents generated from src/agents/")
PYTHON

# ---------------------------------------------------------------------------
# Step 1: Expand skill includes from src/skills/ into shared/skills/
# ---------------------------------------------------------------------------

/usr/bin/python3 - "$SRC_DIR" "$ROOT_DIR" <<'PYTHON'
import pathlib, re, sys

src_dir = pathlib.Path(sys.argv[1])
root_dir = pathlib.Path(sys.argv[2])
skills_src = src_dir / "skills"
shared_skills = root_dir / "shared" / "skills"

# Clean old expanded skills to avoid stale leftovers
import shutil
if shared_skills.exists():
    shutil.rmtree(shared_skills)

# Pattern: <!-- include: includes/filename.md --> or with params {KEY=VALUE}
INCLUDE_RE = re.compile(
    r'^<!-- include: ([\w/.-]+\.md)\s*((?:\{[^}]+\}\s*)*)-->$'
)
PARAM_RE = re.compile(r'\{(\w+)=([^}]+)\}')


def expand_includes(text, base_dir):
    """Recursively expand include markers in text."""
    lines = text.splitlines(keepends=True)
    result = []
    for line in lines:
        stripped = line.strip()
        m = INCLUDE_RE.match(stripped)
        if m:
            include_path = base_dir / m.group(1)
            params_str = m.group(2)
            params = dict(PARAM_RE.findall(params_str))

            if include_path.exists():
                content = include_path.read_text()
                # Apply parameter substitution
                for key, val in params.items():
                    content = content.replace(f"{{{key}}}", val)
                # Recursive expansion
                content = expand_includes(content, base_dir)
                result.append(content)
                if not content.endswith("\n"):
                    result.append("\n")
            else:
                print(f"  WARNING: include not found: {include_path}")
                result.append(line)
        else:
            result.append(line)
    return "".join(result)


# Process each skill directory
for skill_dir in sorted(skills_src.iterdir()):
    if not skill_dir.is_dir() or skill_dir.name == "includes":
        continue
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        continue

    text = skill_md.read_text()
    expanded = expand_includes(text, skills_src)

    out_dir = shared_skills / skill_dir.name
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "SKILL.md").write_text(expanded)

print("  Skills expanded from src/skills/ -> shared/skills/")
PYTHON

# ---------------------------------------------------------------------------
# Step 2: Build dist packages
# ---------------------------------------------------------------------------

rm -rf "$CLAUDE_DIST" "$CODEX_DIST" "$REPO_PLUGIN_DIR"
mkdir -p "$CLAUDE_DIST" "$CODEX_DIST"

# Copy expanded skills to both dists
cp -R "$ROOT_DIR/shared/skills" "$CLAUDE_DIST/"
cp -R "$ROOT_DIR/shared/skills" "$CODEX_DIST/"

# Copy MCP config
cp "$ROOT_DIR/shared/.mcp.json" "$CLAUDE_DIST/"
cp "$ROOT_DIR/shared/.mcp.json" "$CODEX_DIST/"

# Platform-specific manifests
cp -R "$ROOT_DIR/platforms/claude-code/.claude-plugin" "$CLAUDE_DIST/"
cp -R "$ROOT_DIR/platforms/codex/.codex-plugin" "$CODEX_DIST/"

# Claude agents (generated in Step 0)
if [ -d "$ROOT_DIR/platforms/claude-code/agents" ]; then
  cp -R "$ROOT_DIR/platforms/claude-code/agents" "$CLAUDE_DIST/"
fi

# Claude hooks
if [ -d "$ROOT_DIR/platforms/claude-code/hooks" ]; then
  cp -R "$ROOT_DIR/platforms/claude-code/hooks" "$CLAUDE_DIST/"
fi

# Claude LSP config
if [ -f "$ROOT_DIR/platforms/claude-code/.lsp.json" ]; then
  cp "$ROOT_DIR/platforms/claude-code/.lsp.json" "$CLAUDE_DIST/"
fi

# Codex app config
if [ -f "$ROOT_DIR/platforms/codex/.app.json" ]; then
  cp "$ROOT_DIR/platforms/codex/.app.json" "$CODEX_DIST/"
fi

# Codex agent templates (generated in Step 0)
if [ -d "$ROOT_DIR/platforms/codex/agents" ]; then
  mkdir -p "$CODEX_DIST/agent-templates"
  cp -R "$ROOT_DIR/platforms/codex/agents/." "$CODEX_DIST/agent-templates/"
fi

# ---------------------------------------------------------------------------
# Step 3: Strip Codex skill frontmatter (Codex doesn't support model/tools)
# ---------------------------------------------------------------------------

/usr/bin/python3 - "$CODEX_DIST" <<'PYTHON'
import pathlib
import re
import sys

codex_root = pathlib.Path(sys.argv[1])
KEEP_KEYS = {"name:", "description:"}

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
        if any(stripped.startswith(k) for k in KEEP_KEYS):
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

# ---------------------------------------------------------------------------
# Step 4: Build the committed repo plugin (serves both platforms)
# ---------------------------------------------------------------------------

mkdir -p "$ROOT_DIR/plugins"
mkdir -p "$REPO_PLUGIN_DIR"

# Expanded skills
cp -R "$ROOT_DIR/shared/skills" "$REPO_PLUGIN_DIR/"
cp "$ROOT_DIR/shared/.mcp.json" "$REPO_PLUGIN_DIR/"

# Both platform manifests
cp -R "$ROOT_DIR/platforms/claude-code/.claude-plugin" "$REPO_PLUGIN_DIR/"
cp -R "$ROOT_DIR/platforms/codex/.codex-plugin" "$REPO_PLUGIN_DIR/"

# Claude agents
if [ -d "$ROOT_DIR/platforms/claude-code/agents" ]; then
  cp -R "$ROOT_DIR/platforms/claude-code/agents" "$REPO_PLUGIN_DIR/"
fi

if [ -d "$ROOT_DIR/platforms/claude-code/hooks" ]; then
  cp -R "$ROOT_DIR/platforms/claude-code/hooks" "$REPO_PLUGIN_DIR/"
fi

if [ -f "$ROOT_DIR/platforms/claude-code/.lsp.json" ]; then
  cp "$ROOT_DIR/platforms/claude-code/.lsp.json" "$REPO_PLUGIN_DIR/"
fi

if [ -f "$ROOT_DIR/platforms/codex/.app.json" ]; then
  cp "$ROOT_DIR/platforms/codex/.app.json" "$REPO_PLUGIN_DIR/"
fi

# Codex agent templates
if [ -d "$ROOT_DIR/platforms/codex/agents" ]; then
  mkdir -p "$REPO_PLUGIN_DIR/agent-templates"
  cp -R "$ROOT_DIR/platforms/codex/agents/." "$REPO_PLUGIN_DIR/agent-templates/"
fi

# Strip repo plugin skills to keep Claude-compatible frontmatter
/usr/bin/python3 - "$REPO_PLUGIN_DIR" <<'PYTHON'
import pathlib
import re
import sys

plugin_root = pathlib.Path(sys.argv[1])
KEEP_KEYS = {"name:", "description:", "model:", "allowed-tools:"}

for path in plugin_root.rglob("SKILL.md"):
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
        if any(stripped.startswith(k) for k in KEEP_KEYS):
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
PYTHON

echo "  Repo plugin: $REPO_PLUGIN_DIR"
