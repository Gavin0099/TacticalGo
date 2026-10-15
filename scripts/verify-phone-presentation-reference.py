#!/usr/bin/env python3
"""Check saved PRESENT-02 evidence and hashes; does not run behavior tests."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'artifacts/v11/present-02'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()

baseline = json.loads((ROOT / 'artifacts/v11/present-01/baseline-hashes.json').read_text())
assert all(sha(ROOT / p) == h for p, h in baseline.items()), 'Core/rules changed'
sources = json.loads((OUT / 'source-final-hashes.json').read_text())
assert all(sha(ROOT / p) == h for p, h in sources.items()), 'Validated sources changed'
imports = json.loads((ROOT / 'assets/candidates/present-02/source-imports.json').read_text())
for item in imports['files']:
    frozen = ROOT / 'assets/candidates/present-02/reference-1023' / item['path']
    if item['path'].endswith('Anim01Geometry.swift'):
        frozen = ROOT / item['path']
    assert sha(frozen) == item['sha256'], item['path']
pins = json.loads((ROOT / 'ios/TacticalGo/PresentationLab/P02/pins.json').read_text())
for name, digest in pins.items():
    for folder in ['ios/TacticalGo/PresentationLab/P02', 'ios/Build/Products/Debug-iphonesimulator/TacticalGo.app/PresentationLab/P02']:
        assert sha(ROOT / folder / name) == digest, name
assert not (ROOT / 'ios/Build/Products/Release-iphonesimulator/TacticalGo.app/PresentationLab').exists()
assert 'Executed 31 tests, with 0 failures' in (OUT / 'swift-tests.log').read_text()
assert '** TEST BUILD SUCCEEDED **' in (OUT / 'ios-build-final.log').read_text()
assert '** BUILD SUCCEEDED **' in (OUT / 'ios-release.log').read_text()

def cases(path):
    result = []
    def visit(node):
        if node.get('nodeType') == 'Test Case': result.append(node)
        for child in node.get('children', []): visit(child)
    for node in json.loads(path.read_text())['testNodes']: visit(node)
    return result

native = cases(OUT / 'ui-final-results.json')
ab = cases(OUT / 'ui-explicit-ab-results.json')
assert len(native) == 4 and all(c['result'] == 'Passed' for c in native)
assert len(ab) == 1 and ab[0]['result'] == 'Passed'
audio = json.loads((OUT / 'audio-reference.json').read_text())
for source in audio['sources']:
    assert sha(ROOT / 'ios/TacticalGo/Audio' / (source['key'] + '.wav')) == source['sha256']
assert sha(OUT / 'phone-1023-sfx-reference.wav') == audio['preview_sha256']
video = json.loads((OUT / 'video-manifest.json').read_text())
assert (OUT / video['raw']).is_file() and (OUT / video['preview']).is_file()
assert video['new_art_or_sound_quality_claim'] is False
result = {'kind': 'Saved evidence integrity check, not new behavioral tests',
          'motion': '31/0', 'native': '4/0, plus explicit A/B method 1/0',
          'frozen_inputs': len(imports['files']), 'debug_pins': len(pins),
          'release_lab_absent': True, 'core_rules_unchanged': True,
          'phone_updated': False, 'new_quality_accepted': False,
          'video': 'Native Simulator video with original SFX postmix; no physical recording'}
(OUT / 'delivery-verification.json').write_text(json.dumps(result, indent=2) + '\n')
print('PRESENT-02 saved evidence, frozen inputs and delivery checksum verification PASS.')
