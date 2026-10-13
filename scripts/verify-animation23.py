"""Check source and media identity; never substitute this for Swift or AVAudioPlayer tests."""
from pathlib import Path
import hashlib, json, subprocess

root = Path(__file__).resolve().parents[1]
out = root / 'artifacts/animation-23'
report = json.loads((root / 'tools/animation-23/timing.json').read_text(encoding='utf-8'))
for p, digest in report['source_text_sha256_lf'].items():
    assert hashlib.sha256((root / p).read_text(encoding='utf-8').encode()).hexdigest() == digest, p
for p, digest in report['wav_sha256'].items():
    assert hashlib.sha256((root / p).read_bytes()).hexdigest() == digest, p
    assert (root / p).read_bytes() == subprocess.check_output(['git', 'show', '354acb2:' + p], cwd=root), p
protected = ['swift/TacticalGoCore/Sources/TacticalGoCore', 'swift/TacticalGoCore/Sources/TacticalGoContent',
             'swift/TacticalGoCore/Sources/TacticalGoBot', 'swift/TacticalGoCore/Sources/TacticalGoRecords',
             'ios/TacticalGo/Assets.xcassets', 'ios/TacticalGo/PresentationLab', 'ios/TacticalGo/Audio',
             'ios/TacticalGo/GameInterface.swift', 'ios/TacticalGo/PhoneMatchLayout.swift', 'tools/animation-22']
assert not subprocess.check_output(['git', 'diff', '354acb2', '--', *protected], cwd=root)
for p in report['source_text_sha256_lf']:
    archived = out / 'baseline' / p
    assert archived.read_bytes() == subprocess.check_output(['git', 'show', '354acb2:' + p], cwd=root), p
rows = {row['id']: row for row in report['rows']}
assert rows['chain']['candidateInputEnd'] == .70
# Independently recorded sample counts/rate from the pinned source WAV headers.
assert abs(rows['chain']['baselineInputEnd'] - (.06 + 29245 / 24000)) < 1e-9
assert abs(rows['bastion']['baselineInputEnd'] - 1.28) < .0001
assert abs(rows['double']['baselineInputEnd'] - (.08 + 24953 / 24000)) < 1e-9
browser = json.loads((out / 'browser-checks.json').read_text(encoding='utf-8'))
assert all(c['passed'] for c in browser['checks']) and not browser['errors']
swift_tests = root / 'swift/TacticalGoCore/Tests/TacticalGoMotionTests/ExpansionPlaybackWindowTests.swift'
paths = list(report['source_text_sha256_lf']) + [swift_tests.relative_to(root).as_posix(),
        'swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionPlaybackWindow.swift',
        'tools/animation-23/preview.js', 'scripts/review-animation23.cjs']
checks = {'baseline_commit': '354acb22ad77d8e9bdb2b3d5d400fc3e4084e893', 'baseline_source_identity': 'PASS',
          'WAV_bytes': 'unchanged', 'UI20_AV22_art_and_Domain': 'unchanged', 'browser': browser,
          'source_text_sha256_lf': {p: hashlib.sha256((root / p).read_text(encoding='utf-8').encode()).hexdigest() for p in paths},
          'native_build': 'NOT RUN', 'three_Swift_window_tests': 'NOT RUN', 'six_real_store_audio_audit_checks': 'NOT RUN',
          'native_UI_FPS_latency_listening': 'NOT RUN', 'quality_parity': 'NOT ESTABLISHED'}
(out / 'checks.json').write_text(json.dumps(checks, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('PASS: source/WAV identity, archived baseline, UI20/AV22/Domain unchanged; browser report verified. Native NOT RUN.')
