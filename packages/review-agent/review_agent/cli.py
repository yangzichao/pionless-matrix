"""CLI entry point for review-agent."""

from __future__ import annotations

import argparse
import asyncio
import sys
import textwrap


GUIDE = textwrap.dedent("""\
    review-agent — Dual-agent code review (Claude Code x Codex CLI)

    QUICK START
      review-agent                        Review uncommitted changes
      review-agent --last 1               Review the most recent commit
      review-agent --branch main          Review current branch vs main

    WHAT TO REVIEW
      --diff                              Uncommitted changes (default)
      --last N                            Last N commits
      --branch BASE                       Changes compared to a base branch
      --commit REF                        A single commit or range (e.g. HEAD~3..HEAD)
      --files PATH [PATH ...]             Specific files (full content)
      --dir PATH                          All git-tracked files under a directory
      --repo                              Full repository (agents explore via tools)

    FOCUS
      --focus balanced                    Correctness, design, security, performance (default)
      --focus high-level                  Architecture, API design, module boundaries
      --focus low-level                   Logic bugs, edge cases, off-by-one errors
      --focus security                    OWASP Top 10, injection, auth, input validation
      --focus performance                 Complexity, N+1 queries, memory leaks, caching

    CUSTOM INSTRUCTIONS
      --system-prompt TEXT                Inject instructions into every agent prompt
      --system-prompt-file FILE           Read instructions from a file

    TUNING
      --rounds N                          Cross-verification rounds (default: 1, more = stricter)
      --claude-cmd CMD                    Override Claude CLI executable
      --codex-cmd CMD                     Override Codex CLI executable
      --output-dir DIR                    Output directory (default: code-review)

    DEBUG
      --dry-run                           Mock agents, inspect prompts & data flow
      -v, --verbose                       Show previews + save debug traces

    PROTOCOL
      Phase 1  Both agents review independently (parallel)
      Phase 2  Each agent verifies the other's findings (parallel x N rounds)
      Phase 3  Consensus synthesis into FINAL.md

    OUTPUT
      code-review/<timestamp>/
        FINAL.md      <- unified consensus (read this)
        claude.md     <- Claude's full review + verification
        codex.md      <- Codex's full review + verification
        debug/        <- prompts & per-phase responses (with -v or --dry-run)

    EXAMPLES
      review-agent --last 3 --focus security
      review-agent --branch main --rounds 2
      review-agent --dir src/api/ --focus high-level
      review-agent --repo --system-prompt "Focus on error handling"
      review-agent --files auth.py --system-prompt-file .review-rules.md
      review-agent --dry-run --branch main -v
""")


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="review-agent",
        description="Dual-agent code review — Claude Code x Codex CLI collaborate, "
        "cross-verify, and produce a unified review.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # ── Guide ────────────────────────────────────────────────────────
    p.add_argument(
        "--guide",
        action="store_true",
        help="Show the full usage guide with examples",
    )

    # ── What to review ───────────────────────────────────────────────
    src = p.add_mutually_exclusive_group()
    src.add_argument(
        "--diff",
        action="store_true",
        help="Review uncommitted changes (default)",
    )
    src.add_argument(
        "--branch",
        type=str,
        metavar="BASE",
        help="Review changes compared to BASE branch (e.g. main)",
    )
    src.add_argument(
        "--commit",
        type=str,
        metavar="REF",
        help="Review a specific commit or range (e.g. HEAD~3..HEAD)",
    )
    src.add_argument(
        "--last",
        type=int,
        metavar="N",
        help="Review the last N commits",
    )
    src.add_argument(
        "--files",
        nargs="+",
        metavar="PATH",
        help="Review specific files (full content)",
    )
    src.add_argument(
        "--dir",
        type=str,
        metavar="PATH",
        help="Review all tracked files under a directory",
    )
    src.add_argument(
        "--repo",
        action="store_true",
        help="Full repository review (provides file tree; agents explore via tools)",
    )

    # ── Review focus ─────────────────────────────────────────────────
    p.add_argument(
        "--focus",
        type=str,
        default="balanced",
        choices=[
            "high-level",
            "low-level",
            "security",
            "performance",
            "balanced",
        ],
        help="Review focus (default: balanced)",
    )

    # ── Custom system prompt ─────────────────────────────────────────
    sp = p.add_mutually_exclusive_group()
    sp.add_argument(
        "--system-prompt",
        type=str,
        default="",
        metavar="TEXT",
        help="Custom instructions injected into every agent prompt",
    )
    sp.add_argument(
        "--system-prompt-file",
        type=str,
        metavar="FILE",
        help="Read custom instructions from a file",
    )

    # ── Protocol tuning ──────────────────────────────────────────────
    p.add_argument(
        "--rounds",
        type=int,
        default=1,
        help="Cross-verification rounds (default: 1)",
    )

    # ── Agent commands ───────────────────────────────────────────────
    p.add_argument(
        "--claude-cmd",
        type=str,
        default="claude",
        help="Claude Code CLI executable (default: claude)",
    )
    p.add_argument(
        "--codex-cmd",
        type=str,
        default="codex",
        help="Codex CLI executable (default: codex)",
    )

    # ── Output ───────────────────────────────────────────────────────
    p.add_argument(
        "--output-dir",
        type=str,
        default="code-review",
        help="Directory for review output (default: code-review)",
    )

    # ── Misc ─────────────────────────────────────────────────────────
    p.add_argument(
        "-v", "--verbose", action="store_true", help="Show agent output previews"
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Simulate the full protocol with mock agents — "
        "prints every prompt and writes mock output files for inspection",
    )

    return p


def main(argv: list[str] | None = None) -> None:
    args = _build_parser().parse_args(argv)

    if args.guide:
        print(GUIDE)
        return

    # ── Resolve source ───────────────────────────────────────────────
    if args.files:
        source = {"type": "files", "paths": args.files}
    elif args.branch:
        source = {"type": "branch", "base": args.branch}
    elif args.commit:
        source = {"type": "commit", "ref": args.commit}
    elif args.last:
        source = {"type": "last", "n": args.last}
    elif args.dir:
        source = {"type": "dir", "path": args.dir}
    elif args.repo:
        source = {"type": "repo"}
    else:
        source = {"type": "diff"}

    # ── Resolve system prompt ────────────────────────────────────────
    system_prompt = args.system_prompt
    if args.system_prompt_file:
        try:
            with open(args.system_prompt_file, encoding="utf-8") as f:
                system_prompt = f.read()
        except FileNotFoundError:
            print(f"ERROR: system prompt file not found: {args.system_prompt_file}", file=sys.stderr)
            sys.exit(1)

    # Lazy import so --help stays fast
    from review_agent.orchestrator import ReviewOrchestrator

    orchestrator = ReviewOrchestrator(
        source=source,
        focus=args.focus,
        system_prompt=system_prompt,
        rounds=args.rounds,
        claude_cmd=args.claude_cmd,
        codex_cmd=args.codex_cmd,
        output_dir=args.output_dir,
        verbose=args.verbose,
        dry_run=args.dry_run,
    )

    try:
        asyncio.run(orchestrator.run())
    except KeyboardInterrupt:
        print("\nReview cancelled.")
        sys.exit(130)
