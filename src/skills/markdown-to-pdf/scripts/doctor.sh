#!/usr/bin/env bash
# Diagnostic for the markdown-to-pdf pipeline. Read-only — installs nothing.
# Probes every component the build script depends on (pandoc, xelatex, fonts,
# optional mmdc) and prints a structured punch list with [OK] / [--] / [!!]
# markers, ending with the single most useful next install command.

# NOTE: deliberately no `pipefail` here. Several probes pipe huge font lists
# into `grep -q`, which exits on first match and triggers SIGPIPE upstream;
# with pipefail set, that would surface as a false negative.
set -u

PLATFORM="$(uname -s)"
BLOCKERS=()
WARNINGS=()

ok()      { printf "[OK] %s\n" "$1"; }
blocker() { printf "[--] %s\n" "$1"; BLOCKERS+=("$1"); }
warn()    { printf "[!!] %s\n" "$1"; WARNINGS+=("$1"); }

# Font probe order:
#   1. fontconfig (`fc-list`)        — Linux, brew-installed on macOS
#   2. macOS CoreText via system_profiler — slow but authoritative
#   3. kpsewhich                     — for TeX-installed math fonts that
#                                      live outside the system font path
font_present() {
  local family="$1"
  if command -v fc-list >/dev/null 2>&1 && fc-list | grep -i "$family" >/dev/null; then
    return 0
  fi
  if [[ "$PLATFORM" == "Darwin" ]] && command -v system_profiler >/dev/null 2>&1; then
    if system_profiler SPFontsDataType 2>/dev/null | grep -i "$family" >/dev/null; then
      return 0
    fi
  fi
  if command -v kpsewhich >/dev/null 2>&1; then
    case "$family" in
      "Latin Modern Math") [[ -n "$(kpsewhich latinmodern-math.otf 2>/dev/null)" ]] && return 0 ;;
      "STIX Two Math")     [[ -n "$(kpsewhich STIXTwoMath-Regular.otf 2>/dev/null)" ]] && return 0 ;;
    esac
  fi
  return 1
}

check_font() {
  local family="$1" role="$2" severity="${3:-warn}"
  if font_present "$family"; then
    ok "font: $role — $family"
  elif [[ "$severity" == "blocker" ]]; then
    blocker "font: $role — $family not installed"
  else
    warn "font: $role — $family missing (fallback will be used)"
  fi
}

echo "=== markdown-to-pdf doctor ($PLATFORM) ==="
echo

# 1. Core engines (blocker)
if command -v pandoc >/dev/null 2>&1; then
  ok "pandoc $(pandoc --version | head -1 | awk '{print $2}')"
else
  blocker "pandoc — install: brew install pandoc"
fi

if command -v xelatex >/dev/null 2>&1; then
  ok "xelatex ($(xelatex --version | head -1 | sed 's/.*XeTeX //'))"
else
  blocker "xelatex — install: brew install --cask mactex-no-gui"
fi

# 2. Mermaid (optional)
if command -v mmdc >/dev/null 2>&1; then
  ok "mmdc $(mmdc --version 2>&1 | head -1) (mermaid support active)"
else
  warn "mmdc — mermaid blocks will render as plain code. install: npm install -g @mermaid-js/mermaid-cli"
fi

# 3. Fonts: defaults the build script picks per platform
case "$PLATFORM" in
  Darwin)
    check_font "Helvetica Neue" "body (default)"
    check_font "Menlo"          "mono (default)"
    check_font "PingFang SC"    "CJK"
    ;;
  Linux)
    check_font "DejaVu Sans"      "body (default)"
    check_font "DejaVu Sans Mono" "mono (default)"
    check_font "Noto Serif CJK SC" "CJK"
    ;;
esac

if font_present "STIX Two Math"; then
  ok "font: math — STIX Two Math"
elif font_present "Latin Modern Math"; then
  warn "font: math — STIX Two Math missing, falling back to Latin Modern Math"
else
  blocker "font: math — neither STIX Two Math nor Latin Modern Math installed"
fi

# 4. Skill assets
SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for f in assets/preamble.tex assets/mermaid-filter.lua scripts/build_pdf.sh; do
  if [[ -f "$SKILL_ROOT/$f" ]]; then
    ok "asset: $f"
  else
    blocker "asset: $f missing (skill files corrupted)"
  fi
done

echo
echo "=== summary ==="
if [[ ${#BLOCKERS[@]} -gt 0 ]]; then
  echo "${#BLOCKERS[@]} blocker(s), ${#WARNINGS[@]} warning(s) — pipeline will not render."
  echo
  echo "NEXT: ${BLOCKERS[0]}"
  exit 1
elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo "Ready to render with ${#WARNINGS[@]} fallback(s) in effect."
  exit 0
else
  echo "All green. Ready to render."
  exit 0
fi
