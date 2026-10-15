"""Integrity and wiring checks, not Swift compilation, frame time or market-quality validation."""
from pathlib import Path
import hashlib,json,re,subprocess,wave
root=Path(__file__).resolve().parents[1];out=root/'artifacts/animation-24'
data=json.loads((root/'tools/animation-24/contact.json').read_text(encoding='utf-8'))
for p,digest in data['source_text_sha256_lf'].items():
    assert hashlib.sha256((root/p).read_text(encoding='utf-8').encode()).hexdigest()==digest,p
protected=['swift/TacticalGoCore/Sources/TacticalGoCore','swift/TacticalGoCore/Sources/TacticalGoContent',
           'swift/TacticalGoCore/Sources/TacticalGoBot','swift/TacticalGoCore/Sources/TacticalGoRecords',
           'ios/TacticalGo/GameInterface.swift','ios/TacticalGo/PhoneMatchLayout.swift','ios/TacticalGo/Assets.xcassets',
           'ios/TacticalGo/PresentationLab','ios/TacticalGo/Audio','ios/TacticalGo/GameStore.swift',
           'swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionPresentation.swift',
           'swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionPlaybackWindow.swift']
assert not subprocess.check_output(['git','diff','371718e','--',*protected],cwd=root)
project=(root/'ios/TacticalGo.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
assert project.count('000000000000000000000530')==3 and project.count('000000000000000000000531')==2
assert 'path = ExpansionContactEffects.swift' in project
view=(root/'ios/TacticalGo/ExpansionLabView.swift').read_text(encoding='utf-8')
assert 'plane:.ground,center:' in view and ').zIndex(6)' in view and ').zIndex(160)' in view
for p in (out/'baseline').rglob('*'):
    if p.is_file():
        relative=p.relative_to(out/'baseline').as_posix()
        assert p.read_bytes()==subprocess.check_output(['git','show','371718e:'+relative],cwd=root),relative
audio=root/'ios/TacticalGo/PresentationLab/P08/p8-rogue-land.wav'
with wave.open(str(audio),'rb') as wav: sound_duration=wav.getnframes()/wav.getframerate()
assert .36+sound_duration <= .70,'Extra first contact must not extend existing visual/input duration'
samples=(root/'ios/TacticalGo/PresentationLabView.swift').read_text(encoding='utf-8')
assert 'key == "p8-rogue-land-first" ? "p8-rogue-land" : key' in samples
assert audio.read_bytes()==subprocess.check_output(['git','show','371718e:ios/TacticalGo/PresentationLab/P08/p8-rogue-land.wav'],cwd=root)
browser=json.loads((out/'browser-checks.json').read_text(encoding='utf-8'))
contacts=json.loads((out/'contact-checks.json').read_text(encoding='utf-8'))
gain=json.loads((out/'audio-gain-check.json').read_text(encoding='utf-8'))
assert all(c['pass'] for c in browser['checks']) and not browser['errors']
assert all(c['passed'] for c in contacts['checks']) and not contacts['errors']
assert gain['passed'] and abs(gain['first'][0]['volume']-.228)<1e-6
assert subprocess.run(['git','diff','--check'],cwd=root,capture_output=True).returncode==0
report={'baseline_commit':'371718e29dd1591945ba26e7c81c5cf06ec74495','source_identity':'PASS',
        'new_file_project_wiring':'PASS; not a build','UI20_art_audio_Domain_AV23_input_window':'unchanged',
        'chain_contact_WAV_duration':sound_duration,'chain_contact_times':[.26,.36],
        'source_text_sha256_lf':data['source_text_sha256_lf'],'browser':browser,'contact_rendering':contacts,'browser_relative_audio_gain':gain,
        'three_new_Swift_contact_tests':'NOT RUN','new_real_audio_schedule_audit':'NOT RUN',
        'native_build_UI_latency_FPS_listening':'NOT RUN','quality_90_percent':'NOT ESTABLISHED',
        'quality_work_remaining':True}
tool_paths=['tools/animation-24/preview.js','tools/animation-24/contacts.js','tools/animation-24/accents.js',
            'scripts/review-animation24.cjs','scripts/review-animation24-audio.cjs','scripts/review-animation24-native.sh',
            'swift/TacticalGoCore/Tests/TacticalGoMotionTests/ExpansionContactTests.swift']
report['tool_test_text_sha256_lf']={p:hashlib.sha256((root/p).read_text(encoding='utf-8').encode()).hexdigest() for p in tool_paths}
(out/'checks.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('PASS: source/baseline/project wiring, existing art/audio/Domain/input timing unchanged; native and 90% quality NOT ESTABLISHED.')
