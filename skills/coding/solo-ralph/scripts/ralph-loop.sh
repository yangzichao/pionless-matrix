#!/usr/bin/env bash
# Written for bash 3.2 (macOS default), so no namerefs and guarded empty arrays.

set -uo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

LOCK_AND_PID_FILE=".ralph.pid"
OUT_FILE=".ralph.out"

STARTUP_CHECK_SECONDS=1
CANCEL_GRACE_SECONDS=5
SIGTERM_TO_SIGKILL_GRACE_SECONDS=5

PROJECT_DIR="$PWD"
PROMPT="PROMPT.md"
MAX=0
STOP_FILE=".ralph-stop"
RUNNER="${RALPH_RUNNER:-}"
LOG=".ralph-progress.log"
DRY_RUN=0
MAX_CONSECUTIVE_FAILURES=3
MAX_MINUTES=0
SOFT_CANCEL=0
LOCK_HELD_BY_START=0
DRY_RUN_DEFAULT_MAX_ITERATIONS=1
EXTRA_ARGS=()

usage() {
  cat <<'EOF'
Usage: ralph-loop.sh <command> [options] [-- extra args for the runner CLI]

Commands:
  start    Take the lock, launch the loop detached (nohup), check it stayed up, return.
  run      Run the loop in the foreground (this is what `start` launches).
  status   Show whether a loop is running, recent progress markers and output.
  cancel   Stop the loop: create the stop file, wait briefly, then SIGTERM the whole
           process tree (runner subprocesses first, then the driver).

Options:
  -C, --dir DIR        Project directory holding the prompt and runtime files
                       (default: current directory)
  -r, --runner NAME    claude | codex. Default: $RALPH_RUNNER if set, else the first
                       of claude, codex found in PATH
  -p, --prompt PATH    Prompt file fed to each iteration (default: PROMPT.md)
  -n, --max N          Stop after N iterations (0 = no cap, default: 0)
  -s, --stop-file PATH Exit between iterations if this file exists (default: .ralph-stop)
  -l, --log PATH       Per-iteration progress log (default: .ralph-progress.log)
  -f, --max-consecutive-failures N
                       Exit after N consecutive iterations with rc != 0
                       (0 = disabled, default: 3)
  -t, --max-minutes N  Exit once runtime exceeds N minutes, checked between
                       iterations (0 = disabled, default: 0)
      --soft           cancel only: just create the stop file; the loop exits
                       after its current iteration finishes
      --dry-run        start: print the launch command only. run: print each runner
                       command instead of invoking it (stops after 1 iteration unless -n)
      --lock-held-by-start
                       run only, internal: `start` already took the lock for this run
  -h, --help           Show this help

Runner invocations (prompt file on stdin):
  claude:  claude -p --dangerously-skip-permissions [extra args] < PROMPT
  codex:   codex exec --approve-for-me [extra args] - < PROMPT

Runtime files in the project directory:
  .ralph.pid  .ralph.out  .ralph-progress.log  .ralph-stop

Examples:
  bash /path/to/solo-ralph/scripts/ralph-loop.sh start
  bash /path/to/solo-ralph/scripts/ralph-loop.sh start --runner codex -- -m gpt-5
  bash /path/to/solo-ralph/scripts/ralph-loop.sh status
  bash /path/to/solo-ralph/scripts/ralph-loop.sh cancel
EOF
}

die() {
  echo "ralph-loop: $*" >&2
  exit 1
}

usage_error() {
  echo "ralph-loop: $*" >&2
  echo "run 'ralph-loop.sh --help' for usage" >&2
  exit 2
}

check_non_negative_int() {
  local flag=$1 value=$2
  [[ "$value" =~ ^[0-9]+$ ]] || usage_error "$flag must be a non-negative integer (got: $value)"
}

