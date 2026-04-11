"""Thin wrappers around Claude Code and Codex CLI invocations."""

from __future__ import annotations

import asyncio
import shutil
import tempfile
import os
from dataclasses import dataclass

# Default timeout for agent invocations (10 minutes).
AGENT_TIMEOUT_SECONDS = 600


@dataclass
class AgentResult:
    """Captured output from an agent invocation."""

    stdout: str
    stderr: str
    returncode: int

    @property
    def ok(self) -> bool:
        return self.returncode == 0


class BaseAgent:
    """Abstract base for CLI-backed agents."""

    name: str = "base"

    def __init__(self, cmd: str) -> None:
        self.cmd = cmd

    def check_available(self) -> None:
        if not shutil.which(self.cmd):
            raise FileNotFoundError(
                f"`{self.cmd}` not found in PATH. "
                f"Install it or pass --{self.name}-cmd to override."
            )

    async def invoke(self, prompt: str) -> AgentResult:
        raise NotImplementedError

    # ── helpers ───────────────────────────────────────────────────────

    @staticmethod
    async def _run(
        cmd: list[str],
        stdin_data: bytes | None = None,
        timeout: int = AGENT_TIMEOUT_SECONDS,
    ) -> AgentResult:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdin=asyncio.subprocess.PIPE if stdin_data else asyncio.subprocess.DEVNULL,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        try:
            stdout, stderr = await asyncio.wait_for(
                proc.communicate(input=stdin_data),
                timeout=timeout,
            )
        except asyncio.TimeoutError:
            proc.kill()
            await proc.wait()
            return AgentResult(
                stdout="",
                stderr=f"Agent timed out after {timeout}s",
                returncode=-1,
            )
        except (asyncio.CancelledError, KeyboardInterrupt):
            proc.kill()
            await proc.wait()
            raise
        return AgentResult(
            stdout=stdout.decode(errors="replace"),
            stderr=stderr.decode(errors="replace"),
            returncode=proc.returncode,
        )

    @staticmethod
    def _write_prompt_file(prompt: str) -> str:
        """Write prompt to a temp file and return the path."""
        fd, path = tempfile.mkstemp(suffix=".md", prefix="review-agent-")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(prompt)
        return path

    def _get_prompt_or_wrapper(self, prompt: str) -> tuple[str, str | None]:
        """Return (effective_prompt, temp_path_or_None).

        For prompts > 200 KB, writes to a temp file and returns a short
        wrapper instruction that tells the agent to read it.
        """
        if len(prompt.encode()) > 200_000:
            path = self._write_prompt_file(prompt)
            wrapper = (
                f"Read the file {path} — it contains your full instructions. "
                f"Follow every instruction in that file. "
                f"Do NOT modify any files in the repository."
            )
            return wrapper, path
        return prompt, None


class ClaudeAgent(BaseAgent):
    """Invokes Claude Code CLI: claude -p <prompt>"""

    name = "claude"

    async def invoke(self, prompt: str) -> AgentResult:
        effective, tmp = self._get_prompt_or_wrapper(prompt)
        try:
            return await self._run([self.cmd, "-p", effective])
        finally:
            if tmp:
                os.unlink(tmp)


class CodexAgent(BaseAgent):
    """Invokes Codex CLI: codex exec --full-auto -o <tmpfile> <prompt>

    Uses -o (--output-last-message) to capture the final agent response
    cleanly, avoiding any progress/status noise on stdout.
    """

    name = "codex"

    async def invoke(self, prompt: str) -> AgentResult:
        effective, prompt_tmp = self._get_prompt_or_wrapper(prompt)

        out_fd, out_path = tempfile.mkstemp(suffix=".md", prefix="review-agent-codex-out-")
        os.close(out_fd)

        try:
            result = await self._run([
                self.cmd, "exec", "--full-auto",
                "-o", out_path,
                effective,
            ])

            # Prefer the clean -o output over raw stdout
            try:
                with open(out_path, encoding="utf-8") as f:
                    clean = f.read()
                if clean.strip():
                    return AgentResult(
                        stdout=clean,
                        stderr=result.stderr,
                        returncode=result.returncode,
                    )
            except FileNotFoundError:
                pass

            return result
        finally:
            if prompt_tmp:
                os.unlink(prompt_tmp)
            try:
                os.unlink(out_path)
            except FileNotFoundError:
                pass


class MockAgent(BaseAgent):
    """Returns canned responses for --dry-run testing."""

    def __init__(self, name: str) -> None:
        super().__init__(cmd="(mock)")
        self.name = name

    def check_available(self) -> None:
        pass

    async def invoke(self, prompt: str) -> AgentResult:
        await asyncio.sleep(0.1)

        lines = prompt.count("\n")
        return AgentResult(
            stdout=(
                f"# Mock {self.name} Review\n\n"
                f"*(dry-run — this is a mock response, not a real review)*\n\n"
                f"## Summary\n"
                f"Received prompt with {len(prompt):,} chars, ~{lines:,} lines.\n\n"
                f"## Findings\n\n"
                f"### [MEDIUM] Example finding from {self.name}\n"
                f"- **Location**: `example.py:42`\n"
                f"- **Problem**: Placeholder finding for protocol testing\n"
                f"- **Suggestion**: Replace with real agent invocation\n\n"
                f"## Positive Aspects\n"
                f"The code was submitted for dual-agent review, which is commendable.\n"
            ),
            stderr="",
            returncode=0,
        )
