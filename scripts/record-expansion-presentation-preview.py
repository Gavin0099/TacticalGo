#!/usr/bin/env python3
"""Actual SwiftUI confirmed-receipt capture; authored postmix, never phone live AV."""
import json,signal,subprocess,time,sys,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'artifacts/v11/feel-10/video';OUT.mkdir(parents=True,exist_ok=True)
DEVICE='44259159-744B-4270-85A2-86CF756C100F';APP='com.tacticalgo.prototype'
cases=[('rogue-390-7','Rogue',7,'Black',390,[], 'rogue-B-mix.wav'),('priest-390-7','Priest',7,'Black',390,[], 'priest-B-mix.wav'),('mage-double-390-7','Mage',7,'Black',390,[],None),('warrior-reform-390-7','Warrior',7,'Black',390,[],None),('rogue-320-9-white-dense','Rogue',9,'White',320,['--exp-review-dense'],'rogue-B-mix.wav'),('priest-320-9-white-dense','Priest',9,'White',320,['--exp-review-dense'],'priest-B-mix.wav')]
if '--first' in sys.argv:cases=cases[:1]
records=json.loads((OUT/'manifest.json').read_text()) if (OUT/'manifest.json').exists() else []
for name,hero,size,owner,width,extra,mix in cases:
 if any(r['name']==name for r in records):continue
 args=['--expansion-lab','--exp-review',hero,'--exp-review-size',str(size),'--exp-review-owner',owner,'--exp-review-width',str(width),'--exp-autoplay']+extra
 raw=OUT/f'{name}-native-silent.mp4';clock=OUT/f'{name}-clock.log'
 if not raw.exists():
  clock.write_text('');rec=subprocess.Popen(['xcrun','simctl','io',DEVICE,'recordVideo','--codec=h264',str(raw)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True);lines=[]
  while True:
   line=rec.stderr.readline();assert line,'Recorder did not become ready';lines.append(line)
   if 'Recording started' in line:break
  ready=time.time()
  try:
   subprocess.run(['xcrun','simctl','launch','--terminate-running-process','--stdout='+str(clock),DEVICE,APP]+args,check=True,stdout=subprocess.DEVNULL);time.sleep(8)
  finally:
   rec.send_signal(signal.SIGINT);_,tail=rec.communicate(timeout=20);(OUT/f'{name}-recorder.log').write_text(''.join(lines)+tail)
 else:
  assert '--resume' in sys.argv,'Existing original capture retained; pass --resume';ready=None
 assert 'EXPANSION_RECEIPT' in clock.read_text(),clock.read_text()
 frames=OUT/f'{name}-hud-frames';frames.mkdir(exist_ok=True)
 subprocess.run(['ffmpeg','-v','error','-i',str(raw),'-vf','fps=60,crop=iw:ih*0.16:0:ih*0.05','-t','6.5',str(frames/'frame-%04d.png')],check=True)
 onset=json.loads(subprocess.check_output(['swift',str(ROOT/'scripts/locate-expansion-video-onset.swift'),str(frames),'4' if hero=='Priest' else '2']))
 start=max(0,onset['native_visual_onset']-.35);lead=onset['native_visual_onset']-start
 audio=ROOT/'assets/candidates/feel-10/audio'/mix if mix else ROOT/'assets/candidates/warrior-07/audio/cast-B-mix.wav' if hero=='Warrior' else ROOT/'assets/candidates/voice-06/cast-B-mix.wav'
 if not audio.exists():audio=None
 movie=OUT/f'{name}-native-postmix.mp4'
 if audio:
  command=['ffmpeg','-v','error','-i',str(raw),'-i',str(audio),'-filter_complex',f'[0:v]fps=60,tpad=stop_mode=clone:stop_duration=2,trim=start={start},setpts=PTS-STARTPTS[v];[1:a]adelay={round(lead*1000)}:all=1,apad[a]','-map','[v]','-map','[a]','-t','2.35','-c:v','libx264','-preset','fast','-crf','19','-c:a','aac','-b:a','160k','-movflags','+faststart',str(movie)]
 else:command=['ffmpeg','-v','error','-i',str(raw),'-vf',f'fps=60,tpad=stop_mode=clone:stop_duration=2,trim=start={start},setpts=PTS-STARTPTS','-t','2.35','-c:v','libx264','-preset','fast','-crf','19','-movflags','+faststart',str(movie)]
 subprocess.run(command,check=True)
 records.append(dict(name=name,hero=hero,owner=owner,size=size,width_pt=width,args=args,raw=str(raw.relative_to(ROOT)),raw_sha256=hashlib.sha256(raw.read_bytes()).hexdigest(),postmix=str(movie.relative_to(ROOT)),postmix_sha256=hashlib.sha256(movie.read_bytes()).hexdigest(),audio=str(audio.relative_to(ROOT)) if audio else None,clock=str(clock.relative_to(ROOT)),onset=onset,trim=start,lead=lead,ready_wall=ready,platform='actual native SwiftUI iOS Simulator, engineering diagram fixture',sync_limit='actual HUD resource transition at60fps; authored postmix; not measured phone AV latency',human_art_voice_balance='pending'))
 (OUT/'manifest.json').write_text(json.dumps(records,indent=2)+'\n');print(name,flush=True)
