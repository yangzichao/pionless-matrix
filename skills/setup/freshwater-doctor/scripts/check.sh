#!/usr/bin/env bash
set -uo pipefail

print_status() {
  local marker=$1 component=$2 detail=$3
  printf "[%s] %-32s %s\n" "$marker" "$component" "$detail"
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

BLOCKER_MISSING=()
OPTIONAL_MISSING=()
WARNINGS=()

mark_blocker_missing() { BLOCKER_MISSING+=("$1"); }
mark_optional_missing() { OPTIONAL_MISSING+=("$1"); }
mark_warning() { WARNINGS+=("$1"); }

echo "freshwater-doctor: scanning local environment..."
echo

echo "== Core glue =="

if has_command uv; then
  print_status OK "uv" "$(uv --version 2>/dev/null | head -1)"
else
  print_status -- "uv" "not found (needed for installing MCP servers via uvx)"
  mark_blocker_missing "uv"
fi

if has_command uvx; then
  print_status OK "uvx" "available"
else
  print_status -- "uvx" "not found (ships with uv)"
fi

if has_command python3; then
  print_status OK "python3" "$(python3 --version 2>&1)"
else
  print_status -- "python3" "not found"
  mark_blocker_missing "python3"
fi

AGENT_CLIS=()
for agent_cli in claude codex; do
  if has_command "$agent_cli"; then
    AGENT_CLIS+=("$agent_cli")
    print_status OK "$agent_cli CLI" "$("$agent_cli" --version 2>&1 | head -1 || echo unknown)"
  else
    print_status -- "$agent_cli CLI" "not found"
  fi
done
if [[ ${#AGENT_CLIS[@]} -eq 0 ]]; then
  mark_blocker_missing "agent CLI"
fi

echo

echo "== Lean toolchain =="

if has_command elan; then
  ELAN_VERSION="$(elan --version 2>&1 | head -1)"
  print_status OK "elan" "$ELAN_VERSION"

  ACTIVE_TOOLCHAIN="$(elan show 2>/dev/null | grep -E '^(active toolchain|default toolchain)' | head -1 | sed 's/.*: //')"
  if [[ -n "$ACTIVE_TOOLCHAIN" ]]; then
    print_status OK "active toolchain" "$ACTIVE_TOOLCHAIN"
  fi
else
  print_status -- "elan" "not found (manages Lean toolchains)"
  mark_blocker_missing "elan"
fi

if has_command lean; then
  print_status OK "lean" "$(lean --version 2>&1 | head -1)"
else
  print_status -- "lean" "not found (installed by elan)"
fi

if has_command lake; then
  print_status OK "lake" "$(lake --version 2>&1 | head -1)"
else
  print_status -- "lake" "not found (installed by elan)"
fi

echo

echo "== Mathlib project =="

SEARCH_ROOTS=(
  "$HOME/workplace"
  "$HOME/math-workspace"
  "$HOME/lean-projects"
  "$HOME"
)

list_lakefiles_under_search_roots() {
  local root
  for root in "${SEARCH_ROOTS[@]}"; do
    [[ -d "$root" ]] || continue
    find "$root" -maxdepth 4 \( -name 'lakefile.toml' -o -name 'lakefile.lean' \) -not -path '*/.lake/*' 2>/dev/null
  done
}

keep_first_lakefile_per_project_directory() {
  local lakefile project_directory seen_project_directories=" "
  while IFS= read -r lakefile; do
    project_directory="$(dirname "$lakefile")"
    case "$seen_project_directories" in
      *" $project_directory "*) continue ;;
    esac
    seen_project_directories+="$project_directory "
    printf '%s\n' "$lakefile"
  done
}

project_declares_mathlib() {
  local project_directory=$1 lakefile=$2
  if [[ -f "$project_directory/lake-manifest.json" ]] && grep -q '"name": "mathlib"' "$project_directory/lake-manifest.json" 2>/dev/null; then
    return 0
  fi
  grep -q -i 'mathlib' "$lakefile" 2>/dev/null
}

FOUND_LAKEFILES=()
while IFS= read -r lakefile; do
  FOUND_LAKEFILES+=("$lakefile")
done < <(list_lakefiles_under_search_roots | keep_first_lakefile_per_project_directory)

if [[ ${#FOUND_LAKEFILES[@]} -eq 0 ]]; then
  print_status -- "Mathlib project" "no Lake project found under \$HOME/workplace, \$HOME/math-workspace, \$HOME/lean-projects, or \$HOME"
  mark_blocker_missing "Mathlib project"
else
  MATHLIB_PROJECT_FOUND=0
  for lf in "${FOUND_LAKEFILES[@]}"; do
    PROJ_DIR="$(dirname "$lf")"
    if project_declares_mathlib "$PROJ_DIR" "$lf"; then
      MATHLIB_PROJECT_FOUND=1
      BUILT="not yet built"
      if [[ -d "$PROJ_DIR/.lake/build" ]]; then
        BUILT="built (.lake/build present)"
      fi
      print_status OK "Mathlib project" "$PROJ_DIR ($BUILT)"
    fi
  done

  if [[ $MATHLIB_PROJECT_FOUND -eq 0 ]]; then
    print_status !! "Lake project" "found ${#FOUND_LAKEFILES[@]} project(s) but none declare Mathlib as a dependency"
    mark_warning "Lake project without Mathlib"
    mark_blocker_missing "Mathlib project"
  fi
fi

echo

echo "== Wolfram (optional) =="

WOLFRAM_FOUND=0
if has_command wolframscript; then
  print_status OK "wolframscript" "$(wolframscript -version 2>&1 | head -1)"
  WOLFRAM_FOUND=1
fi

for app in "/Applications/Wolfram Engine.app" "/Applications/Mathematica.app" "/Applications/Wolfram.app"; do
  if [[ -d "$app" ]]; then
    print_status OK "Wolfram app" "$app"
    WOLFRAM_FOUND=1
  fi
done

if [[ $WOLFRAM_FOUND -eq 0 ]]; then
  print_status -- "Wolfram Engine" "not installed (optional — only needed for the compute side of freshwater)"
  mark_optional_missing "Wolfram Engine"
fi

echo

echo "== MCP servers =="

MCP_LIST_LINES_PREFIXED_WITH_AGENT_CLI=""
for agent_cli in "${AGENT_CLIS[@]+"${AGENT_CLIS[@]}"}"; do
  MCP_LIST_LINES_PREFIXED_WITH_AGENT_CLI+="$("$agent_cli" mcp list 2>&1 | sed "s/^/$agent_cli: /" || true)"$'\n'
done

agent_clis_whose_mcp_list_matches() {
  local server_pattern=$1
  echo "$MCP_LIST_LINES_PREFIXED_WITH_AGENT_CLI" | grep -Ei "$server_pattern" | cut -d: -f1 | sort -u | paste -sd, -
}

if [[ ${#AGENT_CLIS[@]} -gt 0 ]]; then
  for server in lean-lsp lean-explore; do
    found_in="$(agent_clis_whose_mcp_list_matches "$server")"
    if [[ -n "$found_in" ]]; then
      if echo "$MCP_LIST_LINES_PREFIXED_WITH_AGENT_CLI" | grep -i "$server" | grep -qi 'fail\|error\|unhealthy'; then
        print_status !! "$server MCP" "configured in $found_in but reports failure"
        mark_warning "$server MCP unhealthy"
      else
        print_status OK "$server MCP" "configured in $found_in"
      fi
    else
      print_status -- "$server MCP" "not configured in ${AGENT_CLIS[*]}"
      mark_blocker_missing "$server MCP"
    fi
  done

  # Wolfram MCP: match either the official paclet or the community python one
  found_in="$(agent_clis_whose_mcp_list_matches 'wolfram|mathematica')"
  if [[ -n "$found_in" ]]; then
    print_status OK "wolfram/mathematica MCP" "configured in $found_in"
  else
    print_status -- "wolfram MCP" "not configured (optional)"
    mark_optional_missing "wolfram MCP"
  fi
else
  print_status !! "MCP servers" "cannot inspect without claude or codex CLI"
  mark_warning "no agent CLI found, cannot list MCP servers"
fi

echo

echo "== Claude Code plugins =="

PLUGINS_DIR="$HOME/.claude/plugins"
if [[ -d "$PLUGINS_DIR" ]]; then
  if find "$PLUGINS_DIR" -maxdepth 3 -type d -name 'lean4-skills*' 2>/dev/null | grep -q .; then
    print_status OK "lean4-skills plugin" "installed"
  else
    print_status -- "lean4-skills plugin" "not installed (optional but recommended for Lean workflows)"
    mark_optional_missing "lean4-skills plugin"
  fi
else
  print_status -- "lean4-skills plugin" "no Claude Code plugins directory (skip if you don't use Claude Code)"
fi

echo

echo "== Disk =="

FREE_GB="$(df -g "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')"
if [[ -n "${FREE_GB:-}" ]]; then
  if [[ "$FREE_GB" -lt 10 ]]; then
    print_status !! "free space on \$HOME" "${FREE_GB}G — Mathlib cache alone wants 5–10G"
    mark_warning "low disk space"
  else
    print_status OK "free space on \$HOME" "${FREE_GB}G"
  fi
else
  print_status !! "free space" "could not determine"
fi

echo

echo "== Summary =="

if [[ ${#BLOCKER_MISSING[@]} -eq 0 && ${#WARNINGS[@]} -eq 0 ]]; then
  if [[ ${#OPTIONAL_MISSING[@]} -eq 0 ]]; then
    echo "RECOMMENDATION: stack is fully provisioned."
  else
    echo "RECOMMENDATION: core stack is ready. Optional items still missing: ${OPTIONAL_MISSING[*]}"
  fi
  exit 0
fi

BLOCKERS_IN_DEPENDENCY_ORDER=("uv" "python3" "agent CLI" "elan" "Mathlib project" "lean-lsp MCP" "lean-explore MCP")

RECOMMEND=""
for need in "${BLOCKERS_IN_DEPENDENCY_ORDER[@]}"; do
  for got in "${BLOCKER_MISSING[@]+"${BLOCKER_MISSING[@]}"}"; do
    if [[ "$got" == "$need" ]]; then
      RECOMMEND="$need"
      break 2
    fi
  done
done

case "$RECOMMEND" in
  uv)
    echo "RECOMMENDATION: install uv first (Homebrew: 'brew install uv'). Everything else flows from this."
    ;;
  python3)
    echo "RECOMMENDATION: install Python 3 (pyenv or Homebrew). Required for MCP servers."
    ;;
  "agent CLI")
    echo "RECOMMENDATION: install an agent CLI (Claude Code or Codex). MCP servers are wired into it."
    ;;
  elan)
    echo "RECOMMENDATION: install elan, the Lean toolchain manager:"
    echo "    curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh"
    echo "  This unblocks lean + lake + every Lean-side dependency in one step."
    ;;
  "Mathlib project")
    echo "RECOMMENDATION: create a Mathlib-bearing Lake project, e.g.:"
    echo "    cd ~/workplace && lake new math-sandbox math.toml"
    echo "  then add 'mathlib' to lakefile.toml dependencies and run 'lake update && lake build'."
    ;;
  "lean-lsp MCP")
    echo "RECOMMENDATION: wire lean-lsp-mcp into your agent CLI:"
    echo "    claude mcp add --scope user lean-lsp -- uvx lean-lsp-mcp   # Claude Code"
    echo "    codex mcp add lean-lsp -- uvx lean-lsp-mcp                 # Codex"
    ;;
  "lean-explore MCP")
    echo "RECOMMENDATION: wire lean-explore MCP into your agent CLI:"
    echo "    claude mcp add --scope user lean-explore -- uvx leanexplore mcp   # Claude Code"
    echo "    codex mcp add lean-explore -- uvx leanexplore mcp                 # Codex"
    ;;
  *)
    echo "RECOMMENDATION: review the [--] entries above and address them in order."
    ;;
esac

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo
  echo "Warnings to investigate:"
  printf '  - %s\n' "${WARNINGS[@]}"
fi

exit 0
