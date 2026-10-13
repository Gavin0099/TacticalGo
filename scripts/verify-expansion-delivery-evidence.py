#!/usr/bin/env python3
"""Verify saved candidate evidence without substituting it for Owner acceptance."""
import array,hashlib,json,math,plistlib,re,subprocess,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'artifacts/v11/feel-10'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads((ROOT/p).read_text())
def passed_summary(p,count):
 s=read(p);assert s['result']=='Passed' and s['passedTests']==count and s['failedTests']==0,p
assert 'Executed 235 tests, with 0 failures' in (ROOT/'artifacts/v11/expansion-08/swift-content-final.log').read_text()
# The full Swift run remains applicable: its production package inputs are unchanged.
for path,h in read('artifacts/v11/expansion-08/source-milestone-hashes.json').items():
 if path.startswith('swift/'):assert sha(ROOT/path)==h,path
passed_summary('artifacts/v11/expansion-08/native-feel-first-summary.json',20)
passed_summary('artifacts/v11/feel-10/native-final-summary.json',10)
passed_summary('artifacts/v11/feel-10/frozen-review-summary.json',2)
passed_summary('artifacts/v11/feel-10/expansion-final-summary.json',8)
initial=(ROOT/'artifacts/v11/expansion-08/ui-feel-first.log').read_text()
final=(OUT/'native-final.log').read_text();exp=(OUT/'expansion-final.log').read_text()
assert 'Executed 8 tests, with 0 failures' in exp
assert 'Executed 4 tests, with 0 failures' in final
assert 'Executed 8 tests, with 0 failures' in initial and 'Executed 7 tests, with 0 failures' in initial
tests=set()
for log in [initial,final,exp]:
 tests.update(re.findall(r"Test Case '-\[(TacticalGoUITests\.[^\]]+)\]' passed",log))
assert len(tests)==27,sorted(tests)
for path,h in read('artifacts/v11/audio-05/animation-baseline-hashes.json').items():assert sha(ROOT/path)==h,path
for path,h in read('ios/TacticalGo/PresentationLab/P02/pins.json').items():assert sha(ROOT/'ios/TacticalGo/PresentationLab/P02'/path)==h,path
voice=ROOT/'assets/candidates/feel-10/voice';m=read('assets/candidates/feel-10/voice/manifest.json')
assert sha(ROOT/m['source'])==m['source_sha256']
assert len(m['model_sha256'])==14 and m['model_sha256']==read('assets/candidates/warrior-07/voice/manifest.json')['model_sha256']
assert m['offline_inference'] and not m['paid_service'] and m['reference_audio'] is None
for x in m['assets']:
 assert sha(voice/x['file'])==x['sha256'] and sha(voice/x['raw_file'])==x['raw_sha256']
 assert x['text']=={'rogue':'Too slow!','priest':'Stay with me!'}[x['hero']]
 assert x['peak_dbfs']<=-2.99
 assert sha(ROOT/'ios/TacticalGo/PresentationLab/P08'/f"p8-voice-{x['hero']}-{x['take']}.wav")==x['sha256']
asr=read('assets/candidates/feel-10/voice/ASR-CHECK.json')
assert len(asr['checks'])==4 and all(x['match'] for x in asr['checks']) and asr['target_prompt'] is None
mix=read('assets/candidates/feel-10/audio/manifest.json')
for x in mix['sources']:assert sha(ROOT/x['archive'])==x['sha256']
for x in mix['processing']:assert sha(ROOT/'assets/candidates/feel-10/audio/raw'/x['source'])==x['source_sha256']
for x in mix['files']+mix['previews']:
 assert sha(ROOT/x['file'])==x['sha256']
 with wave.open(str(ROOT/x['file'])) as f:
  assert f.getnchannels()==1 and f.getsampwidth()==2
  v=array.array('h');v.frombytes(f.readframes(f.getnframes()))
 peak=max(map(abs,v))/32767;assert 0<peak<.95
 if 'peak_dbfs' in x:assert abs(20*math.log10(peak)-x['peak_dbfs'])<.04
for x in read('assets/candidates/priest-08/v02/qa/pixels.json'):
 assert sha(ROOT/x['file'])==x['fileSHA256'] and x['alpha'] and x['transparentPixels']>0
