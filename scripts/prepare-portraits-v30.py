#!/usr/bin/env python3
"""Derive requested 512/256 PNGs; preserve immutable generated masters and reference canvas anchors.
Requires Pillow. Does no painting or identity editing.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
import hashlib,json
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'assets/candidates/assets-pass-1/portraits';CAT=ROOT/'ios/TacticalGo/Assets.xcassets';OUT=ROOT/'artifacts/assets-pass-1/portraits';OUT.mkdir(parents=True,exist_ok=True)
def oldpath(h): return CAT/('priest-portrait-v03.imageset/priest-portrait-v03.png' if h=='priest' else f'{h}.imageset/portrait.png')
def record(p):
 im=Image.open(p).convert('RGBA');a=im.getchannel('A')
 return dict(path=str(p.relative_to(ROOT)),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),rgba_sha256=hashlib.sha256(im.tobytes()).hexdigest(),size=im.size,visible_bounds=a.point(lambda x:255 if x>=13 else 0).getbbox(),transparent_pixels=a.histogram()[0],opaque_pixels=a.histogram()[-1])
records=[];sheet=Image.new('RGB',(1000,4*220),(25,37,36));d=ImageDraw.Draw(sheet)
for row,h in enumerate(['warrior','mage','rogue','priest']):
 source=SRC/f'{h}-source-v30.png';master=Image.open(source).convert('RGBA');old=Image.open(oldpath(h)).convert('RGBA');assert min(master.size)>=1024
 bounds=old.getchannel('A').point(lambda x:255 if x>=13 else 0).getbbox();mb=master.getchannel('A').point(lambda x:255 if x>=13 else 0).getbbox()
 # Uniform scale only, align the bottom-center of the visible bust to the previous canvas. No anatomy warping.
 scale=min((bounds[2]-bounds[0])/(mb[2]-mb[0]),(bounds[3]-bounds[1])/(mb[3]-mb[1]));crop=master.crop(mb);crop=crop.resize((round(crop.width*scale),round(crop.height*scale)),Image.Resampling.LANCZOS)
 image=Image.new('RGBA',(512,512));image.alpha_composite(crop,(round((bounds[0]+bounds[2]-crop.width)/2),bounds[3]-crop.height))
 directory=CAT/f'{h}-portrait-v30.imageset';directory.mkdir(exist_ok=True);path=directory/f'{h}-portrait-v30.png';image.save(path)
 (directory/'Contents.json').write_text(json.dumps({'images':[{'filename':path.name,'idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2)+'\n')
 small=SRC/f'{h}-portrait-v30-256.png';image.resize((256,256),Image.Resampling.LANCZOS).save(small)
 refs=[oldpath(h), CAT/f'identity-reference-{h}.imageset/reference.png'] if h!='priest' else [oldpath(h),ROOT/'assets/candidates/priest-08/v02/priest-v02.png']
 records.append(dict(hero=h,generator='built-in image_gen',model='unknown',tool_version='unknown',prompt=str((SRC/f'{h}-prompt.txt').relative_to(ROOT)),inputs=[record(p) for p in refs]+([record(SRC/'warrior-source-v30.png')] if h in ['mage','rogue'] else [record(oldpath('warrior'))] if h=='priest' else []),source=record(source),outputs=[record(path),record(small)],uniform_scale=scale,anchor='previous visible alpha>=13 bottom-center; uniform fit',approval='pending_exact_file_owner_review',availability={'candidate':True,'production':False,'animation':False},rights={'third_party_inputs':[],'status':'pending_owner_release_acceptance'},qa={'owner_visual_approval':'pending','native_ui':'see review report'}))
 y=row*220;d.text((10,y+7),h,fill='white')
 x=100
 for size in [36,40,130]:
  d.text((x,y+8),f'{size}px old / v30',fill='white')
  for j,im in enumerate([old,image]):sheet.paste(im.resize((size,size),Image.Resampling.LANCZOS),(x+j*(size+8),y+42),im.resize((size,size),Image.Resampling.LANCZOS))
  x+=2*size+36
 # Explicit neutral-light and grayscale native samples, no upscaled previews.
 for j,im in enumerate([old,image]):
  gray=ImageOps.grayscale(im).convert('RGBA');gray.putalpha(im.getchannel('A'));gray=gray.resize((64,64),Image.Resampling.LANCZOS);sheet.paste(gray,(800+j*76,y+45),gray)
 sheet.save(OUT/'native-size-before-after.png')
(SRC/'provenance.json').write_text(json.dumps(dict(schema_version=1,original_inputs_only=True,third_party_inputs=[],generation='built-in image_gen, one identity-preserving edit per character; seed unavailable',derivation='scripts/prepare-portraits-v30.py; Pillow uniform resize and alpha canvas placement only',records=records),indent=2)+'\n')
# Independent light-background and silhouette review: no matte/halo hidden by the dark game UI.
for mode,background in [('light',(244,234,211)),('silhouette',(244,234,211))]:
 qa=Image.new('RGB',(1080,4*210),background);draw=ImageDraw.Draw(qa)
 for row,h in enumerate(['warrior','mage','rogue','priest']):
  draw.text((8,row*210+8),h,fill=(30,35,30));x=100
  for size in [32,36,40,48,64,130]:
   draw.text((x,row*210+8),str(size),fill=(30,35,30))
   for j,path in enumerate([oldpath(h),CAT/f'{h}-portrait-v30.imageset/{h}-portrait-v30.png']):
    im=Image.open(path).convert('RGBA').resize((size,size),Image.Resampling.LANCZOS)
    if mode=='silhouette':
     alpha=im.getchannel('A');im=Image.new('RGBA',im.size,(45,36,29));im.putalpha(alpha)
    qa.paste(im,(x+j*(size+4),row*210+35),im)
   x+=size*2+24
 qa.save(OUT/f'{mode}-native-sizes.png')
