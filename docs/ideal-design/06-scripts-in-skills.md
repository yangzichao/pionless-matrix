## 6. Scripts in Skills

Executable scripts (Python, Bash, or any language the runtime supports) live in `scripts/` inside the skill folder. They are invoked by SKILL.md instructing the model to run a Bash command.

### Layout

```
my-skill/
  SKILL.md
  scripts/
    __init__.py             # optional, only if scripts import from each other
    run_analysis.py         # primary entry point
    parsers/                # subfolder when scripts grow
      json_parser.py
      yaml_parser.py
    lib/                    # internal helpers, never invoked directly
      formatting.py
  requirements.txt          # skill-local Python dependencies, if any
```

### Naming conventions

| Convention | Rule |
|---|---|
| File names | `snake_case.py`. Match the verb-noun pattern: `run_analysis.py`, `parse_input.py`, `merge_reports.py`. |
| Entry points | One file per top-level operation. Do not pack multiple unrelated entry points into one file. |
| Helpers | Live in `scripts/lib/`. Never invoked from SKILL.md directly. |
| Subfolders | Create when `scripts/` has more than five files or a clear grouping appears. |
| Dependencies | `requirements.txt` at the skill root. Skills must declare their own deps; do not rely on a repo-level Python environment at runtime. |

### How SKILL.md references a script

```markdown
To analyze the input, run:

\`\`\`bash
python scripts/run_analysis.py --input "$INPUT_FILE" --format json
\`\`\`

The script writes structured output to stdout. Parse the JSON and continue with the report.
```

Paths in SKILL.md are always relative to the skill root. Never absolute, never reaching outside the skill folder.

### What scripts must NOT do

- Read files outside the skill folder unless given an explicit path argument.
- Hard-code paths to shared resources — those are passed in as arguments by the model.
- Print prompt-shaped text intended for the model to interpret as instructions. Scripts return data; the model interprets.
