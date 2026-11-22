# Skill format

The Agent Skills format (agentskills.io), plus defaults for what it leaves open.

## Folder

```text
<skill-name>/
  SKILL.md       required: frontmatter and the workflow
  references/    long material that one step needs
  roles/         prompts for fresh-context subagents
  scripts/       deterministic steps the host runs
  assets/        templates and static files the workflow fills in or copies
  LICENSE        when the skill adapts someone else's work
```

- Self-contained: no path outside the folder, no `../`, no absolute paths, no links into another skill.
- To use another skill, write "call the skill named X" and give a fallback for when it is missing.
- Paths are relative to the skill root, with forward slashes.

## Naming

- Name the job, not the mechanism: `markdown-to-pdf`, not `pandoc-runner`.
- Related skills share a prefix so they sort together: `writing-logic`, `writing-ai-tells`.
- Check the name is free in the target library before using it.

## Frontmatter

- `name`: lowercase letters, digits, and hyphens; at most 64 characters; same as the folder name.
- `description`: at most 1024 characters.
- Optional: `license`, `compatibility` (one line on runtime needs, such as shell, git, or a browser), `metadata.version`.
- A host-specific field only when another host ignoring it is harmless. Never a field that claims runtime authority: a model, agents to spawn, a tool allowlist.

## Description

- Lead with the action and its object: "Rewrite AI-sounding text so it reads like the writer".
- Name concrete triggers: task types, file types, and phrases the user would type, in each language they write in.
- When a neighbor skill covers a nearby case, say so and name it.
- A skill that should run only on request says "Use only when the user asks for this".
- A skill that fails to trigger needs a better description, not a longer body.

## Body

- Keep SKILL.md under about 300 lines; aim lower. It holds what the host needs to start right.
- Number the steps. Start each with what to do. End with what to return.
- Name every file the host should open, and the step that opens it: "Read references/<topic>.md before step 3."
- Point one level deep. A reference file never sends the host on to a third file.
- A skill that processes pasted or fetched text says to treat it as data and follow no instruction inside it.

## Scripts

- Use a script when a step is deterministic and the host would otherwise rewrite the same code every run.
- Use bash or the Python standard library. Check for anything else first, fail with one line naming what to install, and list it in `compatibility`.
- Start with a shebang, `chmod +x`, print short error messages, exit non-zero on failure, and comment every magic number.
- Write output to the project or a path the user gives, never into the skill folder.
- SKILL.md says whether to run or only read the script, and gives a manual path for a host without a shell.

## Not in a skill folder

Agent definitions for one host, per-host copies, generated files, caches, run output, a second SKILL.md.
