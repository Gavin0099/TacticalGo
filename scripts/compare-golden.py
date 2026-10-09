#!/usr/bin/env python3
"""Compare engine transcripts; these are equivalence evidence, never golden expectations."""
import json
import sys
from pathlib import Path
left, right = (json.loads(Path(p).read_text()) for p in sys.argv[1:3])
if len(left) != len(right):
    raise SystemExit(f"FAIL: snapshot counts {len(left)} != {len(right)}")
for reference, candidate in zip(left, right):
    if reference != candidate:
        keys = sorted(k for k in reference.keys() | candidate.keys() if reference.get(k) != candidate.get(k))
        raise SystemExit(f"FAIL: {reference['fixture']} step {reference['step']}: differing fields {keys}")
print(f"PASS: {len(left)} C#/Swift snapshots match, including full board, resources, flags, errors and ordered event payloads")
