#!/usr/bin/env python3
"""Content/PCM audition checks; never asserts acting quality from numbers."""
import pathlib,json,wave,hashlib,re,subprocess
import numpy as np
from scipy.signal import correlate,find_peaks,resample_poly
ROOT=pathlib.Path(__file__).resolve().parents[1];P=ROOT/'artifacts/audio/hero-voice-performance-01'
FF='/opt/homebrew/bin/ffmpeg'
rows=json.loads((P/'selected-takes.json').read_text());qa=[]
def read(path):
 with wave.open(str(path)) as w: rate=w.getframerate();c=w.getnchannels();assert w.getsampwidth()==2;data=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').reshape(-1,c).mean(axis=1).astype(float)/32768
 return data,rate
def write(path,a,rate):
 assert np.max(np.abs(a))<1
 with wave.open(str(path),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(np.round(a*32767).astype('<i2').tobytes())
def convert(wav,mp3):
 subprocess.run([FF,'-y','-loglevel','error','-i',str(wav),'-codec:a','libmp3lame','-b:a','128k',str(mp3)],check=True)
for r in rows:
 f=P/r['file'];a,hz=read(f);clipped=int(np.sum(np.abs(a)>=32767/32768));assert clipped==0
 assert .3<len(a)/hz<5,'Unexpected duration; review words before accepting'
 pitches=[]
 for at in range(0,len(a)-int(hz*.04),int(hz*.01)):
  x=a[at:at+int(hz*.04)];x=x-x.mean()
  if np.sqrt(np.mean(x*x))<.015:continue
  ac=correlate(x*np.hanning(len(x)),x*np.hanning(len(x)),mode='full',method='fft')[len(x)-1:];low=int(hz/500);high=int(hz/65)
  peaks,_=find_peaks(ac[low:high]);
  if len(peaks):
   lag=int(peaks[np.argmax(ac[low:high][peaks])]+low)
   if ac[lag]/max(ac[0],1e-12)>.35:pitches.append(hz/lag)
 qa.append({'file':r['file'],'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'duration_seconds':len(a)/hz,'clipped_samples':clipped,'RMS_dbfs':float(20*np.log10(np.sqrt(np.mean(a*a)))),'peak_dbfs':float(20*np.log10(np.max(np.abs(a)))),'pitch_median_Hz':float(np.median(pitches)) if pitches else None,'pitch_p10_p90_Hz':np.percentile(pitches,[10,90]).tolist() if pitches else [],'pitch_scope':'rough acoustic descriptor, not performance/identity approval'})
 convert(f,f.with_suffix('.mp3'))
for hero in ['warrior','mage']:
 arrays=[]
 old,oldrate=read(ROOT/f'ios/TacticalGo/Audio/Voice/voice-{hero}-skill.wav');old=resample_poly(old,160,147)
 gain=min(.1/np.sqrt(np.mean(old**2)),10**(-3/20)/np.max(np.abs(old)));old*=gain
 arrays.append(old)
 for take in ['A','B']: arrays.append(read(P/next(r['file'] for r in rows if r['hero']==hero and r['take']==take))[0])
 whole=np.concatenate([np.concatenate([a,np.zeros(round(.8*24000))]) for a in arrays]);suffix='old-A-B3' if hero=='mage' and any(x['file']=='mage-B3-dry.wav' for x in rows) else 'old-A-B'
 w=P/f'{hero}-{suffix}.wav';write(w,whole,24000);convert(w,w.with_suffix('.mp3'))
(P/'PCM-CHECK.json').write_text(json.dumps({'status':'PASS','scope':'PCM/content prerequisites only; human expression Gate Pending','checks':qa,'comparison_order':'old rejected Piper -> new A -> new B (mage B3); 0.8sec silent gaps; approximate matched RMS -20dBFS, peak capped -3','effects':'none'},indent=2)+'\n')
print('PCM PASS; four dry takes and two old-A-B comparisons. Acting quality Pending.')
