#!/usr/bin/env python3
"""Saved delivery integrity, distinct from behavior tests and Owner approval."""
import hashlib,json,plistlib,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'artifacts/v11/voice-06'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for pins in ['artifacts/v11/audio-05/animation-baseline-hashes.json','artifacts/v11/present-01/baseline-hashes.json']:
    for p,h in json.loads((ROOT/pins).read_text()).items():assert sha(ROOT/p)==h,p
voice=ROOT/'assets/candidates/voice-06'
m=json.loads((voice/'manifest.json').read_text())
assert sha(ROOT/m['source'])==m['source_sha256']
assert m['model_sha256']==json.loads((ROOT/'assets/candidates/present-01/sources/voice-source-manifest.json').read_text())['model_sha256']
assert m['offline_inference'] and m['reference_audio'] is None
for x in m['assets']:
    assert x['text']=='Move aside!'
    assert sha(voice/x['file'])==x['sha256'] and sha(voice/x['raw_file'])==x['raw_sha256']
    assert x['peak_dbfs']<0 and .5<x['duration_seconds']<1.6
assert all(x['match'] for x in json.loads((voice/'ASR-CHECK.json').read_text())['checks'])
for x in json.loads((voice/'mix-manifest.json').read_text())['takes']:
    assert sha(ROOT/x['file'])==x['sha256'] and x['peak_dbfs']<-3
cases=[]
def visit(n):
    if n.get('nodeType')=='Test Case':cases.append(n)
    for child in n.get('children',[]):visit(child)
for n in json.loads((OUT/'ui-native-B-results.json').read_text())['testNodes']:visit(n)
assert len(cases)==8 and all(c['result']=='Passed' for c in cases)
assert 'Executed 8 tests, with 0 failures' in (OUT/'ui-native-B.log').read_text()
assert 'Executed 37 tests, with 0 failures' in (ROOT/'artifacts/v11/audio-05/swift-tests.log').read_text()
for path,marker in [('ios-build-B.log','** TEST BUILD SUCCEEDED **'),('ios-release.log','** BUILD SUCCEEDED **'),('device-build-B.log','** BUILD SUCCEEDED **')]:assert marker in (OUT/path).read_text()
debug=ROOT/'ios/Build/Products/Debug-iphonesimulator/TacticalGo.app'
phone=OUT/'DeviceProducts/Debug-iphoneos/TacticalGo.app'
for take in ['A','B']:
    expected=sha(voice/f'mage-{take}-dry.wav')
    assert all(sha(p/'PresentationLab/P06'/f'mage-cast-{take}.wav')==expected for p in [ROOT/'ios/TacticalGo',debug,phone])
for name,h in json.loads((ROOT/'ios/TacticalGo/PresentationLab/P02/pins.json').read_text()).items():
    assert all(sha(p/'PresentationLab/P02'/name)==h for p in [debug,phone])
for source in (ROOT/'ios/TacticalGo/PresentationLab/P05').glob('*.wav'):
    assert all(sha(p/'PresentationLab/P05'/source.name)==sha(source) for p in [debug,phone])
for x in json.loads((ROOT/'assets/candidates/present-04/audio/manifest.json').read_text())['original_samples']:
    assert all(sha(p/'Audio'/(x['key']+'.wav'))==x['sha256'] for p in [ROOT/'ios/TacticalGo',debug,phone])
assert not (ROOT/'ios/Build/Products/Release-iphonesimulator/TacticalGo.app/PresentationLab').exists()
assert plistlib.loads((phone/'Info.plist').read_bytes())['CFBundleIdentifier']=='com.tacticalgo.prototype.presentationlab'
for name in ['device-install-B.json','device-launch-B.json']:assert json.loads((OUT/name).read_text())['info']['outcome']=='success'
sources=['ios/TacticalGo/PresentationLabView.swift','ios/TacticalGoUITests/PresentationLabTests.swift','scripts/generate-mage-cast-voice.py','scripts/transcribe-mage-cast-voice.py','scripts/build-mage-cast-preview.py','scripts/verify-mage-cast-evidence.py']
(OUT/'source-final-hashes.json').write_text(json.dumps({p:sha(ROOT/p) for p in sources},indent=2)+'\n')
assert 'var castTake = "B"' in (ROOT/'ios/TacticalGo/PresentationLabView.swift').read_text()
result=dict(scope='saved evidence integrity; not new listening or behavioral test',native='8/0 B-default',motion_saved='37/0',animation_accepted_and_unchanged=True,core_rules_unchanged_this_slice=True,new_voice_takes=2,language='English',text='Move aside!',default_take='B',owner_listening='B relatively preferred; final quality pending',phone_candidate='installed and launched',normal_phone_app_modified_by_this_slice=False,release_lab_excluded=True,phone_live_av_recording=False,preview='accepted native D with new authored postmix',commit_push_merge_release=False)
(OUT/'delivery-verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
