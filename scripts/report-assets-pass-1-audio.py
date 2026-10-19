#!/usr/bin/env python3
"""Produce operator review tables and before/after scientific waveform panels from saved measurements."""
import json,wave
import numpy as np
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1];DIR=ROOT/'artifacts/assets-pass-1/audio'
before={r['key']:r for r in json.loads((DIR/'before/metrics.json').read_text())};after={r['key']:r for r in json.loads((DIR/'after/metrics.json').read_text())}
rows=['# 音訊逐檔量測前後表','','此表的改善是技術規格/事件區隔判讀，主觀聽感全部未檢查。LUFS採ffmpeg EBU R128，短於400ms補靜音至400ms（原始時長與補長值分開保留）；同組差異以相同方法比較。所有原始ffmpeg輸出、頻譜質心、三段能量比、PCM首尾差、峰值及削波數在各stage/metrics.json及*-ebur128.txt。','', '| cue | 前/後 LUFS | 前/後峰值 dBFS | 前/後時長 s | 判定與波形證據 |','|---|---|---|---|---|']
for key,b in after.items():
 a=before.get(key);changed=b['changed'];note='改善（短音效規格/事件包絡）；聽感未檢查' if changed else '持平（位元相同）；聽感未檢查'
 if key=='selection':note='持平（目標響度不變）；音色差異未聽驗'
 if key=='danger':note='未檢查（警示效果）；已降低過突出的基線音量'
 if a is None:note='新增，無對應before；原生路由另驗；聽感未檢查'
 vals=lambda f: f"{a[f] if a else 'N/A'} / {b[f]}"
 link=f'comparisons/{key}.png' if changed else f'after/{key}-waveform.png'
 rows.append(f"| {key} | {vals('integrated_lufs')} | {vals('peak_dbfs')} | {vals('duration_seconds')} | {note}；[波形]({link}) |")
 if changed:
  dest=DIR/'comparisons';dest.mkdir(exist_ok=True);panel=Image.new('RGB',(1000,420),(247,246,240));draw=ImageDraw.Draw(panel)
  span=max(a['duration_seconds'] if a else 0,b['duration_seconds'])
  def plot(record,y,label):
   with wave.open(str(ROOT/record['measured']),'rb') as w:
    rate=w.getframerate();channels=w.getnchannels();pcm=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').reshape(-1,channels).mean(axis=1)/32768
   draw.text((15,y),f"{label} {key}: {record['duration_seconds']:.3f}s  peak {record['peak_dbfs']}dBFS  I {record['integrated_lufs']}LUFS",fill='black')
   center=y+92;draw.line((20,center,980,center),fill=(170,170,170))
   for x in range(960):
    start=round(x/960*span*rate);end=max(start+1,round((x+1)/960*span*rate));chunk=pcm[start:end]
    if len(chunk):draw.line((20+x,center-float(chunk.max())*70,20+x,center-float(chunk.min())*70),fill=(20,105,115))
   for tick in range(5):
    x=20+tick*240;draw.line((x,center+76,x,center+81),fill='black');draw.text((min(935,x),center+83),f'{span*tick/4:.2f}s',fill='black')
  if a:plot(a,10,'BEFORE')
  else:draw.text((15,50),'BEFORE: no independent event resource',fill='black')
  plot(b,220,'AFTER V30');panel.save(dest/(key+'.png'))
(DIR/'comparison.md').write_text('\n'.join(rows)+'\n')
new=[r for r in after.values() if r['changed']];groups={}
manifest=json.loads((ROOT/'ios/TacticalGo/Audio/V30/manifest.json').read_text())
for e in manifest['assets']:groups.setdefault(e['family'],[]).append(after[e['key']]['integrated_lufs'])
assert all(r['true_peak_dbfs']<=-1 and r['clipped_samples']==0 and r['duration_seconds']<=1.2 and r['boundary_jump_pcm']==0 for r in new)
assert all(max(v)-min(v)<=2 for v in groups.values())
summary={'changed_effects':len(new),'max_true_peak_dbfs':max(r['true_peak_dbfs'] for r in new),'max_duration_seconds':max(r['duration_seconds'] for r in new),'all_no_clipped_samples':True,'all_zero_endpoints':True,'families_spread_lu':{k:round(max(v)-min(v),2) for k,v in groups.items()},'loop_inputs_unchanged':[{'key':k,'boundary_jump_pcm':after[k]['boundary_jump_pcm'],'sha256_equal':before[k]['sha256']==after[k]['sha256']} for k in ['b-normal','b-focus','b-danger','tabletop-loop']],'subjective_listening':'NOT CHECKED','actual_mixed_bus_loudness':'NOT MEASURED; existing event gains retained, resource families only'}
(DIR/'limits-summary.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary,indent=2))
