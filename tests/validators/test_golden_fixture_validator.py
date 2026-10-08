"""Execute the actual validator against an accepted R1 fixture and deliberately invalid copies."""
import copy
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("golden_validator", ROOT / "validators/golden_fixture_validator.py")
module = importlib.util.module_from_spec(spec)
# dataclasses requires the module to be registered when the framework isn't on PYTHONPATH.
import sys
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class GoldenValidatorTests(unittest.TestCase):
    def validate(self, mutate=None):
        with tempfile.TemporaryDirectory() as folder:
            repo = Path(folder)
            source = repo / "src/TacticalGo.Domain"
            source.mkdir(parents=True)
            for name in ("Actions.cs", "ActionEvent.cs", "Primitives.cs"):
                shutil.copyfile(ROOT / "src/TacticalGo.Domain" / name, source / name)
            golden = repo / "tests/golden"
            golden.mkdir(parents=True)
            fixture = copy.deepcopy(json.loads((ROOT / "tests/golden/magic_hand_push_then_place.json").read_text()))
            if mutate:
                mutate(fixture)
            (golden / "magic_hand_push_then_place.json").write_text(json.dumps(fixture), encoding="utf-8")
            return module.GoldenFixtureValidator().validate({"repo_root": repo})

    def test_hand_authored_fixture_is_accepted(self):
        result = self.validate()
        self.assertTrue(result.ok, result.violations)
        self.assertEqual(1, result.metadata["fixtures"])

    def test_wrong_direction_is_rejected(self):
        result = self.validate(lambda d: d["steps"][0]["action"].update(direction="Diagonal"))
        self.assertFalse(result.ok)
        self.assertTrue(any("direction" in v for v in result.violations))

    def test_missing_target_is_rejected(self):
        result = self.validate(lambda d: d["steps"][0]["action"].pop("target"))
        self.assertFalse(result.ok)
        self.assertTrue(any("coordinates" in v for v in result.violations))

    def test_wrong_event_is_rejected(self):
        result = self.validate(lambda d: d["steps"][0]["expect"].update(events=["PushHappened"]))
        self.assertFalse(result.ok)
        self.assertTrue(any("PushHappened" in v for v in result.violations))

    def test_wrong_skill_is_rejected(self):
        result = self.validate(lambda d: d["config"].update(mageSkill="Fireball"))
        self.assertFalse(result.ok)
        self.assertTrue(any("mageSkill" in v for v in result.violations))


if __name__ == "__main__":
    unittest.main()
