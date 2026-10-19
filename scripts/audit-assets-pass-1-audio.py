#!/usr/bin/env python3
"""Measure original or v30 PCM with ffmpeg EBU R128; no listening claims.
Sub-400ms sounds are padded to 400ms for EBU's minimum momentary window.
"""
import argparse,hashlib,json,re,subprocess,wave,math
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('stage',choices=['before','after']);args=p.parse_args();OUT=ROOT/'artifacts/assets-pass-1/audio'/args.stage;OUT.mkdir(parents=True,exist_ok=True)
audio=ROOT/'ios/TacticalGo/Audio';paths=list(audio.glob('*.wav'))
paths += [q for q in (ROOT/'ios/TacticalGo/PresentationLab').rglob('*.wav') if 'voice' not in q.name and not q.name.startswith('mage-cast-')]
if args.stage=='after':
 paths += [audio/q.name for q in (audio/'V30').glob('*.wav') if not any(p.name==q.name for p in paths)]
records=[]
for original in sorted(paths):
 candidate=audio/'V30'/original.name;path=candidate if args.stage=='after' and candidate.exists() else original
 with wave.open(str(path),'rb') as w: rate=w.getframerate();ch=w.getnchannels();n=w.getnframes();width=w.getsampwidth();raw=w.readframes(n)
 assert width==2
 pcm=np.frombuffer(raw,dtype='<i2').reshape(-1,ch);samples=pcm.astype(float)/32768;mono=samples.mean(axis=1);duration=n/rate
 peak=float(np.max(np.abs(samples)));rms=float(np.sqrt(np.mean(samples**2)));endpoint=int(np.max(np.abs(pcm[-1].astype(int)-pcm[0].astype(int))))
 # Whole-record spectrum is enough to describe broad overlap, not perceptual quality.
 fft=np.abs(np.fft.rfft(mono));freq=np.fft.rfftfreq(n,1/rate);centroid=float(np.sum(freq*fft)/(np.sum(fft)+1e-12));bands={f'{low}-{high}Hz':round(float(np.sum(fft[(freq>=low)&(freq<high)]**2)/(np.sum(fft**2)+1e-20)),4) for low,high in [(0,250),(250,2000),(2000,20000)]}
 af=('apad=whole_dur=0.4,' if duration<.4 else '')+'ebur128=peak=true'
 result=subprocess.run(['ffmpeg','-hide_banner','-nostats','-i',str(path),'-af',af,'-f','null','-'],capture_output=True,text=True,check=True)
 (OUT/(path.stem+'-ebur128.txt')).write_text(result.stderr)
 integrated=float(re.findall(r'I:\s*(-?[\d.]+) LUFS',result.stderr)[-1]);truepeak=float(re.findall(r'Peak:\s*(-?[\d.]+) dBFS',result.stderr)[-1])
 active=np.where(np.max(np.abs(samples),axis=1)>10**(-60/20))[0];tail=round((active[-1]+1)/rate,5) if len(active) else 0
 record=dict(key=path.stem,original=str(original.relative_to(ROOT)),measured=str(path.relative_to(ROOT)),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),duration_seconds=round(duration,6),sample_rate_hz=rate,channels=ch,peak_dbfs=round(20*math.log10(peak+1e-20),2),true_peak_dbfs=truepeak,rms_dbfs=round(20*math.log10(rms+1e-20),2),integrated_lufs=integrated,ebur128_padding_seconds=round(max(0,.4-duration),6),active_end_minus60db_seconds=tail,boundary_jump_pcm=endpoint,clipped_samples=int(np.count_nonzero(np.abs(pcm.astype(int))>=32767)),spectral_centroid_hz=round(centroid),energy_bands=bands,changed=path!=original)
 records.append(record)
 # Waveform min/max per image column. Unscaled acoustic sample axes; PNG is a scientific diagnostic.
 canvas=Image.new('RGB',(1000,190),(247,246,240));d=ImageDraw.Draw(canvas);d.text((12,8),f'{path.stem}: {duration:.3f}s  peak {record["peak_dbfs"]}dBFS  I {integrated}LUFS',fill=(30,40,40));d.line((20,100,980,100),fill=(170,170,170))
 for x in range(960):
  chunk=mono[x*n//960:max(x*n//960+1,(x+1)*n//960)]
  d.line((20+x,100-float(chunk.max())*70,20+x,100-float(chunk.min())*70),fill=(20,105,115))
 canvas.save(OUT/(path.stem+'-waveform.png'))
 print(path.stem,integrated,flush=True)
(OUT/'metrics.json').write_text(json.dumps(records,indent=2)+'\n')
