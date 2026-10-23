#!/usr/bin/env python3
"""Verify the TG12 P1H offline choice fixture against frozen P0/P1/P1R evidence.

The HTML only presents pre-existing legal Core plans; this verifier never claims
human playtest success, optimal move selection or independent game-rule proof.
"""
import argparse
import copy
import itertools
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
LAB = ROOT / "research/tg12-p1h/choice-lab.html"
P0 = ROOT / "artifacts/tg12/gameplay-p0-20261023/complete-games/b9-Priest-Rogue/trace.json"
P1 = ROOT / "artifacts/tg12/gameplay-p1-20261023/results-v2.json"
P1R = ROOT / "artifacts/tg12/gameplay-p1r-20261023/summary.json"
BASE_REF = "2399cbc9bb03278c0811e6dc47167e2443b98751"
EXPECTED = {"BASIC": 0, "CHAIN": 5, "ORDINARY": 9}

def load(path):
    return json.loads(path.read_text(encoding="utf-8"))

def fixture_and_script():
    html = LAB.read_text(encoding="utf-8")
    match = re.search(r'<script type="application/json" id="studyFixture">([\s\S]*?)</script>', html)
    assert match, "embedded fixture not found"
    scripts = re.findall(r"<script(?:\s[^>]*)?>([\s\S]*?)</script>", html)
    js = next((s for s in scripts if '"use strict";' in s), None)
    assert js, "offline program not found"
    assert not re.search(r'<script[^>]*src=|<link[^>]*href=', html), "external resources"
    assert not re.search(r'\bfetch\s*\(|XMLHttpRequest|localStorage|sessionStorage', js), "network / persistence"
    assert "TG12_P1H_EXPORT_V1" in js and "Math.random" not in js
    order = re.search(r'const ORDERS=(\[[^;]+\]);', js)
    assert order, "counterbalanced orders not found"
    orders = json.loads(order.group(1))
    assert sorted(tuple(x) for x in orders) == sorted(itertools.permutations(EXPECTED)), "six orders not balanced"
    return json.loads(match.group(1)), js

def count_soldiers(board):
    return {"black": board.count("x"), "white": board.count("o")}

def check(data, p0, p1, p1r):
    assert data["study"] == "TG12_P1H_CONTROLLED_CHOICE_V1"
    source = data["source"]
    assert (source["ref"], source["p0Game"], source["turn"], source["ply"],
            source["actor"], source["opponent"]) == (
                BASE_REF, "b9-Priest-Rogue", 59, 60, "white-rogue", "black-priest")
    position = next((p for p in p1["positions"] if (p["game"],p["turn"],p["ply"])
                     == ("b9-Priest-Rogue", 59, 60)), None)
    assert position is not None and position["hero"] == "Rogue" and position["actor"] == 1
    old_start = next(frame["before"] for frame in p0["frames"] if frame["turn"] == 59)
    assert position["before"] == old_start, "P0 source history/snapshot disagreement"
    assert data["root"] == {k: position["before"][k] for k in ("board", "mana", "ap", "ply")}
    assert (data["root"]["mana"][1], data["root"]["ap"], data["root"]["ply"]) == (6, 2, 60)
    assert len(data["root"]["board"].splitlines()) == 9
    assert all(len(row) == 9 for row in data["root"]["board"].splitlines())
    assert len(data["arms"]) == 3
    assert len(set(a["id"] for a in data["arms"])) == 3
    assert data["constraints"]["notFullGame"] is True and data["constraints"]["notHumanEvidence"] is True
    base_count = count_soldiers(data["root"]["board"])
    assert (base_count["white"], base_count["black"]) == (28, 32)
    for arm in data["arms"]:
        idx = EXPECTED[arm["id"]]
        assert arm["sourceCandidate"] == idx
        p = position["alternatives"][idx]
        summary = next(item for item in p1r["branches"] if item["p1AlternativeIndex"] == idx)
        reply = p["reply"]
        assert arm["actions"] == p["actions"] and arm["after"] == p["after"]
        assert arm["replyActions"] == reply["recordActions"]
        assert arm["reply"] == reply["after"]
        assert arm["manaSpent"] == p["manaSpent"]
        assert arm["ownCaptures"] == p["enemySoldiersCaptured"]
        assert arm["opponentCaptures"] == reply["standardBotCapturedOurSoldiers"]
        assert arm["netCaptures"] == arm["ownCaptures"] - arm["opponentCaptures"]
        assert arm["netCaptures"] == summary["standard"]["netCaptures"]
        now = count_soldiers(arm["reply"]["board"])
        delta = (now["white"] - now["black"]) - (base_count["white"] - base_count["black"])
        assert arm["boardBalanceDelta"] == delta == summary["standard"]["boardSoldierBalanceDelta"]
        assert arm["reply"]["mana"][1] == summary["standard"]["nextMana"]
        assert arm["nextAdvancedLegal"] == summary["standard"]["nextAdvancedLegal"]
        assert len(arm["actions"]) == 2, "only complete 2-AP candidates"
        assert len(arm["replyActions"]) == 2, "actual Standard full reply"
    assert data["arms"][1]["sourceCandidate"] == 5
    assert data["arms"][1]["netCaptures"] == 2
    assert data["arms"][1]["boardBalanceDelta"] == 1
    assert data["arms"][1]["reply"]["mana"][1] == 3
    assert data["arms"][1]["nextAdvancedLegal"] is False
    return len(data["arms"])

