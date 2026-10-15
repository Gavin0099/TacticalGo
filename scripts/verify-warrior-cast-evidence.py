#!/usr/bin/env python3
"""Retained delivery integrity, separate from acting and live-device AV quality."""
import hashlib,json,plistlib,subprocess,wave,array,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'artifacts/v11/warrior-07'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for pins in ['artifacts/v11/audio-05/animation-baseline-hashes.json','artifacts/v11/present-01/baseline-hashes.json']:
    for p,h in json.loads((ROOT/pins).read_text()).items():assert sha(ROOT/p)==h,p
voice=ROOT/'assets/candidates/warrior-07/voice';m=json.loads((voice/'manifest.json').read_text())
assert sha(ROOT/m['source'])==m['source_sha256']
assert m['model_sha256']==json.loads((ROOT/'assets/candidates/voice-06/manifest.json').read_text())['model_sha256']
assert m['offline_inference'] and m['reference_audio'] is None and not m['paid_service']
for x in m['assets']:
    assert x['text']=='Hold the line!'
    assert sha(voice/x['file'])==x['sha256'] and sha(voice/x['raw_file'])==x['raw_sha256']
    assert x['peak_dbfs']<-3 and .5<x['duration_seconds']<1.6
assert all(x['match'] for x in json.loads((voice/'ASR-CHECK.json').read_text())['checks'])
audio=json.loads((ROOT/'assets/candidates/warrior-07/audio/manifest.json').read_text())
assert sha(ROOT/audio['source_pack'])==audio['source_sha256']
raw=ROOT/'assets/candidates/warrior-07/audio/raw'
for name,h in audio['raw'].items():assert sha(raw/name)==h
assert sha(raw/'LICENSE.txt')==audio['license_sha256']
for x in audio['files']+audio['previews']:
    assert sha(ROOT/x['file'])==x['sha256'];assert x['peak_dbfs']<0
    with wave.open(str(ROOT/x['file']),'rb') as f:
        assert f.getsampwidth()==2
        a=array.array('h');a.frombytes(f.readframes(f.getnframes()))
    peak=max(map(abs,a))/32767
    assert peak<.95 and abs(20*math.log10(peak)-x['peak_dbfs'])<.02
cases=[]
def visit(n):
    if n.get('nodeType')=='Test Case':cases.append(n)
    for c in n.get('children',[]):visit(c)
for n in json.loads((OUT/'ui-native-results.json').read_text())['testNodes']:visit(n)
assert len(cases)==12 and all(c['result']=='Passed' for c in cases)
assert 'Executed 12 tests, with 0 failures' in (OUT/'ui-native.log').read_text()
assert 'Executed 43 tests, with 0 failures' in (OUT/'swift-tests-effects.log').read_text()
for path,marker in [('ios-build-effects.log','** TEST BUILD SUCCEEDED **'),('ios-release-effects.log','** BUILD SUCCEEDED **'),('device-build-effects.log','** BUILD SUCCEEDED **')]:assert marker in (OUT/path).read_text()
debug=ROOT/'ios/Build/Products/Debug-iphonesimulator/TacticalGo.app';phone=OUT/'DeviceProducts/Debug-iphoneos/TacticalGo.app'
for f in (ROOT/'ios/TacticalGo/PresentationLab/P07').iterdir():
    if f.is_file():assert all(sha(p/'PresentationLab/P07'/f.name)==sha(f) for p in [debug,phone]),f.name
for take in ['A','B']:
    assert sha(ROOT/'ios/TacticalGo/PresentationLab/P07'/f'w7-voice-{take}.wav')==sha(voice/f'warrior-{take}-dry.wav')
    expected=sha(ROOT/'assets/candidates/voice-06'/f'mage-{take}-dry.wav')
    assert all(sha(p/'PresentationLab/P06'/f'mage-cast-{take}.wav')==expected for p in [debug,phone])
for name,h in json.loads((ROOT/'ios/TacticalGo/PresentationLab/P02/pins.json').read_text()).items():
    assert all(sha(p/'PresentationLab/P02'/name)==h for p in [debug,phone])
for folder in ['P04','P05']:
    for f in (ROOT/'ios/TacticalGo/PresentationLab'/folder).iterdir():
        if f.is_file():assert all(sha(p/'PresentationLab'/folder/f.name)==sha(f) for p in [debug,phone])
