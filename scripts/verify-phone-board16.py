#!/usr/bin/env python3
"""Verify the actual Beta archive/export and native evidence, never assume upload."""
import hashlib,json,plistlib,re,subprocess,zipfile
from pathlib import Path
R=Path(__file__).resolve().parents[1];O=R/'artifacts/v11/phone-board-16'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
pin=json.loads((O/'SOURCE_PIN.json').read_text())
assert all(sha(R/p)==h for p,h in pin.items()), 'Beta source/build inputs changed; rebuild/revalidate before upload'
archive=O/'CrownTactics-1.1-1104.xcarchive';app=archive/'Products/Applications/TacticalGo.app';ipa=O/'Distribution/TacticalGo.ipa'
assert 'ARCHIVE SUCCEEDED' in (O/'archive.log').read_text()
assert 'EXPORT SUCCEEDED' in (O/'export.log').read_text()
info=plistlib.loads((app/'Info.plist').read_bytes())
for k,v in {'CFBundleIdentifier':'com.tacticalgo.prototype.herobody','CFBundleShortVersionString':'1.1','CFBundleVersion':'1104','CFBundleDisplayName':'皇冠戰略','ITSAppUsesNonExemptEncryption':False}.items():assert info[k]==v,(k,info.get(k))
assert info['CFBundleIcons']['CFBundlePrimaryIcon']['CFBundleIconName']=='AppIcon'
subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
profile=plistlib.loads(subprocess.check_output(['security','cms','-D','-i',str(app/'embedded.mobileprovision')]))
assert profile['Entitlements']['get-task-allow'] is False
assert profile['Entitlements']['application-identifier']=='P358EB3X9H.com.tacticalgo.prototype.herobody'
assert plistlib.loads((app/'PrivacyInfo.xcprivacy').read_bytes())==plistlib.loads((R/'ios/TacticalGo/PrivacyInfo.xcprivacy').read_bytes())
opts=plistlib.loads((O/'Distribution/ExportOptions.plist').read_bytes())
assert opts['testFlightInternalTestingOnly'] is True and opts['manageAppVersionAndBuildNumber'] is False
assets={str(p.relative_to(R/'ios/TacticalGo')):sha(p) for p in (R/'ios/TacticalGo/PresentationLab').rglob('*') if p.is_file()}
assert len(assets)==54
for rel,h in assets.items():assert sha(app/rel)==h,rel
monster=[]
for n in ['slime-token-v02.png','shadow-wolf-preview-v02.png']:
 result=json.loads(subprocess.check_output(['swift',str(R/'scripts/verify-native-png-pixels.swift'),str(R/'assets/candidates/v11-monsters/v02-preview'/n),str(app/n)]))
 assert result['equal'];monster.append({'name':n,'pixelsEqual':True,'compiledSHA256':sha(app/n)})
with zipfile.ZipFile(ipa) as z:
 exported=plistlib.loads(z.read('Payload/TacticalGo.app/Info.plist'))
 for k in ['CFBundleIdentifier','CFBundleShortVersionString','CFBundleVersion','ITSAppUsesNonExemptEncryption']:assert exported[k]==info[k]
 for rel,h in assets.items():assert hashlib.sha256(z.read('Payload/TacticalGo.app/'+rel)).hexdigest()==h,rel
 assert z.read('Payload/TacticalGo.app/PrivacyInfo.xcprivacy')==(app/'PrivacyInfo.xcprivacy').read_bytes()
native=[]
for f,count in [('main-serial-summary.json',4),('small-repaired-summary.json',1)]:
 d=json.loads((O/f).read_text());assert d['passedTests']==count and d['failedTests']==0
 native.append({'summary':f,'passed':count,'failed':0})
