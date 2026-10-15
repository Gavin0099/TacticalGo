#!/usr/bin/env python3
"""Rebuild one pinned old body against identical new UI, then restore dirty source."""
import hashlib, json, signal, subprocess, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'artifacts/v11/quality-35'
relative='swift/TacticalGoCore/Sources/TacticalGoMotion/WarriorPresentationPlan.swift'
source=ROOT/relative
candidate=source.read_bytes()
baseline=(folder/'baseline-source'/relative).read_bytes()
sha=lambda b:hashlib.sha256(b).hexdigest()
pin=json.loads((folder/'BASELINE_SOURCE_PIN.json').read_text())
assert sha(baseline)==pin[relative]
backup=folder/'pose-sources/final-candidate-before-baseline.swift'
assert not backup.exists(), 'Do not overwrite an existing restoration backup'
backup.write_bytes(candidate)
def interrupted(signum,frame):raise KeyboardInterrupt()
signal.signal(signal.SIGTERM,interrupted)
signal.signal(signal.SIGINT,interrupted)
rc=1;restored=False
try:
    source.write_bytes(baseline)
    cmd=['xcodebuild','build-for-testing','-project','ios/TacticalGo.xcodeproj','-scheme','TacticalGo','-configuration','Debug',
         '-destination','platform=iOS Simulator,id=44259159-744B-4270-85A2-86CF756C100F','-derivedDataPath','artifacts/v11/quality-35/DebugDerived',
         '-jobs','2','CURRENT_PROJECT_VERSION=1112','MARKETING_VERSION=1.1','SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG']
    with (folder/'exact-baseline-body-build.log').open('w') as f:
        subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,check=True)
    print('Pinned 1111 body built with identical candidate UI; capturing exact frames',flush=True)
    with (folder/'exact-baseline-body-frames.log').open('w') as f:
        subprocess.run([sys.executable,'scripts/capture-quality-warrior-frames.py','--device','44259159-744B-4270-85A2-86CF756C100F',
                        '--app','ios/Build/Products/Debug-iphonesimulator/TacticalGo.app','--out','artifacts/v11/quality-35/warrior-exact-baseline',
                        '--profile','1111 body plus identical 1112 UI; confirmed static frames'],cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,check=True)
    rc=0
finally:
    current=sha(source.read_bytes())
    if current==sha(baseline):source.write_bytes(candidate)
    elif current!=sha(candidate):
        raise RuntimeError('Unexpected source edit: preserve it and recover candidate from the saved backup')
    restored=sha(source.read_bytes())==sha(candidate)
    (folder/'BASELINE_BODY_SOURCE_RESTORE.json').write_text(json.dumps(dict(
        path=relative,baselineSHA256=sha(baseline),candidateSHA256=sha(candidate),
        comparisonExitCode=rc,candidateSourceRestored=restored,
        binary='DEBUG products/installed simulator still have old body; next candidate build is required',
        scope='one reversible source file; no Git operations or external delivery'),indent=2)+'\n')
    print('Dirty candidate source restored:',restored,flush=True)
sys.exit(rc)
