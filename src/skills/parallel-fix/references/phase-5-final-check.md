# Phase 5 — Final Self-Check + Loop

## 1. Detect toolchain and run the combined check

Detection rules (same as the parallel-fix-worker):

- `package.json` → npm/pnpm scripts (lint, typecheck, test).
- `Cargo.toml` → `cargo check && cargo test`.
- `pyproject.toml` → `ruff/flake8 + mypy + pytest` if configured.
- `go.mod` → `go vet && go test ./...`.
- `tsconfig.json` → `tsc --noEmit` (alongside any test runner).

Run with a generous timeout (180 s+).

## 2. Pass

Print "all green" with the last lines of output, then stop.

## 3. Fail

- Run the check **one more time** immediately (same command, same timeout) to rule out flakiness.
- If the second run passes, print "all green (flaky pass on retry)" and stop.
- If the second run also fails:
  - Capture the failure output (tail ~200 lines).
  - Announce: "Final check failed — starting follow-up round `<N>`".
  - Re-enter **phase 1** using the failure output as the new description.
  - Write the new queue file at `.claude/fix-queue/YYYYMMDD-HHMM-followup-<N>.md`.
  - Pause for user review per phase 2.

## 4. Hard cap on follow-up rounds

**Maximum 3 follow-up rounds.** After the 3rd round still fails, stop. Print the residual failure with "requires manual intervention". Do not loop further.
