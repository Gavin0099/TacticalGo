#!/usr/bin/env python3
"""
TacticalGo repo-specific validator: the language-neutral golden fixtures in tests/golden must stay well-formed and
must only name things the C# reference engine actually defines (illegal-reason names, event type names, action types).

Why this exists: the fixtures are the contract the future Swift port must pass. If a fixture names a reason or event
that the engine does not define (typo, rename, removed rule), the port would be checked against a nonsense expectation.

Scope and limits: this validates structure, vocabulary, the setup shape and the required argument shape of every action.
KNOWN LIMITS (reported by review, deliberately not closed here): it does not check the JSON *value* types of `config`
entries (e.g. a string boardSize) or of `expect` entries (e.g. {"ok": "true"}, {"cells": []}); GoldenReplayTests
(ParseConfig / Check) reads those with GetInt32/GetBoolean/EnumerateObject and is the authority. An `ok=True` here
therefore means "well-formed enough to attempt a replay", never "replayable"; the C# replay and the Swift parity
tests decide that. It does NOT replay the fixtures (the C# test
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


# Required argument names per action type. Source of truth: GoldenReplayTests.ParseAction in the C# test project
# (tests/TacticalGo.Domain.Tests/GoldenReplayTests.cs), which reads exactly these properties. Point arguments are
# JSON arrays of two integers ([x, y]). Board bounds are NOT checked here: out-of-board coordinates are legitimate
# illegal-move fixtures that the engine, not this validator, must reject.
ACTION_FIELDS = {
    "PlaceSoldier": ("at",),
    "SummonHero": ("at",),
    "CastBastion": ("first", "second"),
    "CastSeal": ("at",),
    "CastSwap": ("target",),
    "EndTurn": (),
}
ACTION_TYPES = set(ACTION_FIELDS)
CONFIG_KEYS = {"boardSize", "apPerTurn", "firstTurnAp", "maxPlies", "manaCap", "allowResummon"}
EXPECT_KEYS = {"ok", "reason", "cells", "current", "ply", "ap", "mana", "status", "winner", "seals", "events"}
TOP_KEYS = {"name", "description", "config", "setup", "steps", "expectInitial"}


def _is_point(value: object) -> bool:
    """True for a JSON array of exactly two integers (bool is not an integer here)."""
    return (
        isinstance(value, list)
        and len(value) == 2
        and all(isinstance(v, int) and not isinstance(v, bool) for v in value)
    )


def _enum_members(source: str, enum_name: str) -> set[str]:
    match = re.search(r"enum\s+" + enum_name + r"\b[^{]*\{(.*?)\}", source, re.S)
    if not match:
        return set()
    members = (m.split("=")[0].strip() for m in match.group(1).replace("\n", " ").split(","))
    return {m for m in members if m}


def _event_names(source: str) -> set[str]:
    return set(re.findall(r"public sealed record (\w+)\(", source)) - {"ActionOutcome"}


SETUP_KEYS = {"classes", "newGame", "diagram", "mana", "heroSummoned", "current", "ap"}


def _is_int(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def check_setup(tag: str, setup: object, hero_classes: set[str], players: set[str]) -> list[str]:
    """Mode-specific required fields of `setup`, as read by GoldenReplayTests.BuildInitialState.

    Two modes: `newGame: true` needs only `classes`; otherwise `diagram`, `mana`, `heroSummoned`, `current` and `ap`
    are all read unconditionally. Enum names come from the engine source so a rename is caught here.
    """
    if not isinstance(setup, dict):
        return [f"{tag}: setup must be an object"]
    out: list[str] = []
    for key in setup:
        if key not in SETUP_KEYS:
            out.append(f"{tag} setup: unknown key '{key}'")
    classes = setup.get("classes")
    if not isinstance(classes, list) or len(classes) != 2 or not all(isinstance(c, str) for c in classes):
        out.append(f"{tag} setup: 'classes' must be a list of exactly two class names")
    elif hero_classes:
        for name in classes:
            if name not in hero_classes:
                out.append(f"{tag} setup: class '{name}' is not a HeroClass in the engine")
    if "newGame" in setup and not isinstance(setup["newGame"], bool):
        out.append(f"{tag} setup: 'newGame' must be a boolean")
    if setup.get("newGame") is True:
        return out
    diagram = setup.get("diagram")
    if not isinstance(diagram, list) or not diagram or not all(isinstance(r, str) for r in diagram):
        out.append(f"{tag} setup: 'diagram' must be a non-empty list of row strings (or set newGame: true)")
    mana = setup.get("mana")
    if not isinstance(mana, list) or len(mana) != 2 or not all(_is_int(m) for m in mana):
        out.append(f"{tag} setup: 'mana' must be two integers")
    summoned = setup.get("heroSummoned")
    if not isinstance(summoned, list) or len(summoned) != 2 or not all(isinstance(b, bool) for b in summoned):
        out.append(f"{tag} setup: 'heroSummoned' must be two booleans")
    current = setup.get("current")
    if not isinstance(current, str) or (players and current not in players):
        out.append(f"{tag} setup: 'current' must be a Player name from the engine ({', '.join(sorted(players)) or '?'})")
    if not _is_int(setup.get("ap")):
        out.append(f"{tag} setup: 'ap' must be an integer")
    return out


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
        hero_classes = _enum_members(primitives, "HeroClass")
        players = _enum_members(primitives, "Player")
        if not hero_classes or not players:
            violations.append("could not read HeroClass / Player from the C# engine source")
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
            if "setup" in doc:
                violations.extend(check_setup(tag, doc["setup"], hero_classes, players))
            for key in doc:
                if key not in TOP_KEYS:
                    violations.append(f"{tag}: unknown top-level key '{key}'")
            if doc.get("name") != path.stem:
                violations.append(f"{tag}: name '{doc.get('name')}' does not match the file name")
            for key in doc.get("config", {}):
                if key not in CONFIG_KEYS:
                    violations.append(f"{tag}: unknown config key '{key}'")

            def check_expect(where: str, expect: object, allow_step_keys: bool) -> None:
                if not isinstance(expect, dict):
                    violations.append(f"{tag} {where}: expectation must be an object")
                    return
                if not expect:
                    violations.append(f"{tag} {where}: expectation is empty (it asserts nothing)")
                    return
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
                if not isinstance(step, dict):
                    violations.append(f"{tag} step {index}: step is not an object")
                    continue
                action = step.get("action")
                if not isinstance(action, dict):
                    violations.append(f"{tag} step {index}: 'action' is missing or not an object")
                    action = {}
                action_type = action.get("type")
                if action_type not in ACTION_TYPES:
                    violations.append(f"{tag} step {index}: unknown action type '{action_type}'")
                else:
                    required = ACTION_FIELDS[action_type]
                    for field_name in required:
                        if field_name not in action:
                            violations.append(
                                f"{tag} step {index}: {action_type} is missing required field '{field_name}'"
                            )
                        elif not _is_point(action[field_name]):
                            violations.append(
                                f"{tag} step {index}: {action_type}.{field_name} must be [x, y] integers, "
                                f"got {action[field_name]!r}"
                            )
                    for field_name in action:
                        if field_name != "type" and field_name not in required:
                            violations.append(
                                f"{tag} step {index}: {action_type} has unexpected field '{field_name}'"
                            )
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
                f"{len(events)} event types; structure, vocabulary, setup and action arguments only, no replay."
            ),
            metadata={"fixtures": len(files), "mode": "structure_vocabulary_and_action_arguments"},
        )


if __name__ == "__main__":
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    result = GoldenFixtureValidator().validate({"repo_root": repo})
    print(f"ok={result.ok}")
    print(result.evidence_summary)
    for v in result.violations:
        print(f"VIOLATION: {v}")
    sys.exit(0 if result.ok else 1)