need_value() {
  [[ $# -ge 2 && -n "$2" ]] || usage_error "$1 needs a value"
}

COMMAND=""
if [[ $# -gt 0 ]]; then
  case "$1" in
    start|run|status|cancel) COMMAND=$1; shift ;;
    help) usage; exit 0 ;;
    *) usage_error "unknown command: $1" ;;
  esac
else
  usage >&2
  exit 2
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -C|--dir)                      need_value "$@"; PROJECT_DIR=$2; shift 2 ;;
    -r|--runner)                   need_value "$@"; RUNNER=$2; shift 2 ;;
    -p|--prompt)                   need_value "$@"; PROMPT=$2; shift 2 ;;
    -n|--max)                      need_value "$@"; MAX=$2; shift 2 ;;
    -s|--stop-file)                need_value "$@"; STOP_FILE=$2; shift 2 ;;
    -l|--log)                      need_value "$@"; LOG=$2; shift 2 ;;
    -f|--max-consecutive-failures) need_value "$@"; MAX_CONSECUTIVE_FAILURES=$2; shift 2 ;;
    -t|--max-minutes)              need_value "$@"; MAX_MINUTES=$2; shift 2 ;;
    --soft)                        SOFT_CANCEL=1; shift ;;
    --dry-run)                     DRY_RUN=1; shift ;;
    --lock-held-by-start)          LOCK_HELD_BY_START=1; shift ;;
    -h|--help)                     usage; exit 0 ;;
    --)                            shift; EXTRA_ARGS=("$@"); break ;;
    *)                             usage_error "unknown option: $1" ;;
  esac
done

check_non_negative_int --max "$MAX"
check_non_negative_int --max-consecutive-failures "$MAX_CONSECUTIVE_FAILURES"
check_non_negative_int --max-minutes "$MAX_MINUTES"

[[ -d "$PROJECT_DIR" ]] || die "project directory not found: $PROJECT_DIR"
cd "$PROJECT_DIR" || die "cannot cd into project directory: $PROJECT_DIR"
PROJECT_DIR="$PWD"

resolve_runner() {
  if [[ -z "$RUNNER" ]]; then
    if command -v claude >/dev/null 2>&1; then
      RUNNER="claude"
    elif command -v codex >/dev/null 2>&1; then
      RUNNER="codex"
    elif [[ $DRY_RUN -eq 1 ]]; then
      RUNNER="claude"
    else
      die "no runner found: install the claude or codex CLI, or pass --runner"
    fi
  fi
  case "$RUNNER" in
    claude|codex) ;;
    *) usage_error "--runner must be claude or codex (got: $RUNNER)" ;;
  esac
  if [[ $DRY_RUN -eq 0 ]] && ! command -v "$RUNNER" >/dev/null 2>&1; then
    echo "ralph-loop: runner '$RUNNER' not found in PATH" >&2
    exit 127
  fi
}

runner_command() {
  case "$RUNNER" in
    claude) RUNNER_CMD=(claude -p --dangerously-skip-permissions) ;;
    codex)  RUNNER_CMD=(codex exec --approve-for-me) ;;
  esac
  if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
    RUNNER_CMD=("${RUNNER_CMD[@]}" "${EXTRA_ARGS[@]}")
  fi
  # `codex exec -` reads the prompt from stdin; `claude -p` reads stdin when no prompt arg is given.
  if [[ "$RUNNER" == "codex" ]]; then
    RUNNER_CMD=("${RUNNER_CMD[@]}" -)
  fi
}

create_lock_file_atomically() {
  ( set -o noclobber; printf 'INIT\n' > "$LOCK_AND_PID_FILE" ) 2>/dev/null
}

acquire_lock() {
  if create_lock_file_atomically; then
    return 0
  fi
  local holder
  holder=$(cat "$LOCK_AND_PID_FILE" 2>/dev/null)
  if [[ "$holder" == "INIT" ]] || { [[ "$holder" =~ ^[0-9]+$ ]] && kill -0 "$holder" 2>/dev/null; }; then
    die "a loop is already running or starting in $PROJECT_DIR (pid=$holder); run 'ralph-loop.sh cancel' first"
  fi
  rm -f "$LOCK_AND_PID_FILE"
  if ! create_lock_file_atomically; then
    die "another start took the lock at the same moment; retry"
  fi
}

release_lock() {
  if [[ "$(cat "$LOCK_AND_PID_FILE" 2>/dev/null)" == "$$" ]]; then
    rm -f "$LOCK_AND_PID_FILE"
  fi
}

list_tree_post_order() {
  local parent=$1 child
  for child in $(pgrep -P "$parent" 2>/dev/null); do
    list_tree_post_order "$child"
  done
  echo "$parent"
}

