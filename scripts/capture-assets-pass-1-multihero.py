#!/usr/bin/env python3
"""Same-device four-class native HUD/tray comparison; explicitly install the pinned before or final app."""
import argparse,subprocess,time,hashlib,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('stage');p.add_argument('--app',required=True);p.add_argument('--device',default='B3E27BF5-0FC6-4378-8A06-A254DC3782B2');args=p.parse_args()
ROOT=Path(__file__).resolve().parents[1];out=ROOT/'artifacts/assets-pass-1/screens'/args.stage;out.mkdir(parents=True,exist_ok=True)
subprocess.run(['xcrun','simctl','install',args.device,args.app],check=True);records=[]
for hero in ['warrior','mage','rogue','priest']:
 cmd=['xcrun','simctl','launch','--terminate-running-process',args.device,'com.tacticalgo.prototype','--integrated-shell','--art-no-ambient','--integrated-practice',hero]
 subprocess.run(cmd,check=True);time.sleep(4);path=out/(hero+'.png');subprocess.run(['xcrun','simctl','io',args.device,'screenshot',str(path)],check=True,capture_output=True)
 records.append({'hero':hero,'args':cmd,'settle_seconds':4,'file':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
(out/'manifest.json').write_text(json.dumps({'app':args.app,'device':args.device,'records':records},indent=2)+'\n')
