#!/usr/bin/env python3
"""PRESENT-04 authored air/wood packet. Retain raw/stems and honest provenance."""
import array, hashlib, json, math, shutil, subprocess, wave, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/candidates/present-04/audio';RESOURCE=ROOT/'ios/TacticalGo/PresentationLab/P04';RATE=44100
for name in ['raw','stems']: (OUT/name).mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def decode(path,filters='anull'):
    b=subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-af',filters,'-ac','1','-ar',str(RATE),'-f','f32le','-'])
    a=array.array('f');a.frombytes(b);return list(a)
def envelope(a,duration,fadein,fadeout,target):
    n=round(duration*RATE);a=(a+[0.0]*n)[:n]
    a=[x*min(1,i/(fadein*RATE),(n-1-i)/(fadeout*RATE)) for i,x in enumerate(a)]
    gain=min(.72/max(map(abs,a)),10**(target/20)/math.sqrt(sum(x*x for x in a)/n))
    return [x*gain for x in a]
def save(path,a):
    assert max(map(abs,a))<.95
    with wave.open(str(path),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'));f.writeframes(array.array('h',(round(x*32767) for x in a)).tobytes())
    return dict(file=str(path.relative_to(ROOT)),sha256=sha(path),duration=len(a)/RATE,peak_dbfs=20*math.log10(max(map(abs,a))),rms_dbfs=20*math.log10(math.sqrt(sum(x*x for x in a)/len(a))),first=a[0],last=a[-1],dc=sum(a)/len(a))
raw=OUT/'raw/sand-spell.flac';shutil.copy2(ROOT/'assets/candidates/present-03/audio/raw/sand-spell.flac',raw)
shutil.copy2(ROOT/'assets/candidates/present-03/audio/raw/source-page.html',OUT/'raw/sand-source-page.html')
pack=ROOT/'assets/candidates/present-01/sources/kenney-impact-sounds.zip'
with zipfile.ZipFile(pack) as z:
    for name in ['impactWood_medium_001.ogg','impactPlank_medium_003.ogg','impactBell_heavy_002.ogg']:
        (OUT/'raw'/name).write_bytes(z.read('Audio/'+name))
    (OUT/'raw/Kenney-License.txt').write_bytes(z.read('License.txt'))
specs=[('inhale',raw,'atrim=start=0.12:end=0.50,asetpts=PTS-STARTPTS,areverse,highpass=f=260,lowpass=f=4600',.38,.10,.025,-20),
('overtone',OUT/'raw/impactBell_heavy_002.ogg','atrim=end=0.38,areverse,highpass=f=1400,lowpass=f=4500',.38,.18,.04,-31),
('flick',raw,'atrim=start=0.10:end=0.36,asetpts=PTS-STARTPTS,highpass=f=180,lowpass=f=6000',.26,.008,.08,-18),
('knock',OUT/'raw/impactWood_medium_001.ogg','atrim=end=0.22,highpass=f=100,lowpass=f=3400',.22,.002,.06,-18),
('body',OUT/'raw/impactPlank_medium_003.ogg','atrim=end=0.22,highpass=f=70,lowpass=f=850',.22,.002,.08,-25)]
layers={};files=[];processing=[]
for name,path,filters,duration,fi,fo,rms in specs:
    a=envelope(decode(path,filters),duration,fi,fo,rms);layers[name]=a
    files.append(save(OUT/'stems'/(name+'.wav'),a))
    processing.append(dict(id=name,raw=str(path.relative_to(ROOT)),raw_sha256=sha(path),filter=filters,duration=duration,fade_in=fi,fade_out=fo,target_rms=rms))
recipes={'p4-conjure':[('inhale',1),('overtone',1)],'p4-push':[('flick',1)],'p4-contact':[('knock',1),('body',1)]}
cues={}
for key,recipe in recipes.items():
    n=max(len(layers[k]) for k,_ in recipe)
    a=[sum(layers[k][i]*v if i<len(layers[k]) else 0 for k,v in recipe) for i in range(n)]
    gain=min(1,.72/max(map(abs,a)));a=[x*gain for x in a];cues[key]=a
    files.append(save(OUT/(key+'.wav'),a));shutil.copy2(OUT/(key+'.wav'),RESOURCE/(key+'.wav'))
previews=[]
for variant in ['A','D']:
    for capture in [False,True]:
        mix=[0.0]*round((3.4 if capture else 1.65)*RATE)
        times=[('mage',.26),('place',.60)] if variant=='A' else [('p4-conjure',.08),('p4-push',.46),('p4-contact',.68)]
        if capture:times += [('capture',.70 if variant=='A' else .80),('victory',.95 if variant=='A' else 1.08)]
        for key,at in times:
            a=cues[key] if key in cues else decode(ROOT/'ios/TacticalGo/Audio'/(key+'.wav'))
            for i,x in enumerate(a):
                j=round(at*RATE)+i
                if j<len(mix):mix[j]+=x*.65
        previews.append(save(OUT/(variant+('-capture' if capture else '')+'-sfx.wav'),mix))
manifest=dict(status='owner_listening_pending',sample_rate=RATE,channels=1,voice=False,bgm=False,
 sources=[dict(author='qubodup',license='CC0',page='https://opengameart.org/content/sand-spell',note='Mouth-made air recording, author processed; not our recording',sha256=sha(raw)),dict(author='Kenney',license='CC0',page='https://kenney.nl/assets/impact-sounds',archive_sha256=sha(pack),license_sha256=sha(OUT/'raw/Kenney-License.txt'))],
 processing=processing,recipes=recipes,files=files,previews=previews,timing=dict(conjure=.08,push=.46,contact=.68,capture=.80,victory=1.08),
 original_samples=[dict(key=k,sha256=sha(ROOT/'ios/TacticalGo/Audio'/(k+'.wav'))) for k in ['mage','place','capture','victory']])
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps([(p['file'],round(p['peak_dbfs'],2),round(p['rms_dbfs'],2)) for p in previews]))
