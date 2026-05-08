# `doctor.sh` — diagnose the markdown-to-pdf pipeline

A read-only health check for every component the skill depends on. Use it before troubleshooting blindly — most "why does my PDF look wrong / fail to build" questions are answered by one component being missing or misnamed.

```bash
bash scripts/doctor.sh
```

Exits `0` when ready to render (warnings allowed); exits `1` when a blocker is present.

## When to run it

- A render fails with a non-obvious error (segfault, "fontspec error", "pandoc not found").
- Setting the skill up on a fresh machine.
- The user asks "do I have everything?" / "why isn't this working?".
- A previously-working render suddenly produces ugly output (likely: a font got uninstalled, or `mmdc` was removed from `PATH`).

The doctor **diagnoses, it does not install** — it prints the install command for each missing component and lets the user run it.

## What it checks

| Component | Severity | Probe |
|---|---|---|
| `pandoc` (≥ 3.0) | blocker | `command -v pandoc` |
| `xelatex` | blocker | `command -v xelatex` |
| Math font (STIX Two Math → Latin Modern Math) | blocker if both missing | fontconfig / CoreText lookup |
| Body font default (Helvetica Neue on macOS / DejaVu Sans on Linux) | warning | font lookup |
| Mono font default (Menlo / DejaVu Sans Mono) | warning | font lookup |
| CJK font (PingFang SC / Noto Serif CJK SC) | warning | font lookup |
| `mmdc` (mermaid-cli) | warning (optional) | `command -v mmdc` |
| Skill assets (`preamble.tex`, `mermaid-filter.lua`, `build_pdf.sh`) | blocker if missing | filesystem |

## Reading the output

- `[OK]` — component present and usable.
- `[!!]` — present partially or with a fallback in effect; render still works but may not look as intended.
- `[--]` — missing; render will fail or degrade significantly.

The final `=== summary ===` block prints one of:

- `All green. Ready to render.`
- `Ready to render with N fallback(s) in effect.` — exit 0; render proceeds with the fallback chain in `assets/preamble.tex`.
- `N blocker(s), N warning(s) — pipeline will not render.` followed by `NEXT: <command>` — exit 1; user must fix the blocker before retrying.

## Install commands by component

| Missing | Command |
|---|---|
| `pandoc` (macOS) | `brew install pandoc` |
| `pandoc` (Linux/Debian) | `apt install pandoc` |
| `xelatex` (macOS) | `brew install --cask mactex-no-gui` |
| `xelatex` (Linux/Debian) | `apt install texlive-xetex texlive-fonts-recommended texlive-latex-extra` |
| `mmdc` (any OS, needs Node) | `npm install -g @mermaid-js/mermaid-cli` |
| STIX Two Math (macOS) | `brew install --cask font-stix-two` |
| Helvetica Neue / Menlo / PingFang SC | shipped with macOS — if missing, the OS install is broken |
| DejaVu Sans / Noto CJK (Debian) | `apt install fonts-dejavu fonts-noto-cjk` |

## Limitations — what the doctor does NOT check

- **Network reachability** — the pipeline is fully local; nothing to probe.
- **Disk space** — XeLaTeX needs a few MB of cache, not gigabytes.
- **Input markdown validity** — pandoc itself produces clear errors for malformed input. The doctor doesn't read your `.md`.
- **CSL/bib correctness** — only checked at render time when you actually pass `--bib` / `--csl`.
- **Puppeteer/Chromium health for `mmdc`** — `command -v mmdc` only verifies the binary exists; if Chromium download is broken, the failure surfaces during render. Run a one-off `mmdc -i /tmp/test.mmd -o /tmp/test.pdf` to verify end-to-end.

## How the agent should use this

When a render fails or the user asks about setup:

1. Run `bash scripts/doctor.sh` from the skill directory.
2. Parse stdout into Working / Blocker / Warning buckets.
3. Report a compact table to the user — don't dump the raw `[OK]` lines.
4. Surface the **single** install command the doctor recommends in `NEXT:`. Ask before running it; do not install autonomously.
