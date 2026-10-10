"""Encoded-frame-aligned trims of actual native input; no synthesized VFX/audio or retiming."""
import hashlib,json,pathlib,subprocess,os
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=pathlib.Path(__file__).resolve().parents[1];P=R/os.environ.get('HERO_BODY_MEDIA','artifacts/ios/vfx-three-classes-01/media-strong-final')
c=json.loads((P/'capture-clock.json').read_text())
r=[x for x in json.loads((P/'game-feel-receipts.json').read_text()) if x['receiptUptime']>=c['recordReadyUptime']]
assert len(r)==18,(len(r),[x['action'] for x in r])
assert all(x['skillVFX'] and x['effectsEnabled'] for x in r)
# Find real encoded-frame AP2→AP1 registration marks. Host recorder and Simulator uptime
# are useful association evidence, but their offset must not choose a cut by themselves.
# This tiny DEBUG-only marker lives outside the board; no effects are reconstructed.
proc=subprocess.Popen(['ffmpeg','-v','error','-i',str(P/'native-ui-silent.mov'),'-vf','fps=30,scale=390:-2,crop=20:150:0:0','-pix_fmt','rgb24','-f','rawvideo','-'],stdout=subprocess.PIPE)
flags=[]
while True:
 frame=proc.stdout.read(20*150*3)
 if not frame:break
 assert len(frame)==20*150*3
 a=np.frombuffer(frame,dtype=np.uint8).reshape(150,20,3)
 flags.append(int(np.count_nonzero((a[:,:,0]>180)&(a[:,:,1]<100)&(a[:,:,2]>170)))>=12)
assert proc.wait()==0
runs=[];start=None
for frame,active in enumerate(flags+[False]):
 if active and start is None:start=frame
 if not active and start is not None:
  if frame-start>=5:runs.append((start/30,frame/30))
  start=None
assert len(runs)==len(r),(len(runs),len(r),runs)
# Normalize only the raw recorder's variable-frame-rate holds once. Keeping frame PTS
# prevents input-side seeking from dropping the quiet lead-in and truncating the animation.
# No interpolation, speed change or rendered VFX: repeat the previous recorded frame in holds.
cfr=P/'native-cfr-local.mp4'
subprocess.run(['ffmpeg','-y','-v','error','-i',str(P/'native-ui-silent.mov'),'-vf','fps=30,scale=540:-2,setpts=PTS-STARTPTS','-an','-c:v','libx264','-crf','18','-pix_fmt','yuv420p',str(cfr)],check=True)
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',16)
scenarios=['BLACK / NO CAPTURE','BLACK / REAL CAPTURE','WHITE / REAL CAPTURE','320pt / 9x9 DENSE','REDUCED MOTION','WHITE / NO CAPTURE']
clips=[];audit=[]
for i,x in enumerate(r):
 encoded,stop=runs[i];start=max(0,encoded-.40);dur=x['visualDuration']+0.80
 assert stop-encoded>=min(x['visualDuration'],0.4), (i,encoded,stop)
 # Host idle-time drift is recorded, not used as a trim boundary. Exact18 AP changes
 # associate in the same UI test order; each shot is later inspected against its class.
 assert i==0 or x['receiptUptime']>r[i-1]['receiptUptime']
 cls=x['skillVFX']['kind'].upper();assert x['before']['ap']==2 and x['after']['ap']==1
 caption=Image.new('RGB',(540,64),'#243F43');d=ImageDraw.Draw(caption)
 d.multiline_text((12,8),f"{cls} / {scenarios[i%6]}\nNative Simulator / normal speed / silent / VFX on",font=font,fill='white',spacing=6)
 png=P/f'caption-{i}.png';caption.save(png);dest=P/f'native-{i}.mp4'
 subprocess.run(['ffmpeg','-y','-v','error','-ss',str(start),'-i',str(cfr),'-i',str(png),'-t',str(dur),'-filter_complex','[0:v]fps=30,scale=540:-2,pad=iw:ih+64:0:0:color=0x243F43[s];[s][1:v]overlay=0:main_h-64[v]','-map','[v]','-an','-c:v','libx264','-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',str(dest)],check=True)
 metadata=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=start_time,duration','-of','json',str(dest)],text=True))['format']
 assert abs(float(metadata.get('start_time',0)))<0.04 and abs(float(metadata['duration'])-dur)<0.07, (i,metadata,dur)
 clips.append(dest);audit.append({'receipt':x['id'],'class':cls,'scenario':scenarios[i%6],'before':x['before'],'after':x['after'],'events':x['events'],'timing':x['skillVFX'],'start':start,'duration':dur,'encodedResourceTransition':encoded,'registrationEnd':stop,'hostClockOffset':encoded-(x['receiptUptime']-c['recordReadyUptime']),'alignment':'actual encoded AP2-to-AP1 debug marker, host clock drift logged; exact18 sequential native resource transitions','speed':1,'file':str(dest.relative_to(R)),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
def concat(name,indices):
 listing=P/(name+'.concat');listing.write_text(''.join("file '"+str(clips[i])+"'\n" for i in indices))
 subprocess.run(['ffmpeg','-y','-v','error','-f','concat','-safe','0','-i',str(listing),'-an','-c','copy','-movflags','+faststart',str(P/name)],check=True)
for n,start in [('warrior',0),('mage',6),('rogue',12)]:
 concat(n+'-vfx-full-board.mp4',range(start,start+6))
 begin=max(0,runs[start][0]-8)
 subprocess.run(['ffmpeg','-y','-v','error','-ss',str(begin),'-i',str(cfr),'-t','14','-vf','fps=30,scale=540:-2','-an','-c:v','libx264','-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',str(P/(n+'-preview-cancel-undo.mp4'))],check=True)
concat('three-class-vfx-overview.mp4',[0,6,12])
concat('three-class-dense-reduced.mp4',[3,4,9,10,15,16])
(P/'edit-audit.json').write_text(json.dumps({'source':'native-ui-silent.mov','sourceSHA256':hashlib.sha256((P/'native-ui-silent.mov').read_bytes()).hexdigest(),'claim':'Actual native SwiftUI/Simulator gestures, normal speed, silent, VFX on, captions outside viewport; DEBUG corner registration mark inside safe margin, not a skill effect. No reconstructed soundtrack or fabricated animation. Human/physical Gates not inferred.','normalization':'30fps duplicate recorded holds only; original timestamp durations retained; no interpolation/retiming or fabricated effects','cfrSHA256':hashlib.sha256(cfr.read_bytes()).hexdigest(),'clips':audit},indent=2)+'\n')
print('18 encoded-frame-aligned native clips and three-class reels written')
