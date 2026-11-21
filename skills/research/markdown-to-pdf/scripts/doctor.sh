#!/usr/bin/env bash
# Diagnostic for the markdown-to-pdf pipeline. Read-only — installs nothing.
#
# Probes every component the build script depends on (pandoc, a Chrome /
# Chromium binary, optional mmdc) and prints a structured punch list with
# [OK] / [--] / [!!] markers, ending with the single most useful next
# install command. The current pipeline is markdown → HTML+KaTeX → Chrome
# → PDF; XeLaTeX is no longer involved, so we don't probe TeX Live or
# math fonts (KaTeX bundles its own).
#
# NOTE: deliberately no `pipefail` here. Some probes pipe huge outputs
# into `grep -q`, which exits on first match and triggers SIGPIPE upstream;
# with pipefail set, that would surface as a false negative.
set -u

PLATFORM="$(uname -s)"
BLOCKERS=()
WARNINGS=()

ok()      { printf "[OK] %s\n" "$1"; }
blocker() { printf "[--] %s\n" "$1"; BLOCKERS+=("$1"); }
warn()    { printf "[!!] %s\n" "$1"; WARNINGS+=("$1"); }

find_chrome() {
  local candidates=() puppeteer
  [[ -n "${CHROME_BIN:-}" ]] && candidates+=("$CHROME_BIN")
  candidates+=(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
  )
  # Puppeteer layout: chrome-mac-{arm64,x64} on macOS, chrome-linux* on Linux.
  case "$PLATFORM" in
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

echo "=== markdown-to-pdf doctor ($PLATFORM) ==="
echo

# 1. Pandoc (blocker)
if command -v pandoc >/dev/null 2>&1; then
  ok "pandoc $(pandoc --version | head -1 | awk '{print $2}')"
else
  blocker "pandoc — install: brew install pandoc"
fi

# 2. Chrome / Chromium (blocker)
if CHROME="$(find_chrome)"; then
  # Try to extract a version string. Most Chrome builds support --version.
  VERSION="$("$CHROME" --version 2>/dev/null | head -1)"
  ok "chrome — $CHROME${VERSION:+ ($VERSION)}"
else
  blocker "chrome/chromium — install Google Chrome from https://www.google.com/chrome/ or set \$CHROME_BIN"
fi

# 3. mmdc (optional, mermaid)
if command -v mmdc >/dev/null 2>&1; then
  ok "mmdc $(mmdc --version 2>&1 | head -1) (mermaid support active)"
else
  warn "mmdc — mermaid blocks will render as plain code. install: npm install -g @mermaid-js/mermaid-cli"
fi

# 4. Skill assets
SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for f in assets/style.css assets/mermaid-filter.lua scripts/build_pdf.sh; do
  if [[ -f "$SKILL_ROOT/$f" ]]; then
    ok "asset: $f"
  else
    blocker "asset: $f missing (skill files corrupted)"
  fi
done

# 5. Network reachability for KaTeX CDN (warning only — Chrome can usually cache)
if command -v curl >/dev/null 2>&1; then
  if curl -sIfL --max-time 5 https://cdn.jsdelivr.net/npm/katex/dist/katex.min.css >/dev/null 2>&1; then
    ok "network: KaTeX CDN reachable (jsdelivr.net)"
  else
    warn "network: KaTeX CDN unreachable — math may not render unless Chrome has cached it"
  fi
fi

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
