"""Read-only asset/source verification; never edits PNG pixels or runs native code."""
from pathlib import Path
import hashlib, json, subprocess, shutil
from PIL import Image

root = Path(__file__).resolve().parents[2]
out = root / 'artifacts/game-interface-20'
generated = Path('C:/Users/reiko/.codex/generated_images/01a13339-d8c4-7ac0-8260-f100653a791b')
assets = []
for name, filename, source, prompt in [
    ('game-ability-atlas-v20', 'game-ability-atlas-v20.png', 'exec-b1a22e84-29d5-4bae-b65e-786a515f9900.png', 'atlas-v2.txt'),
    ('game-tray-frame-v20', 'game-tray-frame-v20.png', 'exec-236000cf-0e8d-4a1a-a2be-93d074d4c909.png', 'frame-v2.txt'),
]:
    folder = root / 'ios/TacticalGo/Assets.xcassets' / (name + '.imageset')
    path = folder / filename
    config = json.loads((folder / 'Contents.json').read_text(encoding='utf-8'))
    assert config['images'][0]['filename'] == filename
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    assert digest == hashlib.sha256((generated / source).read_bytes()).hexdigest(), 'Runtime bytes differ from generation'
    with Image.open(path) as im:
        assert im.mode == 'RGBA'
        alpha = im.getchannel('A')
        extra = {}
        if name == 'game-ability-atlas-v20':
            assert im.width % 4 == 0 and im.height % 3 == 0
            maxima = [alpha.crop((0, y-2, im.width, y+2)).getextrema()[1] for y in [im.height//3, im.height*2//3]]
            assert max(maxima) <= 1, 'Visible sprite bleed across rows'
            extra = {'grid': [4, 3], 'row_boundary_alpha_max': maxima}
        else:
            assert alpha.getpixel((im.width//2, im.height//2)) == 0, 'Frame center must remain transparent'
        assets.append({'asset': path.relative_to(root).as_posix(), 'generator': 'image_gen.imagegen', 'generation_source': str(generated/source), 'prompt_verbatim_file': 'prompts/'+prompt, 'sha256': digest, 'size': [im.width, im.height], 'mode': im.mode, 'alpha_extrema': list(alpha.getextrema()), 'original_pixels_preserved': True, 'source_type': 'original_generated_candidate', **extra})
source = (root / 'ios/TacticalGo/GameInterface.swift').read_text(encoding='utf-8')
assert all(name in source for name in ['game-ability-atlas-v20', 'game-tray-frame-v20'])
assert 'GameInterface.swift' in (root/'ios/TacticalGo.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
av = json.loads((root/'artifacts/av21-pending/manifest.json').read_text(encoding='utf-8'))
assert subprocess.check_output(['git','diff','--',*av['tracked']],cwd=root) == b''
for name in av['new']:
    assert not (root/name).exists()
    assert hashlib.sha256((root/'artifacts/av21-pending/source'/name).read_bytes()).hexdigest() == av['sha256'][name]
provenance = {'date': '2026-10-13', 'source_branch': 'origin/codex/v11-monster-battlefield', 'source_commit': subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(), 'assets': assets, 'competitor_media_imported': False, 'existing_hero_assets': 'Retained current portraits; no character redraw', 'iterations': [
    {'asset': 'atlas-v1', 'generation_source': str(generated/'exec-048046cf-3e05-417e-9674-2be01a0eae5f.png'), 'prompt': 'prompts/atlas-v1.txt', 'issue': 'Priest leaf leaked into mage cell; preserved iteration-1 screenshots and atlas'},
    {'asset': 'frame-v1', 'generation_source': str(generated/'exec-a3c18846-9d2d-4a30-a544-f7fedb700059.png'), 'prompt': 'prompts/frame-v1.txt', 'issue': 'Thick rail and outer margin consumed content area; regenerated thinner frame'},
]}
for item in provenance['iterations']:
    original = Path(item['generation_source'])
    item['sha256'] = hashlib.sha256(original.read_bytes()).hexdigest()
    archived = out/'iteration-1'/(item['asset']+'.png')
    shutil.copyfile(original, archived)
    item['archived_source'] = archived.relative_to(out).as_posix()
(out/'provenance.json').write_text(json.dumps(provenance, ensure_ascii=False, indent=2)+'\n',encoding='utf-8')
report = {'asset_integrity': 'PASS', 'source_registration': 'PASS', 'AV21_parked': 'PASS', 'browser': json.loads((out/'browser-checks.json').read_text(encoding='utf-8')), 'native_build': 'NOT RUN', 'native_UI': 'NOT RUN', 'reason': 'Windows has no Xcode/iOS SDK', 'source_sha256': {name: hashlib.sha256((root/name).read_bytes()).hexdigest() for name in ['ios/TacticalGo/GameInterface.swift','ios/TacticalGo/PlayableGameView.swift','tools/game-interface-20/index.html','tools/game-interface-20/preview.js','tools/game-interface-20/style.css']}, 'screenshots_sha256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in out.glob('*.png')}}
(out/'checks.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('PASS: exact generated asset bytes, atlas boundaries, transparent frame, source registration, and AV21 isolation. Native NOT RUN.')
