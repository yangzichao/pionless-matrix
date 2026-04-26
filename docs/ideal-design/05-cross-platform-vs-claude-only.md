## 5. Cross-Platform vs Claude-Only

Some assets ship to Claude Code only; some ship to both Claude Code and Codex. The instinct is to mirror this in folders (`src/claude-only/`, `src/cross-platform/`). **Reject that instinct.** Folder splits force authors to decide platform targeting before they have written the content, fragment skills across trees, and make refactors a directory move.

### The right model: tag in frontmatter, route in build

Each skill and agent declares its platforms in frontmatter. The build reads the manifest, walks `src/`, and routes each asset to the appropriate `dist/<platform>/` directory.

### Frontmatter

```yaml
---
name: deep-research
platforms: [claude-code, codex]   # cross-platform
---
```

```yaml
---
name: claude-only-skill
platforms: [claude-code]          # Claude only
---
```

### Top-level manifest

```yaml
# manifest.yaml
version: 1
platforms:
  claude-code:
    skills-dir: dist/claude-code/skills
    agents-dir: dist/claude-code/agents
    agent-format: markdown
  codex:
    skills-dir: dist/codex/skills
    agents-dir: dist/codex/agents
    agent-format: toml             # Codex consumes TOML; build converts from MD
build:
  include-resolver: build/include-expander.py
  agent-converter: build/md-to-toml.py
  exclude-from-dist:
    - tests/
    - "**/*.test.*"
```

### Routing logic

```
for each src/skills/<skill>/:
  read SKILL.md frontmatter
  for each platform in frontmatter.platforms:
    expand includes
    convert format if needed
    copy to manifest.platforms[platform].skills-dir/<skill>/

for each src/agents/<agent>:
  read frontmatter
  for each platform in frontmatter.platforms:
    expand includes
    convert format if needed (e.g., MD -> TOML for Codex)
    copy to manifest.platforms[platform].agents-dir/
```

### Why this beats folder splits

| Concern | Folder split | Manifest tag |
|---|---|---|
| Promote a Claude-only skill to cross-platform | `git mv` plus rewrite imports | Edit one frontmatter line |
| Skill that is 90% shared with one Claude-only section | Duplicate the skill | Use a build-time include with platform conditionals |
| New platform added | Restructure tree | Add a manifest entry |
| Author cognitive load | Decide platform first, then write | Write first, tag at the end |

### Platform-conditional content within a single skill

For the rare case where one skill has a small platform-specific block:

```markdown
<!-- platform: claude-code -->
This section appears only in the Claude Code build.
<!-- end-platform -->
```

The build strips blocks whose platform does not match the current target. This handles 95% of real divergence without a folder split.

### Distribution targets (verified specs)

The build emits one dist folder per platform, each conforming to that platform's published install format.

