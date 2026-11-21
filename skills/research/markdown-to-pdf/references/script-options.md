# `build_pdf.sh` — full option reference

```
build_pdf.sh <input.md> [output.pdf] [flags...]
```

Pipeline: `markdown → pandoc (HTML + KaTeX + style.css) → headless Chrome → PDF`.

| Flag | Default | Effect |
|---|---|---|
| `--paper a4\|letter` | `A4` | Paper size; honored via the CSS `@page { size: ... }` rule. |
| `--margin 1in` | `1in` | Page margin; honored via the CSS `@page { margin: ... }` rule. Accepts any CSS length (`2cm`, `0.75in`). |
| `--keep-html` | off | Keep the intermediate `.html` file next to the PDF for inspection. |

## Environment variables

| Variable | Effect |
|---|---|
| `CHROME_BIN` | Path to a specific Chrome / Chromium / Edge binary. Tried first when resolving the browser. Useful when the user has multiple Chrome installs or when the auto-detection picks the wrong one. |
| `PANDOC_MERMAID_BIN` | Path to a non-PATH `mmdc` build. |
| `PANDOC_MERMAID_OUTDIR` | Where intermediate `.mmd` / `.svg` files are written (default `$TMPDIR` or `/tmp`). |

## Mermaid diagrams

If `mmdc` (mermaid-cli) is on `PATH`, the script automatically attaches `assets/mermaid-filter.lua`, which renders each ` ```mermaid ` block to an SVG and inlines it via `<img src=...>`. SVG scales perfectly at print resolution. Install:

```bash
npm install -g @mermaid-js/mermaid-cli
```

Without `mmdc`, mermaid blocks fall through to plain code rendering and a warning is printed.

## How Chrome is located

The build script searches in this order, returning the first executable hit:

1. `$CHROME_BIN`
2. `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
3. `/Applications/Chromium.app/Contents/MacOS/Chromium`
4. `/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge`
5. The most recent Puppeteer-bundled Chrome at `~/.cache/puppeteer/chrome/.../Google Chrome for Testing.app/...` (this is what `mermaid-cli`'s npm install puts on disk).
6. PATH lookup for `chromium`, `google-chrome`, `chrome`.

## Pandoc input extensions enabled

`tex_math_dollars`, `pipe_tables`, `backtick_code_blocks`, `fenced_code_attributes`, `footnotes`, `smart`, `yaml_metadata_block`, `raw_html`, `bracketed_spans`, `definition_lists`, `example_lists`, `task_lists`, `strikeout`, `subscript`, `superscript`.

## What the script does NOT do

- Auto-install pandoc, Chrome, or mmdc — too invasive; the doctor tells the user what is missing.
- Cache or hash inputs — render is fast enough; caching adds correctness risk.
- Use LaTeX or XeLaTeX — by design. If the user needs LaTeX-grade typography, this skill is the wrong tool.

## How to extend

- **Visual changes** → edit `assets/style.css`. The CSS uses custom properties (`--heading-ink`, `--code-bg`, …) for the palette, so most tweaks are one-line.
- **New flag** → add a `case` arm in `build_pdf.sh` and pass through to either pandoc (`PANDOC_ARGS`) or Chrome.
- **Different math renderer** → swap `--katex` for `--mathjax` or `--mathml` in `build_pdf.sh`. KaTeX is the default because its glyph metrics match Computer Modern (the math the user sees in VSCode preview).
