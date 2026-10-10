"""Same-fixture unretimed native comparison. Captions remain outside the viewport."""
import hashlib,json,pathlib,subprocess
from PIL import Image,ImageDraw,ImageFont
R=pathlib.Path(__file__).resolve().parents[1];D=R/'artifacts/ios/anim-warrior-body-02/media';B=R/'artifacts/ios/anim-warrior-rogue-01/media-warrior-impact'
a=json.loads((B/'edit-audit.json').read_text())['clips'][1];b=json.loads((D/'edit-audit.json').read_text())['clips'][1]
for k in ['class','scenario','before','after','events']:assert a[k]==b[k],k
assert a['speed']==b['speed']==1
header=Image.new('RGB',(1080,56),'#243F43');draw=ImageDraw.Draw(header);font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',19)
draw.text((12,10),'PREVIOUS: two-stage stroke',fill='white',font=font);draw.text((552,10),'BODY-02: continuous strike / shared landing',fill='white',font=font)
header.save(D/'comparison-header.png');out=D/'warrior-before-after-native.mp4';duration=max(a['duration'],b['duration'])
subprocess.run(['ffmpeg','-y','-v','error','-i',str(B/'native-1.mp4'),'-i',str(D/'native-1.mp4'),'-i',str(D/'comparison-header.png'),'-filter_complex',f'[0:v]setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=0.5[l];[1:v]setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=0.5[r];[l][r]hstack=inputs=2,pad=iw:ih+56:0:56:color=0x243F43[s];[s][2:v]overlay=0:0[v]','-map','[v]','-t',str(duration),'-an','-c:v','libx264','-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',str(out)],check=True)
(D/'comparison-audit.json').write_text(json.dumps({'sameBeforeAfterEvents':True,'baseline':'eb7be20 / previous native skill clip1','candidate':'ANIM warrior body02 / native skill clip1','speed':1,'alignment':'Both clips start450ms before actual successful receipt uptime; no retiming. Frame scheduling is not exact motion capture. Only final still extended to match duration.','noAudio':True,'sha256':hashlib.sha256(out.read_bytes()).hexdigest()},indent=2)+'\n')
