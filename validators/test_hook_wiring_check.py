"""Tests for validators/hook_wiring_check.py (run: python -m unittest discover -s validators -p "test_*.py")."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hook_wiring_check import HookWiringValidator  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[1]
BRIDGE = "python .github/hooks/ai-governance-lifecycle.py --event-type session_end --surface auto"


def _run(files: dict[str, object]):
    with tempfile.TemporaryDirectory() as tmp:
        hooks = Path(tmp) / ".github" / "hooks"
        hooks.mkdir(parents=True)
        for name, doc in files.items():
            text = doc if isinstance(doc, str) else json.dumps(doc)
            (hooks / name).write_text(text, encoding="utf-8")
        return HookWiringValidator().validate({"repo_root": tmp})


class HookWiringTests(unittest.TestCase):
    def test_the_original_p1_wiring_is_rejected(self):
        bad = {"version": 1, "hooks": {"Stop": [{"type": "command", "command": BRIDGE, "timeout": 30}]}}
        result = _run({"ai-governance-vscode.json": bad})
        self.assertFalse(result.ok)
        self.assertIn("Stop", result.violations[0])

    def test_event_name_case_and_nesting_do_not_hide_it(self):
        for event in ("Stop", "stop", "STOP"):
            with self.subTest(event=event):
                nested = {"hooks": {event: [{"matcher": "", "hooks": [{"type": "command", "command": BRIDGE}]}]}}
                self.assertFalse(_run({"x.json": nested}).ok)
        direct = {"hooks": {"Stop": [{"type": "command", "command": "python -m governance_tools.session_end_hook"}]}}
        self.assertFalse(_run({"x.json": direct}).ok)

    def test_real_session_end_event_is_allowed(self):
        copilot = {"version": 1, "hooks": {"sessionEnd": [{"type": "command", "command": BRIDGE}]}}
        self.assertTrue(_run({"ai-governance-copilot.json": copilot}).ok)

    def test_stop_without_closeout_is_allowed(self):
        stop_only = {"hooks": {"Stop": [{"type": "command", "command": "python scripts/notify.py"}]}}
        self.assertTrue(_run({"x.json": stop_only}).ok)

    def test_invalid_json_fails_closed(self):
        self.assertFalse(_run({"broken.json": "{ not json"}).ok)

    def test_missing_hooks_dir_is_ok(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertTrue(HookWiringValidator().validate({"repo_root": tmp}).ok)

    def test_current_repository_is_clean(self):
        result = HookWiringValidator().validate({"repo_root": str(REPO_ROOT)})
        self.assertTrue(result.ok, result.violations)


if __name__ == "__main__":
    unittest.main()
