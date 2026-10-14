#!/usr/bin/env python3
"""Produce a CI test-evidence receipt only when the run really is the success the claim says it is.

`gh run view --exit-status` exits 0 for a run that is still queued or in progress, so an exit code alone is not
evidence of success. This helper checks, before any receipt is written:

  1. status == completed
  2. conclusion == success
  3. headSha matches the SHA under test (prefix match, at least 7 characters)
  4. every expected step actually ran and concluded success

Only then does it call the framework's test_evidence_receipt_writer. The receipt writer guarantees the receipt
shape, not that the input facts are true; these checks are the facts.

Usage:
  python scripts/ci_evidence_receipt.py --run 123 --sha a0adfef7 --step "Run governance drift check" \
      --output artifacts/evidence/test-results/ci-run-123.json --writer <path to test_evidence_receipt_writer.py>
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from typing import Iterable


def evaluate_run(run: dict, expected_sha: str, expected_steps: Iterable[str]) -> list[str]:
    """Return the list of reasons the run must NOT be turned into a success receipt (empty = ok)."""
    problems: list[str] = []
    if run.get("status") != "completed":
        problems.append(f"status is {run.get('status')!r}, not 'completed'")
    if run.get("conclusion") != "success":
        problems.append(f"conclusion is {run.get('conclusion')!r}, not 'success'")
    head = str(run.get("headSha") or "")
    wanted = (expected_sha or "").strip().lower()
    if len(wanted) < 7:
        problems.append("expected SHA must be at least 7 characters")
    elif not head.lower().startswith(wanted):
        problems.append(f"headSha {head[:12]!r} does not match the SHA under test {wanted!r}")
    steps: dict[str, str | None] = {}
    for job in run.get("jobs") or []:
        for step in job.get("steps") or []:
            steps[str(step.get("name"))] = step.get("conclusion")
    for name in expected_steps:
        if name not in steps:
            problems.append(f"expected step {name!r} did not run")
        elif steps[name] != "success":
            problems.append(f"expected step {name!r} concluded {steps[name]!r}")
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--run", required=True, help="workflow run id")
    parser.add_argument("--sha", required=True, help="commit SHA under test")
    parser.add_argument("--step", action="append", default=[], help="step name that must have succeeded (repeatable)")
    parser.add_argument("--repo", default="Gavin0099/TacticalGo")
    parser.add_argument("--output", required=True, help="receipt path relative to the project root")
    parser.add_argument("--writer", required=True, help="path to the framework test_evidence_receipt_writer.py")
    parser.add_argument("--project-root", default=".")
    args = parser.parse_args(argv)

    view = subprocess.run(
        ["gh", "run", "view", args.run, "--repo", args.repo, "--json", "status,conclusion,headSha,jobs"],
        capture_output=True, text=True,
    )
    if view.returncode != 0:
        print(f"cannot read run {args.run}: {view.stderr.strip()}", file=sys.stderr)
        return 2
    problems = evaluate_run(json.loads(view.stdout), args.sha, args.step)
    if problems:
        print("NOT writing a success receipt:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 2
    return subprocess.call([
        sys.executable, args.writer, "--project-root", args.project_root,
        "--runner", "github-actions", "--output", args.output,
        "--", "gh", "run", "view", args.run, "--repo", args.repo, "--exit-status",
    ])


if __name__ == "__main__":
    raise SystemExit(main())
