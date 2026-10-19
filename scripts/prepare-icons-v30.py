#!/usr/bin/env python3
"""Pack seven original edits in the exact v20 rawValue grid; Sanctum stays384. Requires Pillow."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageOps,ImageEnhance
import hashlib,json,random
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'assets/candidates/assets-pass-1/icons';CAT=ROOT/'ios/TacticalGo/Assets.xcassets';OUT=ROOT/'artifacts/assets-pass-1/icons';OUT.mkdir(parents=True,exist_ok=True)
order=['soldier','summon','bastion','reformation','magicHand','doublePull','swap','chainSwap','offering','slime','shadow','crystal'];keys=order[2:9]+['sanctum'];old=Image.open(CAT/'game-ability-atlas-v20.imageset/game-ability-atlas-v20.png').convert('RGBA');assert old.size==(1448,1086);atlas=old.copy();records=[];pairs={}
def rec(p):
 im=Image.open(p).convert('RGBA');return dict(path=str(p.relative_to(ROOT)),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),rgba_sha256=hashlib.sha256(im.tobytes()).hexdigest(),size=im.size,transparent_pixels=im.getchannel('A').histogram()[0])
for key in keys:
 p=SRC/f'{key}-source-v30.png';im=Image.open(p).convert('RGBA');assert min(im.size)>=1024
 sz=384 if key=='sanctum' else 362;tile=im.resize((sz,sz),Image.Resampling.LANCZOS)
 if key=='sanctum':
  dest=CAT/'game-ability-sanctum-v30.imageset';before=Image.open(CAT/'game-ability-sanctum-v01.imageset/game-ability-sanctum-v01.png').convert('RGBA')
 else:
  idx=order.index(key);x=idx%4*362;y=idx//4*362;before=old.crop((x,y,x+362,y+362));atlas.paste(tile,(x,y));dest=None
 pairs[key]=(before,tile)
 records.append(dict(key=key,rawValue=12 if key=='sanctum' else order.index(key),source=rec(p),prompt=str((SRC/f'{key}-prompt.txt').relative_to(ROOT)),style_input=[] if key=='bastion' else [rec(SRC/'bastion-source-v30.png')]))
 if dest:
  dest.mkdir(exist_ok=True);name=dest.stem+'.png';tile.save(dest/name);(dest/'Contents.json').write_text(json.dumps({'images':[{'filename':name,'idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2)+'\n')
dest=CAT/'game-ability-atlas-v30.imageset';dest.mkdir(exist_ok=True);atlas.save(dest/'game-ability-atlas-v30.png');(dest/'Contents.json').write_text(json.dumps({'images':[{'filename':'game-ability-atlas-v30.png','idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2)+'\n')
# Independent geometry invariants: unchanged rawValue cells stay byte-identical after packing.
for i,key in enumerate(order):
 if key not in keys:
  box=(i%4*362,i//4*362,i%4*362+362,i//4*362+362);assert old.crop(box).tobytes()==atlas.crop(box).tobytes()
# No names in blind sheets; identification key in JSON. Colors/grayscale/disabled all shown at actual pixels.
blind=keys.copy();random.Random(30).shuffle(blind)
for mode in ['color','gray','disabled']:
 sheet=Image.new('RGB',(820,8*104),(25,37,36));d=ImageDraw.Draw(sheet)
 for row,key in enumerate(blind):
  d.text((10,row*104+8),str(row+1),fill='white');x=52
  for size in [32,48,64]:
   d.text((x,row*104+2),f'{size}px before / v30',fill='white')
   for j,im in enumerate(pairs[key]):
    im=im.resize((size,size),Image.Resampling.LANCZOS)
    if mode=='gray':
     a=im.getchannel('A');im=ImageOps.grayscale(im).convert('RGBA');im.putalpha(a)
    if mode=='disabled':
     im=ImageEnhance.Color(im).enhance(.18);im.putalpha(im.getchannel('A').point(lambda x:round(x*.42)))
    sheet.paste(im,(x+j*(size+8),row*104+28),im)
   x+=2*size+50
 sheet.save(OUT/f'blind-{mode}-32-48-64.png')
(OUT/'blind-key.json').write_text(json.dumps({str(i+1):k for i,k in enumerate(blind)},indent=2)+'\n')
(SRC/'provenance.json').write_text(json.dumps(dict(schema_version=1,generator='built-in image_gen',model='unknown',tool_version='unknown',seed='unavailable',third_party_inputs=[],reference='original generated bastion style only; no competitive imagery',approval='pending_exact_file_owner_review',availability={'candidate':True,'production':False},rights='pending_owner_release_acceptance',derivation='scripts/prepare-icons-v30.py; exact362px grid, unchanged non-skill cells from original TacticalGo v20; Sanctum384',records=records,outputs=[rec(dest/'game-ability-atlas-v30.png'),rec(CAT/'game-ability-sanctum-v30.imageset/game-ability-sanctum-v30.png')]),indent=2)+'\n')
