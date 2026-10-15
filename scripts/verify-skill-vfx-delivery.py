"""Verify executed engineering evidence and source pins; never a human VFX verdict."""
import hashlib,json,pathlib,re,subprocess
R=pathlib.Path(__file__).resolve().parents[1];D=R/'artifacts/ios/vfx-three-classes-01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads((D/p).read_text())
def test(name,count):
 p=D/name;t=p.read_text();assert re.search(r'Executed '+str(count)+r' tests?, with 0 failures',t),name
 assert '** TEST EXECUTE SUCCEEDED **' in t or "All tests' passed" in t,name
 return {'executed':count,'failures':0,'log':name,'sha256':sha(p)}
manifest=json.loads((R/'assets/candidates/vfx-three-classes-01/manifest.json').read_text())
for pin in manifest['sources']:assert sha(R/pin['path'])==pin['sha256'],pin
protected=['swift/TacticalGoCore/Sources/TacticalGoCore','swift/TacticalGoCore/Sources/TacticalGoBot','ios/TacticalGo/BoardProjection.swift','ios/TacticalGo/GameStore.swift']
assert not subprocess.check_output(['git','diff',manifest['baseline'],'--']+protected,cwd=R,text=True).strip()
audit=read('skill-vfx-strong-03-audit.json')
assert audit['status']=='PASS' and len(audit['checks'])==156 and all(x['pass'] for x in audit['checks'])
assert audit['revision']=='finite-bursts-03' and audit['runID'] and audit['completedUnix']>audit['startedUnix']
clips=read('media-strong-final/edit-audit.json')['clips'];assert len(clips)==18
for x in clips:
 assert x['speed']==1 and 'encoded' in x['alignment']
 assert sha(R/x['file'])==x['sha256']
 assert x['before']['ap']==2 and x['after']['ap']==1
 if x['class']=='MAGICHAND':
  for key,value in manifest['timingSeconds']['magicHand'].items():assert abs(x['timing'][key]-value)<1e-6,(key,x)
assert 'PASS: 137 C#/Swift snapshots match' in (D/'golden-strong-compare.log').read_text()
assert '** BUILD SUCCEEDED **' in (D/'release-strong.log').read_text()
evidence={'engineeringStatus':'PASS','OwnerVisualStatus':'PENDING after weak first candidate rejected',
 'package':test('package-strong-final.log',177),'nativeReceipt':test('native-strong-03-audit.log',1),
 'nativeSmall':test('native-strong-final-se.log',1),'nativeRecording':test('media-strong-final/native-record-test.log',1),
 'nativeBot':test('native-strong-final-bot.log',1),'physicalIPhone':test('native-strong-iphone.log',2),'stateChecks':156,'nativeCheckpoints':len(audit['renders']),
 'golden':{'snapshots':137,'fixtures':38,'Swift':'fresh','CSharp':'cached, not rerun; equivalence does not establish rule correctness'},
 'clips':18,'audio':'silent; no reconstructed sound; English voice off',
 'physical':read('physical-status.json'),
 'protected':protected,'limits':['No Domain/Bot/projection/identity changes','No second skill, music integration or new voice','No merge/TestFlight/release','No FPS or human performance claim'],
 'auditRunID':audit['runID'],'identityPins':manifest['sources']}
(D/'delivery-verification.json').write_text(json.dumps(evidence,indent=2)+'\n')
print('PASS: 177 Swift tests; 137 equivalence snapshots; 4 nonzero native tests,156 checks;18 encoded-frame-aligned clips. Human VFX Gate not inferred.')
