#!/usr/bin/env bash
# Render a markdown document to a publication-quality PDF via Pandoc + XeLaTeX.
#
# Usage:
#   build_pdf.sh <input.md> [output.pdf] [--paper a4|letter] [--margin 1in]
#                [--mainfont "Family"] [--twocolumn]
#                [--bib refs.bib] [--csl style.csl]
#
# Defaults: A4, 11pt, 1in margins, Latin Modern + STIX Two math, hyperref colored links.

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
MAINFONT=""           # let pandoc/XeLaTeX pick default if empty
TWOCOLUMN=0
BIB=""
CSL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --paper)     PAPER="$2"; shift 2 ;;
    --margin)    MARGIN="$2"; shift 2 ;;
    --mainfont)  MAINFONT="$2"; shift 2 ;;
    --twocolumn) TWOCOLUMN=1; shift ;;
    --bib)       BIB="$2"; shift 2 ;;
    --csl)       CSL="$2"; shift 2 ;;
    *)           echo "unknown flag: $1" >&2; exit 64 ;;
  esac
done

command -v pandoc  >/dev/null || { echo "error: pandoc not installed (brew install pandoc)" >&2; exit 69; }
command -v xelatex >/dev/null || { echo "error: xelatex not installed (brew install --cask mactex-no-gui)" >&2; exit 69; }

SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PREAMBLE="$SKILL_ROOT/assets/preamble.tex"
LOG="${OUTPUT%.pdf}.build.log"

ARGS=(
  "$INPUT"
  --from=markdown+tex_math_dollars+pipe_tables+backtick_code_blocks+fenced_code_attributes+footnotes+smart+yaml_metadata_block+raw_tex+bracketed_spans+definition_lists+example_lists+task_lists+strikeout+subscript+superscript
  --to=pdf
  --pdf-engine=xelatex
  --include-in-header="$PREAMBLE"
  -V geometry:"paper=${PAPER}paper,margin=${MARGIN}"
  -V fontsize=11pt
  -V linkcolor=black
  -V colorlinks=true
  -V lang=en
  -V microtypeoptions=protrusion=true
  --syntax-highlighting=tango
  --shift-heading-level-by=0
  -o "$OUTPUT"
)

if [[ -n "$MAINFONT" ]]; then
  ARGS+=(-V mainfont="$MAINFONT")
fi
if [[ "$TWOCOLUMN" -eq 1 ]]; then
  ARGS+=(-V classoption=twocolumn)
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
