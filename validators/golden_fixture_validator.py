#!/usr/bin/env python3
"""
TacticalGo repo-specific validator: the language-neutral golden fixtures in tests/golden must stay well-formed and
must only name things the C# reference engine actually defines (illegal-reason names, event type names, action types).

Why this exists: the fixtures are the contract the future Swift port must pass. If a fixture names a reason or event
that the engine does not define (typo, rename, removed rule), the port would be checked against a nonsense expectation.

Scope and limits: this validates structure and vocabulary only. It does NOT replay the fixtures (the C# test
`GoldenReplayTests` does that) and says nothing about game balance, fun, or whether a player understands anything.
"""

from __future__ import annotations

import json
import re
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


ACTION_TYPES = {"PlaceSoldier", "SummonHero", "CastBastion", "CastSeal", "CastSwap", "CastMagicHand", "EndTurn"}
CONFIG_KEYS = {"boardSize", "apPerTurn", "firstTurnAp", "maxPlies", "manaCap", "allowResummon", "mageSkill", "magicHandRange"}
EXPECT_KEYS = {"ok", "reason", "cells", "current", "ply", "ap", "mana", "status", "winner", "seals", "events",
               "skillUsed", "liberties", "groups"}
TOP_KEYS = {"name", "description", "config", "setup", "steps", "expectInitial"}


def _enum_members(source: str, enum_name: str) -> set[str]:
    match = re.search(r"enum\s+" + enum_name + r"(?:\s*:\s*\w+)?\s*\{(.*?)\}", source, re.S)
    if not match:
        return set()
    return {m.split("=")[0].strip() for m in match.group(1).replace("\n", " ").split(",") if m.strip()}


def _event_names(source: str) -> set[str]:
    return set(re.findall(r"public sealed record (\w+)\(", source)) - {"ActionOutcome"}


class GoldenFixtureValidator(DomainValidator):
    @property
    def rule_ids(self) -> list[str]:
        return ["tacticalgo-golden", "TG-GOLDEN-001"]

    def validate(self, payload: dict) -> ValidatorResult:
        root = Path(payload.get("repo_root", ".")).resolve()
        golden = root / "tests" / "golden"
        actions_cs = root / "src" / "TacticalGo.Domain" / "Actions.cs"
        events_cs = root / "src" / "TacticalGo.Domain" / "ActionEvent.cs"
        primitives_cs = root / "src" / "TacticalGo.Domain" / "Primitives.cs"

        violations: list[str] = []
        files = sorted(golden.glob("*.json")) if golden.is_dir() else []
        if not files:
            return ValidatorResult(ok=False, rule_ids=self.rule_ids,
                                   violations=[f"no golden fixtures found under {golden}"])
        if not actions_cs.is_file() or not events_cs.is_file() or not primitives_cs.is_file():
            return ValidatorResult(ok=False, rule_ids=self.rule_ids,
                                   violations=["engine source files for the vocabulary check are missing"])

        reasons = _enum_members(actions_cs.read_text(encoding="utf-8-sig"), "IllegalReason") - {"None"}
        events = _event_names(events_cs.read_text(encoding="utf-8-sig"))
        primitives = primitives_cs.read_text(encoding="utf-8-sig")
        directions = _enum_members(primitives, "PushDirection")
        mage_skills = _enum_members(primitives, "MageSkill")
        if not reasons or not events:
            violations.append("could not read IllegalReason / event names from the C# engine source")

        for path in files:
            tag = path.name
            try:
                doc = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as exc:
                violations.append(f"{tag}: not valid JSON ({exc})")
                continue

            for key in ("name", "config", "setup", "steps"):
                if key not in doc:
                    violations.append(f"{tag}: missing top-level key '{key}'")
            for key in doc:
                if key not in TOP_KEYS:
                    violations.append(f"{tag}: unknown top-level key '{key}'")
            if doc.get("name") != path.stem:
                violations.append(f"{tag}: name '{doc.get('name')}' does not match the file name")
            for key in doc.get("config", {}):
                if key not in CONFIG_KEYS:
                    violations.append(f"{tag}: unknown config key '{key}'")
            if "mageSkill" in doc.get("config", {}) and doc["config"]["mageSkill"] not in mage_skills:
                violations.append(f"{tag}: mageSkill is not defined by the engine")

            def check_expect(where: str, expect: dict, allow_step_keys: bool) -> None:
                for key, value in expect.items():
                    if key not in EXPECT_KEYS:
                        violations.append(f"{tag} {where}: unknown expect key '{key}'")
                    if not allow_step_keys and key in {"ok", "reason", "events"}:
                        violations.append(f"{tag} {where}: '{key}' is only valid on steps")
                    if key == "reason" and reasons and value not in reasons:
                        violations.append(f"{tag} {where}: reason '{value}' is not an IllegalReason in the engine")
                    if key == "events":
                        for name in value:
                            if events and name not in events:
                                violations.append(f"{tag} {where}: event '{name}' is not defined by the engine")
                if expect.get("ok") is False and "reason" not in expect:
                    violations.append(f"{tag} {where}: ok=false without a reason")
                if expect.get("ok") is True and "reason" in expect:
                    violations.append(f"{tag} {where}: ok=true must not carry a reason")

            if "expectInitial" in doc:
                check_expect("expectInitial", doc["expectInitial"], allow_step_keys=False)
            if not doc.get("steps"):
                violations.append(f"{tag}: has no steps")
            for index, step in enumerate(doc.get("steps", []), start=1):
                action_type = step.get("action", {}).get("type")
                if action_type not in ACTION_TYPES:
                    violations.append(f"{tag} step {index}: unknown action type '{action_type}'")
                if action_type == "CastMagicHand":
                    action = step["action"]
                    if action.get("direction") not in directions:
                        violations.append(f"{tag} step {index}: Magic Hand direction is not defined by the engine")
                    target = action.get("target")
                    if (not isinstance(target, list) or len(target) != 2 or
                            any(type(v) is not int for v in target)):
                        violations.append(f"{tag} step {index}: Magic Hand target must be two integer coordinates")
                if "expect" not in step:
                    violations.append(f"{tag} step {index}: no expectation (a step must assert something)")
                else:
                    check_expect(f"step {index}", step["expect"], allow_step_keys=True)

        return ValidatorResult(
            ok=not violations,
            rule_ids=self.rule_ids,
            violations=violations,
            evidence_summary=(
                f"Checked {len(files)} golden fixtures against {len(reasons)} engine illegal reasons and "
                f"{len(events)} event types; structure and vocabulary only, no replay."
            ),
            metadata={"fixtures": len(files), "mode": "structure_and_vocabulary"},
        )


if __name__ == "__main__":
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    result = GoldenFixtureValidator().validate({"repo_root": repo})
    print(f"ok={result.ok}")
    print(result.evidence_summary)
    for v in result.violations:
        print(f"VIOLATION: {v}")
    sys.exit(0 if result.ok else 1)