wait_for_exit() {
  local pid=$1 seconds=$2 waited=0
  while kill -0 "$pid" 2>/dev/null && [[ $waited -lt $seconds ]]; do
    sleep 1
    waited=$((waited + 1))
  done
  ! kill -0 "$pid" 2>/dev/null
}

clear_stop_file_left_by_earlier_cancel() {
  rm -f "$STOP_FILE"
}

last_iteration_line() {
  if [[ -f "$LOG" ]]; then
    grep '^=== ralph iter ' "$LOG" | tail -n 1
  fi
}

cmd_start() {
  [[ -f "$PROMPT" ]] || die "prompt file not found: $PROJECT_DIR/$PROMPT"
  resolve_runner

  local child_args=(run --lock-held-by-start -C "$PROJECT_DIR" -r "$RUNNER" -p "$PROMPT" -n "$MAX" -s "$STOP_FILE"
                    -l "$LOG" -f "$MAX_CONSECUTIVE_FAILURES" -t "$MAX_MINUTES")
  if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
    child_args=("${child_args[@]}" -- "${EXTRA_ARGS[@]}")
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] would take lock $PROJECT_DIR/$LOCK_AND_PID_FILE and launch:"
    echo "[dry-run] nohup bash $SCRIPT_PATH ${child_args[*]} >> $OUT_FILE 2>&1 &"
    return 0
  fi

  acquire_lock
  clear_stop_file_left_by_earlier_cancel

  nohup bash "$SCRIPT_PATH" "${child_args[@]}" >> "$OUT_FILE" 2>&1 < /dev/null &
  local pid=$!
  printf '%s\n' "$pid" > "$LOCK_AND_PID_FILE"
  disown "$pid" 2>/dev/null || true

  sleep "$STARTUP_CHECK_SECONDS"
  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$LOCK_AND_PID_FILE"
    echo "ralph-loop: loop exited within ${STARTUP_CHECK_SECONDS}s of starting; last output from $OUT_FILE:" >&2
    tail -n 20 "$OUT_FILE" >&2
    exit 1
  fi

  echo "solo-ralph loop started"
  echo "  pid:     $pid"
  echo "  runner:  $RUNNER"
  echo "  project: $PROJECT_DIR"
  echo "  status:  bash $SCRIPT_PATH status -C $PROJECT_DIR"
  echo "  follow:  tail -f $PROJECT_DIR/$LOG"
  echo "  stop:    bash $SCRIPT_PATH cancel -C $PROJECT_DIR"
}

cmd_run() {
  [[ -f "$PROMPT" ]] || die "prompt file not found: $PROJECT_DIR/$PROMPT"
  resolve_runner
  runner_command

  if [[ $DRY_RUN -eq 1 ]]; then
    LOG=/dev/null
    [[ $MAX -eq 0 ]] && MAX=$DRY_RUN_DEFAULT_MAX_ITERATIONS
  fi

  if [[ $DRY_RUN -eq 0 && $LOCK_HELD_BY_START -eq 0 ]]; then
    acquire_lock
    printf '%s\n' "$$" > "$LOCK_AND_PID_FILE"
  fi
  trap 'release_lock' EXIT

  INTERRUPTED=0
  trap 'INTERRUPTED=1; echo; echo "ralph-loop: interrupted, exiting after current iteration"' INT TERM

  local start_epoch consecutive_failures=0 iteration=0 timestamp rc elapsed_minutes
  start_epoch=$(date +%s)
  while :; do
    iteration=$((iteration + 1))

    if [[ $MAX -gt 0 && $iteration -gt $MAX ]]; then
      echo "ralph-loop: reached max iterations ($MAX)" | tee -a "$LOG"
      break
    fi
    if [[ $MAX_MINUTES -gt 0 ]]; then
      elapsed_minutes=$(( ($(date +%s) - start_epoch) / 60 ))
      if [[ $elapsed_minutes -ge $MAX_MINUTES ]]; then
        echo "ralph-loop: reached max wall-time (${elapsed_minutes}m >= ${MAX_MINUTES}m)" | tee -a "$LOG"
        break
      fi
    fi
    if [[ -f "$STOP_FILE" ]]; then
      echo "ralph-loop: stop file detected ($STOP_FILE), exiting" | tee -a "$LOG"
      rm -f "$STOP_FILE"
      break
    fi
    if [[ ! -f "$PROMPT" ]]; then
      echo "ralph-loop: prompt file disappeared: $PROJECT_DIR/$PROMPT" | tee -a "$LOG" >&2
      exit 1
    fi

    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "=== ralph iter $iteration @ $timestamp ($RUNNER) ===" | tee -a "$LOG"

    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] ${RUNNER_CMD[*]} < $PROMPT"
      rc=0
    else
      "${RUNNER_CMD[@]}" < "$PROMPT"
      rc=$?
    fi

    echo "--- iter $iteration done rc=$rc ---" | tee -a "$LOG"

    if [[ $rc -eq 0 ]]; then
      consecutive_failures=0
    else
      consecutive_failures=$((consecutive_failures + 1))
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
}

