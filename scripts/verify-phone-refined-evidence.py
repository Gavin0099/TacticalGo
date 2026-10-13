#!/usr/bin/env python3
"""Verify PRESENT-03 saved checksums/receipts; not a new behavioral test run."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artifacts/v11/present-03'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for p,digest in json.loads((ROOT/'artifacts/v11/present-01/baseline-hashes.json').read_text()).items():
    assert sha(ROOT/p)==digest,'Core/rules changed: '+p
for p,digest in json.loads((OUT/'source-final-hashes.json').read_text()).items():
    assert sha(ROOT/p)==digest,'Validated source changed: '+p
assert 'Executed 33 tests, with 0 failures' in (OUT/'swift-tests-final.log').read_text()
assert '** TEST BUILD SUCCEEDED **' in (OUT/'ios-build-review.log').read_text()
assert '** BUILD SUCCEEDED **' in (OUT/'ios-release.log').read_text()
assert '** BUILD SUCCEEDED **' in (OUT/'device-build.log').read_text()

def cases(path):
    results=[]
    def visit(n):
        if n.get('nodeType')=='Test Case':results.append(n)
        for c in n.get('children',[]):visit(c)
    for n in json.loads(path.read_text())['testNodes']:visit(n)
    return results
native=cases(OUT/'ui-final-results.json'); small=cases(OUT/'ui-small-final-results.json')
assert len(native)==4 and all(c['result']=='Passed' for c in native)
assert len(small)==1 and small[0]['result']=='Passed'

debug=ROOT/'ios/Build/Products/Debug-iphonesimulator/TacticalGo.app'
phone=OUT/'DeviceProducts/Debug-iphoneos/TacticalGo.app'
pins=json.loads((ROOT/'ios/TacticalGo/PresentationLab/P02/pins.json').read_text())
for name,digest in pins.items():
    assert all(sha(p/'PresentationLab/P02'/name)==digest for p in [debug,phone])
audio=json.loads((ROOT/'assets/candidates/present-03/audio/manifest.json').read_text())
for src in audio['original_samples']:
    assert all(sha(p/'Audio'/(src['key']+'.wav'))==src['sha256'] for p in [ROOT/'ios/TacticalGo',debug,phone])
for p in [ROOT/'ios/TacticalGo',debug,phone]:
    assert sha(p/'PresentationLab/P03/p3-air.wav')==audio['resource_sha256']
assert sha(ROOT/'assets/candidates/present-03/audio/raw/sand-spell.flac')==audio['source']['sha256']
assert audio['voice'] is False
for preview in audio['previews']:
    assert sha(ROOT/preview['file'])==preview['sha256'] and preview['peak_dbfs']<0
assert not (ROOT/'ios/Build/Products/Release-iphonesimulator/TacticalGo.app/PresentationLab').exists()
install=json.loads((OUT/'device-install.json').read_text())
launch=json.loads((OUT/'device-launch.json').read_text())
assert install['info']['outcome']=='success' and launch['info']['outcome']=='success'
assert 'com.tacticalgo.prototype.presentationlab' in (OUT/'device-install.log').read_text()
assert 'satisfies its Designated Requirement' in (OUT/'codesign-verify.log').read_text()

videos=json.loads((OUT/'video/manifest.json').read_text())
assert len(videos)==5
for v in videos:
    assert (ROOT/v['raw']).is_file() and (ROOT/v['postmix']).is_file()
    info=json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-show_entries','stream=duration,nb_frames','-of','json',str(ROOT/v['postmix'])]))['streams'][0]
    assert abs(float(info['duration'])-1.65)<0.02 and int(info['nb_frames'])==99
result={'kind':'Saved evidence integrity verification, not another behavioral test run',
        'motion':'33/0','native':'4/0 + separate small review1/0',
        'reference_art_pins':len(pins),'new_audio_stems':1,'original_sfx_unchanged':True,
        'debug_device_resource_hashes':'match','release_candidate_folder_absent':True,
        'core_rules_unchanged':True,'candidate_phone_install_and_launch':'success',
        'candidate_bundle':'com.tacticalgo.prototype.presentationlab','normal_phone_app_modified':False,
        'native_simulator_clips':len(videos),'sound_preview':'postmix, not physical capture',
        'owner_quality_acceptance':'pending','commit_push_merge_release':False}
(OUT/'delivery-verification.json').write_text(json.dumps(result,indent=2)+'\n')
print('PRESENT-03 saved native evidence, asset pins and separate phone delivery verification PASS.')