assert sha(ROOT/'ios/TacticalGo/PresentationLab/P08/priest-v02.png')==sha(ROOT/'assets/candidates/priest-08/v02/priest-v02.png')
assert sha(ROOT/'ios/TacticalGo/PresentationLab/P08/priest-clean-plate-v02.png')==sha(ROOT/'assets/candidates/priest-08/v02/priest-clean-plate-v02.png')
assert sha(ROOT/'ios/TacticalGo/PresentationLab/P08/rogue-clean-plate.png')=='3fb0d19330e3830c97790208ac875ed6cb41fe5e5119f0289c8625138e5273da'
native=read('artifacts/v11/feel-10/native/manifest.json');assert len(native)==14 and len({x['sha256'] for x in native})==14
for x in native:assert sha(ROOT/x['file'])==x['sha256'] and x['white_pixel_fraction']<.50
videos=read('artifacts/v11/feel-10/video/manifest.json');assert len(videos)==6
for x in videos:
 assert sha(ROOT/x['raw'])==x['raw_sha256'] and sha(ROOT/x['postmix'])==x['postmix_sha256']
 assert 'EXPANSION_RECEIPT' in (ROOT/x['clock']).read_text()
 assert '1AP' in x['onset']['confirmed_text']
 assert x['audio'] and (ROOT/x['audio']).exists()
for name in ['device-frozen-final.log','release-frozen-final.log']:assert '** BUILD SUCCEEDED **' in (OUT/name).read_text()
debug=ROOT/'ios/Build/Products/Debug-iphonesimulator/TacticalGo.app'
phone=OUT/'DeviceProducts/Debug-iphoneos/TacticalGo.app'
release=OUT/'ReleaseProducts/Release-iphoneos/TacticalGo.app'
for path in (ROOT/'ios/TacticalGo/PresentationLab').rglob('*'):
 if path.is_file():
  relative=path.relative_to(ROOT/'ios/TacticalGo')
  for app in [debug,phone]:assert (app/relative).is_file() and sha(app/relative)==sha(path),(app,relative)
compiled=[]
for name in ['slime-token-v02.png','shadow-wolf-preview-v02.png']:
 source=ROOT/'assets/candidates/v11-monsters/v02-preview'/name
 for app in [debug,phone]:
  pixel=json.loads(subprocess.check_output(['swift',str(ROOT/'scripts/verify-native-png-pixels.swift'),str(source),str(app/name)]))
  assert pixel['equal'],name
  compiled.append(dict(source=str(source.relative_to(ROOT)),sourceFileSHA=sha(source),compiled=str((app/name).relative_to(ROOT)),compiledFileSHA=sha(app/name),nativeVisiblePixels=pixel))
 assert not (release/name).exists()
(OUT/'compiled-monster-pixels.json').write_text(json.dumps(compiled,indent=2)+'\n')
assert not (release/'PresentationLab').exists()
info=plistlib.loads((phone/'Info.plist').read_bytes())
assert info['CFBundleIdentifier']=='com.tacticalgo.prototype.presentationlab' and info['CFBundleDisplayName']=='TacticalGo 聲畫'
subprocess.run(['codesign','--verify','--deep','--strict',str(phone)],check=True,capture_output=True)
install=read('artifacts/v11/feel-10/device-install-corrected.json')
assert install['info']['outcome']=='success' and install['result']['installedApplications'][0]['bundleID']==info['CFBundleIdentifier']
launch=read('artifacts/v11/feel-10/device-launch-final.json')
assert launch['info']['outcome']=='failed' and 'Locked' in json.dumps(launch)
subprocess.run(['git','diff','--check'],cwd=ROOT,check=True)
sources={}
for directory in ['swift/TacticalGoCore/Sources','swift/TacticalGoCore/Tests','ios/TacticalGo','ios/TacticalGoUITests']:
 for p in (ROOT/directory).rglob('*.swift'):sources[str(p.relative_to(ROOT))]=sha(p)
for p in [ROOT/'ios/TacticalGo.xcodeproj/project.pbxproj',Path(__file__),ROOT/'scripts/verify-native-png-pixels.swift',ROOT/'scripts/capture-expansion-static-review.py']:sources[str(p.relative_to(ROOT))]=sha(p)
(OUT/'delivery-source-hashes.json').write_text(json.dumps(sources,indent=2)+'\n')
result=dict(scope='1.1 local playable candidate; engineering delivery, not release or Owner acceptance',swift='235/0; production package inputs unchanged since full run',native_distinct='27/0: expansion8 + monster7 + mage8 + warrior4',native_current_expansion='8/0 after frozen/resume fixes',accepted_mage_warrior_baseline='preserved',art_review='14 actual native static frames; two failed capture sets excluded and retained',videos='6 actual native silent captures plus authored audio postmix; no phone latency claim',voice='4 independent unprompted word checks, raw/dry A/B; acting pending',release='build pass; candidate art/audio resources absent',candidate_bundle=info['CFBundleIdentifier'],candidate_installed=True,phone_launch='not verified; last launch denied because locked',physical_av_recording='not done',local_two_player=True,expansion_bot='not implemented; original Bot rejects expansion',commit_push_merge_release=False,owner_fun_art_voice_balance_rights='pending')
(OUT/'delivery-verification.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
