# pionless-matrix

A personal Agent Skills library. Skills live in `skills/<bucket>/<skill-name>/SKILL.md` and are read as-is by every host. There is no build step and nothing is generated.

## Rules

- Follow `docs/authoring/` on every skill change. `skill-anatomy.md` and `subagent-roles.md` are binding.
- Skills must be host-neutral: no host-specific agent definitions, tool names, or model choices. Subagent work goes in the skill's own `roles/<role>.md` with a fallback for hosts without subagents.
- A skill folder is self-contained. No paths outside it; to use another skill, say "call the skill named X".
- Adding, renaming or removing a skill means updating, in the same change: the bucket `README.md`, the `skills` array in `.claude-plugin/plugin.json`, and the table in the top-level `README.md`.
- Bump `metadata.version` in the skill's frontmatter: patch for behavior fixes, minor for new capabilities. Bump `.claude-plugin/plugin.json` `version` when releasing. Versions are manual.
- Before reporting done, run `python3 scripts/validate-skills.py` and `bash -n` on any changed shell script. After touching `.claude-plugin/`, also run `claude plugin validate .` if the Claude Code CLI is installed.

## Research output

When running research in this repo, write reports to `deep-research/` at the repo root (gitignored), named `YYYY-MM-DD-HHMM-topic.md`, with workspace files using the same prefix (`YYYY-MM-DD-HHMM-topic.workspace.md`).
