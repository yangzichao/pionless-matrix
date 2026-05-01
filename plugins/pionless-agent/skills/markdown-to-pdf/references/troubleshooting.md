# Troubleshooting `markdown-to-pdf`

Load this file only when `scripts/build_pdf.sh` fails. The script writes a `.build.log` next to the intended output — read its last ~40 lines first.

## Common errors

### `! LaTeX Error: File 'something.sty' not found.`
A LaTeX package is missing. On macOS with MacTeX, install via:
```
sudo tlmgr update --self
sudo tlmgr install <package>
```
Frequent culprits: `unicode-math`, `mathtools`, `microtype`, `xcolor`, `csquotes`, `footmisc`, `titlesec`.

### `! Package fontspec Error: The font "X" cannot be found.`
The `--mainfont` argument names a font not installed system-wide. Either install the font or omit `--mainfont` (the preamble falls back to Latin Modern).

### `! Undefined control sequence. \tightlist`
Pandoc emits `\tightlist`; the preamble usually defines it. If you see this, add to `assets/preamble.tex`:
```latex
\providecommand{\tightlist}{\setlength{\itemsep}{0pt}\setlength{\parskip}{0pt}}
```

### Math renders as literal `$...$` text
The input uses non-standard delimiters (e.g. `\(...\)` only, or single backticks around math). Re-run with `--from=markdown+tex_math_single_backslash` added, or convert delimiters in the source.

### Inline citations `[1]` become hyperlinks to nothing
That's the expected behavior for **manual** numbered citations (the report keeps the bracket text but has no anchor). To get clickable cross-refs, either:
- Convert references to a real bibliography and pass `--bib refs.bib --csl style.csl`, or
- Add explicit anchors like `[\[1\]](#ref-1)` and matching `<a id="ref-1"></a>` markers in the References section.

### Output PDF is huge (> 5 MB) for a text-only document
Almost always because XeLaTeX embedded a heavy font. Drop `--mainfont` or pick a font with a smaller subset (Latin Modern, STIX Two).

### Chinese / Japanese / Korean text disappears or shows as boxes
The preamble loads `xeCJK` only when a known CJK font is detected (PingFang SC on macOS, Noto Serif CJK SC on Linux, or Songti SC as a last resort). If your CJK glyphs render as blanks/tofu:
1. Confirm at least one of those fonts is installed: `fc-list :lang=zh | head` (macOS users have PingFang SC by default).
2. If you have a different CJK font, pass it as the **main** font via `--mainfont "Source Han Serif SC"` — `fontspec` will pick up CJK ranges from it. Or add another `\IfFontExistsTF{...}{...}` branch to `assets/preamble.tex`.
3. If you see `! Package xeCJK Error: Cannot find ...`, it means a font name is misspelled or missing — install via `tlmgr install ctex` (TeX Live) and the system font manager.

### Build hangs
XeLaTeX is waiting for input on an unrecoverable error. The script runs `pandoc` (which calls XeLaTeX non-interactively), so this should not happen — if it does, kill the process and inspect the log; usually a `\begin{...}` without a matching `\end{...}` from raw-LaTeX in the markdown source.

## When to escalate

If a report fails after fixing the obvious issues, the source markdown may have raw-LaTeX fragments that conflict with the preamble. Strip them, rebuild, then re-add piece by piece.
