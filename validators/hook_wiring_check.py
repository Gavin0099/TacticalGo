#!/usr/bin/env python3
"""
TacticalGo repo-specific validator: managed hook configs must not wire the VS Code `Stop` event to a session closeout.

Why this exists: VS Code documents `Stop` as "the current agent execution is about to stop" and defines no
session-end event (https://code.visualstudio.com/docs/agents/reference/hooks-reference). The framework template
maps it to `session_end`, which would close a session out after every agent response (Codex review of PR #7, P1).
The framework's own installers and F-7 apply can re-create that file (`install_governance_hooks` defaults to
include_copilot=True), so the guard has to live in this repository's checks, not in someone's memory.

Scope and limits: only JSON files under `.github/hooks/` are inspected, and only the VS Code `Stop` event name.
It does not claim anything about other agents' hook semantics, and it does not prove that hooks run anywhere.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

try:  # inside the governance framework
    from governance_tools.validator_interface import DomainValidator, ValidatorResult
except ImportError:  # standalone run: minimal stand-ins with the same shape
    from abc import ABC, abstractmethod
    from dataclasses import dataclass, field

    @dataclass
    class ValidatorResult:  # type: ignore[no-redef]
        ok: bool
        rule_ids: list
        violations: list = field(default_factory=list)
        warnings: list = field(default_factory=list)
        evidence_summary: str = ""
        metadata: dict = field(default_factory=dict)

    class DomainValidator(ABC):  # type: ignore[no-redef]
        @property
        @abstractmethod
        def rule_ids(self): ...

        @abstractmethod
        def validate(self, payload): ...


CLOSEOUT_MARKERS = ("session_end", "session-end", "sessionend")


def _commands(entry: object) -> list[str]:
    """Collect every command string under one hook event, whatever the nesting."""
    found: list[str] = []
    if isinstance(entry, dict):
        for key, value in entry.items():
            if key in {"command", "bash", "powershell", "windows", "linux", "osx"} and isinstance(value, str):
                found.append(value)
            else:
                found.extend(_commands(value))
    elif isinstance(entry, list):
        for item in entry:
            found.extend(_commands(item))
    return found


def check_hook_config(name: str, document: object) -> list[str]:
    violations: list[str] = []
    hooks = document.get("hooks") if isinstance(document, dict) else None
    if not isinstance(hooks, dict):
        return violations
    for event, entry in hooks.items():
        if str(event).lower() != "stop":
            continue
        for command in _commands(entry):
            if any(marker in command.lower().replace(" ", "") for marker in CLOSEOUT_MARKERS):
                violations.append(
                    f"{name}: VS Code '{event}' is wired to a session closeout ({command!r}); "
                    "Stop is the end of one agent run, not of a session"
                )
    return violations


class HookWiringValidator(DomainValidator):
    @property
    def rule_ids(self) -> list[str]:
        return ["tacticalgo-hook-wiring", "TG-HOOK-001"]

    def validate(self, payload: dict) -> ValidatorResult:
        root = Path(payload.get("repo_root", ".")).resolve()
        hooks_dir = root / ".github" / "hooks"
        violations: list[str] = []
        files = sorted(hooks_dir.glob("*.json")) if hooks_dir.is_dir() else []
        for path in files:
            try:
                document = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as exc:
                violations.append(f"{path.name}: not valid JSON ({exc})")
                continue
            violations.extend(check_hook_config(path.name, document))
        return ValidatorResult(
            ok=not violations,
            rule_ids=self.rule_ids,
            violations=violations,
            evidence_summary=f"Checked {len(files)} hook config file(s) under .github/hooks for VS Code Stop -> closeout wiring.",
            metadata={"files": len(files), "mode": "vscode_stop_to_session_end"},
        )


if __name__ == "__main__":
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    result = HookWiringValidator().validate({"repo_root": repo})
    print(f"ok={result.ok}")
    print(result.evidence_summary)
    for v in result.violations:
        print(f"VIOLATION: {v}")
    sys.exit(0 if result.ok else 1)
