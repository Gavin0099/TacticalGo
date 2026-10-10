"""Trim real native recordings by successful receipts; no new animation frames/audio."""
import hashlib,json,pathlib,subprocess,os
from PIL import Image,ImageDraw,ImageFont
ROOT=pathlib.Path(__file__).resolve().parents[1]
P=ROOT/os.environ.get('HERO_BODY_MEDIA','artifacts/ios/anim-warrior-rogue-01/media')
c=json.loads((P/'capture-clock.json').read_text())
r=[x for x in json.loads((P/'game-feel-receipts.json').read_text()) if x['receiptUptime']>=c['recordReadyUptime']]
assert len(r)==12,(len(r),[x['action'] for x in r])
assert all(x['heroBody'] and not x['effectsEnabled'] for x in r)
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',16)
clips=[];audit=[]
scenarios=['SUMMON','SKILL','REAL CAPTURE','WHITE / REAL CAPTURE','320pt / 9x9 DENSE','REDUCED MOTION']
for i,x in enumerate(r):
    start=max(0,x['receiptUptime']-c['recordReadyUptime']-.45)
    dur=x['visualDuration']+1.05
    cls=x['heroBody']['class'].upper()
    caption=Image.new('RGB',(540,64),'#243F43');d=ImageDraw.Draw(caption)
    d.multiline_text((12,8),f"{cls} / {scenarios[i%6]}\nNative Simulator / normal speed / silent / body only",font=font,fill='white',spacing=6)
    png=P/f'caption-{i}.png';caption.save(png)
    dest=P/f'native-{i}.mp4'
    subprocess.run(['ffmpeg','-y','-v','error','-ss',str(start),'-i',str(P/'native-ui-silent.mov'),'-i',str(png),'-t',str(dur),'-filter_complex','[0:v]fps=30,scale=540:-2,pad=iw:ih+64:0:0:color=0x243F43[s];[s][1:v]overlay=0:main_h-64[v]','-map','[v]','-an','-c:v','libx264','-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',str(dest)],check=True)
    clips.append(dest)
    audit.append({'receipt':x['id'],'class':cls,'scenario':scenarios[i%6],'before':x['before'],'after':x['after'],'events':x['events'],'bodyTiming':x['heroBody'],'start':start,'duration':dur,'speed':1,'file':str(dest.relative_to(ROOT)),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
def concat(name,indices):
    listing=P/(name+'.concat');listing.write_text(''.join("file '"+str(clips[i])+"'\n" for i in indices))
    subprocess.run(['ffmpeg','-y','-v','error','-f','concat','-safe','0','-i',str(listing),'-an','-c','copy','-movflags','+faststart',str(P/name)],check=True)
concat('warrior-w1-full-board.mp4',range(6))
concat('rogue-r1-full-board.mp4',range(6,12))
concat('warrior-rogue-small-dense-reduced.mp4',[4,5,10,11])
# Unretimed gestures before and after the no-capture receipt; includes preview,
# cancel, reselect, confirm and undo as recorded by XCTest.
for i,name in [(1,'warrior'),(7,'rogue')]:
    start=max(0,r[i]['receiptUptime']-c['recordReadyUptime']-8)
    subprocess.run(['ffmpeg','-y','-v','error','-ss',str(start),'-i',str(P/'native-ui-silent.mov'),'-t','14','-vf','fps=30,scale=540:-2','-an','-c:v','libx264','-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',str(P/(name+'-preview-cancel-undo.mp4'))],check=True)
(P/'edit-audit.json').write_text(json.dumps({'source':'native-ui-silent.mov','sourceSHA256':hashlib.sha256((P/'native-ui-silent.mov').read_bytes()).hexdigest(),'claim':'Actual SwiftUI/Simulator input. Silent, normal speed, captions outside native viewport; no retiming or synthesized characters. Density uses orthogonally adjacent pre-action soldiers. Human acting/physical device Gates not inferred.','clips':audit},indent=2)+'\n')
print('12 successful native receipt clips, two class reels and dense/Reduced comparison written')
