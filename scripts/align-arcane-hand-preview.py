#!/usr/bin/env python3
"""Align postmixed SFX to an observable native receipt frame, not wall clock.
Retain raw movie, original estimated derivatives, OCR frames and onset result.
"""
import json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'artifacts/v11/present-04/video-predecoded'
OUT=ROOT/'artifacts/v11/present-04/video-aligned';OUT.mkdir(exist_ok=True)
records=[]
for v in json.loads((SOURCE/'manifest.json').read_text()):
    name=v['name'];frames=OUT/(name+'-receipt-frames');frames.mkdir(exist_ok=True)
    y=.628 if '-320-9' in name else .715
    subprocess.run(['ffmpeg','-v','error','-i',str(ROOT/v['raw']),'-vf',f'fps=60,crop=iw*0.80:ih*0.032:iw*0.10:ih*{y}','-t','4',str(frames/'frame-%04d.png')],check=True)
    onset=json.loads(subprocess.check_output(['swift',str(ROOT/'scripts/locate-presentation-video-onset.swift'),str(frames)]))
    (OUT/(name+'-onset.json')).write_text(json.dumps(onset,indent=2)+'\n')
    start=max(0,onset['native_visual_onset']-.35);lead=onset['native_visual_onset']-start
    movie=OUT/(name+'-simulator-postmix.mp4')
    subprocess.run(['ffmpeg','-v','error','-i',str(ROOT/v['raw']),'-i',str(ROOT/v['audio']),'-filter_complex',f'[0:v]fps=60,tpad=stop_mode=clone:stop_duration=2,trim=start={start},setpts=PTS-STARTPTS[v];[1:a]adelay={round(lead*1000)}:all=1,apad[a]','-map','[v]','-map','[a]','-t','1.85','-c:v','libx264','-preset','fast','-crf','19','-c:a','aac','-b:a','160k','-movflags','+faststart',str(movie)],check=True)
    records.append({**v,'estimated_postmix':v['postmix'],'postmix':str(movie.relative_to(ROOT)),'alignment':onset,'trim':start,'lead':lead,'sync_limit':'Native success-label transition quantized at60fps; UI/audio latency not physically calibrated. Not a live device recording.'})
    print(name,onset,flush=True)
(OUT/'manifest.json').write_text(json.dumps(records,indent=2)+'\n')
a=OUT/'A-390-7-simulator-postmix.mp4';d=OUT/'D-390-7-simulator-postmix.mp4'
subprocess.run(['ffmpeg','-v','error','-i',str(a),'-i',str(d),'-filter_complex','[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]','-map','[v]','-map','[a]','-c:v','libx264','-crf','19','-c:a','aac','-movflags','+faststart',str(OUT/'AD-normal-speed-postmix.mp4')],check=True)