cmd_status() {
  echo "=== process ($PROJECT_DIR) ==="
  if [[ -f "$LOCK_AND_PID_FILE" ]]; then
    local pid
    pid=$(cat "$LOCK_AND_PID_FILE" 2>/dev/null)
    if [[ "$pid" == "INIT" ]]; then
      echo "lock held by a starting loop (pid not written yet); if this persists, run cancel to clear it"
    elif [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
      echo "running pid=$pid"
    else
      echo "stale pid file (pid=$pid is not running)"
    fi
  else
    echo "not running (no $LOCK_AND_PID_FILE)"
  fi
  [[ -f "$STOP_FILE" ]] && echo "stop file present: loop will exit after the current iteration"

  echo
  echo "=== last 20 progress lines ($LOG) ==="
  if [[ -f "$LOG" ]]; then tail -n 20 "$LOG"; else echo "no $LOG yet"; fi

  echo
  echo "=== last 30 output lines ($OUT_FILE) ==="
  if [[ -f "$OUT_FILE" ]]; then tail -n 30 "$OUT_FILE"; else echo "no $OUT_FILE yet"; fi
}

cmd_cancel() {
  : > "$STOP_FILE"
  echo "stop file created: $PROJECT_DIR/$STOP_FILE"
  if [[ $SOFT_CANCEL -eq 1 ]]; then
    echo "the loop will exit after its current iteration"
    return 0
  fi

  if [[ ! -f "$LOCK_AND_PID_FILE" ]]; then
    rm -f "$STOP_FILE"
    echo "no $LOCK_AND_PID_FILE: no loop running in $PROJECT_DIR"
    return 0
  fi

  local pid
  pid=$(cat "$LOCK_AND_PID_FILE" 2>/dev/null)
  if ! [[ "$pid" =~ ^[0-9]+$ ]] || ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$LOCK_AND_PID_FILE" "$STOP_FILE"
    echo "cleared stale lock (pid=$pid was not running)"
    return 0
  fi

  if wait_for_exit "$pid" "$CANCEL_GRACE_SECONDS"; then
    echo "loop exited cleanly"
  else
    echo "loop still alive after ${CANCEL_GRACE_SECONDS}s, terminating process tree of pid=$pid"
    local tree member survivors=""
    tree=$(list_tree_post_order "$pid")
    for member in $tree; do
      kill -TERM "$member" 2>/dev/null || true
    done
    wait_for_exit "$pid" "$SIGTERM_TO_SIGKILL_GRACE_SECONDS" >/dev/null
    for member in $tree; do
      if kill -0 "$member" 2>/dev/null; then
        kill -KILL "$member" 2>/dev/null || true
        survivors="$survivors $member"
      fi
    done
    [[ -n "$survivors" ]] && echo "sent SIGKILL to processes that ignored SIGTERM:$survivors"
    for member in $tree; do
      if kill -0 "$member" 2>/dev/null; then
        echo "ralph-loop: process $member is still alive; kill it by hand" >&2
      fi
    done
  fi

  rm -f "$LOCK_AND_PID_FILE" "$STOP_FILE"
  local last
  last=$(last_iteration_line)
  echo "last iteration: ${last:-none recorded in $LOG}"
}

case "$COMMAND" in
  start)  cmd_start ;;
  run)    cmd_run ;;
  status) cmd_status ;;
  cancel) cmd_cancel ;;
esac
