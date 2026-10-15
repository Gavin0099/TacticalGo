#!/usr/bin/env python3
"""Native static review, waiting for the app rather than recording its launch screen."""
import hashlib,json,subprocess,time
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artifacts/v11/feel-10/native'
DEVICE='44259159-744B-4270-85A2-86CF756C100F'
cases=[('priest-v02-art-review',['--exp-art-review']),('rogue-art-review',['--exp-art-review','--exp-art-rogue'])]
for hero in ['Priest','Rogue']:
 for n,owner,width in [(7,'Black',390),(9,'White',320)]:
  for phase,t in [('rest',0),('coil',.20 if hero=='Priest' else .12),('release',.32 if hero=='Priest' else .16)]:
   cases.append((f'{hero.lower()}-{n}-{owner.lower()}-{phase}-body-only',['--expansion-lab','--exp-review',hero,'--exp-review-size',str(n),'--exp-review-owner',owner,'--exp-review-width',str(width),'--exp-review-time',str(t),'--exp-review-body-only','--exp-review-dense']))
OUT.mkdir(parents=True,exist_ok=True)
records=[]
for name,args in cases:
 subprocess.run(['xcrun','simctl','launch','--terminate-running-process',DEVICE,'com.tacticalgo.prototype']+args,check=True,stdout=subprocess.DEVNULL)
 time.sleep(5)
 path=OUT/(name+'.png')
 subprocess.run(['xcrun','simctl','io',DEVICE,'screenshot',str(path)],check=True,capture_output=True)
 # Startup screens in the failed first capture were white. This guards that failure;
 # visual board/faction/pose review is still performed separately.
 im=Image.open(path).convert('RGB');pixels=list(im.getdata())
 white=sum(min(p)>245 for p in pixels)/len(pixels)
 assert white<.50,(name,'possible launch screen',white)
 records.append(dict(name=name,args=args,file=str(path.relative_to(ROOT)),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),white_pixel_fraction=white,settle_seconds=5,platform='native SwiftUI iOS Simulator',scope='art sheet or confirmed receipt static engineering frame; not normal-speed clip'))
 (OUT/'manifest.json').write_text(json.dumps(records,indent=2)+'\n')
 print(name,flush=True)
assert len({r['sha256'] for r in records})==len(records),'unexpected identical capture; inspect and retain failure'
