#!/usr/bin/env python3
"""Fixed native fixtures. Run before install/new build and after each work package."""
import argparse, json, subprocess, time, hashlib
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('stage');p.add_argument('--device',default='B3E27BF5-0FC6-4378-8A06-A254DC3782B2');args=p.parse_args()
root=Path(__file__).resolve().parents[1];out=root/'artifacts/assets-pass-1/screens'/args.stage;out.mkdir(parents=True,exist_ok=True)
cases={'lobby':[], 'capture':['--undo-fixture','capture'], 'priest':['--integrated-practice','priest'], 'impact':['--art-impact','capture','0.74'], 'commander':['--art-impact','win','0.74']}
records=[]
for name,extra in cases.items():
 command=['xcrun','simctl','launch','--terminate-running-process',args.device,'com.tacticalgo.prototype','--integrated-shell','--art-no-ambient']+extra
 subprocess.run(command,check=True);time.sleep(4)
 dest=out/(name+'.png');subprocess.run(['xcrun','simctl','io',args.device,'screenshot',str(dest)],check=True,capture_output=True)
 records.append(dict(file=str(dest.relative_to(root)),command=command,sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),settle_seconds=4))
(out/'manifest.json').write_text(json.dumps(records,indent=2)+'\n')
