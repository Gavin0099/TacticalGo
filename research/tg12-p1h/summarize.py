#!/usr/bin/env python3
"""Summarize genuinely exported P1H anonymous observations without leaking text.

This tool never invents respondents. --self-test uses in-memory synthetic records
for code validation only, and its output must not count as a human playtest.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import statistics
import sys

ARMS = ("BASIC", "CHAIN", "ORDINARY")
ORDERS = (
    ("BASIC", "CHAIN", "ORDINARY"),
    ("CHAIN", "ORDINARY", "BASIC"),
    ("ORDINARY", "BASIC", "CHAIN"),
    ("ORDINARY", "CHAIN", "BASIC"),
    ("BASIC", "ORDINARY", "CHAIN"),
    ("CHAIN", "BASIC", "ORDINARY"),
)
FIELDS = ("understood", "enjoyed", "wantMore", "energyRecall")
REF = "2399cbc9bb03278c0811e6dc47167e2443b98751"

class InvalidExport(Exception): pass

def require(condition, reason):
    if not condition: raise InvalidExport(reason)

def validate(raw):
    require(raw.get("schema") == "TG12_P1H_EXPORT_V1", "wrong export schema")
    require(raw.get("anonymous") is True and raw.get("offline") is True, "not anonymous/offline")
    entry = raw.get("observation")
    require(isinstance(entry, dict), "missing observation")
    require(entry.get("study") == "TG12_P1H_CONTROLLED_CHOICE_V1", "wrong study")
    require(entry.get("source", {}).get("ref") == REF, "not pinned to PR37")
    code=entry.get("participant")
    require(isinstance(code, str) and code in {f"T{i:02d}" for i in range(1,7)}, "invalid participant code")
    require(entry.get("order") == list(ORDERS[int(code[1:])-1]), "unbalanced option order")
    choice=entry.get("firstChoice")
    require(choice in ARMS, "invalid first choice")
    require(entry.get("firstChoiceLabel") == "甲乙丙"[entry["order"].index(choice)], "first label mismatch")
    seconds=entry.get("firstChoiceSeconds")
    require(type(seconds) in (int,float) and 0<=seconds<=3600, "invalid first choice duration")
    viewed=entry.get("otherPlansViewed")
    require(isinstance(viewed, list) and all(v in ARMS for v in viewed), "bad optional comparison list")
    require(entry.get("otherPlansViewedCount")==len(viewed), "comparison count mismatch")
    survey=entry.get("survey")
    require(isinstance(survey,dict) and all(k in survey for k in FIELDS), "missing survey fields")
    require(survey["understood"] in ("unknown","1","2","3","4","5"), "bad understanding")
    require(survey["enjoyed"] in ("unknown","1","2","3","4","5"), "bad enjoyment")
    require(survey["wantMore"] in ("unknown","yes","no"), "bad play intention")
    require(survey["energyRecall"] in ("unknown","yes","no"), "bad 3-vs-4 mana check")
    events=entry.get("events")
    require(isinstance(events,list) and any(e.get("kind")=="first_choice_locked" for e in events)
            and any(e.get("kind")=="reason_submitted" for e in events)
            and any(e.get("kind")=="download_requested" for e in events), "missing real interaction/export sequence")
    return entry

def summarize(inputs, human=True):
    require(len(inputs)>0, "no actual tester files supplied")
    observations=[validate(item) for item in inputs]
    ids=[o["participant"] for o in observations]
    require(len(set(ids))==len(ids), "duplicate participant code; do not treat repeat exports as extra testers")
    first=Counter(o["firstChoice"] for o in observations)
    firstPos=Counter(str(o["order"].index(o["firstChoice"])+1) for o in observations)
    familiarity=Counter(o["familiarity"] for o in observations)
    ratings={k:Counter(o["survey"].get(k,"unknown") for o in observations) for k in FIELDS}
    seconds=[o["firstChoiceSeconds"] for o in observations]
    counts={
        "testerExports":len(inputs),
        "uniqueAnonymousParticipants":len(observations),
        "firstChoices":dict(first),
        "firstChoicePositionCounts":dict(firstPos),
        "familiarity":dict(familiarity),
        "secondsToFirstChoiceMedian":round(statistics.median(seconds),1),
        "selfReportedRatings":{k:dict(v) for k,v in ratings.items()},
        "participantsExploringAnotherPlan":sum(bool(o["otherPlansViewed"]) for o in observations),
        "preRevealReasonsNonempty":sum(bool(o.get("rationale","").strip()) for o in observations),
        "preRevealEnemyPredictionsNonempty":sum(bool(o.get("anticipatedReply","").strip()) for o in observations),
        "realHumanDataClaim":bool(human),
        "limitations":["constrained choices, not free play","self-report interest is not retention",
            "optional comparison click is not spontaneous restart",
            "no automatic coding of strategy understanding from text",
            "small convenience sample, not population statistics",
            "this summary suppresses raw free-text; keep individual exports private"]
    }
    return counts

def synthetic():
    records=[]
    for i,choice in enumerate(ARMS,start=1):
        order=list(ORDERS[i-1])
        records.append({"schema":"TG12_P1H_EXPORT_V1","anonymous":True,"offline":True,
            "observation":{"study":"TG12_P1H_CONTROLLED_CHOICE_V1","source":{"ref":REF},
                "participant":f"T{i:02d}","order":order,"firstChoice":choice,
                "firstChoiceLabel":"甲乙丙"[order.index(choice)],
                "firstChoiceSeconds":10+i,"familiarity":"new",
                "otherPlansViewed":["CHAIN"] if choice!="CHAIN" else [],"otherPlansViewedCount":0 if choice=="CHAIN" else 1,
                "survey":{"understood":"3","enjoyed":"2","wantMore":"unknown","energyRecall":"no"},
                "events":[{"kind":"first_choice_locked"},{"kind":"reason_submitted"},{"kind":"download_requested"}]
            }})
    return records

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("exports",type=Path,nargs="*",help="actual anonymous JSON export paths; do not commit exports to public GitHub")
    parser.add_argument("--output",type=Path,help="write aggregate without raw text")
    parser.add_argument("--self-test",action="store_true")
    args=parser.parse_args()
    if args.self_test:
        report=summarize(synthetic(),human=False)
        assert report["uniqueAnonymousParticipants"]==3
        assert report["firstChoices"]=={"BASIC":1,"CHAIN":1,"ORDINARY":1}
        assert report["realHumanDataClaim"] is False
        tampered=synthetic()
        tampered[0]["observation"]["firstChoiceSeconds"]=-1
        try: summarize(tampered,human=False)
        except InvalidExport: pass
        else: raise InvalidExport("invalid duration accepted")
        print("PASS P1H aggregate self-test: synthetic data only; 1 corruption rejected; human participants 0")
        return
    if not args.exports: parser.error("provide at least one real voluntarily exported JSON file")
    report=summarize([json.loads(p.read_text(encoding="utf-8")) for p in args.exports])
    text=json.dumps(report,ensure_ascii=False,indent=2)
    if args.output: args.output.write_text(text+"\n",encoding="utf-8")
    print(text)
if __name__=="__main__":
    try: main()
    except (InvalidExport,KeyError,TypeError,ValueError,json.JSONDecodeError) as error:
        print("FAIL P1H aggregation:",error,file=sys.stderr);sys.exit(1)
