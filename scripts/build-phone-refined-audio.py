#!/usr/bin/env python3
"""PRESENT-03: keep original SFX, add one quiet CC0 natural-air stem."""
import array
import hashlib
import json
import math
from pathlib import Path
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/candidates/present-03/audio'
RESOURCE = ROOT / 'ios/TacticalGo/PresentationLab/P03'
RESOURCE.mkdir(exist_ok=True)
RATE = 44100
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()

def decode(path, filters='anull'):
    pcm = subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-af',filters,
                                  '-ac','1','-ar',str(RATE),'-f','f32le','-'])
    a=array.array('f'); a.frombytes(pcm); return list(a)

def save(path, values):
    assert max(map(abs,values)) < 0.95
    pcm=array.array('h',(round(x*32767) for x in values))
    with wave.open(str(path),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed')); f.writeframes(pcm.tobytes())
    return {'file':str(path.relative_to(ROOT)),'sha256':sha(path),
            'duration':len(values)/RATE,'sample_rate':RATE,'channels':1,'peak_dbfs':20*math.log10(max(map(abs,values))),
            'rms_dbfs':20*math.log10(math.sqrt(sum(x*x for x in values)/len(values))),
            'dc':sum(values)/len(values),'first':values[0],'last':values[-1]}

raw=OUT/'raw/sand-spell.flac'
filters='atrim=start=0.07:end=0.29,asetpts=PTS-STARTPTS,highpass=f=500,lowpass=f=4200'
air=decode(raw,filters)
air=air[:round(.22*RATE)]
gain=10**(-33/20)/math.sqrt(sum(x*x for x in air)/len(air))
air=[x*gain*min(1,i/(.02*RATE),(len(air)-1-i)/(.06*RATE)) for i,x in enumerate(air)]
stem=save(OUT/'air-isolated.wav',air)
(RESOURCE/'p3-air.wav').write_bytes((OUT/'air-isolated.wav').read_bytes())

previews=[]
for variant in ['A','C']:
    for capture in [False,True]:
        mix=[0.0]*round((3.2 if capture else 1.5)*RATE)
        cues=[('mage',.26),('place',.60)]
        if variant=='C': cues.insert(1,('p3-air',.38))
        if capture: cues.extend([('capture',.70),('victory',.95)])
        for key,at in cues:
            samples=air if key=='p3-air' else decode(ROOT/'ios/TacticalGo/Audio'/(key+'.wav'))
            for i,value in enumerate(samples):
                j=round(at*RATE)+i
                if j<len(mix): mix[j]+=value*.65
        previews.append(save(OUT/(variant+('-capture' if capture else '')+'-sfx.wav'),mix))

manifest={'candidate':'owner listening pending','source':{'author':'qubodup',
          'page':'https://opengameart.org/content/sand-spell','download':'https://opengameart.org/sites/default/files/sand-spell.flac',
          'license':'CC0','description':'Author describes a mouth-made air sound, sped up and faded. Not our recording.',
          'sha256':sha(raw),'retained_page_sha256':sha(OUT/'raw/source-page.html')},
          'processing':{'filter':filters,'target_dry_rms_dbfs':-33,'gain':gain,'fade_in':.02,'fade_out':.06,'duration':.22},
          'original_samples':[{'key':key,'sha256':sha(ROOT/'ios/TacticalGo/Audio'/(key+'.wav'))} for key in ['mage','place','capture','victory']],
          'timing':{'mage':.26,'air':.38,'place':.60,'capture':.70,'victory':.95},
          'stem':stem,'previews':previews,'voice':False,'new_synthesized_tones':False,
          'resource_sha256':sha(RESOURCE/'p3-air.wav')}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Original SFX retained; one quiet natural-air stem and four dry previews built.')
