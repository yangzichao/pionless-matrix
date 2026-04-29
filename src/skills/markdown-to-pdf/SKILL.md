---
name: markdown-to-pdf
description: Use this skill to render a markdown document — especially research reports with LaTeX math, footnotes, code, and inline numbered citations — into a publication-quality PDF via Pandoc + XeLaTeX. Activate when the user asks to "convert to PDF", "make a PDF", "export to PDF", or wants a print-ready / publication-quality version of a `.md` file.
metadata:
  author: pionless-matrix
  version: "1.0"
  pionless.category: rendering
---

# Markdown → High-Quality PDF

Render a markdown document into a typeset, publication-quality PDF using **Pandoc + XeLaTeX** with a curated preamble tuned for academic / research reports (Unicode math, microtype, proper hyphenation, colored hyperlinks, code blocks, footnotes, and citations).

## When this skill activates

- The user has a finished markdown report (e.g. files under `deep-research/`) and asks for a PDF.
- The document contains LaTeX math (`$...$` or `$$...$$`), tables, footnotes, or inline numbered citations like `[1]`.
- The user says "publication quality", "print-ready", "PDF version", "good-looking PDF".

If the user just wants a quick HTML preview, this skill is overkill — point them at `pandoc --to=html5`.

## Required tools

The host runtime needs:

- `pandoc` (≥ 3.0)
- `xelatex` (from MacTeX / TeX Live) — `lualatex` also works as a fallback
- Shell access to invoke them

If either is missing, instruct the user to `brew install pandoc` and `brew install --cask mactex-no-gui` (macOS) before retrying. Do not silently fall back to a lower-quality renderer — the user asked for quality.

## Workflow

When activated, guide the host agent through these steps:

1. **Locate the input.** Confirm the absolute path of the source `.md` file. If the user gave a folder, ask which file.
2. **Pick the output path.** Default to the same directory as the source, same basename, `.pdf` extension. Do not write into a build/cache folder unless the user asks.
3. **Inspect the source briefly.** Skim the first ~80 lines to confirm: does it use display math? bibliography-style references? code blocks? Knowing this lets you choose flags below.
4. **Invoke the build script.** Run:

   ```bash
   bash scripts/build_pdf.sh <input.md> [output.pdf]
   ```

   The script wires Pandoc to XeLaTeX with the curated preamble in `assets/preamble.tex` and sensible defaults (A4, 11pt, Latin Modern + STIX math, microtype, colored links, numbered sections off by default, smart quotes on).
5. **Verify success.** Check the exit code and that the PDF exists and is non-empty (`> 10 KB` for any non-trivial report). Open the file path in the response so the user can click it.
6. **If LaTeX errors.** Read the tail of the build log (the script tees it to a `.log` file next to the PDF). Common causes and fixes are listed in `references/troubleshooting.md` — load that file only when something actually fails.

## Customization knobs (only when the user asks)

- **Different paper size or margins** → pass `--paper a4|letter` and `--margin 1in` flags to the script.
- **Two-column layout** → `--twocolumn`.
- **Different main font** → `--mainfont "Times New Roman"` (must be installed system-wide).
- **Bibliography from a `.bib` file** → `--bib path/to/refs.bib --csl path/to/style.csl`.
- **Cover page / title block** → ensure the markdown starts with a `# Title` heading; the script auto-extracts it via `--metadata title:`.

For the full flag list, read `references/script-options.md` on demand.

## Anti-patterns

- **Don't use `pandoc -o out.pdf` with the default LaTeX engine** — `pdflatex` chokes on Unicode and modern math. Always go through `xelatex`.
- **Don't render via headless Chrome / wkhtmltopdf** for academic content — math rendering and typography are noticeably worse than LaTeX.
- **Don't hand-edit the preamble inline in the pandoc command.** Edit `assets/preamble.tex` so the change is reproducible.
- **Don't commit the generated PDF** unless the user explicitly asks; PDFs are build artifacts.

## Output

A single PDF at the chosen output path, plus a sibling `.log` file kept only on failure (the script deletes it on success). Report both paths in the end-of-turn summary.
