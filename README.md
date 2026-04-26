# pionless-agent

`pionless-agent` is a cross-platform research agent package for Claude Code and OpenAI Codex,
plus a **dual-agent code review CLI** that orchestrates Claude Code and Codex CLI together.

This repository contains:

- shared workflow skills in `shared/`
- Claude plugin subagents in `platforms/claude-code/agents/`
- Codex custom-agent templates in `platforms/codex/agents/`
- Claude-specific manifest in `platforms/claude-code/.claude-plugin/`
- Codex-specific manifest in `platforms/codex/.codex-plugin/`
- a committed universal plugin package in `plugins/pionless-agent/`
- a Claude marketplace in `.claude-plugin/marketplace.json`
- `build.sh` to assemble runnable distributions under `dist/`
- `.agents/plugins/marketplace.json` so Codex can discover the plugin from this repo
- install scripts under `scripts/`
- **`packages/review-agent/`** — pip-installable dual-agent code review tool

## Structure

```text
src/                          # single source of truth
  agents/                     # agent definitions (.md with codex frontmatter)
  contracts/                  # agent input/output contracts (yaml)
  skills/                     # skill sources with <!-- include: --> markers
    includes/                 # modular fragments shared across tiers
shared/                       # expanded skills (generated, gitignored)
platforms/
  claude-code/
    agents/                   # generated, gitignored
    .claude-plugin/plugin.json
  codex/
    agents/                   # generated, gitignored
    .codex-plugin/plugin.json
plugins/
  pionless-agent/             # committed universal plugin (marketplace target)
packages/
  review-agent/               # dual-agent code review CLI (Python)
    review_agent/
      cli.py                  # argparse entry point
      orchestrator.py         # multi-round review protocol
      agents.py               # Claude Code / Codex CLI wrappers
      prompts.py              # prompt templates per phase
      output.py               # file output
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
- `plugins/pionless-agent/` as the committed repo plugin package for both platforms

Agent packaging differs by platform:

- Claude Code can load plugin-shipped subagents from `agents/`.
- Codex custom agents live under `.codex/agents/` or `~/.codex/agents/`, so this repo ships templates in `platforms/codex/agents/` and the installer copies them into `~/.codex/agents/`.

## Install From GitHub

Repository:

- [https://github.com/yangzichao/pionless-agent](https://github.com/yangzichao/pionless-agent)

### Claude Code

True GitHub marketplace install is supported.

```bash
/plugin marketplace add yangzichao/pionless-agent
/plugin install pionless-agent@pionless-agent-marketplace
```

This works because the repo publishes a marketplace at `.claude-plugin/marketplace.json` that points at `./plugins/pionless-agent`.

### Codex

Direct GitHub marketplace install is not documented in current Codex plugin docs. The supported paths today are:

1. Clone the repo and run the installer:

```bash
git clone https://github.com/yangzichao/pionless-agent.git
cd pionless-agent
bash scripts/install-codex.sh
```

This installs:

- the Codex plugin under `~/.codex/plugins/pionless-agent`
- custom research agents under `~/.codex/agents/`

2. Or open the cloned repo in Codex and use the repo marketplace at `.agents/plugins/marketplace.json`, which exposes `pionless-agent` from `./plugins/pionless-agent`. In that mode you still need to copy `platforms/codex/agents/*.toml` into `.codex/agents/` or `~/.codex/agents/` if you want the named orchestrator agents.

## Test

Claude Code:

```bash
claude --plugin-dir dist/claude-plugin
```

Codex:

1. Run `bash scripts/install-codex.sh`, or
2. Open this repo in Codex and use the repo marketplace.

## Agent Model

The intended entrypoints are agents, not bare skills:

- `deep-research`: orchestrator agent for substantial research jobs
- `deep-research-pro`: orchestrator agent for exhaustive investigations
- `quick-research`: lightweight standalone fast-research agent
- `research-worker`: worker agent for focused subquestions
- `research-verifier`: worker agent for contradiction-seeking and claim verification

The shared `skills/` directory exists to keep the operating procedure reusable across Claude and Codex. It is not meant to be the only user-facing surface.

### Orchestrator fan-out requirements

Orchestrator agents (`deep-research`, `deep-research-pro`) spawn `research-worker` and `research-verifier` as named subagents. This requires the orchestrator to run as the **main session agent**, not as a delegated subagent, because subagents cannot spawn other subagents on either platform.

**Claude Code**: Launch the orchestrator as the session agent:

```bash
claude --agent pionless-agent:deep-research
# or
claude --agent pionless-agent:deep-research-pro
```

If you install the plugin and invoke the skill from a normal session (e.g. `/deep-research`), the skill runs inside the main Claude thread and can use the Agent tool to spawn workers — but only if Claude itself is the main agent. If `deep-research` is auto-delegated as a subagent, it will **not** be able to fan out.

**Codex**: Fan-out works in interactive CLI sessions where Codex resolves custom agent names from `~/.codex/agents/`. It does **not** work in tool-backed or API sessions — custom agent name resolution is not yet supported there (see [openai/codex#15250](https://github.com/openai/codex/issues/15250)). The `agents.max_depth` config (default 1) also prevents workers from spawning grandchildren.

## Source Notes

- Claude GitHub marketplace install is documented by Anthropic via `/plugin marketplace add owner/repo`.
- Claude also documents plugin-distributed subagents via plugin `agents/`.
- Codex currently documents plugins for skills/apps/MCP plus project or user custom agents under `.codex/agents/` and `~/.codex/agents/`; public plugin support for shipping custom agents as first-class plugin components is not documented.

## Local Commands

```bash
make build
make install-claude
make install-codex
```

## review-agent — Dual-Agent Code Review

A pip-installable CLI that orchestrates Claude Code and Codex CLI for collaborative code review.

### Install

```bash
cd packages/review-agent
pip install -e .
```

### How It Works

```
Phase 1: Independent Review (parallel)
  Claude Code ──review──> claude review
  Codex CLI   ──review──> codex review

Phase 2: Cross-Verification (parallel × N rounds)
  Claude receives Codex's review, verifies each finding
  Codex receives Claude's review, verifies each finding

Phase 3: Consensus Synthesis
  All findings merged into a single unified review (FINAL.md)
```

### Usage

```bash
# Review uncommitted changes
review-agent

# Review last 3 commits, security focus
review-agent --last 3 --focus security

# Review a directory, high-level architecture focus
review-agent --dir src/ --focus high-level

# Review branch diff with custom instructions
review-agent --branch main --system-prompt "Focus on database migration safety"

# Review specific files
review-agent --files foo.py bar.py

# Full repo review (agents explore via tools)
review-agent --repo

# Multi-round cross-verification
review-agent --last 5 --rounds 2

# Dry run (mock agents, inspect prompts)
review-agent --dry-run --dir src/ -v
```

### Source Options

| Flag | What it reviews |
|------|----------------|
| `--diff` | Uncommitted changes — staged + unstaged (default) |
| `--branch BASE` | Changes compared to a base branch |
| `--commit REF` | A specific commit or range |
| `--last N` | The last N commits (log + diff) |
| `--files PATH...` | Full content of specific files |
| `--dir PATH` | All files under a directory |
| `--repo` | Full repository (file tree; agents explore via tools) |

### Focus Modes

| Mode | Description |
|------|-------------|
| `balanced` | Correctness, design, security, performance (default) |
| `high-level` | Architecture, API design, module boundaries |
| `low-level` | Logic bugs, edge cases, off-by-one errors |
| `security` | OWASP Top 10, injection, auth, input validation |
| `performance` | Complexity, N+1 queries, memory leaks, caching |

### Output

Each run creates a timestamped folder in `code-review/`:

```
code-review/2026-04-11-1522/
  FINAL.md      ← unified consensus review
  claude.md     ← Claude's full review + verification notes
  codex.md      ← Codex's full review + verification notes
  debug/        ← (only with --dry-run or -v)
```
