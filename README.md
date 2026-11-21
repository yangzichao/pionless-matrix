# pionless-matrix

My personal [Agent Skills](https://agentskills.io) library. Every skill is a plain `SKILL.md` folder, so the same files work in Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot, OpenCode, and any other host that reads the format. There is no build step.

## Skills

| Skill | Bucket | What it does |
|---|---|---|
| [deep-research](skills/research/deep-research/SKILL.md) | research | Plan-board research loop: parallel evidence gathering, adversarial claim checks, and a cited report in one of six styles. |
| [markdown-to-pdf](skills/research/markdown-to-pdf/SKILL.md) | research | Markdown to PDF through Pandoc and headless Chrome, with KaTeX math, mermaid, and citations matching the editor preview. |
| [hoah-coder](skills/coding/hoah-coder/SKILL.md) | coding | One focused coding task, driven through clarify, implement, self-check, and an independent reviewer loop until clean. |
| [parallel-fix](skills/coding/parallel-fix/SKILL.md) | coding | Scan for a class of issues, fix each one in its own git worktree in parallel, merge back, run a final check. |
| [no-comments](skills/coding/no-comments/SKILL.md) | coding | Delete comments in a diff through an independent Comment Sicko pass, flag the code they excuse, and fix it at the root. Adapted from backnotprop/pstack. |
| [solo-ralph](skills/coding/solo-ralph/SKILL.md) | coding | Turn a vague goal into a spec and todo, then run a detached loop of fresh agent processes until the todo is done. |
| [humanizer](skills/writing/humanizer/SKILL.md) | writing | Rewrite AI-sounding prose so it reads like the writer without changing what it says. From blader/humanizer, with the plain-style rules of pstack's unslop merged in. |
| [socratic-tutor](skills/learning/socratic-tutor/SKILL.md) | learning | Teach by guided questioning with controlled depth and periodic zoom-out recaps. |
| [onepoint3acres-interview-scraper](skills/career/onepoint3acres-interview-scraper/SKILL.md) | career | Scrape 一亩三分地 面经 for a company and role, filter, cross-check, and cluster them into a 题库. |
| [freshwater-doctor](skills/setup/freshwater-doctor/SKILL.md) | setup | Read-only check of the Lean 4 + Mathlib + Wolfram + MCP math stack, with the next install step. |

Skills that split work across subagents (deep-research, hoah-coder, parallel-fix, no-comments) keep the subagent prompts in their own `roles/` folder. On a host without subagents, the agent runs each role itself as a separate pass.

## Install

Pick one method per host.

Local symlinks, for working on this repo. `git pull` updates every host:

```bash
bash scripts/link-skills.sh
```

This links every skill into `~/.claude/skills` (Claude Code) and `~/.agents/skills` (Codex and other hosts that read the shared folder). Set `SKILL_LINK_DESTS` to choose other folders. `--unlink` removes the links.

Any agent, through the [skills CLI](https://github.com/vercel-labs/skills):

```bash
npx skills add yangzichao/pionless-matrix -g
```

Claude Code plugin (skills are namespaced `pionless-matrix:<skill>`):

```text
/plugin marketplace add yangzichao/pionless-matrix
/plugin install pionless-matrix@pionless-matrix-marketplace
```

## Layout

```text
skills/<bucket>/<skill-name>/   SKILL.md + optional references/ roles/ assets/ scripts/
.claude-plugin/                 Claude Code marketplace + plugin manifest
scripts/validate-skills.py      checks every skill (also runs in CI)
scripts/link-skills.sh          local symlink install
docs/authoring/                 how to write a skill for this repo
```

## Contributing a skill

Read [docs/authoring/README.md](docs/authoring/README.md), then run:

```bash
python3 scripts/validate-skills.py
```
