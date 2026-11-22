# `doctor.sh` — diagnose the markdown-to-pdf pipeline

A read-only health check for every component the skill depends on. Use it before troubleshooting blindly — most "why does my PDF fail / look wrong" questions are answered by one component being missing or misnamed.

```bash
bash scripts/doctor.sh
```

Exits `0` when ready to render (warnings allowed); exits `1` when a blocker is present.

## When to run it

- A render fails with a non-obvious error ("no Chrome found", "pandoc not installed", PDF empty).
- Setting the skill up on a fresh machine.
- The user asks "do I have everything?" / "why isn't this working?".
- Math renders as raw `$...$` text (likely the KaTeX CDN was unreachable; the doctor probes it).

The doctor **diagnoses, it does not install** — it prints the install command for each missing component and lets the user run it.

## What it checks

| Component | Severity | Probe |
|---|---|---|
| `pandoc` (≥ 3.0) | blocker | `command -v pandoc` |
| Chrome / Chromium / Edge | blocker | `$CHROME_BIN`, `/Applications/*.app`, `~/.cache/puppeteer/...`, PATH |
| `mmdc` (mermaid-cli) | warning (optional) | `command -v mmdc` |
| Skill assets (`style.css`, `mermaid-filter.lua`, `build_pdf.sh`) | blocker if missing | filesystem |
| KaTeX CDN reachability | warning | `curl -sIfL https://cdn.jsdelivr.net/npm/katex/dist/katex.min.css` |

Note: this skill no longer probes XeLaTeX, TeX Live, or system math fonts — they're not part of the pipeline anymore. KaTeX bundles its own math glyphs; Chrome handles all other fonts via the system stack.

## Reading the output

- `[OK]` — component present and usable.
- `[!!]` — present partially or with a fallback in effect; render still works but may not look as intended (e.g. mermaid will fall back to code, math may not render if KaTeX CDN is down).
- `[--]` — missing; render will fail.

The final `=== summary ===` block prints one of:

- `All green. Ready to render.`
- `Ready to render with N fallback(s) in effect.` — exit 0; render proceeds.
- `N blocker(s), N warning(s) — pipeline will not render.` followed by `NEXT: <command>` — exit 1; user must fix the blocker before retrying.

## Install commands by component

| Missing | Command |
|---|---|
| `pandoc` (macOS) | `brew install pandoc` |
| `pandoc` (Linux/Debian) | `apt install pandoc` |
| Chrome (macOS / any) | Download from <https://www.google.com/chrome/> |
| Chrome (Debian/Ubuntu) | `apt install google-chrome-stable` (Google's apt repo) or `apt install chromium-browser` |
| `mmdc` (any OS, needs Node) | `npm install -g @mermaid-js/mermaid-cli` |

## Limitations — what the doctor does NOT check

- **Disk space** — Chrome's user-data-dir is in `$TMPDIR` and rarely an issue.
- **Input markdown validity** — pandoc itself produces clear errors for malformed input. The doctor doesn't read your `.md`.
- **CSL/bib correctness** — only checked at render time when you actually pass `--citeproc` flags.
- **Puppeteer/Chromium health for `mmdc`** — `command -v mmdc` only verifies the binary exists; if the bundled Chromium is broken, the failure surfaces during render. Run a one-off `mmdc -i /tmp/test.mmd -o /tmp/test.svg` to verify end-to-end.
- **Whether Chrome can actually print the HTML** — needs a real render to confirm. The doctor only confirms Chrome exists and is executable.

## How the agent should use this

When a render fails or the user asks about setup:

1. Run `bash scripts/doctor.sh` from the skill directory.
2. Parse stdout into Working / Blocker / Warning buckets.
3. Report a compact table to the user — don't dump the raw `[OK]` lines.
4. Surface the **single** install command the doctor recommends in `NEXT:`. Ask before running it; do not install autonomously.
