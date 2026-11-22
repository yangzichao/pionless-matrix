# Host-neutral wording

The host is the agent that runs the skill. It owns the model, the tools, the permissions, and whether subagents exist. Write against capabilities.

| Write | Not |
|---|---|
| If you can start subagents, ... | a host's agent type or spawn tool |
| If you have shell access, run `scripts/<name>` | a host's shell tool |
| Search the web | a host's search tool |
| Ask the user | a host's question tool |
| Call the skill named X | a slash command or a path into another skill |
| (nothing) | a model name or reasoning level |

- A product name is fine when it is the subject of the skill, not when it is only the host running it.
- Never keep one host's wording plus a table that maps it to other hosts. Rewrite each line in capability terms.
- When adapting a skill written for one host, remove tool and parameter names, agent types, model choices, host-only paths such as a host's config folder, and steps that call a host's built-in command. Replace each with a capability and a fallback, or cut it.

## Role files

Work that needs a separate context goes in `roles/<role>.md`: a reviewer who has not seen the author's reasoning, a worker on one subquestion, a blind judge.

A role file is the whole prompt a fresh subagent gets, with no frontmatter, in this order:

1. Who you are and what you get: one paragraph, then the inputs.
2. What to do, in order.
3. What you must not do.
4. What to return, in a fixed shape the caller can parse.
5. You are a leaf: do not start further subagents.

It must stand alone. The subagent sees neither SKILL.md nor the conversation.

Dispatch it from SKILL.md with this shape:

```markdown
Dispatch the <role>.
- If you can start subagents: start one with a fresh context (not a fork of this conversation).
  Give it the full text of `roles/<role>.md`, then the role's inputs. Ask for read-only work if your host lets you restrict tools.
- If you cannot: do it yourself as a separate pass. Re-read `roles/<role>.md`,
  work only from those inputs, and produce exactly the output it specifies.
```

- Name what the role needs in prose ("read-only", "needs shell and git") and let the host map it.
- Independent roles may run in parallel when the host allows; otherwise one after another.
- The caller owns merging, judgment, and the final answer. Roles return data.
