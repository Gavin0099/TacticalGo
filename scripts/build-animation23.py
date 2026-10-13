"""Export AV23 timing comparison from the current schedule and WAV headers; not native execution."""
from pathlib import Path
import hashlib, json, re, subprocess, wave

root = Path(__file__).resolve().parents[1]
out = root / 'tools/animation-23'
evidence = root / 'artifacts/animation-23'
out.mkdir(parents=True, exist_ok=True)
evidence.mkdir(parents=True, exist_ok=True)
sources = ['ios/TacticalGo/ExpansionLabView.swift', 'ios/TacticalGo/PresentationLabView.swift',
           'ios/TacticalGo/GameStore.swift', 'ios/TacticalGo/IntegratedAudioAudit.swift']
for name in sources:
    baseline = evidence / 'baseline' / name
    if not baseline.exists():
        baseline.parent.mkdir(parents=True, exist_ok=True)
        baseline.write_bytes(subprocess.check_output(['git', 'show', '354acb2:' + name], cwd=root))
source = (root / sources[0]).read_text(encoding='utf-8')
fixtures = json.loads((root / 'tools/animation-22/fixtures.json').read_text(encoding='utf-8'))['fixtures']
voices = {'mage': ('mage-cast-B', 'P06', .08), 'warrior': ('w7-voice-B', 'P07', .08),
          'rogue': ('p8-voice-rogue-B', 'P08', .06), 'priest': ('p8-voice-priest-B', 'P08', .06)}
blocks = {'mage': '.castMagicHand,.castDoublePull', 'warrior': '.castBastion,.castReformation',
          'rogue': '.castSwap,.castChainSwap', 'priest': '.castSanctuary, .castOffering'}
rows, wav_hashes = [], {}
for f in fixtures:
    hero = f['hero']
    block = source.split('case ' + blocks[hero] + ':', 1)[1].split('case ', 1)[0]
    cues = []
    for key, at in re.findall(r'\("([^"]+)",([^,]+),skillVolume\)', block):
        delay = {'p.moveStart': f['moveStart'], 'p.arrival': f['arrival']}.get(at)
        if delay is None:
            delay = float(at)
        folder = 'P05' if hero == 'mage' else 'P07' if hero == 'warrior' else 'P08'
        cues.append((key, folder, delay, 'effect'))
    assert len(cues) == 3, (hero, cues)
    key, folder, delay = voices[hero]
    cues.append((key, folder, delay, 'voice'))
    exported = []
    for key, folder, delay, kind in cues:
        p = root / 'ios/TacticalGo/PresentationLab' / folder / (key + '.wav')
        with wave.open(str(p), 'rb') as wav:
            duration = wav.getnframes() / wav.getframerate()
        wav_hashes[p.relative_to(root).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
        exported.append({'file': folder + '/' + key + '.wav', 'at': delay, 'duration': duration, 'kind': kind})
    audio_end = max(f['duration'], *(c['at'] + c['duration'] for c in exported))
    rows.append({'id': f['id'], 'hero': hero, 'title': f['title'], 'visualEnd': f['duration'],
                 'baselineInputEnd': audio_end, 'candidateInputEnd': f['duration'],
                 'audioEnd': audio_end, 'savedWait': audio_end - f['duration'], 'cues': exported})
report = {'evidence': 'Source/WAV timing only; no native latency measurement', 'voiceTake': 'B',
          'specimens': 'Seven nonterminal specimens without captures; terminal stays held separately',
          'rows': rows, 'wav_sha256': wav_hashes,
          'source_sha256': {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in sources},
          'source_text_sha256_lf': {p: hashlib.sha256((root / p).read_text(encoding='utf-8').encode()).hexdigest() for p in sources}}
(out / 'timing.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
(evidence / 'timing.json').write_bytes((out / 'timing.json').read_bytes())
print('Exported seven source/WAV timing specimens. Native NOT RUN.')
