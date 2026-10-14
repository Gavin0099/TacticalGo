"""Negative and positive tests for validators/golden_fixture_validator.py.

Run: python -m unittest discover -s validators -p "test_*.py"

The expected required fields come from the C# replay parser (GoldenReplayTests.ParseAction), not from the validator,
so these tests fail if the validator and the parser drift apart. They use a throwaway repo layout, plus one test
that the real repository fixtures still pass.
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from golden_fixture_validator import GoldenFixtureValidator  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[1]

ACTIONS_CS = "public enum IllegalReason { None, OutOfBounds, Occupied }\n"
EVENTS_CS = "public sealed record PiecePlaced(int X, int Y);\npublic sealed record ActionOutcome(bool Ok);\n"


def _fixture(name: str, action: object, expect: dict | None = None) -> dict:
    return {
        "name": name,
        "config": {"boardSize": 7},
        "setup": {"newGame": True, "classes": ["Warrior", "Mage"]},
        "steps": [{"action": action, "expect": expect if expect is not None else {"ok": True}}],
    }


class ActionArgumentTests(unittest.TestCase):
    def _run(self, action: object):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "src" / "TacticalGo.Domain").mkdir(parents=True)
            (root / "src" / "TacticalGo.Domain" / "Actions.cs").write_text(ACTIONS_CS, encoding="utf-8")
            (root / "src" / "TacticalGo.Domain" / "ActionEvent.cs").write_text(EVENTS_CS, encoding="utf-8")
            (root / "tests" / "golden").mkdir(parents=True)
            doc = _fixture("sample", action)
            (root / "tests" / "golden" / "sample.json").write_text(json.dumps(doc), encoding="utf-8")
            return GoldenFixtureValidator().validate({"repo_root": str(root)})

    def assertRejected(self, action: object, fragment: str):
        result = self._run(action)
        self.assertFalse(result.ok, f"expected rejection of {action!r}")
        self.assertTrue(
            any(fragment in v for v in result.violations),
            f"no violation containing {fragment!r}: {result.violations}",
        )

    # valid actions, one per type
    def test_valid_actions_pass(self):
        valid = [
            {"type": "PlaceSoldier", "at": [0, 0]},
            {"type": "SummonHero", "at": [4, 6]},
            {"type": "CastBastion", "first": [1, 0], "second": [0, 1]},
            {"type": "CastSeal", "at": [4, 2]},
            {"type": "CastSwap", "target": [1, 0]},
            {"type": "EndTurn"},
            # out-of-board coordinates are legitimate illegal-move fixtures; shape only is checked here
            {"type": "PlaceSoldier", "at": [-1, 99]},
        ]
        for action in valid:
            with self.subTest(action=action):
                result = self._run(action)
                self.assertTrue(result.ok, result.violations)

    # the review's counter-example
    def test_missing_at_is_rejected(self):
        self.assertRejected({"type": "PlaceSoldier"}, "missing required field 'at'")

    def test_each_type_requires_its_own_fields(self):
        self.assertRejected({"type": "SummonHero"}, "missing required field 'at'")
        self.assertRejected({"type": "CastSeal"}, "missing required field 'at'")
        self.assertRejected({"type": "CastSwap"}, "missing required field 'target'")
        self.assertRejected({"type": "CastBastion", "first": [1, 0]}, "missing required field 'second'")
        self.assertRejected({"type": "CastBastion", "second": [0, 1]}, "missing required field 'first'")

    def test_wrong_value_shapes_are_rejected(self):
        for bad in ("1,2", [1], [1, 2, 3], [1, "2"], [1.5, 2], [True, False], {"x": 1, "y": 2}, None):
            with self.subTest(at=bad):
                self.assertRejected({"type": "PlaceSoldier", "at": bad}, "must be [x, y] integers")

    def test_wrong_field_name_is_rejected(self):
        # CastSwap reads "target"; "at" is a typo-class mistake that the C# parser would throw on
        result = self._run({"type": "CastSwap", "at": [1, 0]})
        self.assertFalse(result.ok)
        self.assertTrue(any("missing required field 'target'" in v for v in result.violations))
        self.assertTrue(any("unexpected field 'at'" in v for v in result.violations))

    def test_extra_field_on_endturn_is_rejected(self):
        self.assertRejected({"type": "EndTurn", "at": [0, 0]}, "unexpected field 'at'")

    def test_non_object_action_is_rejected_without_crashing(self):
        for bad in ("PlaceSoldier", ["PlaceSoldier"], 7, None):
            with self.subTest(action=bad):
                self.assertRejected(bad, "'action' is missing or not an object")

    def test_unknown_action_type_is_still_rejected(self):
        self.assertRejected({"type": "Teleport", "at": [0, 0]}, "unknown action type 'Teleport'")


class RealRepositoryTests(unittest.TestCase):
    def test_current_golden_fixtures_pass(self):
        result = GoldenFixtureValidator().validate({"repo_root": str(REPO_ROOT)})
        self.assertTrue(result.ok, result.violations)
        self.assertGreater(result.metadata["fixtures"], 0)


if __name__ == "__main__":
    unittest.main()
