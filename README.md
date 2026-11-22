# pionless-matrix

My personal [Agent Skills](https://agentskills.io) library. Every skill is a plain `SKILL.md` folder, so the same files work in Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot, OpenCode, and any other host that reads the format. There is no build step.

## Skills

| Skill | What it does |
|---|---|
| [deep-research](skills/deep-research/SKILL.md) | Plan-board research loop: parallel evidence gathering, adversarial claim checks, and a cited report in one of six styles. |
| [markdown-to-pdf](skills/markdown-to-pdf/SKILL.md) | Markdown to PDF through Pandoc and headless Chrome, with KaTeX math, mermaid, and citations matching the editor preview. |
| [no-comments](skills/no-comments/SKILL.md) | Delete comments in a diff through an independent Comment Sicko pass, flag the code they excuse, and fix it at the root. Adapted from backnotprop/pstack. |
| [writing-ai-tells](skills/writing-ai-tells/SKILL.md) | Rewrite AI-sounding prose so it reads like the writer without changing what it says. From blader/humanizer, with the plain-style rules of pstack's unslop merged in. |
| [writing-logic](skills/writing-logic/SKILL.md) | Write or restructure prose with strong, blunt logic: one of four paragraph types per paragraph (answer, argument, explanation, critique), one main claim per document, answer-first or guided (step-by-step) shape, plain scientific sentences, a logic skeleton shown before and after drafting, a counted length budget (one claim plus at most three sentences per paragraph), then a logic-critic pass. |
| [socratic-tutor](skills/socratic-tutor/SKILL.md) | Teach by guided questioning with controlled depth and periodic zoom-out recaps. |
| [question-the-question](skills/question-the-question/SKILL.md) | Check whether the user is asking the right question and replace it: down to the deeper question many questions circle, up from a vague question to concrete ones, back from a solution to the problem it solves, or reverse to audit the assistant's unconfirmed assumptions. Stops once the user confirms the better question. |
| [unknown-unknowns](skills/unknown-unknowns/SKILL.md) | Find what you don't know you don't know about a plan, decision, or unfamiliar field: hold your picture of the task against outside references (how practitioners break it down, how attempts fail, what similar cases took) and turn unstated assumptions into either-or choices. After Thariq's "Know your unknowns". |
| [code-unknowns](skills/code-unknowns/SKILL.md) | Find the gap between a coding plan and the real codebase: a blindspot pass before implementation, a deviation log during it, and a plan-against-diff check with a quiz before merge. After Thariq's "Know your unknowns" and the blindspot-pass skill in arniesaha/ctxops. |

Skills that split work across subagents (deep-research, no-comments, writing-logic, unknown-unknowns, code-unknowns) keep the subagent prompts in their own `roles/` folder. On a host without subagents, the agent runs each role itself as a separate pass.

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
skills/<skill-name>/            SKILL.md + optional references/ roles/ assets/ scripts/
archive/                        retired skills, kept for reading only, never installed
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
