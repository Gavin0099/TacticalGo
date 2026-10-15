#!/usr/bin/env python3
"""Independent offline word check: no target-text prompt, not a human acting review."""
import argparse,pathlib,json,re,hashlib,wave
import numpy as np
from scipy.signal import resample_poly
import mlx_whisper
ROOT=pathlib.Path(__file__).resolve().parents[1];P=ROOT/'artifacts/audio/hero-voice-performance-01'
a=argparse.ArgumentParser();a.add_argument('--model',type=pathlib.Path,required=True);args=a.parse_args()
rows=json.loads((P/'selected-takes.json').read_text());checks=[]
normalize=lambda s:re.sub('[^a-z ]','',s.lower()).split()
for r in rows:
 f=P/r['file']
 with wave.open(str(f)) as w:hz=w.getframerate();samples=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(np.float32)/32768
 samples=resample_poly(samples,2,3) if hz==24000 else samples
 # Only English/language constraints; expected dialogue is deliberately not supplied.
 out=mlx_whisper.transcribe(samples,path_or_hf_repo=str(args.model),language='en',temperature=0,condition_on_previous_text=False,word_timestamps=False,verbose=False)
 got=out['text'].strip();passed=normalize(got)==normalize(r['text'])
 checks.append({'file':r['file'],'expected':r['text'],'recognized':got,'match':passed,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'avg_logprobs':[s.get('avg_logprob') for s in out.get('segments',[])]})
 print(r['file'],repr(got),'MATCH',passed,flush=True)
(P/'ASR-CHECK.json').write_text(json.dumps({'status':'PASS' if all(c['match'] for c in checks) else 'HOLD','model':'mlx-community/whisper-tiny.en-mlx','revision':'5f4dafbb28e62a53c1b10426ff7eed36ca733bf7','runtime':'mlx-whisper0.4.3','target_text_used_as_prompt':False,'scope':'independent automated word recognition only, may mishear; expression and human intelligibility Pending','checks':checks},indent=2)+'\n')
