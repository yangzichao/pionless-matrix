#!/usr/bin/env python3

import json
import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_ROOT = REPO_ROOT / "skills"
PLUGIN_MANIFEST = REPO_ROOT / ".claude-plugin" / "plugin.json"

# Limits from the Agent Skills spec (agentskills.io).
MAX_NAME_LENGTH = 64
MAX_DESCRIPTION_LENGTH = 1024
SOFT_MAX_SKILL_MD_LINES = 300

NESTED_MAP_PLACEHOLDER = "<map>"

SKILL_NAME_PATTERN = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
INTERNAL_PATH_PATTERN = re.compile(
    r"(?<![\w/.-])((?:references|roles|assets|scripts)/[\w./-]*\w)"
)
MARKDOWN_LINK_PATTERN = re.compile(r"\]\(([^)\s]+)\)")

FORBIDDEN_PATTERNS = {
    r"subagent_type": "names a host-specific agent type",
    r"disallowedTools": "host-specific agent frontmatter",
    r"\bAgent\(": "host-specific spawn allowlist",
    r"\.claude/agents": "points at host-specific agent files",
    r"pionless-agent:": "old plugin namespace",
    r"deep-research-(worker|verifier|drafter|writer)\b": "old agent name; use roles/<role>.md",
    r"\bhoah-reviewer\b": "old agent name; use roles/reviewer.md",
    r"parallel-fix-worker\b": "old agent name; use roles/worker.md",
}
HOST_TOOL_PATTERNS = [
    r"\bAgent tool\b",
    r"\bTask tool\b",
    r"\bBash tool\b",
    r"\bAskUserQuestion\b",
    r"\bWebSearch\b",
    r"\bWebFetch\b",
    r"\bTodoWrite\b",
]


class Report:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, where, message):
        self.errors.append(f"ERROR   {where}: {message}")

    def warn(self, where, message):
        self.warnings.append(f"warning {where}: {message}")


def relative(path):
    return str(Path(path).relative_to(REPO_ROOT))


def parse_frontmatter(text):
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        return None
    fields = {}
    lines = match.group(1).splitlines()
    index = 0
    while index < len(lines):
        line = lines[index]
        key_match = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", line)
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
            fields[key] = joiner.join(part for part in block if part) if value else NESTED_MAP_PLACEHOLDER
            continue
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        fields[key] = value
    return fields


def is_template_placeholder_link(target):
    return "/" not in target and "." not in target


def find_skill_folders(report):
    skill_folders = []
    for skill_md in sorted(SKILLS_ROOT.rglob("SKILL.md")):
        depth = len(skill_md.relative_to(SKILLS_ROOT).parts)
        if depth != 3:
            report.error(relative(skill_md), "SKILL.md must sit at skills/<bucket>/<skill-name>/SKILL.md")
            continue
        skill_folders.append(skill_md.parent)
    return skill_folders


def check_frontmatter(skill_folder, report, seen_names):
    skill_md = skill_folder / "SKILL.md"
    where = relative(skill_md)
    text = skill_md.read_text(encoding="utf-8")
    fields = parse_frontmatter(text)
    if fields is None:
        report.error(where, "missing YAML frontmatter")
        return
    name = fields.get("name", "")
    description = fields.get("description", "")
    if not name:
        report.error(where, "frontmatter has no name")
    elif not SKILL_NAME_PATTERN.match(name) or len(name) > MAX_NAME_LENGTH:
        report.error(where, f"name '{name}' must be lowercase-hyphenated and at most {MAX_NAME_LENGTH} chars")
    elif name != skill_folder.name:
        report.error(where, f"name '{name}' does not match folder '{skill_folder.name}'")
    if name in seen_names:
        report.error(where, f"name '{name}' already used by {seen_names[name]}")
    seen_names[name] = where
    if not description:
        report.error(where, "frontmatter has no description")
    elif len(description) > MAX_DESCRIPTION_LENGTH:
        report.error(where, f"description is {len(description)} chars, limit is {MAX_DESCRIPTION_LENGTH}")
    line_count = text.count("\n")
    if line_count > SOFT_MAX_SKILL_MD_LINES:
        report.warn(where, f"{line_count} lines; move branch-only detail into references/")


