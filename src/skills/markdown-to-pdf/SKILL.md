---
name: markdown-to-pdf
description: Use this skill to render a markdown document — especially research reports with LaTeX math, footnotes, code, mermaid diagrams, and inline numbered citations — into a polished PDF whose visuals match what the user sees in their markdown editor preview (VSCode, Typora, GitHub). Activate when the user asks to "convert to PDF", "make a PDF", "export to PDF", or wants a print-ready / shareable version of a `.md` file.
metadata:
  author: pionless-matrix
  version: "2.0"
  pionless.category: rendering
---

# Markdown → PDF (HTML + KaTeX + Chrome)

Render a markdown document into a PDF whose look mirrors what users see in modern markdown editors. The pipeline is **Pandoc → HTML (KaTeX-rendered math, custom CSS) → headless Chrome → PDF**. KaTeX handles the math (so it matches VSCode preview character-for-character), Chrome's print engine handles layout, and a single CSS file in `assets/style.css` controls the visual design end-to-end.

## When this skill activates

- The user has a finished markdown report (e.g. files under `deep-research/`) and asks for a PDF.
- The document contains LaTeX math (`$...$` or `$$...$$`), tables, footnotes, mermaid diagrams, or inline numbered citations like `[1]`.
- The user says "PDF version", "print-ready", "shareable PDF", "good-looking PDF".

If the user wants the raw HTML for a web preview instead of a PDF, this skill is overkill — `pandoc --to=html5 --standalone --katex` does that in one line.

## Required tools

The host runtime needs:

- `pandoc` (≥ 3.1 — `--embed-resources` was introduced then)
- A Chrome / Chromium / Edge binary — used in `--headless=new` mode for printing. The script searches `$CHROME_BIN`, the macOS `/Applications` bundles, and the Puppeteer-bundled copy that ships with `mermaid-cli`'s npm install.
- Shell access to invoke them.

If pandoc or Chrome is missing, instruct the user to `brew install pandoc` and install Chrome from <https://www.google.com/chrome/>. Do not fall back to a lower-quality engine.

**Optional:** `mmdc` (mermaid-cli) for rendering ` ```mermaid ` diagrams. Install via `npm install -g @mermaid-js/mermaid-cli`. The build script auto-detects it; without it, mermaid blocks render as plain code (and a warning is printed).

## Workflow

When activated, guide the host agent through these steps:

1. **Locate the input.** Confirm the absolute path of the source `.md` file. If the user gave a folder, ask which file.
2. **Pick the output path.** Default to the same directory as the source, same basename, `.pdf` extension. Do not write into a build/cache folder unless the user asks.
3. **Inspect the source briefly.** Skim the first ~80 lines to confirm: does it use display math? mermaid? code blocks? Knowing this lets you decide whether to flag missing optional deps.
4. **Invoke the build script.** Run:

   ```bash
   bash scripts/build_pdf.sh <input.md> [output.pdf]
   ```

   The script (a) calls pandoc with `--katex --css=assets/style.css --embed-resources` to produce a self-contained intermediate HTML, then (b) runs Chrome `--headless=new --print-to-pdf=...` against that HTML. The HTML file is deleted on success unless `--keep-html` is passed.
5. **Verify success.** Check the exit code and that the PDF exists and is non-empty (`> 10 KB` for any non-trivial report). Open the file path in the response so the user can click it.
6. **If something fails.** Read the tail of the build log (the script tees it to a `.log` file next to the PDF). Common causes and fixes are listed in `references/troubleshooting.md` — load that file only when something actually fails.
7. **If something looks structurally wrong** (Chrome not found, KaTeX not rendering, mermaid not appearing, fresh-machine setup) — run `bash scripts/doctor.sh` first. It probes every dependency the pipeline needs and prints a punch list with the single highest-priority install command. Details: `references/doctor.md`.

## Customization knobs (only when the user asks)

- **Different paper size or margins** → pass `--paper a4|letter` and `--margin 1in` flags. (The CSS `@page` rule respects them.)
- **Different fonts / colors / spacing** → edit `assets/style.css`. The CSS uses CSS custom properties for the color palette, so most visual changes are one-line edits.
- **Keep the intermediate HTML for inspection** → pass `--keep-html` and the `.html` file lands next to the PDF.
- **Override the Chrome binary** → set `CHROME_BIN=/path/to/chrome` in the environment.
- **Cover page / title block** → ensure the markdown starts with a YAML metadata block (`title:`, `author:`, `date:`); the CSS styles `header#title-block-header` for a centered title.

For the full flag list, read `references/script-options.md` on demand.

## Anti-patterns

- **Don't use `pandoc -o out.pdf`** with the default LaTeX engine — that route is XeLaTeX, and the math will not look like KaTeX. This skill exists precisely because that mismatch was visible.
- **Don't hand-edit the CSS inline in the pandoc command.** Edit `assets/style.css` so the change is reproducible.
- **Don't commit the generated PDF or intermediate HTML** unless the user explicitly asks; both are build artifacts.
- **Don't try to use this for documents that need LaTeX-grade typography** (long math-heavy theses, multi-page tables with column-aligned decimals, journal-style two-column layouts). Chrome's print engine is not LaTeX. For those, point the user back at a XeLaTeX flow.

## Output

A single PDF at the chosen output path. The intermediate HTML and `.log` file are removed on success. Report the PDF path in the end-of-turn summary.
