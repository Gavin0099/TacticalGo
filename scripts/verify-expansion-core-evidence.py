#!/usr/bin/env python3
"""Saved Core/record/motion/UI evidence: bounded claims, no Owner Gate or physical-media pass."""
import hashlib,json,re,wave,array,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'artifacts/v11/expansion-08'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
log=(OUT/'swift-content-final.log').read_text();assert 'Executed 235 tests, with 0 failures' in log and "Test Suite 'All tests' passed" in log
for name in ['priest-counter-first.log','monster-integration-first.log','record-second.log','pose-first.log','review-fixture-first.log']:assert 'with 0 failures' in (OUT/name).read_text()
ui=json.loads((OUT/'native-feel-first-summary.json').read_text());assert ui['passedTests']==20 and ui['failedTests']==0 and ui['result']=='Passed'
assert 'Executed 5 tests, with 0 failures' in (OUT/'ui-feel-first.log').read_text()
assert 'Executed 7 tests, with 0 failures' in (OUT/'ui-feel-first.log').read_text()
assert 'Executed 8 tests, with 0 failures' in (OUT/'ui-feel-first.log').read_text()
assert '** TEST BUILD SUCCEEDED **' in (OUT/'feel-review-build.log').read_text()
for name,h in json.loads((ROOT/'artifacts/v11/audio-05/animation-baseline-hashes.json').read_text()).items():assert sha(ROOT/name)==h,name
for name,h in json.loads((ROOT/'ios/TacticalGo/PresentationLab/P02/pins.json').read_text()).items():assert sha(ROOT/'ios/TacticalGo/PresentationLab/P02'/name)==h,name
voice=ROOT/'assets/candidates/feel-10/voice';m=json.loads((voice/'manifest.json').read_text());assert sha(ROOT/m['source'])==m['source_sha256']
assert m['model_sha256']==json.loads((ROOT/'assets/candidates/warrior-07/voice/manifest.json').read_text())['model_sha256']
assert len(m['model_sha256'])==14 and m['offline_inference'] and m['reference_audio'] is None and not m['paid_service']
for x in m['assets']:
 assert x['text']=={'rogue':'Too slow!','priest':'Stay with me!'}[x['hero']]
 assert sha(voice/x['file'])==x['sha256'] and sha(voice/x['raw_file'])==x['raw_sha256']
 assert x['peak_dbfs']<=-2.99 and .5<x['duration_seconds']<1.6
 assert sha(ROOT/'ios/TacticalGo/PresentationLab/P08'/f"p8-voice-{x['hero']}-{x['take']}.wav")==x['sha256']
asr=json.loads((voice/'ASR-CHECK.json').read_text());assert len(asr['checks'])==4 and all(x['match'] for x in asr['checks']) and asr['target_prompt'] is None
mix=json.loads((ROOT/'assets/candidates/feel-10/audio/manifest.json').read_text())
for x in mix['sources']:assert sha(ROOT/x['archive'])==x['sha256']
for x in mix['processing']:assert sha(ROOT/'assets/candidates/feel-10/audio/raw'/x['source'])==x['source_sha256']
for x in mix['files']+mix['previews']:
 assert sha(ROOT/x['file'])==x['sha256']
 with wave.open(str(ROOT/x['file'])) as f:
  assert f.getsampwidth()==2 and f.getnchannels()==1
  values=array.array('h');values.frombytes(f.readframes(f.getnframes()))
 peak=max(map(abs,values))/32767;assert 0<peak<.95
 if 'peak_dbfs' in x:assert abs(20*math.log10(peak)-x['peak_dbfs'])<.04
# Asset verification is separate from performance/rights acceptance.
for x in json.loads((ROOT/'assets/candidates/priest-08/v02/qa/pixels.json').read_text()):
 assert sha(ROOT/x['file'])==x['fileSHA256'] and x['alpha'] and x['transparentPixels']>0
resource=ROOT/'ios/TacticalGo/PresentationLab/P08';assert sha(resource/'priest-v02.png')==sha(ROOT/'assets/candidates/priest-08/v02/priest-v02.png')
assert sha(resource/'priest-clean-plate-v02.png')==sha(ROOT/'assets/candidates/priest-08/v02/priest-clean-plate-v02.png')
assert sha(resource/'rogue-clean-plate.png')=='3fb0d19330e3830c97790208ac875ed6cb41fe5e5119f0289c8625138e5273da'
files=['swift/TacticalGoCore/Sources/TacticalGoCore/Model.swift','swift/TacticalGoCore/Sources/TacticalGoCore/GameEngine.swift','swift/TacticalGoCore/Sources/TacticalGoCore/ExpansionSkills.swift','swift/TacticalGoCore/Sources/TacticalGoContent/ExpansionPractice.swift','swift/TacticalGoCore/Sources/TacticalGoContent/PriestSanctuaryChallenge.swift','swift/TacticalGoCore/Sources/TacticalGoRecords/ExpansionMatchRecord.swift','swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionPresentation.swift','swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionHeroPose.swift','swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionReviewFixture.swift','ios/TacticalGo/ExpansionLabView.swift','ios/TacticalGo/ExpansionHeroBody.swift','ios/TacticalGo/ExpansionSpellEffects.swift','ios/TacticalGoUITests/ExpansionLabTests.swift','scripts/verify-expansion-core-evidence.py']
(OUT/'source-milestone-hashes.json').write_text(json.dumps({p:sha(ROOT/p) for p in files},indent=2)+'\n')
result=dict(scope='saved 1.1 Core/records/motion and first native evidence; ongoing delivery',swift='235/0',native='20/0 (5 expansion +7 monsters +8 mage); warrior fresh regression pending',classes=['warrior','mage','rogue','priest'],advanced_costs=[4,5],monster_hunt_costs=[0,1],reachable_two_eye_rescue_and_mage_counter=True,expansion_records='candidate schema rebuild + final state validation, legacy format rejects',voices='4 independent unprompted word checks; acting Owner pending',accepted_mage_animation_SHA_preserved=True,old_bot='original planner rejects expansion; local2player candidate only',native_v02_body_review='pending',release_physical_video='pending',owner_fun_art_voice_balance_rights='pending',commit_push_merge_release=False)
(OUT/'core-milestone-verification.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
