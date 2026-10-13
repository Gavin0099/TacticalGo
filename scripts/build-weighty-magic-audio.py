#!/usr/bin/env python3
"""AUDIO-05: layered thrust/body/tail; accepted animation unmodified."""
import array,hashlib,json,math,shutil,subprocess,wave,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/candidates/audio-05';RES=ROOT/'ios/TacticalGo/PresentationLab/P05';RATE=44100
for d in ['raw','stems']: (OUT/d).mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def decode(p,f='anull'):
    a=array.array('f');a.frombytes(subprocess.check_output(['ffmpeg','-v','error','-i',str(p),'-af',f,'-ac','1','-ar',str(RATE),'-f','f32le','-']));return list(a)
def rms(a):return math.sqrt(sum(x*x for x in a)/len(a))
def level(a,target,ceiling=.78):
    gain=min(ceiling/max(map(abs,a)),10**(target/20)/rms(a));return [x*gain for x in a]
def save(p,a):
    assert max(map(abs,a))<.95
    with wave.open(str(p),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'));f.writeframes(array.array('h',(round(x*32767) for x in a)).tobytes())
    return dict(file=str(p.relative_to(ROOT)),sha256=sha(p),duration=len(a)/RATE,peak_dbfs=20*math.log10(max(map(abs,a))),rms_dbfs=20*math.log10(rms(a)),dc=sum(a)/len(a),first=a[0],last=a[-1])
raw=OUT/'raw/sand-spell.flac';shutil.copy2(ROOT/'assets/candidates/present-03/audio/raw/sand-spell.flac',raw)
pack=ROOT/'assets/candidates/present-01/sources/kenney-impact-sounds.zip'
with zipfile.ZipFile(pack) as z:
    for k in ['impactPunch_heavy_002.ogg','impactWood_medium_001.ogg','impactPlank_medium_003.ogg','impactBell_heavy_002.ogg']: (OUT/'raw'/k).write_bytes(z.read('Audio/'+k))
    (OUT/'raw/Kenney-License.txt').write_bytes(z.read('License.txt'))
specs=[
('gather-air',raw,'atrim=start=0.12:end=0.50,asetpts=PTS-STARTPTS,areverse,highpass=f=150,lowpass=f=4700,acompressor=threshold=0.08:ratio=2:attack=4:release=60',.38,.045,.025,-20),
('gather-resonance',OUT/'raw/impactBell_heavy_002.ogg','atrim=end=0.34,areverse,highpass=f=650,lowpass=f=5200',.38,.08,.05,-24),
('force-air',raw,'atrim=start=0.10:end=0.36,asetpts=PTS-STARTPTS,highpass=f=140,lowpass=f=6200,acompressor=threshold=0.07:ratio=3:attack=2:release=70',.26,.004,.045,-17),
('force-body',OUT/'raw/impactPunch_heavy_002.ogg','atrim=end=0.20,highpass=f=130,lowpass=f=1700,acompressor=threshold=0.09:ratio=3:attack=2:release=70',.20,.003,.06,-19),
('contact-transient',OUT/'raw/impactWood_medium_001.ogg','atrim=end=0.22,highpass=f=450,lowpass=f=4800',.22,.002,.05,-20),
('contact-body',OUT/'raw/impactPunch_heavy_002.ogg','atrim=end=0.26,highpass=f=100,lowpass=f=2200,acompressor=threshold=0.08:ratio=3:attack=2:release=70',.26,.002,.06,-16),
('contact-table',OUT/'raw/impactPlank_medium_003.ogg','atrim=end=0.26,highpass=f=140,lowpass=f=1200',.26,.002,.08,-21),
('contact-magic-tail',OUT/'raw/impactBell_heavy_002.ogg','atrim=end=0.35,highpass=f=750,lowpass=f=4300,aecho=0.8:0.7:42|81:0.22|0.12',.35,.004,.10,-25)]
layers={};meta=[];files=[]
for key,p,filters,length,fi,fo,target in specs:
    n=round(length*RATE);a=(decode(p,filters)+[0.0]*n)[:n]
    a=[x*min(1,i/(fi*RATE),(n-1-i)/(fo*RATE)) for i,x in enumerate(a)]
    a=level(a,target);layers[key]=a;files.append(save(OUT/'stems'/(key+'.wav'),a))
    meta.append(dict(id=key,source=str(p.relative_to(ROOT)),sha256=sha(p),filters=filters,duration=length,fade_in=fi,fade_out=fo,target_rms=target))
recipes={'p5-conjure':[('gather-air',1,0),('gather-resonance',1,.015)],'p5-push':[('force-air',1,0),('force-body',1,.008)],'p5-contact':[('contact-transient',.7,0),('contact-body',1,0),('contact-table',1,.006),('contact-magic-tail',1,.018)]}
final={}
for key,recipe in recipes.items():
    n=max(len(layers[k])+round(at*RATE) for k,_,at in recipe);a=[0.0]*n
    for k,v,at in recipe:
        start=round(at*RATE)
        for i,x in enumerate(layers[k]):a[start+i]+=x*v
    # Mild soft saturation of recorded layers; no generated oscillator tones.
    a=[math.tanh(x*1.35)/1.35 for x in a]
    a=level(a,-17 if key=='p5-conjure' else -15);final[key]=a
    files.append(save(OUT/(key+'.wav'),a));shutil.copy2(OUT/(key+'.wav'),RES/(key+'.wav'))
previews=[]
for name,cues in [('D',[('p4-conjure',.08),('p4-push',.46),('p4-contact',.68)]),('E',[('p5-conjure',.08),('p5-push',.46),('p5-contact',.68)])]:
    for capture in [False,True]:
        mix=[0.0]*round((3.4 if capture else 1.65)*RATE)
        times=cues+([('capture',.80),('victory',1.08)] if capture else [])
        for key,at in times:
            a=final[key] if key in final else decode(ROOT/('ios/TacticalGo/Audio' if key in ['capture','victory'] else 'ios/TacticalGo/PresentationLab/P04')/(key+'.wav'))
            for i,x in enumerate(a):
                j=round(at*RATE)+i
                if j<len(mix):mix[j]+=x*.65
        previews.append(save(OUT/(name+('-capture' if capture else '')+'-sfx.wav'),mix))
        if not capture:previews.append(save(OUT/(name+'-level-matched.wav'),level(mix,-24.5)))
manifest=dict(status='owner_listening_pending',sample_rate=RATE,channels=1,voice=False,bgm=False,animation_changed=False,
 references=[dict(url='https://news.blizzard.com/en-us/article/23964694/inside-battle-net-meet-the-sound-team-behind-hearthstones-harmonic-design',use='Fixed cast/hit beats, emotional identity and layered source texture'),dict(url='https://www.gamedeveloper.com/audio/making-of-rpg-magic-2-sound-pack',use='Cast/impact split, low/mid/high balance, foley+synth layering and tails; no source samples copied'),dict(url='https://blog.prosoundeffects.com/how-to-sound-design-magic-spell-sound-effects',use='Primary tutorial: design/layer/process reusable source sounds; no commercial library copied')],
 rights=[dict(author='Kenney',license='CC0',page='https://kenney.nl/assets/impact-sounds',archive_sha256=sha(pack),license_sha256=sha(OUT/'raw/Kenney-License.txt')),dict(author='qubodup',license='CC0',page='https://opengameart.org/content/sand-spell',sha256=sha(raw),description='Author mouth-made source; not our studio recording')],processing=meta,recipes=recipes,files=files,previews=previews,timing=dict(conjure=.08,push=.46,contact=.68,capture=.80,victory=1.08),level_match='D and E dry previews independently match -24.5dBFS RMS over1.65s; compare texture apart from loudness')
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(json.dumps(previews,indent=2))
