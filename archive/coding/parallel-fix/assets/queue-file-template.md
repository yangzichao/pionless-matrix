# Fix Queue — {YYYY-MM-DD HH:MM}

Source: {verbatim user description}
Scope: {files / dirs scanned}
Category: {category}
Branch: {current branch}
Max parallel: {N}

## Checklist applied

- {item 1}
- {item 2}
- ...

## Scan coverage

- Angle A (direct): {N findings}
- Angle B (adversarial): {N findings}
- Angle C (harsh reviewer): {N findings}
- Self-pass (cross-cutting): {N findings}
- After dedupe: {N unique tasks}

## Tasks

| # | Severity | Files | Issue | Found by | Status |
|---|----------|-------|-------|----------|--------|
| 1 | high | src/auth/login.py:42 | SQL injection in query | A,C | pending |
| 2 | med  | src/auth/session.py, src/auth/tokens.py:88 | stale token not invalidated | B | pending |
| 3 | low  | src/util/cache.py:12 | [low-confidence] possible race on eviction | C | pending |

## Worker results

_(filled in by the orchestrator during dispatch)_
