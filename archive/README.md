# Archive

Retired skills, kept here only so they are easy to read. Nothing in this folder is installed or validated.

## Layout

```text
archive/
  <bucket>/
    <skill-name>/
      SKILL.archived.md   # the old SKILL.md, renamed
      ...                 # the rest of the skill folder, unchanged
```

The rename is what keeps the skill out of every install path. `link-skills.sh` and `validate-skills.py` only look under `skills/`. `npx skills add --full-depth` searches the whole repo for files named exactly `SKILL.md`, so a renamed file is never picked up.

## Archiving a skill

1. `git mv skills/<bucket>/<skill-name> archive/<bucket>/<skill-name>`
2. `git mv archive/<bucket>/<skill-name>/SKILL.md archive/<bucket>/<skill-name>/SKILL.archived.md`
3. Remove the skill from `skills/<bucket>/README.md`, the `skills` array in `.claude-plugin/plugin.json`, and the table in the top-level `README.md`.
4. Add a line below.
5. Run `bash scripts/link-skills.sh` to drop the stale local symlink, then `python3 scripts/validate-skills.py`.

To restore one, reverse the steps.

## Archived skills

None yet.
