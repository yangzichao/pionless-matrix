# Repository layout and install paths

## Layout

```text
skills/
  <skill-name>/SKILL.md  # one folder per skill, flat
archive/
  <bucket>/<skill-name>/ # retired skills, read-only, never installed (see archive/README.md)
.claude-plugin/
  marketplace.json       # Claude Code marketplace, points at this repo root
  plugin.json            # Claude Code plugin, lists every skill path
scripts/
  validate-skills.py     # checks every skill against docs/authoring/skill-anatomy.md
  install-stable-copy.sh # keeps a clean copy on main and links hosts to it
  link-skills.sh         # symlinks the skills of the checkout it runs in
docs/authoring/          # how to write a skill for this repo
AGENTS.md                # instructions for agents working in this repo (CLAUDE.md points here)
```

There is no build step. The files under `skills/` are what every host reads.

Live skills sit flat under `skills/`, the same way every host installs them into one flat folder. The skill name is the folder name. Only `archive/` groups skills into buckets, to keep retired skills easy to browse.

## Adding or renaming a skill

1. Create `skills/<skill-name>/SKILL.md`.
2. Add the path to the `skills` array in `.claude-plugin/plugin.json`.
3. Add a row to the skill table in the top-level `README.md`.
4. Run `python3 scripts/validate-skills.py`.

## Retiring a skill

Move it to `archive/<bucket>/<skill-name>/` and rename its `SKILL.md` to `SKILL.archived.md`, then undo steps 2 and 3 above. `archive/README.md` has the exact commands. The rename matters: `npx skills add --full-depth` installs any file named `SKILL.md` anywhere in the repo.

## Install paths

| How | Command | What it does |
|---|---|---|
| Stable copy plus symlinks (recommended for the owner) | `bash scripts/install-stable-copy.sh` | Clones or fast-forwards a clean copy on `main` at `~/.local/share/pionless-matrix`, then symlinks every skill from it into `~/.claude/skills` (Claude Code) and `~/.agents/skills` (Codex and other Agent Skills hosts). Re-run after each merge to update. |
| Symlinks to a checkout (trying a branch) | `bash scripts/link-skills.sh` | Same links, but into the checkout it runs in, so hosts follow that checkout's branch and edits. Re-run `install-stable-copy.sh` to switch back. |
| skills CLI, any host | `npx skills add yangzichao/pionless-matrix -g` | Copies skills into the folders of every agent it detects. |
| Claude Code plugin | `/plugin marketplace add yangzichao/pionless-matrix`, then `/plugin install pionless-matrix@pionless-matrix-marketplace` | Installs all skills as one plugin, namespaced `pionless-matrix:<skill>`. |

Pick one method per host. Using both symlinks and the Claude plugin makes each skill appear twice in Claude Code.
