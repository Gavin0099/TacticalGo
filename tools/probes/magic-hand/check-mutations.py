"""Bounded sensitivity checks. Restores each exact source byte sequence; never changes golden expectations."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
if sys.argv[1:] not in ([], ["--friendly-only"]):
    raise SystemExit("Usage: check-mutations.py [--friendly-only]")
FRIENDLY = sys.argv[1:] == ["--friendly-only"]
RESULTS = ROOT / ("artifacts/r1-review/mutations" if FRIENDLY else "artifacts/r1-validation/mutations")
RESULTS.mkdir(parents=True, exist_ok=True)
NS = {"t": "http://microsoft.com/schemas/VisualStudio/TeamTest/2010"}


def run(name):
    trx = RESULTS / (name + ".trx")
    result = subprocess.run(["dotnet", "test", "tests/TacticalGo.Domain.Tests", "--filter",
        "FullyQualifiedName~MagicHandFriendlyTests" if FRIENDLY else "FullyQualifiedName~MagicHand",
        "--logger", f"trx;LogFileName={trx.name}",
        "--results-directory", str(RESULTS)], cwd=ROOT, capture_output=True, timeout=30)
    (RESULTS / (name + ".log")).write_bytes(result.stdout + result.stderr)
    if not trx.exists():
        raise RuntimeError(f"{name}: no test results; build/runner failure is not a killed mutant")
    tree = ET.parse(trx)
    counters = tree.find(".//t:Counters", NS).attrib
    failures = [node.attrib["testName"] for node in tree.findall(".//t:UnitTestResult", NS)
                if node.attrib["outcome"] == "Failed"]
    return dict(exitCode=result.returncode, counters=counters, failedTests=failures)


resolver = "src/TacticalGo.Domain/ActionResolver.cs"
mutations = [
    ("range_boundary", resolver, "hero.ManhattanTo(a.Target) > s.Config.MagicHandRange",
        "hero.ManhattanTo(a.Target) >= s.Config.MagicHandRange"),
    ("source_not_cleared", resolver, "trial[a.Target] = null;", "// MUTATION: source not cleared"),
    ("free_mana", resolver,
        "return Finish(s, trial, NoPlacements, null, s.Config.SkillManaCost, isSkill: true, seal: null,",
        "return Finish(s, trial, NoPlacements, null, 0, isSkill: true, seal: null,"),
    ("suicide_guard_removed", resolver, "if (resolution.MoverHasDeadGroup)",
        "if (false && resolution.MoverHasDeadGroup)"),
    ("superko_guard_removed", resolver, "if (s.History.Contains(trial.ComputeHash()))",
        "if (false && s.History.Contains(trial.ComputeHash()))"),
    ("repeat_skill_allowed", resolver, "if (s.SkillUsedThisTurn)", "if (false && s.SkillUsedThisTurn)"),
    ("left_candidate_missing", "src/TacticalGo.Domain/ActionValidator.cs",
        "Enum.GetValues<PushDirection>()", "Enum.GetValues<PushDirection>().Where(d => d != PushDirection.Left)"),
]
if FRIENDLY:
    mutations = [
        ("friendly_rejected_by_resolver", resolver,
            'if (s.Board[a.Target] is not { Kind: PieceKind.Soldier } victim)',
            'if (s.Board[a.Target] is not { Kind: PieceKind.Soldier } victim || victim.Owner == s.Current)'),
        ("friendly_omitted_from_candidates", "src/TacticalGo.Domain/ActionValidator.cs",
            'if (board[p] is { Kind: PieceKind.Soldier } &&',
            'if (board[p] is { Kind: PieceKind.Soldier } victim && victim.Owner != me &&'),
    ]
baseline = run("baseline")
if baseline["exitCode"] or int(baseline["counters"]["failed"]):
    raise RuntimeError("Focused baseline must pass before mutation")
records = []
for name, relative, old, new in mutations:
    path = ROOT / relative
    original = path.read_bytes()
    content = original.decode("utf-8")
    if "\r\n" in content:
        old, new = old.replace("\n", "\r\n"), new.replace("\n", "\r\n")
    if content.count(old) != 1:
        raise RuntimeError(f"{name}: mutation anchor must occur exactly once")
    try:
        path.write_bytes(content.replace(old, new).encode("utf-8"))
        result = run(name)
        killed = result["exitCode"] != 0 and int(result["counters"]["failed"]) > 0
        records.append(dict(name=name, file=relative, old=old, new=new, killed=killed, **result))
        print(f"{name}: {'killed' if killed else 'SURVIVED'}; failed={result['counters']['failed']}", flush=True)
    finally:
        path.write_bytes(original)
        if path.read_bytes() != original:
            raise RuntimeError(f"{name}: source restoration failed")

restored = run("restored")
report = dict(baseline=baseline, mutations=records, restored=restored,
    sourceSha256={p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in {r["file"] for r in records}},
    claimBoundary=f"Only these {len(mutations)} mutations; not full mutation coverage or domain correctness proof.")
report_path = ROOT / ("docs/evidence/r1-magic-hand/friendly-mutations.json" if FRIENDLY else "docs/evidence/r1-magic-hand/mutations.json")
report_path.parent.mkdir(parents=True, exist_ok=True)
report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
if not all(r["killed"] for r in records) or restored["exitCode"] or int(restored["counters"]["failed"]):
    raise SystemExit(1)
