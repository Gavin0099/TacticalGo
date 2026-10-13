"""Source and artifact integrity only; not a Swift compiler or native playback test."""
from pathlib import Path
import json,hashlib,subprocess,wave
root=Path(__file__).resolve().parents[1]
out=root/'artifacts/animation-21'
old=json.loads((root/'artifacts/game-interface-20/checks.json').read_text(encoding='utf-8'))
for name,digest in old['source_sha256'].items():
    assert hashlib.sha256((root/name).read_bytes()).hexdigest()==digest, 'UI20 source changed: '+name
for item in json.loads((root/'artifacts/game-interface-20/provenance.json').read_text(encoding='utf-8'))['assets']:
    assert hashlib.sha256((root/item['asset']).read_bytes()).hexdigest()==item['sha256']
assert subprocess.check_output(['git','diff','--','swift/TacticalGoCore/Sources/TacticalGoCore','swift/TacticalGoCore/Sources/TacticalGoContent','swift/TacticalGoCore/Sources/TacticalGoBot','swift/TacticalGoCore/Sources/TacticalGoRecords'],cwd=root)==b'', 'Domain/content changed'
data=json.loads((root/'tools/animation-21/fixtures.json').read_text(encoding='utf-8'))
for name,digest in data['source_sha256'].items():
    assert hashlib.sha256((root/name).read_bytes()).hexdigest()==digest, 'Re-export changed timeline source: '+name
for f in data['fixtures']:
    assert 0<=f['release']<=f['moveStart']<f['arrival']<f['captureStart']<f['duration']
audio=[]
for folder,names in [('P07',['w7-brace','w7-strike','w7-land']),('P05',['p5-conjure','p5-push','p5-contact']),('P08',['p8-rogue-coil','p8-rogue-dash','p8-rogue-land','p8-priest-prayer','p8-priest-bless','p8-priest-land'])]:
    for name in names:
        p=root/'ios/TacticalGo/PresentationLab'/folder/(name+'.wav')
        with wave.open(str(p),'rb') as wav:
            assert wav.getnframes()>0
            audio.append({'path':p.relative_to(root).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'duration':wav.getnframes()/wav.getframerate()})
paths=['ios/TacticalGo/CombatAudio.swift','ios/TacticalGo/GameStore.swift','ios/TacticalGo/ExpansionLabView.swift','ios/TacticalGo/ExpansionSpellEffects.swift','ios/TacticalGo/IntegratedAudioAudit.swift','swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionPresentation.swift','swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionFeedback.swift','swift/TacticalGoCore/Tests/TacticalGoMotionTests/ExpansionFeedbackTests.swift']
report={'scope':'AV21 candidate', 'ui20_source_and_assets':'byte-identical','domain_content_bot_records_diff':'empty','timeline_source_hash':'PASS','existing_audio_assets':audio,'browser':json.loads((out/'browser-checks.json').read_text(encoding='utf-8')),'source_sha256':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in paths},'artifact_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.glob('*') if p.suffix in ['.png','.webm']},'native_build':'NOT RUN','swift_tests':'NOT RUN','native_audio_audit':'NOT RUN','native_performance':'NOT RUN','reason':'No Swift compiler in Windows or WSL; no Xcode/iOS SDK'}
(out/'checks.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('PASS: UI20 bytes unchanged, Domain/content unchanged, actual timeline source hashes, 12 existing audio assets. Native NOT RUN.')
