"""Package the review and verify archive paths, CRC, inventory and SHA-256."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import re
import zipfile

ROOT=Path(__file__).resolve().parents[1]
ZIP=ROOT/'TacticalGo-VIS-FEEL01-review.zip'
MANIFEST=ROOT/'artifact-sha256.json'
sha=lambda data:hashlib.sha256(data).hexdigest()
# pathlib sorting follows host case rules; relative POSIX strings have portable order.
files=sorted((p for p in ROOT.rglob('*') if p.is_file() and p not in (ZIP,MANIFEST) and '__pycache__' not in p.parts),key=lambda p:p.relative_to(ROOT).as_posix())
entries=[]
for p in files:
    rel=p.relative_to(ROOT).as_posix()
    assert not PurePosixPath(rel).is_absolute() and '..' not in PurePosixPath(rel).parts
    if p.suffix.lower() in ('.md','.html','.json','.css','.js','.cjs','.py','.yaml'):
        content=p.read_text(encoding='utf-8')
        assert not re.search(r'[A-Za-z]:[\\/](?:Users|BackUp|Temp)[\\/]',content),f'Absolute machine path: {rel}'
    entries.append({'path':rel,'sha256':sha(p.read_bytes()),'bytes':p.stat().st_size})
provenance=json.loads((ROOT/'provenance.json').read_text(encoding='utf-8'))
parent=ROOT.parent/provenance['parent_package']['name']
prior_verification='not_present; source hashes retained'
if parent.exists():
    assert sha((parent/'TacticalGo-art-adjustment-v01.zip').read_bytes())==provenance['parent_package']['zip_sha256']
    assert sha((parent/'provenance.json').read_bytes())==provenance['parent_package']['provenance_sha256']
    prior_verification='verified_unchanged'
for asset in provenance['assets']:
    assert sha((ROOT/asset['path']).read_bytes())==asset['sha256']
    if parent.exists():
        assert sha((parent/asset['source_path']).read_bytes())==asset['sha256']
MANIFEST.write_bytes((json.dumps({'schema':'sha256-manifest-v1','self_excluded':'artifact-sha256.json','files':entries},ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
with zipfile.ZipFile(ZIP,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
    for p in files+[MANIFEST]:archive.write(p,p.relative_to(ROOT).as_posix())
with zipfile.ZipFile(ZIP) as archive:
    assert archive.testzip() is None
    names=archive.namelist();assert len(names)==len(set(names))
    assert set(names)=={e['path'] for e in entries}|{'artifact-sha256.json'}
    for name in names:
        assert not PurePosixPath(name).is_absolute() and '..' not in PurePosixPath(name).parts and ':' not in name
    for e in entries:assert sha(archive.read(e['path']))==e['sha256']
print(json.dumps({'zip':ZIP.name,'bytes':ZIP.stat().st_size,'zip_sha256':sha(ZIP.read_bytes()),'manifest_records':len(entries),'zip_entries':len(names),'crc':'pass','inventory':'pass','sha256_verification':'pass','prior_source_verification':prior_verification,'absolute_machine_paths':'none'}))
