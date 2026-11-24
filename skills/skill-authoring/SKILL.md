---
name: skill-authoring
description: |
  Create, revise, or test an Agent Skill: a folder with a SKILL.md that any Agent
  Skills host can read. Writes host-neutral, lean skills: a description that routes,
  ordered steps, branch-only detail in references/, subagent prompts in roles/, and
  deterministic steps in scripts/. Validates the folder, has a fresh reader run it
  cold, and can fold this session's lessons into a skill or blind-test a skill
  change. Use when the user asks to write, create, or scaffold a skill, turn a
  workflow into a skill, tighten or shorten a skill, fix a skill that does not
  trigger, reflect on this session into a skill, or A/B test a skill edit; also
  "写个 skill", "把这个流程做成 skill", "这个 skill 太啰嗦", "这个 skill 不触发",
  "把这次的教训写进 skill", "A/B 测一下这个 skill 改动".
license: MIT
metadata:
  version: "0.1.1"
---

# Skill authoring

Adapted in part from pstack by Lauren Tan (MIT, see `LICENSE`): its authoring-a-skill and eval playbooks and its reflect skill.

## Files

- `references/skill-format.md`: folder, naming, frontmatter, description, body, scripts. Read before step 2.
- `references/host-neutral-wording.md`: capability wording, fallbacks, role files. Read before step 3.
- `references/prose-rules.md`: the cut pass. Read before step 4.
- `references/session-lessons.md`: Lessons mode.
- `references/blind-eval.md`: Eval mode.
- `roles/cold-reader.md`: step 6.
- `roles/judge.md`: Eval mode.
- `scripts/check-skill.py`: step 5.

## Modes

- **New:** the user describes a workflow or asks for a skill. Run every step.
- **Revise:** an existing skill needs a fix, a cut, or a new capability. Run every step.
- **Lessons:** the user asks to reflect, or to keep what this session taught. Follow `references/session-lessons.md`. Run each approved finding as Revise.
- **Eval:** the user wants to know whether a change makes a skill better. Follow `references/blind-eval.md` instead of the steps, dispatch its judge from `roles/judge.md` the way step 6 dispatches the cold reader, and reply with its report.

## Steps

1. **Read the house rules.** In the target repo, look for an authoring guide (AGENTS.md, CONTRIBUTING, docs about skills) and a skill validator, and read two existing skills. House rules win over this skill's defaults; list every conflict in the reply. With no repo, use this skill's references.
2. **Pin the job.** In Revise mode, first read the whole skill, references and roles included. Edit only the source copy the user owns, never an installed copy in a host's cache or plugin folder; if that is the only copy you find, ask where the source lives. Then write a job card, one line each: what the skill does, when it triggers, what it takes in, what it returns, what it must not do. Check existing skill names and descriptions for overlap, and extend a skill rather than add a near-duplicate. In New mode, pick the name and the folder: the house rules' skills directory, or ask the user. Ask the user only what you cannot infer.
3. **Draft.** Write the description first: it is all a host reads before deciding to load the skill. Then write the steps in order, ending with what to return. Move branch-only detail to references, separate-context work to roles, and repeated deterministic work to scripts. Give every capability a host might lack a fallback.
4. **Cut.** Apply `references/prose-rules.md` to every file. If a skill named writing-ai-tells is available, also call it in embedded mode on the prose, and tell it to keep every rule, path, and step number.
5. **Validate.** If you have a shell, run `python3 scripts/check-skill.py <skill-folder>` from this skill's folder, with the target folder's absolute path. Fix every error; fix each warning or say in the reply why it stays. Then run the repo's own validator, if any. Without a shell, check by hand: the name matches the folder, the description is under 1024 characters, every named path exists, no link leaves the folder, SKILL.md names every support file, no host tool, agent, or model names appear, and each script has a shebang and is executable.
6. **Cold read.** Dispatch the cold reader.
   - If you can start subagents: start one with a fresh context (not a fork of this conversation). Give it the full text of `roles/cold-reader.md`, then the skill folder's path and the job card. Ask for read-only work if your host lets you restrict tools.
   - If you cannot: do it yourself as a separate pass. Re-read `roles/cold-reader.md`, work only from the folder and the job card, and produce exactly the output it specifies.
   Fix every blocking finding. Decide the rest yourself.
7. **Register.** Do what the house rules require when a skill is added or changed: manifest entries, README rows, version bump, changelog. Without house rules, bump `metadata.version`: patch for fixes, minor for new capability. Do not push or open a pull request unless the user asks.
8. **Offer an eval** when the change alters behavior the user will rely on. Do not run one unasked.

## Reply

The job card, the files written or changed, key design decisions, house-rule conflicts, each validator command with its result and any warning left in place, and each cold-reader finding with what you did about it.
