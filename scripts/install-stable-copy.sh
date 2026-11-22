#!/usr/bin/env bash
set -euo pipefail

SCRIPT_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${PIONLESS_INSTALL_DIR:-$HOME/.local/share/pionless-matrix}"
INSTALL_BRANCH="main"
DEFAULT_REMOTE="https://github.com/yangzichao/pionless-matrix.git"

usage() {
  cat <<'EOF'
Keep a separate, clean copy of this repo on main and link agent hosts to it.

  bash scripts/install-stable-copy.sh            clone or fast-forward the copy, then link it
  bash scripts/install-stable-copy.sh --dry-run  print what would change

The copy lives at ~/.local/share/pionless-matrix (override with PIONLESS_INSTALL_DIR).
Hosts read skills from the copy, never from a development checkout, so switching
branches or half-finished edits in a checkout do not reach them. Re-run after every
merge to main to update the hosts. The copy is never edited by hand: if it has local
changes or is off main, this script stops instead of touching it.
EOF
}

DRY_RUN=0
for argument in "$@"; do
  case "$argument" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument '$argument' (try --help)" >&2; exit 2 ;;
  esac
done

remote_url="$(git -C "$SCRIPT_REPO_ROOT" remote get-url origin 2>/dev/null || echo "$DEFAULT_REMOTE")"

if [[ ! -e "$INSTALL_DIR" ]]; then
  echo "== cloning $remote_url ($INSTALL_BRANCH) into $INSTALL_DIR"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "would run: git clone --branch $INSTALL_BRANCH $remote_url $INSTALL_DIR"
    echo "would then run: bash $INSTALL_DIR/scripts/link-skills.sh"
    exit 0
  fi
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --quiet --branch "$INSTALL_BRANCH" "$remote_url" "$INSTALL_DIR"
else
  if ! git -C "$INSTALL_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: $INSTALL_DIR exists but is not a git checkout; move it away and re-run." >&2
    exit 1
  fi
  current_branch="$(git -C "$INSTALL_DIR" branch --show-current)"
  if [[ "$current_branch" != "$INSTALL_BRANCH" ]]; then
    echo "error: $INSTALL_DIR is on '$current_branch', not $INSTALL_BRANCH; it must only track $INSTALL_BRANCH." >&2
    exit 1
  fi
  if [[ -n "$(git -C "$INSTALL_DIR" status --porcelain)" ]]; then
    echo "error: $INSTALL_DIR has local changes; the install copy is never edited. Inspect it with 'git -C $INSTALL_DIR status'." >&2
    exit 1
  fi
  echo "== updating $INSTALL_DIR"
  git -C "$INSTALL_DIR" fetch --quiet origin "$INSTALL_BRANCH"
  if [[ $DRY_RUN -eq 1 ]]; then
    git -C "$INSTALL_DIR" log --oneline "HEAD..origin/$INSTALL_BRANCH" | sed 's/^/would fast-forward: /'
  else
    git -C "$INSTALL_DIR" merge --quiet --ff-only "origin/$INSTALL_BRANCH"
  fi
fi

echo "== copy is at $(git -C "$INSTALL_DIR" log --oneline -1)"
link_arguments=()
[[ $DRY_RUN -eq 1 ]] && link_arguments+=(--dry-run)
bash "$INSTALL_DIR/scripts/link-skills.sh" "${link_arguments[@]+"${link_arguments[@]}"}"
