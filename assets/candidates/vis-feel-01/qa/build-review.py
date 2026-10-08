"""Build an offline review page from the editable web files. No image changes."""
from pathlib import Path
import argparse
import base64
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
NAMES = ['A-warrior-v01', 'A-mage-v01', 'A-rogue-v02', 'B-warrior-v02', 'B-mage-v02', 'B-rogue-v02']
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, help='Existing adjustment package, read only')
    args = parser.parse_args()
    if args.source:
        source = args.source.resolve()
        copied = []
        for name in NAMES:
            src = source / 'tokens' / (name + '.png')
            dst = ROOT / 'tokens' / src.name
            before = sha(src)
            shutil.copyfile(src, dst)
            assert sha(dst) == before
            copied.append({'id': name, 'path': 'tokens/' + dst.name, 'sha256': before,
                           'source_package': source.name, 'source_path': 'tokens/' + src.name,
                           'method': 'byte_identical_copy', 'approval': 'pending_owner',
                           'availability': {'candidate_review': True, 'production': False},
                           'rights': 'pending_confirmation'})
        shutil.copyfile(source / 'provenance.json', ROOT / 'sources' / 'asset-provenance.json')
        provenance = {'schema': 'tacticalgo-visual-feedback-v1', 'date': '2026-10-08',
                      'approval': 'pending_owner', 'availability': {'candidate_review': True, 'production': False},
                      'rights': 'pending_confirmation', 'mage_visual_default': 'magic_hand_R1',
                      'rule_integration': False, 'fixture_source': 'fixed_visual_fixture',
                      'assets': copied, 'parent_package': {'name': source.name,
                      'zip_sha256': sha(source / 'TacticalGo-art-adjustment-v01.zip'),
                      'provenance_sha256': sha(source / 'provenance.json')},
                      'human_recognition': 'not_run', 'physical_iphone': 'not_run',
                      'skill_installation': 'not_installed_draft', 'git_delivery': 'not_committed_or_pushed',
                      'git_delivery_observation': 'initial_generation_snapshot; subsequent delivery is recorded in the visual checkpoint and PR'}
        (ROOT / 'provenance.json').write_bytes((json.dumps(provenance, ensure_ascii=False, indent=2) + '\n').encode('utf-8'))
    assets = {}
    for name in NAMES:
        form, role, _ = name.split('-')
        assets[form + '-' + role] = 'data:image/png;base64,' + base64.b64encode((ROOT / 'tokens' / (name + '.png')).read_bytes()).decode('ascii')
    html = (ROOT / 'web' / 'index.html').read_text(encoding='utf-8')
    css = (ROOT / 'web' / 'feel.css').read_text(encoding='utf-8')
    js = (ROOT / 'web' / 'feel.js').read_text(encoding='utf-8')
    html = html.replace('<link rel="stylesheet" href="feel.css">', '<style>' + css + '</style>')
    html = html.replace('<script src="feel.js"></script>', '<script>window.FEEL_ASSETS=' + json.dumps(assets) + ';\n' + js + '\n</script>')
    # Write exact UTF-8/LF bytes on every OS; text-mode output translates on Windows.
    (ROOT / 'REVIEW.html').write_bytes(html.encode('utf-8'))
    print(json.dumps({'review': 'REVIEW.html', 'embedded_assets': len(assets), 'bytes': len(html.encode('utf-8'))}))

if __name__ == '__main__':
    main()
