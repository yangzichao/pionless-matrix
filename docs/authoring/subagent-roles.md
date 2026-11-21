# Subagent roles

Some workflows work better when part of the job runs in a separate context: a reviewer that has not seen the coder's reasoning, a research worker that only sees one subquestion, a fixer inside its own worktree. This repo does not ship host-specific agent definitions for that. Each such part is a plain prompt file under the skill's own `roles/` folder.

## Role file

`roles/<role>.md` is the full prompt a fresh subagent receives. It has no frontmatter. It contains:

1. **Who you are and what you get.** One short paragraph, then the inputs the caller will pass (a task card, a path, a diff range).
2. **What to do.** The procedure, in order.
3. **What you must not do.** For example: do not edit files, do not widen scope.
4. **What to return.** The exact output format, usually a JSON object or a fixed markdown shape, so the caller can parse it.
5. **You are a leaf.** Do the task and return the result. Do not start further subagents.

The role file must stand alone. The subagent does not see `SKILL.md`, the conversation, or other role files. If the role needs a reference (for example a report style), the caller pastes it into the task card or names a path the subagent can read.

## Dispatch wording in SKILL.md

Use the same shape every time:

```markdown
Dispatch the reviewer.
- If you can start subagents: start one with a fresh context (not a fork of this conversation).
  Give it the full text of `roles/reviewer.md`, then the task card. Ask for read-only work if your host lets you restrict tools.
- If you cannot: do the review yourself as a separate pass. Re-read `roles/reviewer.md`,
  work only from the task card, and produce exactly the output it specifies.
```

Rules:

- Always ask for a fresh context. Some hosts fork the parent conversation by default, which defeats the point.
- Never name a host-specific agent type, model, or tool allowlist. Say what the role needs in prose ("read-only", "needs shell and git") and let the host map it.
- Independent roles can run in parallel: "start all workers at once if your host allows parallel subagents; otherwise run them one after another."
- The caller owns merging, judgment and the final answer. Roles return data.