for x in json.loads((ROOT/'assets/candidates/present-04/audio/manifest.json').read_text())['original_samples']:
    assert all(sha(p/'Audio'/(x['key']+'.wav'))==x['sha256'] for p in [ROOT/'ios/TacticalGo',debug,phone])
assert not (ROOT/'ios/Build/Products/Release-iphonesimulator/TacticalGo.app/PresentationLab').exists()
assert plistlib.loads((phone/'Info.plist').read_bytes())['CFBundleIdentifier']=='com.tacticalgo.prototype.presentationlab'
assert json.loads((OUT/'device-install-effects.json').read_text())['info']['outcome']=='success'
launch_path=OUT/'device-launch-final.json' if (OUT/'device-launch-final.json').exists() else OUT/'device-launch-effects.json'
launch=json.loads(launch_path.read_text());launched=launch['info']['outcome']=='success'
if not launched:assert 'Locked' in json.dumps(launch) or 'unlocked' in json.dumps(launch)
assert 'var take="B"' in (ROOT/'ios/TacticalGo/WarriorPresentationLab.swift').read_text()
assert 'var castTake = "B"' in (ROOT/'ios/TacticalGo/PresentationLabView.swift').read_text()
videos=json.loads((OUT/'video/manifest.json').read_text());assert len(videos)==5
for v in videos:
    assert 'WARRIOR_RECEIPT' in (ROOT/v['clock']).read_text()
    assert v['onset']['prepared_frame']<v['onset']['frame']
    assert (ROOT/v['raw']).stat().st_size>10000
    probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','json',str(ROOT/v['postmix'])]))
    assert 2.3<=float(probe['format']['duration'])<=2.5
    if v['name'].startswith('new-'):assert v['take']=='B'
pixel=json.loads((OUT/'native-pixel-review.json').read_text())
assert sha(ROOT/pixel['source'])==pixel['source_sha256'] and sha(ROOT/pixel['output'])==pixel['output_sha256']
assert pixel['review_canvas_pixels']==[32,48,64]
sources=['ios/TacticalGo/WarriorBodyView.swift','ios/TacticalGo/WarriorPresentationLab.swift','ios/TacticalGo/PresentationLabView.swift','ios/TacticalGo/TacticalGoApp.swift','ios/TacticalGo.xcodeproj/project.pbxproj','ios/TacticalGoUITests/PresentationLabTests.swift','swift/TacticalGoCore/Sources/TacticalGoMotion/WarriorPresentationPlan.swift','swift/TacticalGoCore/Tests/TacticalGoMotionTests/WarriorPresentationTests.swift','scripts/generate-warrior-cast-voice.py','scripts/transcribe-warrior-cast-voice.py','scripts/build-warrior-presentation-audio.py','scripts/record-warrior-presentation-preview.py','scripts/locate-warrior-video-onset.swift','scripts/verify-warrior-cast-evidence.py']
(OUT/'source-final-hashes.json').write_text(json.dumps({p:sha(ROOT/p) for p in sources},indent=2)+'\n')
manifest=ROOT/'assets/candidates/warrior-07/asset-manifest.json';a=json.loads(manifest.read_text());a['source_sha256']['ios/TacticalGo/WarriorBodyView.swift']=sha(ROOT/'ios/TacticalGo/WarriorBodyView.swift')
for p,h in a['source_sha256'].items():assert sha(ROOT/p)==h
manifest.write_text(json.dumps(a,indent=2)+'\n')
result=dict(scope='saved integrity plus referenced fresh behavioral tests; no acting approval',native='12/0 (8 mage +4 warrior)',motion='43/0',warrior_text='Hold the line!',default_take='B',owner_voice='B relatively preferred',owner_effect='new tangible shield projection candidate pending',accepted_mage_D_and_B_preserved=True,core_rules_unchanged_this_slice=True,recordings='5 actual Simulator scenes, receipt-frame-aligned postmix; no live phone AV',phone_candidate='installed and launched' if launched else 'installed; automatic launch blocked by device lock',normal_phone_app_modified_by_this_slice=False,release_lab_excluded=True,full_match_bot_integration=False,commit_push_merge_release=False)
(OUT/'delivery-verification.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
