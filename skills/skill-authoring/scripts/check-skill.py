#!/usr/bin/env python3
"""Check one or more Agent Skills folders. Usage: check-skill.py <skill-folder> [...]"""

import os
import re
import sys
from pathlib import Path

# Limits from the Agent Skills spec (agentskills.io).
MAX_NAME_LENGTH = 64
MAX_DESCRIPTION_LENGTH = 1024
# Soft cap: past this, SKILL.md usually holds detail that only one step needs.
SOFT_MAX_SKILL_MD_LINES = 300

SUPPORT_FOLDERS = ("references", "roles", "scripts", "assets")
SKILL_NAME_PATTERN = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
INTERNAL_PATH_PATTERN = re.compile(r"(?<![\w/.-])((?:references|roles|scripts|assets)/[\w./-]*\w)")
# A path like references/report-styles/<style>.md names every file under references/report-styles/.
PLACEHOLDER_PATH_PATTERN = re.compile(r"(?<![\w/.-])((?:references|roles|scripts|assets)/[\w./-]*)<")
MARKDOWN_LINK_PATTERN =re.compile(r"\]\(([^)\s]+)\)")
SCRIPT_SUFFIXES = (".sh", ".py", ".js", ".mjs")

HOST_SPECIFIC_PATTERNS = {
    r"subagent_type": "host-specific agent type",
    r"\.claude/agents|\.cursor/|\.codex/": "host-only config path",
    r"\b(Agent|Task|Bash) tool\b": "host tool name",
    r"\b(AskUserQuestion|WebSearch|WebFetch|TodoWrite|spawn_agent)\b": "host tool name",
    r"\bclaude-(opus|sonnet|haiku|fable)-\d|\bgpt-\d|\bgemini-\d": "model name",
}


class Report:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, where, message):
        self.errors.append(f"ERROR   {where}: {message}")

    def warn(self, where, message):
        self.warnings.append(f"warning {where}: {message}")


def parse_frontmatter(text):
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        return None
    fields = {}
    lines = match.group(1).splitlines()
    index = 0
    while index < len(lines):
        key_match = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", lines[index])
        index += 1
        if not key_match:
            continue
        key, value = key_match.group(1), key_match.group(2).strip()
        if value in ("|", ">", "|-", ">-", ""):
            block = []
            while index < len(lines) and (lines[index].startswith(" ") or not lines[index].strip()):
                block.append(lines[index].strip())
                index += 1
            joiner = "\n" if value.startswith("|") else " "
            fields[key] = joiner.join(part for part in block if part)
            continue
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        fields[key] = value
    return fields


def check_frontmatter(skill_folder, skill_text, report):
    where = "SKILL.md"
    fields = parse_frontmatter(skill_text)
    if fields is None:
        report.error(where, "missing YAML frontmatter")
        return
    name = fields.get("name", "")
    description = fields.get("description", "")
    if not name:
        report.error(where, "frontmatter has no name")
    elif not SKILL_NAME_PATTERN.match(name) or len(name) > MAX_NAME_LENGTH:
        report.error(where, f"name '{name}' must be lowercase-hyphenated, at most {MAX_NAME_LENGTH} chars")
    elif name != skill_folder.name:
        report.error(where, f"name '{name}' does not match folder '{skill_folder.name}'")
    if not description:
        report.error(where, "frontmatter has no description")
    elif len(description) > MAX_DESCRIPTION_LENGTH:
        report.error(where, f"description is {len(description)} chars, limit is {MAX_DESCRIPTION_LENGTH}")
    line_count = skill_text.count("\n")
    if line_count > SOFT_MAX_SKILL_MD_LINES:
        report.warn(where, f"{line_count} lines; move detail one step needs into references/")


