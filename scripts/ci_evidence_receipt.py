#!/usr/bin/env python3
"""Produce a CI test-evidence receipt only when the run really is the success the claim says it is.

`gh run view --exit-status` exits 0 for a run that is still queued or in progress, so an exit code alone is not
evidence of success. This helper checks, before any receipt is written:

  1. status == completed
  2. conclusion == success
  3. headSha matches the SHA under test (prefix match, at least 7 characters)
  4. at least one expected step is given, and every expected step actually ran and concluded success
  5. the checkout the receipt is produced from has HEAD == the SHA under test, because the framework writer records
     `linked_commit` from the LOCAL git HEAD of --project-root, not from the remote run
  6. after writing, the receipt's `linked_commit` is read back and must match; otherwise the receipt is deleted

Only then does a receipt survive. The receipt writer guarantees the receipt shape, not that the input facts are
true; these checks are the facts.

Candidate head vs checked-out SHA: for `pull_request` runs GitHub's `headSha` is the PR head, while the job checks
out the PR merge ref by default. The receipt binds the PR head; the workflow logs both SHAs in its first step so the
two are never conflated.

Usage:
  python scripts/ci_evidence_receipt.py --run 123 --sha a0adfef7 --step "Run governance drift check" \
      --output artifacts/evidence/test-results/ci-run-123.json --writer <path to test_evidence_receipt_writer.py>
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
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
    expected_steps = list(expected_steps)
    if not expected_steps:
        problems.append("no expected steps given; a CI receipt must name the steps that had to succeed")
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


def check_producer_head(local_head: str, expected_sha: str) -> list[str]:
    """The receipt writer binds `linked_commit` to the local HEAD; it must be the commit under test."""
    wanted = (expected_sha or "").strip().lower()
    head = (local_head or "").strip().lower()
    if len(wanted) < 7:
        return ["expected SHA must be at least 7 characters"]
    if not head:
        return ["cannot read the local git HEAD of the project root"]
    if not head.startswith(wanted):
        return [
            f"local HEAD {head[:12]!r} is not the commit under test {wanted!r}; "
            "produce the receipt from a checkout of the tested commit"
        ]
    return []


def check_receipt_binding(receipt: object, expected_sha: str) -> list[str]:
    """Read-back check: the written receipt must be bound to the commit under test and carry exit_code 0."""
    if not isinstance(receipt, dict):
        return ["receipt is not a JSON object"]
    linked = str(receipt.get("linked_commit") or "").strip().lower()
    wanted = (expected_sha or "").strip().lower()
    problems: list[str] = []
    if not linked or not linked.startswith(wanted):
        problems.append(f"receipt linked_commit {linked[:12]!r} does not match {wanted!r}")
    if receipt.get("exit_code") != 0:
        problems.append(f"receipt exit_code is {receipt.get('exit_code')!r}")
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--run", required=True, help="workflow run id")
    parser.add_argument("--sha", required=True, help="commit SHA under test")
    parser.add_argument("--step", action="append", required=True,
                        help="step name that must have succeeded (repeatable, at least one)")
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
    head = subprocess.run(["git", "-C", args.project_root, "rev-parse", "HEAD"], capture_output=True, text=True)
    problems += check_producer_head(head.stdout if head.returncode == 0 else "", args.sha)
    if problems:
        print("NOT writing a success receipt:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 2
    code = subprocess.call([
        sys.executable, args.writer, "--project-root", args.project_root,
        "--runner", "github-actions", "--output", args.output,
        "--", "gh", "run", "view", args.run, "--repo", args.repo, "--exit-status",
    ])
    if code != 0:
        return code
    out = Path(args.project_root) / args.output
    try:
        receipt = json.loads(out.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"receipt unreadable after writing: {exc}", file=sys.stderr)
        return 2
    bad = check_receipt_binding(receipt, args.sha)
    if bad:
        print("receipt failed the read-back check and was removed:", file=sys.stderr)
        for p in bad:
            print(f"  - {p}", file=sys.stderr)
        out.unlink(missing_ok=True)
        out.with_suffix(".txt").unlink(missing_ok=True)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
