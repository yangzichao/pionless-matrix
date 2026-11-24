"""How to start each host headless and how to spot a skill load in its event stream."""

import json
import re

SUPPORTED_HOSTS = ("claude-code", "codex")
SKILL_PATH_PATTERN = re.compile(r"/skills/([a-z0-9-]+)/SKILL\.md")


def host_command(host, prompt):
    if host == "claude-code":
        return ["claude", "-p", prompt, "--output-format", "stream-json", "--verbose", "--max-turns", "3"]
    if host == "codex":
        return ["codex", "exec", "--json", "--skip-git-repo-check", prompt]
    raise ValueError(f"unknown host {host}")


def host_version_command(host):
    return ["claude", "--version"] if host == "claude-code" else ["codex", "--version"]


def skills_loaded_in_event(host, event):
    """Return the skill names this event shows the host loading.

    Claude Code loads a skill through its Skill tool, or by reading SKILL.md.
    Codex loads a skill by running a shell command that reads SKILL.md.
    Plugin-namespaced names such as "plugin:skill" are cut to "skill".
    """
    if host == "claude-code":
        if event.get("type") != "assistant":
            return []
        found = []
        for block in event.get("message", {}).get("content", []):
            if block.get("type") != "tool_use":
                continue
            tool_input = block.get("input", {})
            if block.get("name") == "Skill" and tool_input.get("skill"):
                found.append(tool_input["skill"].split(":")[-1])
            found += SKILL_PATH_PATTERN.findall(json.dumps(tool_input))
        return found
    item = event.get("item", {})
    if event.get("type") == "item.started" and item.get("type") == "command_execution":
        return SKILL_PATH_PATTERN.findall(item.get("command", ""))
    return []


def model_in_event(host, event):
    if host == "claude-code" and event.get("type") == "system" and event.get("subtype") == "init":
        return event.get("model")
    return None


def final_text_in_event(host, event):
    if host == "claude-code" and event.get("type") == "result":
        return event.get("result") or ""
    item = event.get("item", {})
    if host == "codex" and item.get("type") == "agent_message":
        return item.get("text", "")
    return None
