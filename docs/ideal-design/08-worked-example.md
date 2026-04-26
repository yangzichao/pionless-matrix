## 8. Worked Example

A `deep-research` skill that uses build-time includes to share research rules with other skills, ships a Python script for source extraction, and spawns `research-worker` subagents via a `research-orchestrator` agent.

### Source tree

```
repo-root/
  manifest.yaml
  build/
    build.sh
    include-expander.py
    manifest-router.py
    md-to-toml.py
  src/
    shared/
      fragments/
        research-rules.md
        citation-format.md
        output-gates.md
        token-budgets.md
      templates/
        report-skeleton.md
        workspace-skeleton.md
      schemas/
        research-output.json
    skills/
      deep-research/
        SKILL.md
        scripts/
          extract_sources.py
          dedupe_citations.py
          lib/
            url_normalizer.py
        references/
          domain-glossary.md
          known-good-sources.md
        assets/
          report-template.md
          workspace-template.md
        tests/
          fixtures/
            sample_query.json
          test_extract_sources.py
        requirements.txt
    agents/
      research-orchestrator/
        AGENT.md
        scripts/
          merge_reports.py
        tests/
          test_merge_reports.py
      research-worker.md
  dist/
    claude-code/
      .claude-plugin/
        plugin.json
      skills/
        deep-research/
          SKILL.md                          # includes expanded inline
          scripts/
            extract_sources.py
            dedupe_citations.py
            lib/url_normalizer.py
          references/
            domain-glossary.md
            known-good-sources.md
          assets/
            report-template.md
            workspace-template.md
      agents/
        research-orchestrator.md            # flattened from src folder form
        research-worker.md
      scripts/
        research-orchestrator/              # orchestrator's scripts hoisted here
          merge_reports.py
    codex/
      skills/
        deep-research/
          SKILL.md
          scripts/
          references/
          assets/
      agents/
        research-orchestrator.toml
        research-worker.toml
        research-orchestrator/              # orchestrator scripts kept beside
          merge_reports.py
      install.sh                            # cp into ~/.agents/skills and ~/.codex/agents
  docs/
    ideal-design.md
    contributor-guide.md
  tests/
    integration/
      test_full_research_flow.py
```

### `src/skills/deep-research/SKILL.md`

```markdown
---
name: deep-research
description: Conducts multi-source research on a topic, produces a cited report.
platforms: [claude-code, codex]
allowed-tools: [Bash, Read, Write, WebFetch, Task]
spawns-agents: [research-orchestrator, research-worker]
---

# Deep Research

<!-- include: shared/fragments/research-rules.md -->

## Workflow

1. Parse the user's question.
2. Run `python scripts/extract_sources.py --query "$QUERY"` to gather candidate sources.
3. For broad questions, invoke the `research-orchestrator` agent to parallelize across `research-worker` subagents.
4. Merge results, dedupe citations: `python scripts/dedupe_citations.py --input merged.json`.
5. Write the report using the template at `assets/report-template.md`.

<!-- include: shared/fragments/citation-format.md -->

<!-- include: shared/fragments/output-gates.md -->

## References

- For domain terminology, read `references/domain-glossary.md`.
- For source-quality heuristics, read `references/known-good-sources.md`.
```

### `src/agents/research-orchestrator/AGENT.md`

```markdown
---
name: research-orchestrator
description: Spawns parallel research-worker subagents and merges their outputs.
platforms: [claude-code, codex]
allowed-tools: [Bash, Read, Write, Task]
spawns-agents: [research-worker]
invokable-by: [skill, agent]
---

# Research Orchestrator

<!-- include: shared/fragments/token-budgets.md -->

## Protocol

1. Receive a research question and a list of sub-questions.
2. For each sub-question, invoke `research-worker` with a clear scope.
3. Collect worker outputs as JSON.
4. Run `python scripts/merge_reports.py --inputs worker_outputs/` to merge.
5. Return the merged report to the caller.

<!-- include: shared/fragments/output-gates.md -->
```

### `src/agents/research-worker.md`

```markdown
---
name: research-worker
description: Researches a single sub-question and returns structured findings.
platforms: [claude-code, codex]
allowed-tools: [Bash, Read, Write, WebFetch]
invokable-by: [agent:research-orchestrator]
---

# Research Worker

<!-- include: shared/fragments/research-rules.md -->

## Protocol

1. Receive a single sub-question and source budget.
2. Fetch and read sources up to the budget.
3. Return findings as JSON matching `shared/schemas/research-output.json`.

<!-- include: shared/fragments/citation-format.md -->
```

### `src/skills/deep-research/scripts/extract_sources.py`

```python
"""Extract candidate sources for a research query.

Invoked from SKILL.md as:
    python scripts/extract_sources.py --query "$QUERY"

Writes a JSON list of {url, title, snippet} to stdout.
"""
import argparse
import json
import sys
from lib.url_normalizer import normalize

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--query", required=True)
    args = parser.parse_args()
    # ... gather sources ...
    json.dump(sources, sys.stdout)

if __name__ == "__main__":
    main()
```

### `manifest.yaml`

```yaml
version: 1
platforms:
  claude-code:
    skills-dir: dist/claude-code/skills
    agents-dir: dist/claude-code/agents
    agent-format: markdown
  codex:
    skills-dir: dist/codex/skills
    agents-dir: dist/codex/agents
    agent-format: toml
build:
  include-resolver: build/include-expander.py
  agent-converter: build/md-to-toml.py
  exclude-from-dist:
    - tests/
    - "**/*.test.*"
    - "**/__pycache__/**"
```

### Build outputs

After running `bash build/build.sh`:

- `dist/claude-code/skills/deep-research/SKILL.md` is a single self-contained file with all `<!-- include: -->` directives expanded inline.
- `dist/claude-code/skills/deep-research/scripts/` contains `extract_sources.py`, `dedupe_citations.py`, and `lib/url_normalizer.py`. Tests are excluded.
- `dist/claude-code/agents/research-orchestrator/AGENT.md` is the expanded markdown.
- `dist/claude-code/agents/research-worker.md` is the expanded markdown.
- `dist/codex/agents/research-orchestrator.toml` is the agent converted to TOML.
- `dist/codex/agents/research-worker.toml` is the worker converted to TOML.
- Both platform trees contain a copy of the `deep-research` skill because its frontmatter declares `platforms: [claude-code, codex]`.

### What this proves

The example exercises every part of the design:

- A skill with scripts, references, assets, and tests (Section 1).
- An agent in folder form because it ships scripts (Section 2).
- An agent in file form because it does not (Section 2).
- Skills and agents as flat siblings under `src/` (Section 3).
- Shared fragments in `src/shared/`, pulled in via build-time includes (Section 4).
- Cross-platform routing driven by frontmatter and `manifest.yaml`, with no folder split (Section 5).
- Orchestrator and worker as siblings, with the relationship encoded in `spawns-agents` and `invokable-by` (Section 6).
- Python scripts in `scripts/` with a `lib/` subfolder for helpers, invoked from SKILL.md by relative path (Section 7).

The structure stays correct if a second skill starts using `research-worker`, if a Codex-only skill is added, if `research-orchestrator` grows a third worker type, or if a new shared fragment is introduced. No move, rename, or restructure is required for any of those changes.
