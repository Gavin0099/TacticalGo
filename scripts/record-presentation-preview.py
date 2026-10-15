#!/usr/bin/env python3
"""Record the actual Debug app on the dedicated Simulator, retain silent raw
video and wall-clock sidecars, then create clearly named SFX-only postmix clips.
No synthetic character frames or substituted Domain results.
"""
import json
from pathlib import Path
import re
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'artifacts/v11/present-01/video'
OUT.mkdir(parents=True,exist_ok=True)
DEVICE = '44259159-744B-4270-85A2-86CF756C100F'
APP = 'com.tacticalgo.prototype'
records = []

for variant in ['A','B']:
    raw = OUT/(variant+'-native-silent.mp4')
    stdout = OUT/(variant+'-app-clock.log')
    assert not raw.exists(), 'Retain prior raw recordings; choose a fresh output directory.'
    stdout.write_text('')
    recorder = subprocess.Popen(['xcrun','simctl','io',DEVICE,'recordVideo','--codec=h264',str(raw)],
        stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    lines = []
    while True:
        line = recorder.stderr.readline()
        if not line: raise RuntimeError('Recorder failed before readiness: '+''.join(lines))
        lines.append(line)
        if 'Recording started' in line: break
    ready_wall = time.time()
    args = ['--presentation-lab','--presentation-autoplay','--presentation-board-390']
    if variant == 'A': args.append('--presentation-A')
    subprocess.run(['xcrun','simctl','launch','--terminate-running-process','--stdout='+str(stdout),DEVICE,APP]+args,check=True)
    # Long enough for the first complete performance; no blocking wait exceeds 60s.
    time.sleep(4.4)
    recorder.send_signal(signal.SIGINT)
    _,tail = recorder.communicate(timeout=20)
    (OUT/(variant+'-record.log')).write_text(''.join(lines)+tail)
    clocks = re.findall(r'PRESENT_CLOCK (\w+) wall=([\d.]+) uptime=([\d.]+)',stdout.read_text())
    if not clocks: raise RuntimeError('No actual successful receipt clock in native app output.')
    event_wall = float(clocks[0][1]); estimated = event_wall-ready_wall
    # Trim to shortly before the confirmed event. Ready stderr is the time
    # anchor; this is a postmix estimate, not a captured device audio track.
    trim = max(0,estimated-.35)
    lead = estimated-trim
    clip = OUT/(variant+'-simulator-sfx-postmix.mp4')
    audio = ROOT/'assets/candidates/present-01/audio'/(variant+'-sfx-preview.wav')
    subprocess.run(['ffmpeg','-v','error','-i',str(raw),'-i',str(audio),
        '-filter_complex',f'[0:v]fps=60,trim=start={trim},setpts=PTS-STARTPTS[v];[1:a]adelay={round(lead*1000)}:all=1,apad[a]',
        '-map','[v]','-map','[a]','-t','1.65','-c:v','libx264','-preset','fast','-crf','19',
        '-c:a','aac','-b:a','160k','-movflags','+faststart',str(clip)],check=True)
    record = {'variant':variant,'raw':str(raw.relative_to(ROOT)),'postmix':str(clip.relative_to(ROOT)),
        'native_receipt_clock':clocks[0],'record_ready_wall':ready_wall,'estimated_event_offset':estimated,
        'trim_start':trim,'audio_lead':lead,'audio_source':str(audio.relative_to(ROOT)),
        'platform':'iOS Simulator, actual SwiftUI app','audio':'Postmixed SFX only; no BGM or voice; not live device audio',
        'sync_limit':'Recorder readiness wall anchor; startup/encoder latency is not measured. Raw video retained.',
        'board_width_pt':390,'board_size':7,'same_input':'castMagicHand(Point(4,3),up)'}
    records.append(record)
    print(json.dumps(record,ensure_ascii=False),flush=True)
(OUT/'manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n')
