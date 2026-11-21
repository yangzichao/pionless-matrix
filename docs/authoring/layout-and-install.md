# Repository layout and install paths

## Layout

```text
skills/
  <bucket>/
    README.md            # one line per skill in the bucket
    <skill-name>/SKILL.md
.claude-plugin/
  marketplace.json       # Claude Code marketplace, points at this repo root
  plugin.json            # Claude Code plugin, lists every skill path
scripts/
  validate-skills.py     # checks every skill against docs/authoring/skill-anatomy.md
  link-skills.sh         # symlinks every skill into local agent skill folders
docs/authoring/          # how to write a skill for this repo
AGENTS.md                # instructions for agents working in this repo (CLAUDE.md points here)
```

There is no build step. The files under `skills/` are what every host reads.

Buckets group skills by area (`research/`, `coding/`, `writing/`, `learning/`, `career/`, `setup/`). Skill names must stay unique across all buckets, because hosts install skills into one flat folder.

## Adding or renaming a skill

1. Create `skills/<bucket>/<skill-name>/SKILL.md`.
2. Add one line to `skills/<bucket>/README.md`.
3. Add the path to the `skills` array in `.claude-plugin/plugin.json`.
4. Add a row to the skill table in the top-level `README.md`.
5. Run `python3 scripts/validate-skills.py`.

## Install paths

| How | Command | What it does |
|---|---|---|
| Local symlinks (recommended for the owner) | `bash scripts/link-skills.sh` | Symlinks every skill into `~/.claude/skills` (Claude Code) and `~/.agents/skills` (Codex and other Agent Skills hosts). `git pull` updates them. |
| skills CLI, any host | `npx skills add yangzichao/pionless-matrix -g` | Copies skills into the folders of every agent it detects. |
| Claude Code plugin | `/plugin marketplace add yangzichao/pionless-matrix`, then `/plugin install pionless-matrix@pionless-matrix-marketplace` | Installs all skills as one plugin, namespaced `pionless-matrix:<skill>`. |

Pick one method per host. Using both symlinks and the Claude plugin makes each skill appear twice in Claude Code.
