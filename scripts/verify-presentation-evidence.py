#!/usr/bin/env python3
"""Verify saved PRESENT-01 delivery evidence; does not rerun behavioral tests."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'artifacts/v11/present-01'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
baseline = json.loads((OUT/'baseline-hashes.json').read_text())
assert all(sha(ROOT/p) == h for p,h in baseline.items()), 'Domain baseline changed'
source = json.loads((OUT/'source-final-hashes.json').read_text())
assert all(sha(ROOT/p) == h for p,h in source.items()), 'Validated source changed'
assert 'Executed 30 tests, with 0 failures' in (OUT/'swift-tests.log').read_text()
assert '** TEST BUILD SUCCEEDED **' in (OUT/'ios-build.log').read_text()
assert '** BUILD SUCCEEDED **' in (OUT/'ios-release-final.log').read_text()
assert '** BUILD SUCCEEDED **' in (OUT/'device-build-polish.log').read_text()
assert 'bundleID: com.tacticalgo.prototype.presentationlab' in (OUT/'device-install-final.log').read_text()
tests = json.loads((OUT/'ui-verified-results.json').read_text())
cases = []
def visit(node):
    if node.get('nodeType') == 'Test Case': cases.append(node)
    for c in node.get('children', []): visit(c)
for n in tests['testNodes']: visit(n)
assert len(cases) == 4 and all(c['result'] == 'Passed' for c in cases)
audio = json.loads((ROOT/'assets/candidates/present-01/audio/manifest.json').read_text())
resources = []
for r in audio['resources']:
    candidate = ROOT/'ios/TacticalGo/PresentationLab'/r['file']
    debug = ROOT/'ios/Build/Products/Debug-iphonesimulator/TacticalGo.app/PresentationLab'/r['file']
    phone = OUT/'DeviceProducts/Debug-iphoneos/TacticalGo.app/PresentationLab'/r['file']
    assert all(sha(p) == r['sha256'] for p in [candidate,debug,phone])
    resources.append({'file':r['file'], 'candidate_debug_device_same_bytes':True})
release = ROOT/'ios/Build/Products/Release-iphonesimulator/TacticalGo.app/PresentationLab'
assert not release.exists(), 'Candidate resources leaked into Release'
for p in audio['overlap_previews']:
    assert p['duration'] == 3.1 and p['peak_dbfs'] < 0 and p['end_sample'] == 0
for v in json.loads((OUT/'video/manifest.json').read_text()):
    assert (ROOT/v['raw']).exists() and (ROOT/v['postmix']).exists()
result = {'behavioral_tests':'Saved Motion 30/0 and native UI 4/0; this command verifies evidence, not behavior',
          'native_tests':[{ 'name':c['name'], 'result':c['result']} for c in cases],
          'resources':resources, 'release_candidate_folder_absent':True,
          'domain_baseline_unchanged':True,'validated_source_unchanged':True,
          'physical_install':'verified; locked launch is not a playback claim',
          'owner_listening_acceptance':'pending'}
(OUT/'delivery-verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print('Saved evidence and delivery checksum verification PASS; behavioral results remain in their original logs/xcresult.')
