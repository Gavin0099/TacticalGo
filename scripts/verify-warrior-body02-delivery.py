"""Focused, reproducible evidence check; does not judge acting or art quality."""
import hashlib, json, pathlib, subprocess
R=pathlib.Path(__file__).resolve().parents[1];D=R/'artifacts/ios/anim-warrior-body-02'
def read(name): return (D/name).read_text()
assert 'Executed 170 tests, with 0 failures' in read('package-final.log')
assert 'PASS: 137 C#/Swift snapshots match' in read('golden-compare.log')
for name,count in [('native-audit-rim-final.log',2),('native-se-rim-final.log',1),('media/native-record-test.log',1)]:
    log=read(name);assert f'Executed {count} test' in log and 'with 0 failures' in log and '** TEST EXECUTE SUCCEEDED **' in log,name
assert '** BUILD SUCCEEDED **' in read('release-rim-final.log')
a=json.loads(read('hero-body-audit.json'));assert a['status']=='PASS' and len(a['checks'])==108 and all(x['pass'] for x in a['checks'])
manifest=json.loads((R/'assets/candidates/anim-warrior-body-02/rig-and-timing.json').read_text())
for s in manifest['sources']: assert hashlib.sha256((R/s['path']).read_bytes()).hexdigest()==s['sha256'],s['path']
assert manifest['sources'][0]['sha256']=='50885855dc9faee8966558ea854f99d24bd0ffd0ed93c03bb6b87c8643d42298'
edits=json.loads(read('media/edit-audit.json'));assert len(edits['clips'])==6
for c in edits['clips']:
    assert c['class']=='WARRIOR' and c['speed']==1
    assert hashlib.sha256((R/c['file']).read_bytes()).hexdigest()==c['sha256']
protected=['swift/TacticalGoCore/Sources/TacticalGoCore','swift/TacticalGoCore/Sources/TacticalGoBot','ios/TacticalGo/CozyBoard.swift','ios/TacticalGo/BoardViews.swift','ios/TacticalGo/BoardPlayback.swift','ios/TacticalGo/GameStore.swift','ios/TacticalGo/MageBodyView.swift']
assert not subprocess.check_output(['git','diff','eb7be20','--',*protected],cwd=R,text=True).strip()
physical=json.loads(read('physical-ipad-audit.json')) if (D/'physical-ipad-audit.json').exists() else None
result={'packageTests':170,'goldenSnapshots':137,'simulatorTests':4,'simulatorStateChecks':108,'nativeWarriorClips':6,'release':'PASS','protectedRuntimeDiff':'NONE','physicalIPadInAppChecks':len(physical['checks']) if physical and physical['status']=='PASS' else None,'physicalInputGate':'NOT PASS: iPad UI runner authentication canceled; iPhone unavailable','ownerBodyActingGate':'PENDING; never inferred from this script','voice':'HOLD/off; no voice production','vfx':'NOT STARTED: requires explicit Owner pass of all three bodies'}
(D/'delivery-verification.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
