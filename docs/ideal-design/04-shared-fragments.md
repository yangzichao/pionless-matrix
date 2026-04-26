## 4. Shared Fragments

When prompt content is reused across skills or agents — research rules, output gates, token budgets, writing style guides, citation rules — it lives in `src/shared/`. Duplicating prompt fragments is the fastest path to drift.

### Layout

```
src/shared/
  fragments/
    research-rules.md
    citation-format.md
    token-budget-warnings.md
    output-gates.md
  templates/
    report-skeleton.md
    workspace-skeleton.md
  schemas/
    research-output.json
```

`fragments/` holds prose included into SKILL.md or AGENT.md bodies. `templates/` holds files used as runtime assets (copied into a skill's `assets/` at build time, or referenced directly). `schemas/` holds JSON/YAML schemas referenced by scripts.

### How a SKILL.md references shared content

Three mechanisms exist; each has a distinct correct use.

| Mechanism | How it works | Right use | Wrong use |
|---|---|---|---|
| **Build-time include** | `<!-- include: shared/fragments/research-rules.md -->` is expanded into the file at build time. The dist artifact is self-contained. | Prose fragments composed into SKILL.md / AGENT.md bodies. | Anything that must be editable post-build or platform-variant. |
| **Runtime read** | SKILL.md instructs the model to read a path that is copied into the skill's `references/` at build time. | Long reference docs the model loads on demand. | Short fragments — the indirection costs more than the duplication saves. |
| **Symlink** | A symlink in the source tree points from a skill's `references/foo.md` to `shared/fragments/foo.md`. | Never. | Always — symlinks break on Windows, in tarballs, in some package managers, and confuse build tools. |

### Recommendation: build-time include for prose, runtime read for long references, never symlinks

Build-time includes win for prose fragments because the dist artifact ends up self-contained — the runtime sees one file with no indirection, and the build deterministically resolves drift. Runtime reads (with the file copied into `references/` at build time) are right for long documents the model conditionally loads, because inlining them would bloat every invocation. Symlinks are a non-starter for cross-platform shipping.

### Include directive specification

```markdown
<!-- include: shared/fragments/research-rules.md -->
<!-- include: shared/fragments/citation-format.md#strict -->
```

The `#anchor` form pulls a named section (delimited by `<!-- region: strict -->` / `<!-- endregion -->` in the source). Includes are non-recursive by default; the build fails on cycles.
