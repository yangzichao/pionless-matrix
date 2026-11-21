#!/usr/bin/env bash
# Symlink every skill in this repo into the local skill folders agent hosts read.
#
#   bash scripts/link-skills.sh            link (or relink) every skill
#   bash scripts/link-skills.sh --dry-run  print what would change
#   bash scripts/link-skills.sh --unlink   remove every symlink that points into this repo
#
# Default destinations:
#   ~/.claude/skills  Claude Code
#   ~/.agents/skills  Codex and other Agent Skills hosts that read the shared folder
# Override with SKILL_LINK_DESTS, a colon-separated list of folders.
#
# Each entry is a symlink into this checkout, so `git pull` updates every host.
# A real (non-symlink) folder with the same name is never replaced; it is reported
# and skipped. Symlinks into this repo whose skill no longer exists are removed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_ROOT="$REPO_ROOT/skills"
DEFAULT_DESTS="$HOME/.claude/skills:$HOME/.agents/skills"
IFS=':' read -r -a DESTINATIONS <<< "${SKILL_LINK_DESTS:-$DEFAULT_DESTS}"

MODE="link"
DRY_RUN=0
for argument in "$@"; do
  case "$argument" in
    --dry-run) DRY_RUN=1 ;;
    --unlink) MODE="unlink" ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "error: unknown argument '$argument' (try --help)" >&2; exit 2 ;;
  esac
done

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "would run: $*"
  else
    "$@"
  fi
}

points_into_repo() {
  local link_path="$1"
  [[ -L "$link_path" ]] || return 1
  local target
  target="$(readlink "$link_path")"
  [[ "$target" == "$REPO_ROOT"/* ]]
}

# skills/<bucket>/<skill-name>/SKILL.md -> skill folder paths
SKILL_FOLDERS=()
while IFS= read -r skill_md; do
  SKILL_FOLDERS+=("$(dirname "$skill_md")")
done < <(find "$SKILLS_ROOT" -mindepth 3 -maxdepth 3 -name SKILL.md | sort)

for destination in "${DESTINATIONS[@]}"; do
  [[ -n "$destination" ]] || continue
  if [[ -L "$destination" ]] && [[ "$(cd "$destination" && pwd -P)" == "$REPO_ROOT"* ]]; then
    echo "error: $destination is itself a symlink into this repo; remove it and re-run." >&2
    exit 1
  fi
  echo "== $destination"
  run mkdir -p "$destination"

  # Remove links into this repo that are stale (or all of them, in unlink mode).
  if [[ -d "$destination" ]]; then
    for existing in "$destination"/*; do
      points_into_repo "$existing" || continue
      if [[ "$MODE" == "unlink" || ! -f "$existing/SKILL.md" ]]; then
        run rm "$existing"
        echo "removed $(basename "$existing")"
      fi
    done
  fi
  [[ "$MODE" == "link" ]] || continue

  for skill_folder in "${SKILL_FOLDERS[@]}"; do
    skill_name="$(basename "$skill_folder")"
    target="$destination/$skill_name"
    if [[ -e "$target" && ! -L "$target" ]]; then
      echo "skipped $skill_name: $target is a real folder, not a symlink (move it away to link this one)"
      continue
    fi
    run ln -sfn "$skill_folder" "$target"
    echo "linked $skill_name"
  done
done
