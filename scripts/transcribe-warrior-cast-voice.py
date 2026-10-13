#!/usr/bin/env python3
"""Independent offline word recognition; never certifies voice performance."""
import argparse,json,re,wave
from pathlib import Path
import mlx_whisper,numpy as np
ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'assets/candidates/warrior-07/voice'
a=argparse.ArgumentParser();a.add_argument('--model',required=True);args=a.parse_args()
rows=[]
for take in ['A','B']:
    with wave.open(str(p/f'warrior-{take}-dry.wav')) as w:
        x=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float)/32768;rate=w.getframerate()
    t=np.arange(0,len(x),rate/16000);x=np.interp(t,np.arange(len(x)),x).astype(np.float32)
    result=mlx_whisper.transcribe(x,path_or_hf_repo=args.model,language='en',temperature=0,condition_on_previous_text=False,verbose=False)
    text=result['text'].strip();rows.append(dict(take=take,recognized=text,match=re.sub('[^a-z]','',text.lower())=='holdtheline'))
(p/'ASR-CHECK.json').write_text(json.dumps(dict(model='mlx-community/whisper-tiny.en-mlx',revision='5f4dafbb28e62a53c1b10426ff7eed36ca733bf7',target_prompt=None,checks=rows,scope='word recognition only; acting quality Owner pending'),indent=2)+'\n')
assert all(x['match'] for x in rows)
print(json.dumps(rows,indent=2))
