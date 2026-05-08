#!/usr/bin/env bash
# Render a markdown document to a publication-quality PDF via Pandoc + XeLaTeX.
#
# Usage:
#   build_pdf.sh <input.md> [output.pdf] [--paper a4|letter] [--margin 1in]
#                [--mainfont "Family"] [--monofont "Family"] [--twocolumn]
#                [--bib refs.bib] [--csl style.csl]
#
# Defaults: A4, 11pt, 1in margins. Body font defaults to a modern sans-serif
# tuned per platform (Helvetica Neue on macOS, DejaVu Sans on Linux); pass
# --mainfont to override. STIX Two math, GitHub-style code blocks, blue links.

set -euo pipefail

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

PAPER="a4"
MARGIN="1in"
MAINFONT=""           # auto-detect based on platform if empty
MONOFONT=""           # auto-detect based on platform if empty
TWOCOLUMN=0
BIB=""
CSL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --paper)     PAPER="$2"; shift 2 ;;
    --margin)    MARGIN="$2"; shift 2 ;;
    --mainfont)  MAINFONT="$2"; shift 2 ;;
    --monofont)  MONOFONT="$2"; shift 2 ;;
    --twocolumn) TWOCOLUMN=1; shift ;;
    --bib)       BIB="$2"; shift 2 ;;
    --csl)       CSL="$2"; shift 2 ;;
    *)           echo "unknown flag: $1" >&2; exit 64 ;;
  esac
done

command -v pandoc  >/dev/null || { echo "error: pandoc not installed (brew install pandoc)" >&2; exit 69; }
command -v xelatex >/dev/null || { echo "error: xelatex not installed (brew install --cask mactex-no-gui)" >&2; exit 69; }

# Platform-aware font defaults. macOS ships Helvetica Neue + Menlo; most
# Linux distros ship DejaVu. If neither pattern matches, leave empty and
# let pandoc/XeLaTeX use its built-in default (Latin Modern).
if [[ -z "$MAINFONT" ]]; then
  case "$(uname -s)" in
    Darwin) MAINFONT="Helvetica Neue" ;;
    Linux)
      if command -v fc-list >/dev/null 2>&1 && fc-list | grep -qi "DejaVu Sans"; then
        MAINFONT="DejaVu Sans"
      fi
      ;;
  esac
fi
if [[ -z "$MONOFONT" ]]; then
  case "$(uname -s)" in
    Darwin) MONOFONT="Menlo" ;;
    Linux)
      if command -v fc-list >/dev/null 2>&1 && fc-list | grep -qi "DejaVu Sans Mono"; then
        MONOFONT="DejaVu Sans Mono"
      fi
      ;;
  esac
fi

SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PREAMBLE="$SKILL_ROOT/assets/preamble.tex"
MERMAID_FILTER="$SKILL_ROOT/assets/mermaid-filter.lua"
LOG="${OUTPUT%.pdf}.build.log"

ARGS=(
  "$INPUT"
  --from=markdown+tex_math_dollars+pipe_tables+backtick_code_blocks+fenced_code_attributes+footnotes+smart+yaml_metadata_block+raw_tex+bracketed_spans+definition_lists+example_lists+task_lists+strikeout+subscript+superscript
  --to=pdf
  --pdf-engine=xelatex
  --include-in-header="$PREAMBLE"
  -V geometry:"paper=${PAPER}paper,margin=${MARGIN}"
  -V fontsize=11pt
  -V colorlinks=true
  -V lang=en
  -V microtypeoptions=protrusion=true
  --syntax-highlighting=tango
  --shift-heading-level-by=0
  -o "$OUTPUT"
)

[[ -n "$MAINFONT" ]] && ARGS+=(-V mainfont="$MAINFONT")
[[ -n "$MONOFONT" ]] && ARGS+=(-V monofont="$MONOFONT")
if [[ "$TWOCOLUMN" -eq 1 ]]; then
  ARGS+=(-V classoption=twocolumn)
fi

# Mermaid: attach the Lua filter only when mmdc is installed. Without it,
# ```mermaid blocks fall through to plain code rendering. Print a hint if
# the input actually contains mermaid blocks so the user knows what's missing.
if command -v mmdc >/dev/null 2>&1; then
  ARGS+=(--lua-filter="$MERMAID_FILTER")
elif grep -qE '^[[:space:]]*```[[:space:]]*mermaid' "$INPUT" 2>/dev/null; then
  echo "warning: input has \`\`\`mermaid blocks but mmdc is not installed." >&2
  echo "         they will render as plain code. install with:" >&2
  echo "         npm install -g @mermaid-js/mermaid-cli" >&2
fi
if [[ -n "$BIB" ]]; then
  ARGS+=(--citeproc --bibliography="$BIB")
  [[ -n "$CSL" ]] && ARGS+=(--csl="$CSL")
fi

echo "→ pandoc → $OUTPUT" >&2
if pandoc "${ARGS[@]}" 2> "$LOG"; then
  rm -f "$LOG"
  if [[ -s "$OUTPUT" ]]; then
    SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
    echo "✓ wrote $OUTPUT (${SIZE} bytes)" >&2
    exit 0
  else
    echo "✗ pandoc reported success but PDF is empty" >&2
    exit 1
  fi
else
  RC=$?
  echo "✗ pandoc/xelatex failed (exit $RC). Log: $LOG" >&2
  echo "--- last 40 lines ---" >&2
  tail -40 "$LOG" >&2 || true
  exit "$RC"
fi
