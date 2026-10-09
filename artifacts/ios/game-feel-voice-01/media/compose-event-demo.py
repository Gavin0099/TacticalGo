"""Real native video; event-timed reconstruction, explicitly NOT system audio capture."""
import json,pathlib,subprocess,wave,sys,numpy as np
from PIL import Image,ImageDraw,ImageFont
P=pathlib.Path(__file__).resolve().parent; ROOT=P.parents[3]; FF='/opt/homebrew/bin/ffmpeg'
ordinary='--ordinary' in sys.argv
if ordinary:P=P/'ordinary'
clock=json.loads((P/'capture-clock.json').read_text()); start=clock['recordReadyUptime']
receipts=[r for r in json.loads((P/'game-feel-receipts.json').read_text()) if start<r['receiptUptime']<clock['recordStopUptime']]
trace=json.loads((P/'game-feel-audio-trace.json').read_text()); trace.sort(key=lambda x:x['uptime'])
assets=ROOT/'ios/TacticalGo/Audio'; rate=44100
labels=['Warrior / summon','Warrior / Hold the line','Mage / summon','Mage / Off you go','Rogue / summon','Rogue / Lets switch','Mage / capture + victory']
if ordinary:labels=['Ordinary drop / commander captured / undo verified']
assert len(receipts)==len(labels)
clips=[]; audit=[]
for i,(r,title) in enumerate(zip(receipts,labels)):
 a=r['receiptUptime']-1.25;b=r['receiptUptime']+2.05; duration=b-a
 caption=Image.new('RGBA',(1170,166),(23,44,45,248)); d=ImageDraw.Draw(caption)
 font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',30)
 d.text((24,10),'NATIVE iOS SIMULATOR / PROTOTYPE ENGLISH VO',font=font,fill='#fff1cf')
 d.text((24,55),'EVENT-TIMED POSTMIX / NOT DEVICE AUDIO CAPTURE',font=font,fill='white')
 d.text((24,106),title+' / successful Domain receipt',font=font,fill='#ffdf75')
 png=P/f'caption-{i}.png';caption.save(png)
 mix=np.zeros((round(duration*rate),2)); events=[]
 for e in trace:
  if e['kind'] not in ['voice','sfx'] or not e['playing'] or not a<=e['uptime']<b:continue
  f=assets/('Voice' if e['kind']=='voice' else '')/(e['key']+'.wav')
  if not f.exists():raise FileNotFoundError(f)
  with wave.open(str(f)) as w: samples=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').reshape(-1,w.getnchannels())/32768; hz=w.getframerate()
  count=round(len(samples)*rate/hz); times=np.arange(count)*hz/rate
  samples=np.stack([np.interp(times,np.arange(len(samples)),samples[:,c]) for c in range(samples.shape[1])],axis=1)
  if samples.shape[1]==1:samples=np.repeat(samples,2,axis=1)
  stop=next((x['uptime'] for x in trace if x['uptime']>e['uptime'] and x['kind']=='stop-'+e['kind']),b)
  samples=samples[:max(0,round((min(stop,b)-e['uptime'])*rate))]*e['volume']
  at=round((e['uptime']-a)*rate); n=min(len(samples),len(mix)-at)
  mix[at:at+n]+=samples[:n];events.append(e)
 peak=float(np.max(np.abs(mix))); assert peak<1,(i,peak)
 wav=P/f'mix-{i}.wav'
 with wave.open(str(wav),'wb') as w:w.setnchannels(2);w.setsampwidth(2);w.setframerate(rate);w.writeframes((mix*32767).astype('<i2').tobytes())
 clip=P/f'clip-{i}.mp4'
 command=[FF,'-y','-loglevel','error','-ss',str(a-start),'-t',str(duration),'-i',str(P/'native-ui-silent.mov'),'-loop','1','-i',str(png),'-i',str(wav),'-filter_complex','[0:v][1:v]overlay=0:H-h,scale=584:-2[v]','-map','[v]','-map','2:a','-t',str(duration),'-c:v','libx264','-preset','fast','-crf','23','-c:a','aac','-b:a','160k','-pix_fmt','yuv420p',str(clip)]
 subprocess.run(command,check=True);clips.append(clip);audit.append({'title':title,'receipt':r['id'],'before':r['before'],'after':r['after'],'windowUptime':[a,b],'audioEvents':events,'mixPeak':peak})
(P/'concat.txt').write_text(''.join("file '"+str(c)+"'\n" for c in clips))
subprocess.run([FF,'-y','-loglevel','error','-f','concat','-safe','0','-i',str(P/'concat.txt'),'-c','copy','-movflags','+faststart',str(P/'native-hero-game-feel-demo.mp4')],check=True)
for i,name in ([] if ordinary else [(2,'A-mage-summon'),(3,'B-magic-hand'),(6,'B-magic-hand-capture')]):
 (P/(name+'.mp4')).write_bytes(clips[i].read_bytes())
(P/'demo-edit-audit.json').write_text(json.dumps({'audio':'event-timed postmix; AVAudioPlayer actual start and volume; not recorded system audio','timingBoundary':'capture-ready acknowledgement used as zero; no hardware audiovisual synchronization claim','clips':audit},indent=2))
print('PASS',len(receipts),'real receipt clips / mix peaks below 1')