**Claude Code plugin layout** (per [plugins-reference](https://code.claude.com/docs/en/plugins-reference.md), [plugins](https://code.claude.com/docs/en/plugins.md), [marketplaces](https://code.claude.com/docs/en/plugin-marketplaces.md)):

```
dist/claude-code/
├── .claude-plugin/
│   └── plugin.json              # required: name + metadata
├── skills/
│   └── {skill-name}/
│       ├── SKILL.md             # YAML frontmatter, includes expanded
│       ├── scripts/
│       ├── references/
│       └── assets/
├── agents/
│   └── {agent-name}.md          # FLAT .md files only
├── commands/                    # optional slash commands
│   └── {cmd}.md
├── hooks/hooks.json             # optional
├── .mcp.json                    # optional
├── bin/                         # optional, added to PATH
└── settings.json                # optional
```

Constraints to honor in source-to-dist conversion:
- Agents at `dist/claude-code/agents/` must be flat `.md` files. Source-side folder-form agents (`src/agents/{name}/AGENT.md + scripts/`) flatten in build: `AGENT.md` → `agents/{name}.md`, `scripts/` → `bin/{name}/` or plugin-root `scripts/{name}/`, body paths rewritten.
- Plugin name (in `plugin.json`) is kebab-case and becomes the invocation namespace: `/{plugin-name}:{skill-name}`.
- All paths must resolve inside the plugin folder; cross-plugin file references break.

**Codex plugin layout** (per [Codex Agent Skills](https://developers.openai.com/codex/skills), [Subagents](https://developers.openai.com/codex/subagents), [Configuration](https://developers.openai.com/codex/config-advanced)):

```
dist/codex/
├── skills/                      # install destination: ~/.agents/skills/ (user) or .agents/skills/ (project)
│   └── {skill-name}/
│       ├── SKILL.md             # YAML frontmatter, same shape as Claude
│       ├── scripts/
│       ├── references/
│       ├── assets/
│       └── agents/openai.yaml   # optional UI metadata, policy, deps
└── agents/                      # install destination: ~/.codex/agents/ (user) or .codex/agents/ (project)
    └── {agent-name}.toml
```

Constraints:
- Skills and agents land in **different roots** at install time (`.agents/skills/` vs `.codex/agents/`). The build emits both under one `dist/codex/` tree; the install script (or a one-line `cp`) places each subtree at its destination.
- Agents are TOML, one file per agent. Required fields: `name`, `description`, `developer_instructions`. Optional: `model`, `model_reasoning_effort`, `sandbox_mode`, `nickname_candidates`, `mcp_servers`, `skills.config`. Build converts source agent MD: YAML `name` → `name`, `description` → `description`, body → `developer_instructions`.
- SKILL.md frontmatter shape matches Claude's, so the same source file works on both platforms with no conversion.

### Install commands (verified)

**Claude Code:**

| Step | Command |
|---|---|
| Register marketplace (one-time) | `/plugin marketplace add github:owner/marketplace-repo` or `/plugin marketplace add ./local-marketplace` |
| Install plugin | `/plugin install plugin-name@marketplace-name` |
| Local development | `claude --plugin-dir ./dist/claude-code` |
| List installed | `/plugin list` |
| Update | `/plugin update plugin-name` |
| Reload after edit | `/reload-plugins` |

For marketplace distribution, ship a separate marketplace repo whose root contains `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-marketplace",
  "owner": { "name": "Team" },
  "plugins": [
    {
      "name": "deep-research",
      "source": "./plugins/deep-research",
      "version": "1.0.0",
      "description": "Multi-source research with cited reports"
    }
  ]
}
```

The `source` field can be a local relative path (preferred for marketplaces that bundle their own plugins) or a `{ "source": "github", "repo": "owner/repo", "ref": "main" }` object pointing at an external plugin repo.

**Codex:**

| Step | Command |
|---|---|
| Install skills (user scope) | `mkdir -p ~/.agents/skills && cp -r dist/codex/skills/* ~/.agents/skills/` |
| Install agents (user scope) | `mkdir -p ~/.codex/agents && cp -r dist/codex/agents/* ~/.codex/agents/` |
| Project scope | replace `~/.agents/skills/` with `<repo>/.agents/skills/` and `~/.codex/agents/` with `<repo>/.codex/agents/` |
| Verify | Codex auto-discovers on next session |

Codex's plugin marketplace mechanism is less mature than Claude's. The practical install path today is symlink or copy from `dist/codex/` into the discovery directories; ship an `install.sh` in the release that does this with one command.

### Build output mapping (single source → two dists)

| Source path | `dist/claude-code/` | `dist/codex/` |
|---|---|---|
| `src/skills/{name}/SKILL.md` | `skills/{name}/SKILL.md` (includes expanded) | `skills/{name}/SKILL.md` (includes expanded) |
| `src/skills/{name}/scripts/` | `skills/{name}/scripts/` | `skills/{name}/scripts/` |
| `src/skills/{name}/references/` | `skills/{name}/references/` | `skills/{name}/references/` |
| `src/skills/{name}/assets/` | `skills/{name}/assets/` | `skills/{name}/assets/` |
| `src/agents/{name}.md` (file form) | `agents/{name}.md` | `agents/{name}.toml` (converted) |
| `src/agents/{name}/AGENT.md` (folder form) | `agents/{name}.md` + `scripts/{name}/` (flattened) | `agents/{name}.toml` + `agents/{name}/` (scripts kept beside) |
| `src/shared/fragments/*` | inlined into consumers; not shipped as standalone | same |
| (synthesized) | `.claude-plugin/plugin.json` | (no top-level manifest required) |

### Release workflow

```
edit src/  →  bash build/build.sh  →  test dist/{claude-code,codex}/  →
git commit src/ + dist/  →  git tag v1.0.0  →  push tag  →  marketplace points at the tagged ref
```

Committing `dist/` is a deliberate choice: users `git clone` and install without needing the build toolchain. The cost is a noisy diff on every source edit. The alternative — uploading dist as release artifacts — keeps git clean but requires users to download a release tarball. For a project shipping to end users, commit dist; for a project shipping to other developers who can build, don't.
