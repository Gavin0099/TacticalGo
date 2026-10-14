#!/usr/bin/env python3
"""FEEL-10 recorded-material layers. Original sources/stems retained, no synth notes or voice warp."""
import array,hashlib,json,math,shutil,subprocess,wave,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/candidates/feel-10/audio';RAW=OUT/'raw';RES=ROOT/'ios/TacticalGo/PresentationLab/P08';RATE=44100
for p in [RAW,OUT/'stems',RES]:p.mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
with zipfile.ZipFile(ROOT/'assets/candidates/present-01/sources/kenney-impact-sounds.zip') as z:(RAW/'impactBell_heavy_000.ogg').write_bytes(z.read('Audio/impactBell_heavy_000.ogg'))
shutil.copy2(ROOT/'assets/candidates/feel-10/source/wolf_monster_6.mp3',RAW/'wolf_monster_6.mp3')
def decode(p,filters='anull'):
 a=array.array('f');a.frombytes(subprocess.check_output(['ffmpeg','-v','error','-i',str(p),'-af',filters,'-ac','1','-ar',str(RATE),'-f','f32le','-']));return list(a)
def level(a,target):
 peak=max(map(abs,a));rms=math.sqrt(sum(x*x for x in a)/len(a));assert peak>0 and rms>0
 gain=min(.78/peak,10**(target/20)/rms);return [x*gain for x in a]
def save(p,a):
 peak=max(map(abs,a));assert peak<.95
 with wave.open(str(p),'wb') as f:f.setparams((1,2,RATE,0,'NONE','not compressed'));f.writeframes(array.array('h',(round(x*32767) for x in a)).tobytes())
 return dict(file=str(p.relative_to(ROOT)),sha256=sha(p),duration=len(a)/RATE,peak_dbfs=20*math.log10(peak),rms_dbfs=20*math.log10(math.sqrt(sum(x*x for x in a)/len(a))))
specs=[
 ('cloth','cloth2.ogg',0,.20,'highpass=f=180,lowpass=f=6500',-26),
 ('blade','drawKnife2.ogg',0,.24,'highpass=f=450,lowpass=f=6500',-24),
 ('slice','knifeSlice.ogg',0,.20,'highpass=f=600,lowpass=f=5500',-27),
 ('foot','footstep01.ogg',0,.20,'highpass=f=100,lowpass=f=2500',-24),
 ('book','bookOpen.ogg',0,.25,'highpass=f=200,lowpass=f=4500',-25),
 ('page','bookFlip1.ogg',0,.24,'highpass=f=500,lowpass=f=6000',-27),
 ('bell','impactBell_heavy_000.ogg',0,.42,'highpass=f=600,lowpass=f=6800',-27),
 ('ground','impactWood_medium_001.ogg',0,.22,'highpass=f=160,lowpass=f=3800',-25),
 ('soft','impactSoft_medium_000.ogg',0,.18,'highpass=f=130,lowpass=f=3000',-27),
 ('wet-coil','slime_01.ogg',0,.24,'highpass=f=180,lowpass=f=4800',-24),
 ('wet-bounce','slime_05.ogg',0,.26,'highpass=f=150,lowpass=f=5000',-22),
 ('wet-land','slime_12.ogg',0,.22,'highpass=f=180,lowpass=f=4500',-24),
 ('bubble','bubble_02.ogg',0,.24,'highpass=f=200,lowpass=f=5000',-27),
 ('wolf-growl','wolf_monster_6.mp3',.10,.52,'highpass=f=100,lowpass=f=5200',-23)]
layers={};files=[];recipes=[]
for key,name,start,length,filters,target in specs:
 n=round(length*RATE);a=decode(RAW/name,f'atrim=start={start}:duration={length},asetpts=PTS-STARTPTS,'+filters);a=(a+[0]*n)[:n]
 a=[x*max(0,min(1,i/(.006*RATE),(n-1-i)/(.045*RATE))) for i,x in enumerate(a)]
 layers[key]=level(a,target);files.append(save(OUT/'stems'/f'{key}.wav',layers[key]));recipes.append(dict(stem=key,source=name,source_sha256=sha(RAW/name),start=start,duration=length,filters=filters,target_rms=target,edge_fades=[.006,.045]))
