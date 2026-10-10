"""Native receipt-timed trims only. No synthesized character frames, retiming or soundtrack."""
import json,pathlib,subprocess
from PIL import Image,ImageDraw,ImageFont
ROOT=pathlib.Path(__file__).resolve().parents[1]
P=ROOT/'artifacts/ios/anim-mage-m3/media'
c=json.loads((P/'capture-clock.json').read_text())
r=[x for x in json.loads((P/'game-feel-receipts.json').read_text()) if x['receiptUptime']>=c['recordReadyUptime']]
assert len(r)==10
for i in range(3):
    for key in ['before','after','events']:
        assert r[i][key]==r[i+3][key]==r[i+6][key],key
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',16)
clips=[];audit=[]
for i,x in enumerate(r):
    kind='SUMMON' if x['action'].startswith('summonHero') else 'PUSH + REAL CAPTURE' if any('piecesCaptured' in e for e in x['events']) else 'PUSH'
    start=max(0,x['receiptUptime']-c['recordReadyUptime']-.45);dur=x['visualDuration']+1.05
    caption=Image.new('RGB',(540,64),'#243F43');d=ImageDraw.Draw(caption)
    d.multiline_text((12,8),f"{x['mageRevision'].upper()} / {x['mageTempo'].upper()} / {kind}\nSimulator / normal speed / silent / {'directed FX' if x['effectsEnabled'] else 'body only'}",font=font,fill='white',spacing=6)
    png=P/f'caption-{i}.png';caption.save(png)
    dest=P/f'native-{i}.mp4'
    subprocess.run(['ffmpeg','-y','-v','error','-ss',str(start),'-i',str(P/'native-ui-silent.mov'),'-i',str(png),'-t',str(dur),'-filter_complex','[0:v]fps=30,scale=540:-2,pad=iw:ih+64:0:0:color=0x243F43[s];[s][1:v]overlay=0:main_h-64[v]','-map','[v]','-an','-c:v','libx264','-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',str(dest)],check=True)
    clips.append(dest);audit.append({'receipt':x['id'],'revision':x['mageRevision'],'tempo':x['mageTempo'],'effects':x['effectsEnabled'],'action':x['action'],'before':x['before'],'after':x['after'],'events':x['events'],'trimStart':start,'duration':dur,'speed':1,'file':str(dest.relative_to(ROOT))})
def concat(name,indices):
    listing=P/(name+'.concat');listing.write_text(''.join("file '"+str(clips[i])+"'\n" for i in indices))
    subprocess.run(['ffmpeg','-y','-v','error','-f','concat','-safe','0','-i',str(listing),'-an','-c','copy','-movflags','+faststart',str(P/name)],check=True)
concat('mage-m3-full.mp4',[3,4,5]);concat('mage-m3-compact.mp4',[6,7,8]);concat('mage-m2-m3-same-board.mp4',[0,3,1,4,2,5])
# Side-by-side counterpart: same fixture, time scale, viewport. Individual full boards remain available.
subprocess.run(['ffmpeg','-y','-v','error','-i',str(clips[1]),'-i',str(clips[4]),'-filter_complex','[0:v][1:v]hstack=inputs=2:shortest=1[v]','-map','[v]','-an','-c:v','libx264','-crf','19','-pix_fmt','yuv420p',str(P/'mage-m2-m3-push-side-by-side.mp4')],check=True)
# Native preview/cancel, confirmation and undo gesture sequence, uncut normal speed.
start=r[4]['receiptUptime']-c['recordReadyUptime']-5.3
subprocess.run(['ffmpeg','-y','-v','error','-ss',str(start),'-i',str(P/'native-ui-silent.mov'),'-t','9.4','-vf','fps=30,scale=540:-2','-an','-c:v','libx264','-crf','19','-pix_fmt','yuv420p',str(P/'mage-m3-preview-cancel-undo.mp4')],check=True)
(P/'edit-audit.json').write_text(json.dumps({'source':'actual native-ui-silent.mov','claim':'Simulator recording; silent; no retiming or synthesized character frames; captions outside native viewport','sameFixtureDomainReceipts':'PASS for all 3 actions across M2 full / M3 full / M3 compact','clips':audit,'previewCancelUndo':{'start':start,'duration':9.4,'speed':1}},indent=2)+'\n')
print('10 receipt clips and same-board comparison written')
