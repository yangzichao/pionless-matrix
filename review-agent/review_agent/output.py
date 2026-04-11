"""Write review results to disk.

Each run gets its own timestamped folder under output_dir:

    code-review/2026-04-11-152243/
        FINAL.md          <- consensus review (the one people read)
        claude.md         <- Claude's accumulated review
        codex.md          <- Codex's accumulated review
        debug/            <- (only with --dry-run or -v)
            claude-phase1-prompt.md
            claude-phase1.md
            ...
"""

from __future__ import annotations

import os
from datetime import datetime


class ReviewOutput:
    def __init__(self, output_dir: str, *, save_debug: bool = False) -> None:
        self.save_debug = save_debug
        self._output_dir = output_dir
        self._prefix = datetime.now().strftime("%Y-%m-%d-%H%M%S")
        # Lazy — directories created on first write
        self._run_dir: str | None = None
        self._debug_dir: str | None = None

    @property
    def run_dir(self) -> str:
        if self._run_dir is None:
            self._run_dir = os.path.join(self._output_dir, self._prefix)
            os.makedirs(self._run_dir, exist_ok=True)
        return self._run_dir

    @property
    def debug_dir(self) -> str:
        if self._debug_dir is None:
            self._debug_dir = os.path.join(self.run_dir, "debug")
            os.makedirs(self._debug_dir, exist_ok=True)
        return self._debug_dir

    # ── debug traces (prompts + per-phase responses) ─────────────────

    def write_prompt(self, agent: str, phase: str, prompt: str) -> str | None:
        if not self.save_debug:
            return None
        path = os.path.join(self.debug_dir, f"{agent}-{phase}-prompt.md")
        self._write(path, prompt)
        return path

    def write_response(self, agent: str, phase: str, response: str) -> str | None:
        if not self.save_debug:
            return None
        path = os.path.join(self.debug_dir, f"{agent}-{phase}.md")
        self._write(path, response)
        return path

    # ── final outputs (always written) ───────────────────────────────

    def write_final(
        self,
        unified: str,
        claude_review: str,
        codex_review: str,
    ) -> dict[str, str]:
        """Write the 3 final files. Returns {label: path}."""
        paths: dict[str, str] = {}
        for filename, content, label in [
            ("FINAL.md", unified, "FINAL"),
            ("claude.md", claude_review, "claude"),
            ("codex.md", codex_review, "codex"),
        ]:
            path = os.path.join(self.run_dir, filename)
            self._write(path, content)
            paths[label] = path
        return paths

    # ── helpers ───────────────────────────────────────────────────────

    @staticmethod
    def _write(path: str, content: str) -> None:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
