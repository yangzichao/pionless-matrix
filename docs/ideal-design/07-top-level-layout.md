## 7. Top-Level Layout

> **Status: finalized.** This chapter is the synthesis of chapters 01–06. It defines the repository shape implied by the lower-level decisions; revisit only when one of those chapters changes.

Once the lower-level decisions are fixed, most of the repository shape follows:

- a skill is a directory package (chapter 01);
- an agent is a single markdown definition (chapter 02);
- skills do not share prompt content — duplicates are physical (chapter 03);
- the source layer is Claude-first; other platforms are produced by translation (chapter 04);
- orchestration topology lives in the orchestrator's `tools: Agent(...)`, not in folder structure (chapter 05);
- a skill may bundle scripts inside its own `scripts/` directory (chapter 06).

The top-level layout follows from these. It should be organized by **lifecycle first** (source vs generated) and **runtime concept second** (skills vs agents).

### First split: source vs generated

The most important boundary is between files humans author and files the build derives. Source-of-truth content lives under one authoring tree. Generated platform outputs, assembled plugin bundles, and normalized published skills live elsewhere.

If source and generated files mix inside the same subtree, authors stop knowing where edits belong, reviews become noisy, and stale generated artifacts drift.

### Source tree

```text
repo-root/
  CLAUDE.md
  build.sh
  src/
    skills/
      <skill-name>/
        SKILL.md
        references/
        assets/
        scripts/
    agents/
      <agent-name>.md
```

This is the recommended authoring layout.

- `src/skills/` contains self-contained skill packages. Each skill is its own directory holding its `SKILL.md`, plus optional `references/`, `assets/`, and `scripts/` (chapter 01, chapter 06).
- `src/agents/` contains source-of-truth agent definitions, each as a single `.md` file (chapter 02). Flat — no folder form, no nesting by orchestrator/worker role (chapter 05).

Skills and agents are siblings. They are different runtime concepts and deserve different top-level homes.

**No `src/shared/`.** Chapter 03 decided against shared prompt fragments between skills; if two skills need similar text they each carry their own copy. Chapter 06 puts skill scripts inside each skill's own `scripts/` directory. There is therefore nothing for a `src/shared/` tree to hold at the source layer. (The `shared/` folder under repo root is something else — a generated output, covered below.)

### Agent layout: keep it flat

The part that is easiest to overdesign is `src/agents/`. Do not make each agent a folder by default.

```text
src/agents/
  deep-research.md
  deep-research-pro.md
  quick-research.md
  deep-research-worker.md
  deep-research-verifier.md
  parallel-fix-worker.md
```

This is the right source layout for agents because the source-of-truth runtime object is one markdown file (chapter 02).

Folder nesting does not buy much here:

- An orchestrator/worker distinction is a runtime relationship, not a filesystem type (chapter 05).
- Nesting workers under one orchestrator couples a reusable worker to one parent. A bonded worker may legitimately appear in multiple orchestrators' `Agent(...)` allowlists, and the bonded prefix declares provenance, not exclusivity (chapter 05).
- Splitting into `orchestrators/` and `workers/` freezes one role classification too early; the same agent definition can be a main-session orchestrator in one context and a leaf in another.

When an agent needs related material, that material usually belongs somewhere else:

- reusable workflow knowledge belongs in a skill (chapter 01);
- test fixtures belong in `tests/`;
- helper scripts belong in `scripts/` inside the skill that owns the workflow (chapter 06).

Only introduce an agent folder if the source-of-truth agent format itself stops being single-file. Until then, flat files are the stable convention.

### Platform packaging layer

Platform-specific packaging metadata lives outside `src/`:

```text
platforms/
  claude-code/
    .claude-plugin/
  codex/
    .codex-plugin/
```

These directories hold platform scaffolding and packaging metadata only. They do not replace `src/agents/` or `src/skills/` as the source of truth. The build writes generated agent files into platform-specific output directories beside the scaffolding, but humans still edit the source definitions under `src/`.

This split is what chapter 04 calls "Claude-first source with platform-specific projections." Per-platform forks of `src/` are not allowed; per-platform packaging metadata is.

### Generated outputs

The build materializes several different outputs, each for a different purpose:

```text
shared/
  skills/                  # normalized published skill trees

dist/
  claude-plugin/
  codex-plugin/

plugins/
  pionless-agent/          # assembled repo-local installable bundle
```

- `shared/skills/` holds the published, host-agnostic copy of each skill. It is not a place to put hand-authored shared content (chapter 03 forbade that); it is the post-build snapshot of `src/skills/`.
- `dist/claude-plugin/` and `dist/codex-plugin/` are the per-platform plugin bundles, each combining the matching `platforms/<target>/` scaffolding with the published skills and translated agents.
- `plugins/pionless-agent/` is an in-repo committed bundle for users who want a single-directory install without going through `dist/`.

The exact folder names can change. The important invariant is that everything in this section is a derived artifact. If a file can be regenerated, it should not be the place humans edit.

`CLAUDE.md` documents which directories are GENERATED so authors do not edit them by mistake.

### Recommendation

The repository should be grouped by runtime concept inside one source tree, with derived outputs kept outside it:

1. `src/skills/<name>/` — self-contained skill packages (chapter 01, chapter 06).
2. `src/agents/<name>.md` — flat single-file agent definitions (chapter 02, chapter 05).
3. `platforms/<target>/` — platform-specific packaging metadata, no source forks.
4. `shared/skills/`, `dist/<target>-plugin/`, `plugins/<bundle>/` — generated outputs outside `src/`.

This resolves the agent-layout question cleanly. Agents are not mini-packages at the source layer; they are single-file definitions. And the absence of `src/shared/` is a deliberate consequence of chapter 03 — there is nothing for it to hold.
