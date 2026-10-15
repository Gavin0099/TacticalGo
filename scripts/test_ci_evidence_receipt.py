"""Tests for the success judgement in scripts/ci_evidence_receipt.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ci_evidence_receipt import check_producer_head, check_receipt_binding, evaluate_run  # noqa: E402

SHA = "a0adfef7f3cd9455614c33281d6b20584726d22f"


def _run(**over):
    run = {
        "status": "completed", "conclusion": "success", "headSha": SHA,
        "jobs": [{"steps": [
            {"name": "Run governance drift check", "conclusion": "success"},
            {"name": "Check managed hook wiring", "conclusion": "success"},
        ]}],
    }
    run.update(over)
    return run


class EvaluateRunTests(unittest.TestCase):
    STEPS = ["Run governance drift check", "Check managed hook wiring"]

    def test_real_success_is_accepted(self):
        self.assertEqual(evaluate_run(_run(), SHA[:8], self.STEPS), [])

    def test_a_queued_run_is_rejected_even_though_exit_status_would_be_zero(self):
        for status in ("queued", "in_progress", "waiting"):
            with self.subTest(status=status):
                problems = evaluate_run(_run(status=status, conclusion=None), SHA, self.STEPS)
                self.assertTrue(any("not 'completed'" in p for p in problems), problems)

    def test_non_success_conclusions_are_rejected(self):
        for conclusion in ("failure", "cancelled", "skipped", "timed_out", None):
            with self.subTest(conclusion=conclusion):
                self.assertTrue(evaluate_run(_run(conclusion=conclusion), SHA, self.STEPS))

    def test_wrong_or_short_sha_is_rejected(self):
        self.assertTrue(evaluate_run(_run(), "122e0005", self.STEPS))
        self.assertTrue(evaluate_run(_run(), "a0adf", self.STEPS))
        self.assertTrue(evaluate_run(_run(headSha=""), SHA, self.STEPS))

    def test_missing_or_failed_expected_step_is_rejected(self):
        problems = evaluate_run(_run(), SHA, ["Run validator unit tests (negative cases)"])
        self.assertTrue(any("did not run" in p for p in problems), problems)
        failed = _run(jobs=[{"steps": [{"name": "Check managed hook wiring", "conclusion": "failure"}]}])
        self.assertTrue(evaluate_run(failed, SHA, ["Check managed hook wiring"]))


class EmptyStepSetTests(unittest.TestCase):
    def test_no_expected_steps_is_refused_instead_of_silently_passing(self):
        problems = evaluate_run(_run(), SHA, [])
        self.assertTrue(any("no expected steps" in p for p in problems), problems)


class ProducerHeadTests(unittest.TestCase):
    """The writer records the LOCAL HEAD; a remote run for A must not be receipted from a checkout of B."""

    def test_matching_local_head_is_accepted(self):
        self.assertEqual(check_producer_head(SHA, SHA[:8]), [])

    def test_a_different_local_head_is_refused(self):
        other = "122e00056529" + "0" * 28
        problems = check_producer_head(other, SHA[:8])
        self.assertTrue(any("not the commit under test" in p for p in problems), problems)

    def test_unreadable_head_or_short_sha_is_refused(self):
        self.assertTrue(check_producer_head("", SHA))
        self.assertTrue(check_producer_head(SHA, "a0adf"))


class ReceiptReadBackTests(unittest.TestCase):
    def test_bound_receipt_with_exit_zero_is_accepted(self):
        self.assertEqual(check_receipt_binding({"linked_commit": SHA, "exit_code": 0}, SHA[:8]), [])

    def test_receipt_bound_to_another_commit_is_rejected(self):
        problems = check_receipt_binding({"linked_commit": "122e0005" + "0" * 32, "exit_code": 0}, SHA[:8])
        self.assertTrue(any("linked_commit" in p for p in problems), problems)

    def test_nonzero_exit_or_garbage_is_rejected(self):
        self.assertTrue(check_receipt_binding({"linked_commit": SHA, "exit_code": 1}, SHA))
        self.assertTrue(check_receipt_binding({"exit_code": 0}, SHA))
        self.assertTrue(check_receipt_binding([], SHA))


if __name__ == "__main__":
    unittest.main()