prior=json.loads((R/'artifacts/v11/integration-14/DELIVERY.json').read_text())
unchanged=[p for p,h in prior['sourceHashes'].items() if p.startswith('swift/') and sha(R/p)!=h]
assert unchanged==['swift/TacticalGoCore/Sources/TacticalGoVisuals/Anim01Geometry.swift'],unchanged
assert re.search(r'Executed 8 tests, with 0 failures',(O/'visual-tests.log').read_text())
assert re.search(r'Executed 239 tests, with 0 failures',(R/'artifacts/v11/integration-14/swift-final.log').read_text())
source=(R/'ios/TacticalGo/TacticalGoApp.swift').read_text()
assert '#if DEBUG ||' not in source
assert '#if DEBUG\n            let args' in (R/'ios/TacticalGo/PlayableGameView.swift').read_text()
log=(O/'archive.log').read_text();assert '-D TACTICALGO_V11' in log or '-DTACTICALGO_V11' in log
upload=(O/'upload.log').read_text() if (O/'upload.log').exists() else ''
runs=sorted(O.glob('upload-*/exit-code.txt'))
uploadExit=int(runs[-1].read_text()) if runs else None
def uploadSucceeded(log,exitCode):
 return exitCode==0 and 'Upload succeeded.' in log and '** EXPORT SUCCEEDED **' in log
# An exported IPA alone does not prove an upload.
assert not uploadSucceeded((O/'export.log').read_text(),0)
completed=uploadSucceeded(upload,uploadExit)
blocked='Failed to Use Accounts' in upload or 'No Accounts' in upload
receipt={'schema':'tacticalgo-phone-board-16-v1','version':'1.1','build':'1104','appID':'6821588889','bundle':info['CFBundleIdentifier'],'archive':str(archive.relative_to(R)),'ipa':str(ipa.relative_to(R)),'ipaSHA256':sha(ipa),'ipaBytes':ipa.stat().st_size,'signature':'verified_distribution_getTaskAllow_false','privacyManifest':'present_local_settings_elapsed_animation_timers','presentationAssetsUnchanged':54,'compiledMonsters':monster,'nativeBeta':native,'nativeRunCondition':'No DEBUG launch fixture flags; actual lobby and practice menu','priorFullSwiftEvidence':{'passed':239,'failed':0,'rulesSourcesUnchanged':True,'visualGeometryChangedAndTested':True,'ref':'artifacts/v11/integration-14/DELIVERY.json'},'internalTestFlightOnly':True,'uploaded':completed,'uploadExit':uploadExit,'uploadBlockedByAccount':blocked,'appleProcessingVerified':False,'ownerGroupAvailabilityVerified':False,'publicRelease':False,'submittedForAppReview':False,'humanQualityAcceptance':False,'sourceHashes':{str(p.relative_to(R)):sha(p) for p in (R/'ios/TacticalGo').rglob('*.swift')},'visualTests':{'passed':8,'failed':0},'failureEvidenceRetained':['Phone-native.xcresult','Phone-final.xcresult','Phone-corners-repaired.xcresult','Small-native.xcresult','TEST_RUN_NOTES.md'],'notes':['Final main run is serial with 4/0; small run separately 1/0. Earlier overlapping main runners and test-input mistakes are excluded.','1.0 submission/worktree/archive untouched.','1103 remains available as prior comparison build. New 1104 is not a physical-phone acceptance claim.']}
if (O/'ASC_BUILD.json').exists():
 receipt['appleBuild'] = json.loads((O/'ASC_BUILD.json').read_text())
 receipt['appleProcessingVerified'] = completed and receipt['appleBuild']['processingComplete']
if (O/'ASC_GROUP.json').exists():
 receipt['ownerGroup'] = json.loads((O/'ASC_GROUP.json').read_text())
 receipt['ownerGroupAvailabilityVerified'] = completed and receipt['ownerGroup']['build1104Available']
(O/'DELIVERY.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:receipt[k] for k in ['version','build','signature','presentationAssetsUnchanged','nativeBeta','internalTestFlightOnly','uploaded','uploadBlockedByAccount']},ensure_ascii=False))