def check_markdown_files(skill_folder, report):
    for markdown_file in sorted(skill_folder.rglob("*.md")):
        where = relative(markdown_file)
        text = markdown_file.read_text(encoding="utf-8")
        for pattern, reason in FORBIDDEN_PATTERNS.items():
            if re.search(pattern, text):
                report.error(where, f"contains '{pattern}' ({reason})")
        for pattern in HOST_TOOL_PATTERNS:
            if re.search(pattern, text):
                report.warn(where, f"mentions host tool '{pattern}'; prefer capability wording")
        for path_text in INTERNAL_PATH_PATTERN.findall(text):
            candidate = skill_folder / path_text.rstrip(".")
            if "*" in path_text or "<" in path_text:
                continue
            if not candidate.exists():
                report.error(where, f"points at '{path_text}', which does not exist in this skill")
        for link in MARKDOWN_LINK_PATTERN.findall(text):
            if re.match(r"^[a-z]+:", link) or link.startswith("#"):
                continue
            target = link.split("#", 1)[0]
            if is_template_placeholder_link(target):
                continue
            if target.startswith("/") or target.startswith("~"):
                report.error(where, f"absolute link '{link}'")
                continue
            resolved = (markdown_file.parent / target).resolve()
            if not str(resolved).startswith(str(skill_folder.resolve())):
                report.error(where, f"link '{link}' leaves the skill folder")
            elif not resolved.exists():
                report.error(where, f"broken link '{link}'")


def check_scripts(skill_folder, report):
    scripts_folder = skill_folder / "scripts"
    if not scripts_folder.is_dir():
        return
    for script in sorted(scripts_folder.iterdir()):
        if not script.is_file() or script.suffix not in (".sh", ".py", ".js", ".mjs"):
            continue
        where = relative(script)
        if not os.access(script, os.X_OK):
            report.error(where, "script is not executable (chmod +x)")
        if not script.read_text(encoding="utf-8").startswith("#!"):
            report.error(where, "script has no shebang line")


def check_bucket_readmes(skill_folders, report):
    for bucket in sorted({folder.parent for folder in skill_folders}):
        readme = bucket / "README.md"
        if not readme.exists():
            report.error(relative(bucket), "bucket has no README.md")
            continue
        readme_text = readme.read_text(encoding="utf-8")
        for folder in skill_folders:
            if folder.parent == bucket and f"{folder.name}/SKILL.md" not in readme_text:
                report.error(relative(readme), f"does not link {folder.name}/SKILL.md")


def check_plugin_manifest(skill_folders, report):
    if not PLUGIN_MANIFEST.exists():
        report.error(relative(PLUGIN_MANIFEST), "missing")
        return
    manifest = json.loads(PLUGIN_MANIFEST.read_text(encoding="utf-8"))
    listed = set(manifest.get("skills", []))
    expected = {"./" + relative(folder) for folder in skill_folders}
    for missing in sorted(expected - listed):
        report.error(relative(PLUGIN_MANIFEST), f"skills array is missing {missing}")
    for extra in sorted(listed - expected):
        report.error(relative(PLUGIN_MANIFEST), f"skills array lists {extra}, which is not a skill")


def check_top_readme(skill_folders, report):
    readme = REPO_ROOT / "README.md"
    text = readme.read_text(encoding="utf-8") if readme.exists() else ""
    for folder in skill_folders:
        if relative(folder) + "/SKILL.md" not in text:
            report.error("README.md", f"does not link {relative(folder)}/SKILL.md")


def main():
    report = Report()
    skill_folders = find_skill_folders(report)
    seen_names = {}
    for skill_folder in skill_folders:
        check_frontmatter(skill_folder, report, seen_names)
        check_markdown_files(skill_folder, report)
        check_scripts(skill_folder, report)
    check_bucket_readmes(skill_folders, report)
    check_plugin_manifest(skill_folders, report)
    check_top_readme(skill_folders, report)

    for line in report.warnings + report.errors:
        print(line)
    print(f"\n{len(skill_folders)} skills, {len(report.errors)} errors, {len(report.warnings)} warnings")
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
