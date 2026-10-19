#!/usr/bin/env python3
"""Regression invariants independent of generation logic: immutable Release inputs, pins, grid, and audio limits."""
from pathlib import Path
import hashlib,json,subprocess,wave,math,array
ROOT=Path(__file__).resolve().parents[1];BASE='f2a28b712d3392973f37360a41ea25ce255b0cb7'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def old(p):return subprocess.check_output(['git','show',f'{BASE}:{p}'],cwd=ROOT)
checks=[]
def check(name,value):
 checks.append(dict(name=name,passed=bool(value)));assert value,name
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'ios/TacticalGo/Assets.xcassets','ios/TacticalGo/Audio','ios/TacticalGo/PresentationLab','ios/TacticalGo/HeroBody'],cwd=ROOT,text=True).splitlines()
check('all_preexisting_raster_audio_body_inputs_byte_identical',all((ROOT/p).read_bytes()==old(p) for p in paths))
folder=ROOT/'ios/TacticalGo/PresentationLab/P02';pins=json.loads((folder/'pins.json').read_text())
check('all_P02_sha256_pins',all(sha(folder/p)==value for p,value in pins.items()))
from PIL import Image
cat=ROOT/'ios/TacticalGo/Assets.xcassets'
check('v30_atlas_exact_1448x1086',Image.open(cat/'game-ability-atlas-v30.imageset/game-ability-atlas-v30.png').size==(1448,1086))
check('v30_sanctum_exact_384',Image.open(cat/'game-ability-sanctum-v30.imageset/game-ability-sanctum-v30.png').size==(384,384))
for h in ['warrior','mage','rogue','priest']:
 for p,size in [(cat/f'{h}-portrait-v30.imageset/{h}-portrait-v30.png',512),(ROOT/f'assets/candidates/assets-pass-1/portraits/{h}-portrait-v30-256.png',256)]:
  im=Image.open(p);check(f'{h}_{size}_rgba_transparency',im.size==(size,size) and im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255))
check('rawValue_order_unchanged','case soldier, summon, bastion, reformation, magicHand, doublePull, swap, chainSwap, offering, slime, shadow, crystal' in (ROOT/'ios/TacticalGo/GameInterface.swift').read_text())
manifest=json.loads((ROOT/'ios/TacticalGo/Audio/V30/manifest.json').read_text());families={}
for entry in manifest['assets']:
 p=ROOT/'ios/TacticalGo/Audio/V30'/entry['file']
 with wave.open(str(p)) as w:
  pcm=array.array('h',w.readframes(w.getnframes()));duration=w.getnframes()/w.getframerate()
 check(entry['key']+'_PCM_no_clip_zero_endpoints_and_duration',max(abs(v) for v in pcm)<=29204 and pcm[0]==pcm[-1]==0 and duration<=1.2)
 check(entry['key']+'_hash_true_peak_lufs',sha(p)==entry['sha256'] and entry['true_peak_dbfs']<=-1 and math.isfinite(entry['integrated_lufs']))
 families.setdefault(entry['family'],[]).append(entry['integrated_lufs'])
check('same_family_spread_le_2LU',all(max(v)-min(v)<=2 for v in families.values()))
# Manifest metadata cannot replace independent ffmpeg measurements; audit separately after generation.
out=ROOT/'artifacts/assets-pass-1/validation-invariants.json';out.write_text(json.dumps(checks,indent=2)+'\n');print(f'{len(checks)} invariants passed; {len(paths)} original files unchanged; {len(pins)} P02 pins verified')
