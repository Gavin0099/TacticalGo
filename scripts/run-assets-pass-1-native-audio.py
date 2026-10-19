#!/usr/bin/env python3
"""Drive existing DEBUG native audit entry on an explicitly supplied simulator/app. No test-result inference from logs."""
import argparse,json,shutil,subprocess,time,uuid
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--device',required=True);p.add_argument('--app',required=True);p.add_argument('--mode',choices=['v30','art-v1','volumes','cadence'],default='v30');args=p.parse_args()
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'artifacts/assets-pass-1/native-audio'/args.mode;OUT.mkdir(parents=True,exist_ok=True)
subprocess.run(['xcrun','simctl','install',args.device,args.app],check=True)
data=Path(subprocess.check_output(['xcrun','simctl','get_app_container',args.device,'com.tacticalgo.prototype','data'],text=True).strip())/'Documents'
filenames={'v30':'integrated-audio-audit.json','art-v1':'integrated-audio-audit.json','volumes':'integrated-volume-audit.json','cadence':'integrated-cadence-audit.json'};name=filenames[args.mode];target=data/name
# This is the audit output produced by this helper, not a user's save or preferences.
if target.exists():target.unlink()
entry='--integrated-volume-audit' if args.mode=='volumes' else '--integrated-cadence-audit' if args.mode=='cadence' else '--integrated-audio-audit'
cmd=['xcrun','simctl','launch','--terminate-running-process',args.device,'com.tacticalgo.prototype','--integrated-shell','--cozy-demo',entry,'--sound-preferences-reset',str(uuid.uuid4()),'--record-isolation',str(uuid.uuid4())]+(['--art-v1'] if args.mode=='art-v1' else [])
subprocess.run(cmd,check=True)
(OUT/'invocation.json').write_text(json.dumps({'command':cmd,'app':args.app,'timeout_seconds':150},indent=2)+'\n')
end=time.monotonic()+150
while not target.exists() and time.monotonic()<end:time.sleep(2)
if not target.exists():raise SystemExit('FAIL: native audit output not produced within150s')
shutil.copyfile(target,OUT/name);checks=json.loads(target.read_text());failed=[r for r in checks if not r['passed']]
for path in data.glob('integrated-audio-observations.json'):shutil.copyfile(path,OUT/path.name)
print(json.dumps({'checks':len(checks),'failed':failed,'mode':args.mode},indent=2))
raise SystemExit(2 if failed else 0)
