#!/usr/bin/env python3
"""Actual native scenes with receipt/frame aligned authored postmix, not live AV."""
import json,re,signal,subprocess,time,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'artifacts/v11/warrior-07/video';OUT.mkdir(exist_ok=True)
DEVICE='44259159-744B-4270-85A2-86CF756C100F';APP='com.tacticalgo.prototype'
cases=[('body-only-390-7',['--warrior-board-390','--warrior-body-only'],None),('old-390-7',['--warrior-board-390','--warrior-original'],'original'),('new-390-7',['--warrior-board-390'],'B'),('new-320-9-white-dense',['--warrior-board-320','--warrior-9','--warrior-white','--warrior-dense'],'B'),('new-390-7-capture',['--warrior-board-390','--warrior-capture','--warrior-voice-B'],'B')]
records=json.loads((OUT/'manifest.json').read_text()) if (OUT/'manifest.json').exists() else []
if '--body-review' in sys.argv:cases=cases[:1]
for name,args,take in cases:
    if any(r['name']==name for r in records):continue
    raw=OUT/f'{name}-native-silent.mp4';clock=OUT/f'{name}-clock.log'
    ready=None
    if raw.exists():
        assert '--resume' in sys.argv,'Use explicit --resume to retain an existing raw capture'
    else:
        clock.write_text('')
        rec=subprocess.Popen(['xcrun','simctl','io',DEVICE,'recordVideo','--codec=h264',str(raw)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        lines=[]
        while True:
            line=rec.stderr.readline();assert line,'Recorder not ready'
            lines.append(line)
            if 'Recording started' in line:break
        ready=time.time()
        try:
            subprocess.run(['xcrun','simctl','launch','--terminate-running-process','--stdout='+str(clock),DEVICE,APP,'--presentation-lab','--presentation-warrior','--warrior-autoplay']+args,check=True,stdout=subprocess.DEVNULL)
            time.sleep(10)
        finally:
            rec.send_signal(signal.SIGINT);_,tail=rec.communicate(timeout=20);(OUT/f'{name}-recorder.log').write_text(''.join(lines)+tail)
    assert 'WARRIOR_RECEIPT' in clock.read_text()
    frames=OUT/f'{name}-receipt-frames-v2';frames.mkdir(exist_ok=True)
    subprocess.run(['ffmpeg','-v','error','-i',str(raw),'-vf','fps=60,crop=iw*0.98:ih*0.40:iw*0.01:ih*0.53','-t','6.5',str(frames/'frame-%04d.png')],check=True)
    onset=json.loads(subprocess.check_output(['swift',str(ROOT/'scripts/locate-warrior-video-onset.swift'),str(frames)]))
    start=max(0,onset['native_visual_onset']-.35);lead=onset['native_visual_onset']-start
    audio=ROOT/'assets/candidates/warrior-07/audio'/f'cast-{take}-mix.wav' if take else None
    movie=OUT/f'{name}-native-postmix.mp4'
    if audio:
        # Capture outcome sound is intentionally excluded from review postmix:
        # review action packet vs live players remain separate evidence surfaces.
        command=['ffmpeg','-v','error','-i',str(raw),'-i',str(audio),'-filter_complex',f'[0:v]fps=60,tpad=stop_mode=clone:stop_duration=2,trim=start={start},setpts=PTS-STARTPTS[v];[1:a]adelay={round(lead*1000)}:all=1,apad[a]','-map','[v]','-map','[a]','-t','2.35','-c:v','libx264','-preset','fast','-crf','19','-c:a','aac','-b:a','160k','-movflags','+faststart',str(movie)]
    else:
        command=['ffmpeg','-v','error','-i',str(raw),'-vf',f'fps=60,tpad=stop_mode=clone:stop_duration=2,trim=start={start},setpts=PTS-STARTPTS','-t','2.35','-c:v','libx264','-preset','fast','-crf','19','-movflags','+faststart',str(movie)]
    subprocess.run(command,check=True)
    for phase,at in [('coil',.20),('contact',.58),('rest',1.02)]:
        subprocess.run(['ffmpeg','-v','error','-i',str(raw),'-vf',f"fps=60,select=eq(n\,{round((onset['native_visual_onset']+at)*60)})",'-frames:v','1',str(OUT/f'{name}-{phase}.png')],check=True)
    records.append(dict(name=name,args=args,take=take,raw=str(raw.relative_to(ROOT)),postmix=str(movie.relative_to(ROOT)),clock=str(clock.relative_to(ROOT)),onset=onset,trim=start,lead=lead,ready_wall=ready,platform='actual SwiftUI iOS Simulator',sync_limit='receipt label frame at60fps; not live physical AV calibration',audio='authored action packet postmix; no BGM; capture/victory sound excluded' if audio else 'body-only native silent'))
    (OUT/'manifest.json').write_text(json.dumps(records,indent=2)+'\n');print(name,flush=True)
if '--body-review' not in sys.argv:
    subprocess.run(['ffmpeg','-v','error','-i',str(OUT/'old-390-7-native-postmix.mp4'),'-i',str(OUT/'new-390-7-native-postmix.mp4'),'-filter_complex','[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]','-map','[v]','-map','[a]','-c:v','libx264','-crf','19','-c:a','aac','-movflags','+faststart',str(OUT/'old-new-normal-speed-postmix.mp4')],check=True)
