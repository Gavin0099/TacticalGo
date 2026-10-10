"""Check frozen receipts, source pins and executed evidence; no human acting verdict."""
import hashlib, json, pathlib, re, subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
D = ROOT / 'artifacts/ios/anim-warrior-rogue-01'
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def data(name):
    return json.loads((D / name).read_text())
def executed(name, count):
    path = D / name
    text = path.read_text()
    assert re.search(r'Executed '+str(count)+r' tests?, with 0 failures', text), name
    assert '** TEST EXECUTE SUCCEEDED **' in text or 'All tests\' passed' in text, name
    return {'executed': count, 'failures': 0, 'log': name, 'logSHA256': sha(path)}

provenance = json.loads((ROOT / 'assets/candidates/anim-warrior-rogue-01/provenance.json').read_text())
for name, expected in provenance['inputOutputSHA'].items():
    assert sha(ROOT / name) == expected, name
rig = json.loads((ROOT / 'assets/candidates/anim-warrior-rogue-01/rig-and-timing.json').read_text())
assert sha(ROOT / rig['maskSource']) == rig['maskSHA256']
for name in ['hero-body-warrior-impact-audit.json', 'physical-iphone-warrior-impact-audit.json']:
    x = data(name)
    assert x['status'] == 'PASS' and len(x['checks']) == 108
    assert all(row['pass'] for row in x['checks'])

clips = data('media-warrior-impact/edit-audit.json')['clips']
assert len(clips) == 12 and all(x['speed'] == 1 for x in clips)
for x in clips:
    assert sha(ROOT / x['file']) == x['sha256']
    assert x['before']['ap'] == 2 and x['after']['ap'] == 1
    # Compare the actual receipt timeline with the published contract, rather
    # than assigning success from an exported image or movie file name.
    if x['scenario'] != 'SUMMON':
        expected = rig[x['class'].lower()]['skillMs']
        timing = x['bodyTiming']
        for key, value in expected.items():
            if key == 'anticipationEnd':
                continue  # Receipt trace exports release/move/land/capture/recovery.
            assert abs(timing[key]*1000-value) < 0.001, (x['class'], key, timing)

protected = ['swift/TacticalGoCore/Sources/TacticalGoCore',
             'swift/TacticalGoCore/Sources/TacticalGoBot',
             'ios/TacticalGo/BoardProjection.swift']
assert not subprocess.check_output(['git', 'diff', 'c13f23e', '--']+protected,cwd=ROOT,text=True).strip()
assert 'PASS: 137 C#/Swift snapshots match' in (D/'golden-compare.log').read_text()
for log in ['skill-warrior-impact-validation.log','skill-installed-warrior-impact-validation.log']:
    assert 'Skill is valid!' in (D/log).read_text()
assert '** BUILD SUCCEEDED **' in (D/'release-warrior-impact.log').read_text()

evidence = {
    'engineeringStatus': 'PASS',
    'package': executed('package-warrior-impact.log',169),
    'simulatorReceiptAndSecondAP': executed('native-warrior-impact.log',2),
    'simulatorRecording': executed('media-warrior-impact/native-record-test.log',1),
    'simulatorSmallDense': executed('native-warrior-impact-small.log',1),
    'physicalIPhone': executed('native-iphone-warrior-impact.log',2),
    'stateChecks': {'simulator':108,'physicalIPhone':108},
    'golden': {'fixtures':38,'actions':99,'snapshots':137,'CSharp':'cached evidence; not rerun','Swift':'fresh replay'},
    'physicalIPad': '1003 installed and launched over Wi-Fi; UI runner authentication canceled, NOT PASS',
    'ownerFeedback': 'Rogue body motion liked; warrior initial only okay. Warrior contact refinement: Owner reports improved movement but insufficient force; skill atmosphere NOT PASS.',
    'limits': ['No human acting/final art acceptance inferred','No VFX-01/VFX-02, new voice or haptics','Silent native Simulator movies, not physical-device video','No gameplay/Bot/projection changes'],
    'rawPhysicalLogs': 'Local evidence retains diagnostics; public summary omits device identifiers',
    'identitySHA256': provenance['inputOutputSHA'],
    'maskSHA256': rig['maskSHA256'],
}
(D/'delivery-verification.json').write_text(json.dumps(evidence,indent=2)+'\n')
print('PASS: source pins, 169 tests, actual 108+108 checks, executed UI cases, 12 native receipts; Owner acting and iPad UI pending')
