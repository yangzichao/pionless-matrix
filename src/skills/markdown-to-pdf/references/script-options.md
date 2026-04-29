# `build_pdf.sh` — full option reference

```
build_pdf.sh <input.md> [output.pdf] [flags...]
```

| Flag | Default | Effect |
|---|---|---|
| `--paper a4\|letter` | `a4` | Sets `geometry` paper size. |
| `--margin 1in` | `1in` | Symmetric page margin. Accepts any LaTeX length (`2cm`, `0.75in`). |
| `--mainfont "Family"` | (Latin Modern) | Main text font. Must be installed system-wide. |
| `--twocolumn` | off | Two-column layout via `\documentclass[twocolumn]`. |
| `--bib path.bib` | none | Enable `pandoc --citeproc` with this bibliography. |
| `--csl path.csl` | Chicago author-date | Citation style; only meaningful with `--bib`. |

## Pandoc input extensions enabled

`tex_math_dollars`, `pipe_tables`, `backtick_code_blocks`, `fenced_code_attributes`, `footnotes`, `smart`, `yaml_metadata_block`, `raw_tex`, `bracketed_spans`, `definition_lists`, `example_lists`, `task_lists`, `strikeout`, `subscript`, `superscript`.

## How to extend

- **New preamble package** → edit `assets/preamble.tex` once; every future render picks it up.
- **New flag** → add a `case` arm in `build_pdf.sh` and pass through to `pandoc` via the `ARGS` array.
- **Different engine** (e.g. `lualatex`) → swap `--pdf-engine=xelatex` and ensure the preamble's `unicode-math` font load still resolves.

## What the script intentionally does NOT do

- Auto-install LaTeX packages — too invasive; the script tells you what's missing.
- Cache or hash inputs — render is fast enough; caching adds correctness risk.
- Generate intermediate `.tex` — pass `pandoc -s ... -o out.tex` manually if you need to inspect.
