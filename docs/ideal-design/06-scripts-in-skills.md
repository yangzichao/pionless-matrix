## 6. Scripts in Skills

> **Status: not finalized — needs further review.**

A skill may bundle executable code in a `scripts/` directory. Claude reads `SKILL.md` for instructions, then invokes scripts via Bash. The script's source never enters the context window — only what it writes to stdout/stderr does.

This chapter follows Anthropic's official guidance — referred to as "the spec" throughout. Anything not stated here is not part of the spec; project-local conventions belong in a separate document.

**Sources:** [Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) · [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) · [Code execution tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool)

### Directory

```
my-skill/
  SKILL.md
  scripts/
    analyze_form.py
    fill_form.py
    validate_fields.py
```

`scripts/` is one of three optional directories the spec recognizes alongside `references/` and `assets/`. Supported languages depend on the agent runtime; Python, Bash, and JavaScript are the common choices.

### Paths

- File references in `SKILL.md` are **relative to the skill root** (e.g. `scripts/extract.py`).
- Use **forward slashes only**, even on Windows. Backslashes break on Unix systems.
- Keep file references **one level deep** from `SKILL.md`. Deeply nested reference chains cause Claude to read partially and miss context.

### Declaring environment requirements

Use the optional `compatibility` field in the `SKILL.md` frontmatter to declare what the skill needs — Python version, runtime tools, system packages, network access:

```yaml
---
name: pdf-processing
description: ...
compatibility: Requires Python 3.14+ and uv
---
```

Whatever the skill depends on at runtime should be listed in `SKILL.md` or `compatibility`. The Anthropic spec does not define a `requirements.txt` convention; this project follows [ch.01](01-skill-anatomy.md), whose canonical tree puts `requirements.txt` at the skill root for skill-local Python deps when scripts need them.

### Per-surface dependency constraints

How dependencies actually become available depends on which Claude surface runs the skill ([Runtime environment constraints](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#runtime-environment-constraints)):

| Surface | Network | Runtime install |
|---|---|---|
| **claude.ai** | Varies (user/admin settings) | Can install from npm and PyPI |
| **Claude API** | None | Pre-installed packages only — no runtime install |
| **Claude Code** | Full (same as the user's machine) | Allowed; install locally, not globally |

A skill that relies on `pip install` at runtime will not work on the API. Skills targeting multiple surfaces should rely on the standard library, on packages already available in the [code execution environment](https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool), or on self-contained scripts that pull their own dependencies at run time.

### Authoring principles

From [Skills with executable code](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):

- **Solve, don't punt.** Handle error conditions inside the script. Fall back, retry, or fail with a clear message — do not let raw exceptions bubble up for Claude to interpret.
- **No voodoo constants.** Justify every configuration value with a comment. If the author can't explain why a number is what it is, Claude will not be able to either.
- **Make intent explicit in `SKILL.md`.** State whether Claude should *execute* the script ("Run `analyze_form.py` to extract fields") or *read it as reference* ("See `analyze_form.py` for the field-extraction algorithm").
- **Prefer scripts for deterministic operations.** A pre-written script is more reliable, saves tokens, and stays consistent across runs compared to having Claude regenerate equivalent code.

### How `SKILL.md` invokes a script

`SKILL.md` invokes a script via a fenced bash block:

````markdown
Run the form analyzer:

```bash
python scripts/analyze_form.py input.pdf > fields.json
```

The script writes JSON to stdout. Read `fields.json` and continue with the workflow.
````

The script's source never enters the context window — only the bytes it writes to stdout/stderr do. This is the main reason to package a deterministic operation as a script rather than asking Claude to write equivalent code inline.

### What the spec does not specify

The official Anthropic spec is silent on:

- The internal structure of `scripts/` — subfolders, helper modules, naming conventions.
- The working directory at script invocation time (relative paths from skill root work in practice).
- A canonical place for tests inside a skill. The closest documented concept is **evaluations**, recorded in `evals/evals.json` per the [best-practices guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — these test agent behavior on representative tasks, not script units. For this project, [ch.01](01-skill-anatomy.md)'s canonical tree places author-side script tests under `tests/` inside the skill folder, separate from any `evals/` directory.

Anything beyond what this chapter states or what ch.01 fixes is project-local convention and should be documented as such, not treated as part of the Anthropic Skills spec.