def check_negative(data,p0,p1,p1r):
    mutations = [
        ("mana",lambda x:x["root"]["mana"].__setitem__(1,5)),
        ("root-board",lambda x:x["root"].__setitem__("board",x["root"]["board"].replace("Q","."))),
        ("candidate-index",lambda x:x["arms"][0].__setitem__("sourceCandidate",99)),
        ("reply-board",lambda x:x["arms"][0]["reply"].__setitem__("board","."*81)),
        ("net-captures",lambda x:x["arms"][1].__setitem__("netCaptures",5)),
        ("skill-legal",lambda x:x["arms"][1].__setitem__("nextAdvancedLegal",True)),
        ("board-soldier-balance",lambda x:x["arms"][1].__setitem__("boardBalanceDelta",2)),
        ("missing-choice",lambda x:x["arms"].pop()),
        ("source-ply",lambda x:x["source"].__setitem__("ply",61)),
        ("wrong-move",lambda x:x["arms"][0]["actions"][1]["points"][0].__setitem__("x",0)),
    ]
    count = 0
    for name,mutate in mutations:
        altered = copy.deepcopy(data); mutate(altered)
        try:
            check(altered,p0,p1,p1r)
        except (AssertionError,KeyError,StopIteration,ValueError,TypeError):
            count += 1
        else:
            raise AssertionError(f"negative control {name} was accepted")
    return count

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--negative-controls",action="store_true")
    parser.add_argument("--check-js",action="store_true")
    args=parser.parse_args()
    data,script=fixture_and_script()
    count=check(data,load(P0),load(P1),load(P1R))
    print(f"PASS P1H source pinned; {count} candidate/reply pairs matched P0/P1/P1R")
    if args.negative_controls:
        rejected=check_negative(data,load(P0),load(P1),load(P1R))
        print(f"PASS {rejected} fixture corruption controls rejected")
    if args.check_js:
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/"choice-script.js"
            path.write_text(script,encoding="utf-8")
            subprocess.run(["node","--check",str(path)],check=True)
            print("PASS offline JS syntax")
    print("HUMAN RESULTS: 0 (must be collected voluntarily from actual testers)")
if __name__=="__main__":
    try: main()
    except (AssertionError,KeyError,StopIteration,ValueError,TypeError,subprocess.CalledProcessError) as error:
        print(f"FAIL P1H fixture check: {error}",file=sys.stderr)
        sys.exit(1)