groups=[('p8-rogue-coil',['cloth','blade'],-24),('p8-rogue-dash',['cloth','slice'],-23),('p8-rogue-land',['foot','soft'],-23),('p8-priest-prayer',['book','page'],-24),('p8-priest-bless',['bell','page'],-25),('p8-priest-land',['ground','soft'],-24),('p8-slime-coil',['wet-coil','bubble'],-24),('p8-slime-bounce',['wet-bounce'],-22),('p8-slime-land',['wet-land','soft'],-23),('p8-wolf-growl',['wolf-growl'],-23),('p8-wolf-dash',['cloth','foot'],-24),('p8-wolf-land',['foot','soft'],-23)]
final={}
for key,parts,target in groups:
 a=[sum(layers[p][i] if i<len(layers[p]) else 0 for p in parts) for i in range(max(len(layers[p]) for p in parts))]
 final[key]=level(a,target);files.append(save(RES/f'{key}.wav',final[key]))
for hero in ['rogue','priest']:
 for take in ['A','B']:
  src=ROOT/f'assets/candidates/feel-10/voice/{hero}-{take}-dry.wav';dest=RES/f'p8-voice-{hero}-{take}.wav';shutil.copy2(src,dest);files.append(dict(file=str(dest.relative_to(ROOT)),sha256=sha(dest),source=str(src.relative_to(ROOT))))
previews=[]
for hero,cues in [
 ('rogue',[('p8-rogue-coil',.04),('p8-rogue-dash',.16),('p8-rogue-land',.36)]),
 ('priest',[('p8-priest-prayer',.06),('p8-priest-bless',.32),('p8-priest-land',.58)])]:
 for take in ['A','B','no-voice']:
  speech=decode(ROOT/f'assets/candidates/feel-10/voice/{hero}-{take}-dry.wav') if take!='no-voice' else []
  end=.06+len(speech)/RATE;mix=[0.0]*round(2*RATE)
  for key,at in cues:
   for i,x in enumerate(final[key]):
    j=round(at*RATE)+i;t=j/RATE;duck=.46 if speech and t<end else 1
    if j<len(mix):mix[j]+=x*.65*duck
  for i,x in enumerate(speech):mix[round(.06*RATE)+i]+=x*.85
  previews.append(save(OUT/f'{hero}-{take}-mix.wav',mix))
for monster,cues in [('slime',[('p8-slime-coil',.12),('p8-slime-bounce',.22),('p8-slime-land',.44)]),('wolf',[('p8-wolf-growl',.02),('p8-wolf-dash',.18),('p8-wolf-land',.42)])]:
 mix=[0.0]*round(1.5*RATE)
 for key,at in cues:
  for i,x in enumerate(final[key]):mix[round(at*RATE)+i]+=x*.65
 previews.append(save(OUT/f'{monster}-mix.wav',mix))
sources=[dict(author='Kenney',license='CC0',page='https://kenney.nl/assets/rpg-audio',archive='assets/candidates/present-01/sources/kenney-rpg-audio.zip'),dict(author='Kenney',license='CC0',page='https://kenney.nl/assets/impact-sounds',archive='assets/candidates/present-01/sources/kenney-impact-sounds.zip'),dict(author='rubberduck',license='CC0 as declared on author page',page='https://opengameart.org/content/40-cc0-water-splash-slime-sfx',archive='assets/candidates/feel-10/source/water-splash-slime-sfx.zip',note='Recorded slime/water material; no synthesized tone'),dict(author='CaveboyTup',license='CC0 as declared on author page',page='https://opengameart.org/content/wolf-monster-sound',archive='assets/candidates/feel-10/source/wolf_monster_6.mp3',note='Author-made processed creature sound from CC0 sources, not a real wolf recording')]
for s in sources:s['sha256']=sha(ROOT/s['archive'])
m=dict(version='FEEL-10',status='candidate; listening/acting Owner pending',sources=sources,processing=recipes,files=files,previews=previews,voice_gain=.85,sfx_gain=.65,voice_duck=.46,raw_voice_warp=False,master='mono44.1k16bit PCM; voices24k original dry',rights='source records retained; final release clearance not claimed')
(OUT/'manifest.json').write_text(json.dumps(m,indent=2)+'\n');print(json.dumps(previews,indent=2))