def check_markdown_file(skill_folder, markdown_file, report):
    where = str(markdown_file.relative_to(skill_folder))
    text = markdown_file.read_text(encoding="utf-8")
    is_reference = markdown_file.parent.name == "references"
    for pattern, reason in HOST_SPECIFIC_PATTERNS.items():
        if re.search(pattern, text):
            report.warn(where, f"matches '{pattern}' ({reason}); prefer capability wording")
    for path_text in INTERNAL_PATH_PATTERN.findall(text):
        if "*" in path_text or "<" in path_text:
            continue
        if not (skill_folder / path_text.rstrip(".")).exists():
            report.error(where, f"points at '{path_text}', which does not exist in this skill")
        elif is_reference and path_text.startswith("references/"):
            report.warn(where, f"points at '{path_text}'; references should not chain to other references")
    for link in MARKDOWN_LINK_PATTERN.findall(text):
        if re.match(r"^[a-z]+:", link) or link.startswith("#"):
            continue
        target = link.split("#", 1)[0]
        if "/" not in target and "." not in target:
            continue
        if target.startswith(("/", "~")):
            report.error(where, f"absolute link '{link}'")
            continue
        resolved = (markdown_file.parent / target).resolve()
        if not str(resolved).startswith(str(skill_folder.resolve())):
            report.error(where, f"link '{link}' leaves the skill folder")
        elif not resolved.exists():
            report.error(where, f"broken link '{link}'")


def check_support_files_are_named(skill_folder, skill_text, report):
    placeholder_prefixes = PLACEHOLDER_PATH_PATTERN.findall(skill_text)
    for folder_name in SUPPORT_FOLDERS:
        folder = skill_folder / folder_name
        if not folder.is_dir():
            continue
        for support_file in sorted(path for path in folder.rglob("*") if path.is_file()):
            relative_path = str(support_file.relative_to(skill_folder))
            if folder_name == "assets" and "assets/" in skill_text:
                continue
            if any(relative_path.startswith(prefix) for prefix in placeholder_prefixes):
                continue
            if relative_path not in skill_text:
                report.warn("SKILL.md", f"never names '{relative_path}'; the host will not know to open it")


def check_scripts(skill_folder, report):
    scripts_folder = skill_folder / "scripts"
    if not scripts_folder.is_dir():
        return
    for script in sorted(scripts_folder.rglob("*")):
        if not script.is_file() or script.suffix not in SCRIPT_SUFFIXES:
            continue
        where = str(script.relative_to(skill_folder))
        if not os.access(script, os.X_OK):
            report.error(where, "not executable (chmod +x)")
        if not script.read_text(encoding="utf-8").startswith("#!"):
            report.error(where, "no shebang line")


def check_skill(skill_folder):
    report = Report()
    skill_md = skill_folder / "SKILL.md"
    if not skill_md.is_file():
        report.error(str(skill_folder), "no SKILL.md")
        return report
    skill_text = skill_md.read_text(encoding="utf-8")
    check_frontmatter(skill_folder, skill_text, report)
    for markdown_file in sorted(skill_folder.rglob("*.md")):
        check_markdown_file(skill_folder, markdown_file, report)
    if len(list(skill_folder.rglob("SKILL.md"))) > 1:
        report.error(str(skill_folder), "more than one SKILL.md")
    check_support_files_are_named(skill_folder, skill_text, report)
    check_scripts(skill_folder, report)
    return report


def main(arguments):
    if not arguments:
        print("usage: check-skill.py <skill-folder> [<skill-folder> ...]", file=sys.stderr)
        return 2
    total_errors = 0
    for argument in arguments:
        skill_folder = Path(argument).expanduser().resolve()
        if not skill_folder.is_dir():
            print(f"ERROR   {argument}: not a folder")
            total_errors += 1
            continue
        report = check_skill(skill_folder)
        for line in report.warnings + report.errors:
            print(f"{skill_folder.name}: {line}")
        print(f"{skill_folder.name}: {len(report.errors)} errors, {len(report.warnings)} warnings")
        total_errors += len(report.errors)
    return 1 if total_errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
