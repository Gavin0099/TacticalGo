"""Validate retained M3 evidence and identity/receipt boundaries, not human acting quality."""
import hashlib,json,pathlib,subprocess
ROOT=pathlib.Path(__file__).resolve().parents[1];P=ROOT/'artifacts/ios/anim-mage-m3'
def read(name):return (P/name).read_text()
assert 'Executed 164 tests, with 0 failures' in read('package-initial.log')
assert 'PASS: 137 C#/Swift snapshots match' in read('golden-compare.log')
a=json.loads(read('mage-body-audit.json'));assert a['status']=='PASS' and len(a['checks'])==97 and all(x['pass'] for x in a['checks'])
for log in ['native-two-ap-corrected.log','native-ipad.log','native-se.log','media/native-record-test.log','media/dense/native-record-test.log']:
 assert '** TEST EXECUTE SUCCEEDED **' in read(log),log
assert 'testMagePushAndCaptureArePresentedFromRealBotEvents]' in read('native-focused.log')
assert 'testMagePushAndCaptureArePresentedFromRealBotEvents]\' passed' in read('native-focused.log')
for log in ['release-build.log','native-final-build.log','device-build.log']:assert ('** BUILD SUCCEEDED **' in read(log) or '** TEST BUILD SUCCEEDED **' in read(log)),log
pins={'ios/TacticalGo/Cozy/B-mage-v02.png':'6980751a325e51156e56f14b38171a435bd54f4ef7d509433e94d6e3b9061a33','ios/TacticalGo/MageBody/clean-plate.png':'9a633d497e0ce5baaa1f726312d87b49507df65b1c997c84374fa2f612be294d'}
for path,sha in pins.items():assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==sha
c=json.loads(read('media/capture-clock.json'));r=[x for x in json.loads(read('media/game-feel-receipts.json')) if x['receiptUptime']>=c['recordReadyUptime']];assert len(r)==10
for i in range(3):
 for key in ['before','after','events']:assert r[i][key]==r[i+3][key]==r[i+6][key]
assert all(not x['effectsEnabled'] for x in r[:9]) and r[9]['effectsEnabled']
for side in ['iphone','ipad']:assert json.loads(read(side+'-install.json'))['info']['outcome']=='success'
for size in [32,48,64]:
 for rev in ['m2','m3']:
  for side in ['one','two']:
   for pose in ['rest','anticipation','release']:assert (P/f'native-size-review/{rev}-{side}-{pose}-{size}.png').is_file()
subprocess.run(['codesign','--verify','--deep','--strict',str(ROOT/'ios/Build/Products/Debug-iphoneos/TacticalGo.app')],check=True)
paths=subprocess.check_output(['git','diff','449e906','--name-only'],cwd=ROOT,text=True).splitlines()
assert not any(x.startswith('swift/TacticalGoCore/Sources/TacticalGoCore/') or x.endswith(('GameStore.swift','BoardPlayback.swift','BoardProjection.swift','BotPlanner.swift')) for x in paths)
result={'engineeringEvidence':'PASS','swiftTests':164,'golden':{'fixtures':38,'actions':99,'snapshots':137,'swift':'fresh replay','csharp':'cached reviewed baseline; not rerun'},'nativeAuditChecks':97,'sameFixtureReceipts':10,'identityPins':pins,'visualGate':'Owner Pending','physicalDynamic':'blocked by lock; installation only','limitations':['32pt and 28.52pt dense board glyph readability needs human check','fixed art staff direction; no multi-direction authored pose','not all orthogonally packed neighbor arrangements tested'],'initialFailuresRetained':['AP assertion assumed 0 AP, corrected against Core auto end turn then fresh PASS','ffmpeg optional tpad duration syntax, removed extra frozen frame; final composition PASS']}
(P/'validation.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
