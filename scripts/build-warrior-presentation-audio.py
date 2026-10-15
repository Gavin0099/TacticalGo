#!/usr/bin/env python3
"""Layer licensed recorded materials; no synthesized spell tones or voice warp."""
import array,hashlib,json,math,subprocess,wave,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/candidates/warrior-07/audio';RES=ROOT/'ios/TacticalGo/PresentationLab/P07';RATE=44100
OUT.mkdir(parents=True,exist_ok=True);(OUT/'raw').mkdir(exist_ok=True);(OUT/'stems').mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def decode(p,filters='anull'):
    a=array.array('f');a.frombytes(subprocess.check_output(['ffmpeg','-v','error','-i',str(p),'-af',filters,'-ac','1','-ar',str(RATE),'-f','f32le','-']));return list(a)
def save(p,a):
    assert max(map(abs,a))<.95
    with wave.open(str(p),'wb') as f:f.setparams((1,2,RATE,0,'NONE','not compressed'));f.writeframes(array.array('h',(round(x*32767) for x in a)).tobytes())
    return dict(file=str(p.relative_to(ROOT)),sha256=sha(p),duration=len(a)/RATE,peak_dbfs=20*math.log10(max(map(abs,a))),rms_dbfs=20*math.log10(math.sqrt(sum(x*x for x in a)/len(a))))
def level(a,rms):
    gain=min(.78/max(map(abs,a)),10**(rms/20)/math.sqrt(sum(x*x for x in a)/len(a)));return [x*gain for x in a]
pack=ROOT/'assets/candidates/present-01/sources/kenney-impact-sounds.zip'
names=['impactSoft_medium_000.ogg','impactMetal_light_002.ogg','impactMetal_heavy_003.ogg','impactPunch_heavy_002.ogg','impactWood_medium_001.ogg']
with zipfile.ZipFile(pack) as z:
    for name in names:(OUT/'raw'/name).write_bytes(z.read('Audio/'+name))
    (OUT/'raw/LICENSE.txt').write_bytes(z.read('License.txt'))
specs=[
 ('brace-soft',names[0],.20,'highpass=f=200,lowpass=f=4200',-24),
 ('brace-rim',names[1],.20,'highpass=f=650,lowpass=f=3900',-26),
 ('strike-metal',names[2],.33,'highpass=f=200,lowpass=f=5200,acompressor=threshold=0.08:ratio=2:attack=3:release=65',-21),
 ('strike-body',names[3],.26,'highpass=f=110,lowpass=f=2100,acompressor=threshold=0.08:ratio=3:attack=2:release=75',-18),
 ('pawn-ground',names[4],.24,'highpass=f=350,lowpass=f=4700',-24)]
layers={};files=[];recipes=[]
for key,name,length,filters,target in specs:
    n=round(length*RATE);a=(decode(OUT/'raw'/name,filters)+[0]*n)[:n]
    a=[x*min(1,i/(.003*RATE),(n-1-i)/(.055*RATE)) for i,x in enumerate(a)]
    layers[key]=level(a,target);files.append(save(OUT/'stems'/f'{key}.wav',layers[key]));recipes.append(dict(stem=key,source=name,filters=filters,duration=length,target_rms=target,edge_fades=[.003,.055]))
final={}
for key,parts,target in [('w7-brace',['brace-soft','brace-rim'],-23),('w7-strike',['strike-metal','strike-body'],-17),('w7-land',['pawn-ground'],-22)]:
    a=[sum(layers[p][i] if i<len(layers[p]) else 0 for p in parts) for i in range(max(len(layers[p]) for p in parts))]
    a=level([math.tanh(x*1.2)/1.2 for x in a],target);final[key]=a;files.append(save(RES/f'{key}.wav',a))
previews=[]
for take in ['A','B','silent-voice','original']:
    speech=decode(ROOT/f'assets/candidates/warrior-07/voice/warrior-{take}-dry.wav') if take in ['A','B'] else []
    voice_end=.08+len(speech)/RATE if speech else 0;recovery=max(1.02,voice_end)
    mix=[0.0]*round(2*RATE)
    cues=[('w7-brace',.20),('w7-strike',.58),('w7-land',.58)] if take!='original' else [('warrior',0),('place',.25)]
    for key,at in cues:
        a=final[key] if key in final else decode(ROOT/'ios/TacticalGo/Audio'/f'{key}.wav')
        for i,x in enumerate(a):
            j=round(at*RATE)+i;t=j/RATE
            duck=(.42 if t<recovery else .42+.58*min(4,int((t-recovery)/.03)+1)/4) if speech else 1
            if j<len(mix):mix[j]+=x*.65*duck
    for i,x in enumerate(speech):mix[round(.08*RATE)+i]+=x*.85
    previews.append(save(OUT/f'cast-{take}-mix.wav',mix))
m=dict(source_pack=str(pack.relative_to(ROOT)),source_sha256=sha(pack),license='Kenney Impact Sounds CC0',page='https://kenney.nl/assets/impact-sounds',raw={n:sha(OUT/'raw'/n) for n in names},license_sha256=sha(OUT/'raw/LICENSE.txt'),processing=recipes,files=files,previews=previews,timing=dict(voice=.08,brace=.20,strike=.58,land=.58,capture=.68,rest=1.02),voice_gain=.85,sfx_gain=.65,voice_duck=.42,quality='Owner pending')
(OUT/'manifest.json').write_text(json.dumps(m,indent=2)+'\n');print(json.dumps(previews,indent=2))
