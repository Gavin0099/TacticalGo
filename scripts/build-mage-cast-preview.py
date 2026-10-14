#!/usr/bin/env python3
"""Review postmix follows Lab gain/clock; never presented as live phone audio."""
import array, hashlib, json, math, subprocess, wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/candidates/voice-06'; RATE=44100
def decode(p):
    a=array.array('f');a.frombytes(subprocess.check_output(['ffmpeg','-v','error','-i',str(p),'-ac','1','-ar',str(RATE),'-f','f32le','-']));return a
rows=[]
for take in ['A','B']:
    speech=decode(OUT/f'mage-{take}-dry.wav');end=.08+len(speech)/RATE
    recovery=max(1.08,end)
    mix=[0.0]*round(1.65*RATE)
    for key,at in [('p5-conjure',.08),('p5-push',.46),('p5-contact',.68)]:
        s=decode(ROOT/'ios/TacticalGo/PresentationLab/P05'/f'{key}.wav')
        for i,x in enumerate(s):
            j=round(at*RATE)+i;t=j/RATE
            # Lab schedules all three sounds at .42 gain, then recovers
            # in four cancellable 30ms steps after speech/animation finish.
            duck=.42 if t<recovery else .42+.58*min(4,int((t-recovery)/.03)+1)/4
            if j<len(mix):mix[j]+=x*.65*duck
    for i,x in enumerate(speech):mix[round(.08*RATE)+i]+=x*.85
    peak=max(map(abs,mix));assert peak<.95
    path=OUT/f'cast-{take}-mix.wav'
    with wave.open(str(path),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'));f.writeframes(array.array('h',(round(x*32767) for x in mix)).tobytes())
    rows.append(dict(take=take,file=str(path.relative_to(ROOT)),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),voice_start=.08,voice_end=end,recovery=recovery,voice_volume=.85,sfx_volume=.65,sfx_duck=.42,peak_dbfs=20*math.log10(peak),rms_dbfs=20*math.log10(math.sqrt(sum(x*x for x in mix)/len(mix)))))
    video=ROOT/'artifacts/v11/voice-06'/f'cast-{take}-native-postmix.mp4'
    subprocess.run(['ffmpeg','-y','-v','error','-i',str(ROOT/'artifacts/v11/present-04/video-aligned/D-390-7-simulator-postmix.mp4'),'-i',str(path),'-filter_complex','[1:a]adelay=350:all=1,apad[a]','-map','0:v','-map','[a]','-t','1.85','-c:v','copy','-c:a','aac','-b:a','160k','-movflags','+faststart',str(video)],check=True)
(OUT/'mix-manifest.json').write_text(json.dumps({'scope':'accepted native D animation reused with authored postmix; not live phone audio','takes':rows},indent=2)+'\n')
print(json.dumps(rows,indent=2))
