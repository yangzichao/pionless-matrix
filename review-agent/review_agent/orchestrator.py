"""Multi-round dual-agent review orchestrator.

Protocol
--------
Phase 1 — Independent review (parallel)
Phase 2 — Cross-verification (parallel, repeated `rounds` times)
Phase 3 — Consensus synthesis

Source types
------------
    --diff          uncommitted changes (staged + unstaged)
    --branch BASE   changes vs a base branch
    --commit REF    a specific commit or range
    --last N        the last N commits (diff + log)
    --files P ...   full content of specific files
    --dir PATH      all git-tracked files under a directory
    --repo          full repository tree (agents explore via tools)
"""

from __future__ import annotations

import asyncio
import os
import subprocess
import sys
from typing import Any

from review_agent.agents import BaseAgent, ClaudeAgent, CodexAgent, MockAgent, AgentResult
from review_agent import prompts
from review_agent.output import ReviewOutput

_MAX_FILE_BYTES = 1_048_576  # 1 MB — skip files larger than this


class GitError(RuntimeError):
    """A git command exited non-zero."""


class ReviewOrchestrator:
    def __init__(
        self,
        *,
        source: dict[str, Any],
        focus: str,
        system_prompt: str,
        rounds: int,
        claude_cmd: str,
        codex_cmd: str,
        output_dir: str,
        verbose: bool,
        dry_run: bool = False,
    ) -> None:
        self.source = source
        self.focus = focus
        self.system_prompt = system_prompt
        self.rounds = rounds
        self.verbose = verbose
        self.dry_run = dry_run

        if dry_run:
            self.claude: BaseAgent = MockAgent("Claude")
            self.codex: BaseAgent = MockAgent("Codex")
        else:
            self.claude = ClaudeAgent(claude_cmd)
            self.codex = CodexAgent(codex_cmd)

        self.output = ReviewOutput(output_dir, save_debug=dry_run or verbose)

    # ── public entry point ───────────────────────────────────────────

    async def run(self) -> None:
        if not self.dry_run:
            self._check_agents()

        try:
            code = self._get_code()
        except GitError as e:
            print(f"ERROR: {e}", file=sys.stderr)
            sys.exit(1)

        if not code.strip():
            print("Nothing to review — no changes detected.")
            return

        self._banner(code)

        # Phase 1 — independent reviews (parallel)
        self._phase_header(1, "Independent reviews")
        review_prompt = prompts.initial_review(code, self.focus, self.system_prompt)

        claude_text, codex_text = await asyncio.gather(
            self._invoke("claude", "phase1", self.claude, review_prompt),
            self._invoke("codex", "phase1", self.codex, review_prompt),
        )

        # Phase 2 — cross-verification rounds (parallel per round)
        for r in range(1, self.rounds + 1):
            self._phase_header(2, f"Cross-verification (round {r}/{self.rounds})")

            claude_verify_prompt = prompts.cross_verify(code, codex_text, "Codex")
            codex_verify_prompt = prompts.cross_verify(code, claude_text, "Claude")

            claude_ver, codex_ver = await asyncio.gather(
                self._invoke("claude", f"verify-r{r}", self.claude, claude_verify_prompt),
                self._invoke("codex", f"verify-r{r}", self.codex, codex_verify_prompt),
            )

            claude_text += f"\n\n---\n## Verification Round {r}\n{claude_ver}"
            codex_text += f"\n\n---\n## Verification Round {r}\n{codex_ver}"

        # Phase 3 — consensus synthesis
        self._phase_header(3, "Consensus synthesis")
        consensus_prompt = prompts.consensus(code, claude_text, codex_text)
        unified = await self._invoke("synthesiser", "consensus", self.claude, consensus_prompt)

        paths = self.output.write_final(unified, claude_text, codex_text)
        self._summary(paths)

    # ── agent invocation with logging ────────────────────────────────

    async def _invoke(
        self, agent_tag: str, phase: str, agent: BaseAgent, prompt: str
    ) -> str:
        label = f"{agent_tag} ({phase})"

        prompt_path = self.output.write_prompt(agent_tag, phase, prompt)

        print(f"  -> {label}: working ...", flush=True)
        result: AgentResult = await agent.invoke(prompt)

        if not result.ok:
            print(f"  !! {label}: FAILED (exit {result.returncode})", file=sys.stderr)
            if result.stderr:
                print(f"     stderr: {result.stderr[:500]}", file=sys.stderr)
            text = result.stdout or f"[{label} failed with exit code {result.returncode}]"
        else:
            text = result.stdout
            print(f"  ok {label}: done ({len(text):,} chars)")

        resp_path = self.output.write_response(agent_tag, phase, text)

        if prompt_path or resp_path:
            print(f"     debug -> {resp_path}")
        if self.verbose and text:
            print(f"     preview: {text[:300]}...\n")

        return text

    # ── code collection ──────────────────────────────────────────────

    def _get_code(self) -> str:
        t = self.source["type"]

        if t == "diff":
            unstaged = self._git("diff")
            staged = self._git("diff", "--cached")
            return (unstaged + "\n" + staged).strip()

        if t == "branch":
            return self._git("diff", f"{self.source['base']}...HEAD")

        if t == "commit":
            ref = self.source["ref"]
            # Single commit → show that commit's patch.
            # Range (contains "..") → diff as given.
            if ".." in ref:
                return self._git("diff", ref)
            return self._git("show", "--format=", ref)

        if t == "last":
            n = self.source["n"]
            log = self._git("log", f"-{n}", "--stat", "--format=medium")
            diff = self._git("diff", f"HEAD~{n}..HEAD")
            return f"## Recent {n} commit(s)\n\n```\n{log}```\n\n## Diff\n\n```\n{diff}```"

        if t == "files":
            return self._read_files(self.source["paths"])

        if t == "dir":
            dir_path = self.source["path"]
            tracked = self._git("ls-files", "--", dir_path).strip().splitlines()
            if not tracked:
                return ""
            return self._read_files(tracked)

        if t == "repo":
            tree = self._git("ls-files")
            stats = self._git("log", "--oneline", "-10")
            return (
                f"## Repository file tree\n\n```\n{tree}```\n\n"
                f"## Recent commits\n\n```\n{stats}```\n\n"
                f"**You have full tool access.** Read any file you need to review. "
                f"Explore the codebase systematically — start with entry points, "
                f"configuration, and high-traffic modules."
            )

        return ""

    @staticmethod
    def _read_files(paths: list[str]) -> str:
        parts: list[str] = []
        for p in paths:
            try:
                size = os.path.getsize(p)
                if size > _MAX_FILE_BYTES:
                    parts.append(f"### {p}\n[Skipped — {size:,} bytes, exceeds 1 MB limit]")
                    continue
                with open(p, encoding="utf-8", errors="replace") as f:
                    parts.append(f"### {p}\n```\n{f.read()}\n```")
            except FileNotFoundError:
                parts.append(f"### {p}\n[File not found]")
            except OSError as e:
                parts.append(f"### {p}\n[Error reading file: {e}]")
        return "\n\n".join(parts)

    @staticmethod
    def _git(*args: str) -> str:
        r = subprocess.run(
            ["git", *args], capture_output=True, text=True, timeout=30
        )
        if r.returncode != 0:
            raise GitError(f"git {' '.join(args)}: {r.stderr.strip()}")
        return r.stdout

    # ── availability check ───────────────────────────────────────────

    def _check_agents(self) -> None:
        errors: list[str] = []
        for agent in (self.claude, self.codex):
            try:
                agent.check_available()
            except FileNotFoundError as e:
                errors.append(str(e))
        if errors:
            for e in errors:
                print(f"ERROR: {e}", file=sys.stderr)
            sys.exit(1)

    # ── pretty output ────────────────────────────────────────────────

    def _banner(self, code: str) -> None:
        lines = code.count("\n")
        mode = "DRY-RUN (mock agents)" if self.dry_run else "LIVE"
        src = self.source["type"]
        print(
            f"\n{'=' * 60}\n"
            f"  review-agent v0.1  |  {mode}\n"
            f"  source: {src}  |  focus: {self.focus}  |  rounds: {self.rounds}\n"
            f"  code: {len(code):,} chars, ~{lines:,} lines\n"
            f"{'=' * 60}"
        )
        if self.system_prompt:
            print(f"  system prompt: {self.system_prompt[:80]}...")

    @staticmethod
    def _phase_header(n: int, title: str) -> None:
        print(f"\n[Phase {n}] {title}")

    @staticmethod
    def _summary(paths: dict[str, str]) -> None:
        print(f"\n{'=' * 60}")
        print("  Review complete! Output files:")
        for label, path in paths.items():
            print(f"    {label:>10}: {path}")
        print(f"{'=' * 60}\n")
