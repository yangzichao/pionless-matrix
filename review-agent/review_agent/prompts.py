"""Prompt templates for each phase of the dual-agent review protocol."""

from __future__ import annotations

# ── Focus-area descriptions ──────────────────────────────────────────

FOCUS_DESCRIPTIONS: dict[str, str] = {
    "high-level": (
        "Architecture, design patterns, API surface, separation of concerns, "
        "naming, module boundaries, scalability, and maintainability. "
        "Ignore cosmetic nits and low-level bugs."
    ),
    "low-level": (
        "Logic bugs, off-by-one errors, null/undefined handling, edge cases, "
        "type mismatches, resource leaks, error handling, and subtle "
        "correctness issues. Ignore high-level architecture."
    ),
    "security": (
        "OWASP Top 10 vulnerabilities: injection (SQL, command, XSS), "
        "broken auth, sensitive data exposure, insecure deserialization, "
        "CSRF, SSRF, path traversal, and missing input validation."
    ),
    "performance": (
        "Algorithmic complexity, unnecessary allocations, N+1 queries, "
        "missing caching, blocking I/O on hot paths, bundle size impact, "
        "and memory leaks."
    ),
    "balanced": (
        "A balanced review covering correctness, design, security, and "
        "performance. Prioritise the most impactful findings."
    ),
}


# ── Phase 1: Independent review ─────────────────────────────────────

def initial_review(code: str, focus: str, system_prompt: str = "") -> str:
    focus_desc = FOCUS_DESCRIPTIONS[focus]
    sys_block = f"\n\n## System Instructions\n{system_prompt}" if system_prompt else ""

    return f"""\
You are an expert code reviewer.
{sys_block}

## Task
Review the code changes below. Focus on: **{focus}**.

{focus_desc}

## Rules
- Do NOT modify any files. This is a read-only review.
- You MAY use tools (file reading, web search) to understand context.
- Be specific: cite file paths and line numbers where possible.
- Rate each finding: CRITICAL / HIGH / MEDIUM / LOW / NIT.

## Output Format

### Summary
One paragraph describing what the changes do.

### Findings
For each issue:

#### [SEVERITY] Title
- **Location**: `file:line`
- **Problem**: What is wrong and why it matters
- **Suggestion**: Concrete fix or alternative

### Positive Aspects
What is done well — name specific patterns worth keeping.

---

## Code to Review

```
{code}
```"""


# ── Phase 2: Cross-verification ─────────────────────────────────────

def cross_verify(code: str, other_review: str, other_name: str) -> str:
    return f"""\
You are a senior reviewer verifying another reviewer's findings.

## Context
Below is the code that was reviewed, followed by **{other_name}**'s review.

## Your Task
For EACH finding in {other_name}'s review:
1. **Verify** — read the actual code (use tools if needed) to confirm the issue exists.
2. **Assess severity** — agree or re-rate with justification.
3. **Evaluate the fix** — is the suggested fix correct? Propose a better one if not.
4. If you need to, search the web or read documentation to validate claims.

Then add a section for **Missed Issues** — anything important the other reviewer overlooked.

## Rules
- Do NOT modify any files. Read-only.
- Be precise: cite file paths and line numbers.
- If a finding is a false positive, say so explicitly and explain why.

## Output Format

### Verification of {other_name}'s Findings

For each finding:

#### Re: [Original Title]
- **Verified**: Yes / No / Partially
- **Severity**: Agree ({other_name}'s rating) / Revised (your rating) — reason
- **Fix Assessment**: Correct / Improved suggestion: ...
- **Evidence**: what you checked to verify

### Missed Issues
Any findings not in {other_name}'s review (use the same SEVERITY format).

### Agreement Summary
Brief note on where you agree, disagree, and why.

---

## Code Under Review

```
{code}
```

## {other_name}'s Review

{other_review}"""


# ── Phase 3: Consensus synthesis ─────────────────────────────────────

def consensus(
    code: str,
    claude_review: str,
    codex_review: str,
) -> str:
    return f"""\
You are a principal engineer synthesizing two independent code reviews and their
cross-verifications into a single, unified review.

## Input
- **Claude's review** (including any verification rounds)
- **Codex's review** (including any verification rounds)

## Synthesis Rules
1. Include a finding only if it was **confirmed by at least one verification pass**
   or **raised independently by both reviewers**.
2. For confirmed findings, use the **higher** severity if reviewers disagree.
3. Pick the **best suggested fix** (or merge the two).
4. Note any **unresolved disagreements** in a dedicated section.
5. Preserve file paths and line numbers.
6. Do NOT modify any files. This is a read-only synthesis.

## Output Format

# Unified Code Review

## Summary
One paragraph on what the changes do and overall quality assessment.

## Critical & High Findings
(sorted by severity, then by file)

### [SEVERITY] Title
- **Location**: `file:line`
- **Problem**: ...
- **Suggested Fix**: ...
- **Reviewers**: Claude / Codex / Both
- **Verification**: confirmed by ... / disputed by ...

## Medium & Low Findings
(same format)

## Nits
Bullet list.

## Positive Aspects
What both reviewers agree is done well.

## Unresolved Disagreements
Any findings where reviewers could not converge. State both positions.

---

## Claude's Full Review

{claude_review}

## Codex's Full Review

{codex_review}

## Code Under Review

```
{code}
```"""
