#!/usr/bin/env python3
"""Saved evidence/resource integrity; does not prove artistic or audio quality."""
import hashlib,json,plistlib,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'artifacts/v11/present-04'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for p,h in json.loads((ROOT/'artifacts/v11/present-01/baseline-hashes.json').read_text()).items(): assert sha(ROOT/p)==h,p
assert 'Executed 36 tests, with 0 failures' in (OUT/'swift-tests-final.log').read_text()
assert 'Executed 6 tests, with 0 failures' in (OUT/'ui-native.log').read_text()
cases=[]
def visit(n):
    if n.get('nodeType')=='Test Case':cases.append(n)
    for child in n.get('children',[]):visit(child)
for n in json.loads((OUT/'ui-native-results.json').read_text())['testNodes']:visit(n)
assert len(cases)==6 and all(c['result']=='Passed' for c in cases)
for name,marker in [('ios-build-predecoded.log','** TEST BUILD SUCCEEDED **'),('ios-release-final.log','** BUILD SUCCEEDED **'),('device-build-final.log','** BUILD SUCCEEDED **')]:assert marker in (OUT/name).read_text()
debug=ROOT/'ios/Build/Products/Debug-iphonesimulator/TacticalGo.app';phone=OUT/'DeviceProducts/Debug-iphoneos/TacticalGo.app'
pins=json.loads((ROOT/'ios/TacticalGo/PresentationLab/P02/pins.json').read_text())
for name,h in pins.items():assert all(sha(p/'PresentationLab/P02'/name)==h for p in [debug,phone]),name
manifest=json.loads((ROOT/'assets/candidates/present-04/audio/manifest.json').read_text())
for src in manifest['original_samples']:assert all(sha(p/'Audio'/(src['key']+'.wav'))==src['sha256'] for p in [ROOT/'ios/TacticalGo',debug,phone])
resources=['arcane-hand-atlas.png','p4-conjure.wav','p4-push.wav','p4-contact.wav']
for name in resources:
    expected=sha(ROOT/'ios/TacticalGo/PresentationLab/P04'/name)
    assert all(sha(p/'PresentationLab/P04'/name)==expected for p in [debug,phone]),name
assert not (ROOT/'ios/Build/Products/Release-iphonesimulator/TacticalGo.app/PresentationLab').exists()
for f in manifest['files']+manifest['previews']:assert sha(ROOT/f['file'])==f['sha256'] and f['peak_dbfs']<0
assert manifest['voice'] is False and manifest['bgm'] is False
for name in ['device-install-final.json','device-launch-final.json']:assert json.loads((OUT/name).read_text())['info']['outcome']=='success'
info=plistlib.loads((phone/'Info.plist').read_bytes());assert info['CFBundleIdentifier']=='com.tacticalgo.prototype.presentationlab'
assert 'satisfies its Designated Requirement' in (OUT/'codesign-verify-final.log').read_text()
clips=json.loads((OUT/'video-aligned/manifest.json').read_text());assert len(clips)==5
for v in clips:
    assert (ROOT/v['raw']).exists() and (ROOT/v['postmix']).exists()
    assert v['alignment']['fps']==60 and v['alignment']['frame']>0
    stream=json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-show_entries','stream=duration,nb_frames','-of','json',str(ROOT/v['postmix'])]))['streams'][0]
    assert abs(float(stream['duration'])-1.85)<.02 and int(stream['nb_frames'])==111
paths=['swift/TacticalGoCore/Sources/TacticalGoMotion/ArcaneHandFrame.swift','swift/TacticalGoCore/Sources/TacticalGoMotion/MagePresentationPlan.swift','ios/TacticalGo/PresentationMageBody.swift','ios/TacticalGo/PresentationLabView.swift','ios/TacticalGoUITests/PresentationLabTests.swift','swift/TacticalGoCore/Tests/TacticalGoMotionTests/ArcaneHandTests.swift','scripts/build-arcane-hand-audio.py','scripts/record-arcane-hand-preview.py','scripts/locate-presentation-video-onset.swift','scripts/align-arcane-hand-preview.py']
(OUT/'source-final-hashes.json').write_text(json.dumps({p:sha(ROOT/p) for p in paths},indent=2)+'\n')
result=dict(kind='Saved engineering evidence integrity; not another behavioral or quality test',motion='36/0',native='6/0 (includes1 retained C diagnostic)',core_rules_unchanged_this_slice=True,phone_baseline_art_pins=len(pins),p04_resource_hash_matches=len(resources),original_sfx_byte_identical=True,release_lab_absent=True,candidate_phone_install_launch='success',bundle=info['CFBundleIdentifier'],normal_phone_app_modified_by_this_slice=False,original_native_clips_retained=5,aligned_postmix_clips=5,alignment='Native success-label frame,60fps; device AV sync not calibrated',owner_art_acting_listening='pending',phone_live_recording='not produced',other_classes_full_match_integration='not done',commit_push_merge_release=False)
(OUT/'delivery-verification.json').write_text(json.dumps(result,indent=2)+'\n')
print('Saved Motion36/0, native6/0, builds, pinned baseline, candidate resources, separate phone install/launch and5 native-aligned clips verified. Quality not claimed.')
