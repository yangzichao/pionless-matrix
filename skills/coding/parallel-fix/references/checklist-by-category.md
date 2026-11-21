# Checklist Seeds by Category

Use these as starting checklists for the phase-1 scan. Add items based on the user's description and your judgment.

## security

OWASP-style and adjacent:

- SQL injection, NoSQL injection.
- XSS (reflected, stored, DOM).
- CSRF on state-changing endpoints.
- Auth/session bypass and IDOR (insecure direct object reference).
- SSRF and unsafe URL fetching.
- Path traversal and arbitrary file read/write.
- Command, template, and LDAP injection.
- Crypto misuse (weak algorithms, ECB mode, hardcoded keys, predictable nonces).
- Hardcoded secrets and API keys.
- Unsafe deserialization (`pickle`, `yaml.load`, etc.).
- Insecure defaults on public entrypoints.
- TOCTOU (time-of-check vs time-of-use).
- Missing rate limiting or authorization on sensitive endpoints.
- Open redirect.

## bugs

- Null/undefined dereferences.
- Race conditions in shared state.
- Off-by-one errors in indexing or slicing.
- Resource leaks (unclosed files, connections, subscriptions, timers).
- Swallowed exceptions.
- Wrong type coercion (truthy/falsy traps).
- Missing input validation.
- Shadowed variables.
- Async/await misuse and unchecked promise rejections.
- Dead branches and unreachable code.

## performance

- N+1 queries.
- Unbounded loops or recursion.
- Sync I/O on an async path.
- Missing database indexes on filtered/sorted columns.
- Redundant work in hot paths.
- Unbounded memory growth (caches without eviction, unbounded queues).
- Blocking the event loop.

## types

- Unsafe casts (`as any`, `cast(...)`).
- `any` / `unknown` leaks across module boundaries.
- Missing null guards.
- Wrong generic constraints.
- Ignored type errors (`@ts-ignore`, `# type: ignore`, `// eslint-disable`).

## lint-cleanup

- Dead code.
- Unused imports, variables, parameters.
- Magic numbers without constants.
- Duplicated code blocks.
- Stale `TODO` / `FIXME` / `XXX` markers.
- Inconsistent naming conventions.

## tests

- Missing coverage for public APIs.
- Sleep-based flakiness.
- Over-mocking — especially mocks of the unit under test.
- Missing edge or error cases.
- Tests that do not actually assert anything meaningful.

## docs

- Stale references to renamed or removed items.
- Broken links.
- Wrong function signatures or arguments.
- Missing invariants or preconditions.

## mixed

Build the checklist from the description plus your judgment. Combine the seeds above as relevant. Aim for at least 6–10 items.
