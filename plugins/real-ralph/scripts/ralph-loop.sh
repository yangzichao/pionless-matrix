#!/usr/bin/env bash
# Real Ralph Loop: spawn a fresh `claude -p` (or `codex exec`) subprocess per
# iteration. Every iteration starts with zero conversation history; all state
# lives on disk (prompt file, repo, git, logs). The loop exits via --max,
# the stop file, Ctrl-C, consecutive failures, or a wall-time cap.

set -uo pipefail

PROMPT="PROMPT.md"
MAX=0
STOP_FILE=".ralph-stop"
CMD="claude"
LOG=".ralph-progress.log"
DRY_RUN=0
MAX_CONSECUTIVE_FAILURES=3
MAX_MINUTES=0

usage() {
  cat <<'EOF'
Usage: ralph-loop.sh [options] [-- extra args for claude/codex]

Options:
  -p, --prompt PATH              Prompt file fed to each iteration (default: PROMPT.md)
  -n, --max N                    Stop after N iterations (0 = infinite, default: 0)
  -s, --stop-file PATH           Exit if this file exists, then delete it (default: .ralph-stop)
  -c, --cmd NAME                 claude | codex (default: claude)
  -l, --log PATH                 Per-iteration log (default: .ralph-progress.log)
  -f, --max-consecutive-failures N
                                 Exit after N consecutive iterations with rc!=0
                                 (0 = disabled, default: 3). Protects against a
                                 broken PROMPT.md spinning forever.
  -t, --max-minutes N            Exit once wall-clock runtime exceeds N minutes,
                                 checked between iterations (0 = disabled, default: 0).
      --dry-run                  Print what would run, don't invoke
      --cancel                   Create the stop file and exit (ask a running loop to stop)
  -h, --help                     Show this help

Example PROMPT.md:
  Read AGENTS.md. Pick ONE unchecked task. Do it. Mark it [x].
  If every task is done, write DONE to STATUS.md and stop.

Run:
  scripts/ralph-loop.sh -p PROMPT.md -n 20

Stop a running loop from another shell:
  scripts/ralph-loop.sh --cancel
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--prompt)                   PROMPT=$2; shift 2 ;;
    -n|--max)                      MAX=$2; shift 2 ;;
    -s|--stop-file)                STOP_FILE=$2; shift 2 ;;
    -c|--cmd)                      CMD=$2; shift 2 ;;
    -l|--log)                      LOG=$2; shift 2 ;;
    -f|--max-consecutive-failures) MAX_CONSECUTIVE_FAILURES=$2; shift 2 ;;
    -t|--max-minutes)              MAX_MINUTES=$2; shift 2 ;;
    --dry-run)      DRY_RUN=1; shift ;;
    --cancel)       : > "$STOP_FILE"; echo "stop file created: $STOP_FILE"; exit 0 ;;
    -h|--help)      usage; exit 0 ;;
    --)             shift; break ;;
    *)              echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$CMD" != "claude" && "$CMD" != "codex" ]]; then
  echo "--cmd must be claude or codex (got: $CMD)" >&2; exit 2
fi
check_non_negative_int() {
  local flag=$1 val=$2
  if ! [[ "$val" =~ ^[0-9]+$ ]]; then
    echo "$flag must be a non-negative integer (got: $val)" >&2; exit 2
  fi
}
check_non_negative_int --max "$MAX"
check_non_negative_int --max-consecutive-failures "$MAX_CONSECUTIVE_FAILURES"
check_non_negative_int --max-minutes "$MAX_MINUTES"
if [[ $DRY_RUN -eq 0 ]] && ! command -v "$CMD" >/dev/null 2>&1; then
  echo "$CMD not found in PATH" >&2; exit 127
fi

INTERRUPTED=0
trap 'INTERRUPTED=1; echo; echo "ralph-loop: interrupted, exiting after current iteration"' INT TERM

start_epoch=$(date +%s)
consecutive_failures=0
i=0
while :; do
  i=$((i+1))

  if [[ $MAX -gt 0 && $i -gt $MAX ]]; then
    echo "ralph-loop: reached max iterations ($MAX)" | tee -a "$LOG"
    break
  fi
  if [[ $MAX_MINUTES -gt 0 ]]; then
    elapsed_min=$(( ($(date +%s) - start_epoch) / 60 ))
    if [[ $elapsed_min -ge $MAX_MINUTES ]]; then
      echo "ralph-loop: reached max wall-time (${elapsed_min}m >= ${MAX_MINUTES}m)" | tee -a "$LOG"
      break
    fi
  fi
  if [[ -f "$STOP_FILE" ]]; then
    echo "ralph-loop: stop file detected ($STOP_FILE), exiting" | tee -a "$LOG"
    rm -f "$STOP_FILE"
    break
  fi
  if [[ ! -f "$PROMPT" ]]; then
    echo "ralph-loop: prompt file missing: $PROMPT" >&2
    exit 1
  fi

  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "=== ralph iter $i @ $ts ($CMD) ===" | tee -a "$LOG"

  if [[ $DRY_RUN -eq 1 ]]; then
    case "$CMD" in
      claude) echo "[dry-run] cat $PROMPT | claude -p --dangerously-skip-permissions $*" ;;
      codex)  echo "[dry-run] codex exec --full-auto \"\$(cat $PROMPT)\" $*" ;;
    esac
    rc=0
  else
    case "$CMD" in
      claude) cat "$PROMPT" | claude -p --dangerously-skip-permissions "$@"; rc=$? ;;
      codex)  codex exec --full-auto "$(cat "$PROMPT")" "$@"; rc=$? ;;
    esac
  fi

  echo "--- iter $i done rc=$rc ---" | tee -a "$LOG"

  if [[ $rc -eq 0 ]]; then
    consecutive_failures=0
  else
    consecutive_failures=$((consecutive_failures+1))
    if [[ $MAX_CONSECUTIVE_FAILURES -gt 0 && $consecutive_failures -ge $MAX_CONSECUTIVE_FAILURES ]]; then
      echo "ralph-loop: $consecutive_failures consecutive failures (limit $MAX_CONSECUTIVE_FAILURES), exiting" | tee -a "$LOG"
      break
    fi
  fi

  if [[ $INTERRUPTED -eq 1 ]]; then
    echo "ralph-loop: exiting after signal" | tee -a "$LOG"
    break
  fi
done
