#!/usr/bin/env python3
"""Actual native Simulator A/D captures; authored spectral-hand SFX postmix.
No synthetic frames. Recorder wall anchor is an estimate, not device AV sync.
"""
import json
from pathlib import Path
import re
import signal
import subprocess
import time
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artifacts/v11/present-04/video-predecoded';OUT.mkdir(parents=True,exist_ok=True)
DEVICE='44259159-744B-4270-85A2-86CF756C100F';APP='com.tacticalgo.prototype'
cases=[('A-390-7',['--presentation-A','--presentation-board-390'],'A'),
       ('D-390-7',['--presentation-D','--presentation-board-390'],'D'),
       ('A-320-9-white-dense',['--presentation-A','--presentation-board-320','--presentation-9','--presentation-white','--presentation-dense'],'A'),
       ('D-320-9-white-dense',['--presentation-D','--presentation-board-320','--presentation-9','--presentation-white','--presentation-dense'],'D'),
       ('D-body-only',['--presentation-D','--presentation-board-390','--presentation-body-only'],'D')]
records=[]
for name,args,audio_variant in cases:
    raw=OUT/(name+'-native-silent.mp4');clock=OUT/(name+'-clock.log')
    assert not raw.exists(),'Preserve old recordings; select fresh output folder.'
    clock.write_text('')
    rec=subprocess.Popen(['xcrun','simctl','io',DEVICE,'recordVideo','--codec=h264',str(raw)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    lines=[]
    while True:
        line=rec.stderr.readline()
        if not line: raise RuntimeError('Recorder not ready: '+''.join(lines))
        lines.append(line)
        if 'Recording started' in line: break
    ready=time.time()
    subprocess.run(['xcrun','simctl','launch','--terminate-running-process','--stdout='+str(clock),DEVICE,APP,'--presentation-lab','--presentation-autoplay']+args,check=True,stdout=subprocess.DEVNULL)
    time.sleep(8.1)
    rec.send_signal(signal.SIGINT);_,tail=rec.communicate(timeout=20)
    (OUT/(name+'-recorder.log')).write_text(''.join(lines)+tail)
    clocks=re.findall(r'PRESENT_CLOCK (\w+) wall=([\d.]+) uptime=([\d.]+)',clock.read_text())
    assert clocks,'Missing actual successful receipt clock'
    event=float(clocks[0][1]);estimate=event-ready;trim=max(0,estimate-.35);lead=estimate-trim
    postmix=OUT/(name+'-simulator-postmix.mp4')
    audio=ROOT/'assets/candidates/present-04/audio'/(audio_variant+'-sfx.wav')
    subprocess.run(['ffmpeg','-v','error','-i',str(raw),'-i',str(audio),'-filter_complex',
        f'[0:v]fps=60,tpad=stop_mode=clone:stop_duration=2,trim=start={trim},setpts=PTS-STARTPTS[v];[1:a]adelay={round(lead*1000)}:all=1,apad[a]',
        '-map','[v]','-map','[a]','-t','1.85','-c:v','libx264','-preset','fast','-crf','19','-c:a','aac','-b:a','160k','-movflags','+faststart',str(postmix)],check=True)
    records.append({'name':name,'args':args,'raw':str(raw.relative_to(ROOT)),'postmix':str(postmix.relative_to(ROOT)),
         'audio':str(audio.relative_to(ROOT)),'receipt_clock':clocks[0],'ready_wall':ready,'trim':trim,'lead':lead,
         'platform':'actual SwiftUI iOS Simulator','sound':'SFX postmix; not live phone audio; no voice or BGM',
         'sync_limit':'Encoder startup latency unmeasured; readiness wall estimate',
         'idle_hold':'Repeat final native idle frame to cover variable-frame-rate recording tail; raw retained','input':'castMagicHand(Point(4,3),up)','owner_quality':'not claimed'})
    print(name+' native/postmix retained',flush=True)
(OUT/'manifest.json').write_text(json.dumps(records,indent=2)+'\n')
subprocess.run(['xcrun','simctl','launch','--terminate-running-process',DEVICE,APP,'--presentation-lab','--presentation-D'],check=True,stdout=subprocess.DEVNULL)
