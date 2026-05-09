#!/usr/bin/env bash
# Render a markdown document to PDF via:
#   pandoc → HTML (KaTeX-rendered math, custom CSS) → headless Chrome → PDF
#
# Usage:
#   build_pdf.sh <input.md> [output.pdf] [--paper a4|letter] [--margin 1in]
#                [--keep-html]
#
# This pipeline picks Chrome over XeLaTeX so that math, code highlighting,
# and overall typography match what the user sees in their markdown editor
# preview (VSCode, Typora, GitHub) — KaTeX renders the math, not LaTeX.
#
# Defaults: A4, 1in margins. Body / mono / CJK fonts are picked by the
# browser from the system font stack defined in assets/style.css; tweak
# that file (not this script) to change the look.

set -u

if [[ $# -lt 1 ]]; then
  echo "usage: build_pdf.sh <input.md> [output.pdf] [flags...]" >&2
  exit 64
fi

INPUT="$1"; shift
if [[ ! -f "$INPUT" ]]; then
  echo "error: input not found: $INPUT" >&2
  exit 66
fi

OUTPUT=""
if [[ $# -gt 0 && "$1" != --* ]]; then
  OUTPUT="$1"; shift
fi
if [[ -z "$OUTPUT" ]]; then
  OUTPUT="${INPUT%.md}.pdf"
fi

PAPER="A4"
MARGIN="1in"
KEEP_HTML=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --paper)     PAPER="$2"; shift 2 ;;
    --margin)    MARGIN="$2"; shift 2 ;;
    --keep-html) KEEP_HTML=1; shift ;;
    *)           echo "unknown flag: $1" >&2; exit 64 ;;
  esac
done

command -v pandoc >/dev/null || {
  echo "error: pandoc not installed (brew install pandoc)" >&2; exit 69
}

# Resolve a Chrome / Chromium binary. Order:
#   1. $CHROME_BIN env var (explicit override)
#   2. macOS system Chrome / Chromium / Edge
#   3. Puppeteer-bundled Chrome from mermaid-cli's npm install
#   4. Linux PATH (chromium, google-chrome, chrome)
find_chrome() {
  local candidates=() puppeteer
  [[ -n "${CHROME_BIN:-}" ]] && candidates+=("$CHROME_BIN")
  candidates+=(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
  )
  # Most recent puppeteer-bundled Chrome (sorted by version dir mtime).
  # Puppeteer's per-platform layout: chrome-mac-{arm64,x64}/ on macOS,
  # chrome-linux*/ on Linux. The macOS binary lives inside the .app bundle;
  # Linux ships a flat `chrome` binary.
  case "$(uname -s)" in
    Darwin)
      puppeteer="$(ls -td "$HOME/.cache/puppeteer/chrome"/*/chrome-mac-*/"Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" 2>/dev/null | head -1)"
      ;;
    Linux)
      puppeteer="$(ls -td "$HOME/.cache/puppeteer/chrome"/*/chrome-linux*/chrome 2>/dev/null | head -1)"
      ;;
  esac
  [[ -n "${puppeteer:-}" ]] && candidates+=("$puppeteer")
  for c in chromium google-chrome chrome; do
    local p; p="$(command -v "$c" 2>/dev/null)"
    [[ -n "$p" ]] && candidates+=("$p")
  done
  for c in "${candidates[@]}"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return 0; }
  done
  return 1
}

CHROME="$(find_chrome)" || {
  echo "error: no Chrome/Chromium found." >&2
  echo "       install Chrome (https://www.google.com/chrome/) or set CHROME_BIN to a binary path." >&2
  exit 69
}

SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STYLESHEET="$SKILL_ROOT/assets/style.css"
MERMAID_FILTER="$SKILL_ROOT/assets/mermaid-filter.lua"
TMP_HTML="${OUTPUT%.pdf}.html"
LOG="${OUTPUT%.pdf}.build.log"

# ---------- Step 1: markdown → HTML (KaTeX math) ----------
PANDOC_ARGS=(
  "$INPUT"
  --from=markdown+tex_math_dollars+pipe_tables+backtick_code_blocks+fenced_code_attributes+footnotes+smart+yaml_metadata_block+raw_html+bracketed_spans+definition_lists+example_lists+task_lists+strikeout+subscript+superscript
  --to=html5
  --standalone
  --katex
  --css="$STYLESHEET"
  --embed-resources
  --highlight-style=tango
  -o "$TMP_HTML"
)

# Mermaid: only when mmdc is installed; otherwise plain code blocks survive.
if command -v mmdc >/dev/null 2>&1; then
  PANDOC_ARGS+=(--lua-filter="$MERMAID_FILTER")
elif grep -qE '^[[:space:]]*```[[:space:]]*mermaid' "$INPUT" 2>/dev/null; then
  echo "warning: input has \`\`\`mermaid blocks but mmdc is not installed." >&2
  echo "         they will render as plain code. install with:" >&2
  echo "         npm install -g @mermaid-js/mermaid-cli" >&2
fi

echo "→ pandoc → $TMP_HTML" >&2
if ! pandoc "${PANDOC_ARGS[@]}" 2> "$LOG"; then
  RC=$?
  echo "✗ pandoc failed (exit $RC). Log: $LOG" >&2
  echo "--- last 40 lines ---" >&2
  tail -40 "$LOG" >&2 || true
  exit "$RC"
fi

# ---------- Step 2: HTML → PDF (headless Chrome) ----------
# CSS @page rules in style.css control paper size and margins. Flags here
# are only the runtime knobs Chrome exposes via the command line.
#
# --virtual-time-budget=15000 → wait up to 15s for KaTeX/JS to finish
#                                rendering before snapshotting to PDF.
echo "→ chrome → $OUTPUT" >&2
CHROME_RC=0
"$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-pdf-header-footer \
  --no-sandbox \
  --hide-scrollbars \
  --virtual-time-budget=15000 \
  --print-to-pdf="$OUTPUT" \
  "file://$TMP_HTML" 2>>"$LOG" || CHROME_RC=$?

if [[ "$CHROME_RC" -ne 0 ]]; then
  echo "✗ chrome failed (exit $CHROME_RC). Log: $LOG" >&2
  tail -40 "$LOG" >&2 || true
  exit "$CHROME_RC"
fi
if [[ ! -s "$OUTPUT" ]]; then
  echo "✗ chrome produced empty PDF (exit 0 but no output). Log: $LOG" >&2
  tail -40 "$LOG" >&2 || true
  exit 1
fi

if [[ "$KEEP_HTML" -eq 0 ]]; then
  rm -f "$TMP_HTML"
fi
rm -f "$LOG"

SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
echo "✓ wrote $OUTPUT (${SIZE} bytes)" >&2
