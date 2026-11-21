# Troubleshooting `markdown-to-pdf`

Load this file only when `scripts/build_pdf.sh` fails or produces visibly wrong output. The script writes a `.build.log` next to the intended output — read its last ~40 lines first.

Pipeline reminder: `markdown → pandoc (HTML + KaTeX + style.css) → headless Chrome → PDF`.

## Common errors

### `error: pandoc not installed`
`brew install pandoc` (macOS), or `apt install pandoc` (Debian/Ubuntu).

### `error: no Chrome/Chromium found`
The build script walks the macOS `/Applications` bundles, the Puppeteer cache that `mermaid-cli` populates, and the PATH. If none hit, install Chrome from <https://www.google.com/chrome/> or set `CHROME_BIN=/explicit/path/to/chrome` and retry.

### Output PDF exists but math looks like literal `$...$` text
KaTeX did not run. Three causes, in order of likelihood:

1. **No network** — pandoc's `--katex` injects `<link>` and `<script>` tags pointing at the `cdn.jsdelivr.net` CDN. If Chrome can't reach the CDN, math falls back to raw text. Run `bash scripts/doctor.sh`; the network probe will flag this. Workaround: render somewhere with internet, or download KaTeX locally and edit `build_pdf.sh` to point at the local copy.
2. **Non-standard delimiters** — input uses `\(...\)` exclusively, or single backticks around math, or `\begin{equation}...\end{equation}` outside a fenced math block. Re-run with `--from=markdown+tex_math_single_backslash` added, or normalize the delimiters in the source.
3. **Chrome printed before KaTeX finished** — the script passes `--virtual-time-budget=15000` (15s wait). For very large documents this can be too short; bump it in `scripts/build_pdf.sh`.

### Mermaid diagrams render as code blocks instead of figures
`mmdc` is not on PATH. Install with `npm install -g @mermaid-js/mermaid-cli` and re-run. The build script prints a warning when it detects mermaid blocks but no `mmdc`.

If `mmdc` IS installed but renders are missing, check for stderr lines beginning with `[mermaid-filter]` in the build log — the filter writes one diagnostic per failed render and falls back to the original code block.

### Code blocks overflow the page
The CSS already has `pre code { white-space: pre-wrap; word-break: break-word }`. If a specific document still overflows, it likely contains an `<img>` or table inside a `<pre>` (rare). Inspect the `--keep-html` output to confirm.

### Tables break across pages and look wrong
CSS rule `table { page-break-inside: avoid }` is set. For tables longer than a page that genuinely need to break, remove that rule for that table inline (`<table style="break-inside: auto">`) or rework the data into a list. Chrome's print engine is not LaTeX longtable.

### Chinese / Japanese / Korean text disappears or shows as tofu
The CSS font stack (`assets/style.css`) lists `"PingFang SC", "Noto Sans CJK SC", "Microsoft YaHei"` after the Latin sans-serifs. If none of those is installed, Chrome falls back to a default that may not cover CJK ranges.

- macOS: PingFang SC is preinstalled. If it's missing, the OS install is broken.
- Linux: `apt install fonts-noto-cjk` (Debian/Ubuntu) or equivalent.
- If the user has a different CJK font, append it to the `body { font-family: ... }` rule in `assets/style.css`.

### Output PDF is huge (> 5 MB) for a text-only document
With `--embed-resources`, pandoc inlines KaTeX's CSS and JS (~300 KB combined). That is the floor; anything significantly larger means the document is embedding images. Use `--keep-html` and inspect.

### Chrome prints with default URL header / page footer
The script passes `--no-pdf-header-footer`. Older Chrome builds (before ~v109) used different flag names; if upgrading is not an option, see `chrome --help | grep print` for that build's flag.

### Build hangs / Chrome never exits
This used to be a XeLaTeX hazard but Chrome `--headless=new` is generally well-behaved. If it does hang:
1. Confirm no zombie Chrome process from a prior run is holding the user-data-dir lock.
2. Check the log for `DevTools listening on …` — if Chrome started in interactive mode by mistake, the printed flag set was wrong (most likely missing `--headless=new`).

## When to escalate

If a render fails after the above, the source markdown may have raw HTML or raw LaTeX fragments that conflict with pandoc's HTML output. Strip them, rebuild, then re-add piece by piece. Pass `--keep-html` and open the intermediate HTML directly in Chrome to see exactly what gets printed before the print snapshot.
