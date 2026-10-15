#!/usr/bin/env python3
"""Exact confirmed-receipt native frames. Static pose QA, not physical AV timing."""
import argparse, hashlib, json, subprocess, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('--device', required=True)
p.add_argument('--app', required=True)
p.add_argument('--out', required=True)
p.add_argument('--profile', required=True)
a = p.parse_args()
out = Path(a.out).resolve();out.mkdir(parents=True, exist_ok=False)
def run(*args):
    return subprocess.check_output(args, stderr=subprocess.STDOUT).decode().strip()
inventory = json.loads(run('xcrun','simctl','list','devices','-j'))
device = next(d for group in inventory['devices'].values() for d in group if d['udid']==a.device)
if device['state'] != 'Booted':run('xcrun','simctl','boot',a.device)
run('xcrun','simctl','bootstatus',a.device,'-b')
bundle = 'com.tacticalgo.prototype'
run('xcrun','simctl','install',a.device,str(Path(a.app).resolve()))
data = Path(run('xcrun','simctl','get_app_container',a.device,bundle,'data'))
trace = data/'Documents/polish-native-review.json'
pin = {str(f.relative_to(ROOT)):hashlib.sha256(f.read_bytes()).hexdigest()
       for folder in ['ios/TacticalGo','swift/TacticalGoCore/Sources']
       for f in (ROOT/folder).rglob('*') if f.is_file()}
(out/'SOURCE_PIN.json').write_text(json.dumps(pin,indent=2)+'\n')
cases = [(9,owner,True,False,t) for owner in ['black','white'] for t in [.22,.28,.34,.58,.64]]
cases += [(7,owner,True,False,t) for owner in ['black','white'] for t in [.34,.58]]
cases += [(9,owner,False,True,.58) for owner in ['black','white']]
frames=[]
for size,owner,dense,reduced,phase in cases:
    name=f'{size}-{owner}-'+('dense' if dense else 'sparse')+('-reduced' if reduced else '')+f'-{phase:.2f}'
    if trace.exists():trace.unlink()
    flags=['--integrated-practice','warrior','--quality-warrior-fixture','--polish-basic',
           '--polish-autoplay','--polish-body-only','--polish-frame',str(phase)]
    if size==7:flags+=['--quality-seven']
    if owner=='white':flags+=['--quality-white']
    if not dense:flags+=['--quality-sparse']
    if reduced:flags+=['--polish-reduced']
    (out/(name+'-launch.log')).write_text(run('xcrun','simctl','launch','--terminate-running-process',a.device,bundle,*flags))
    deadline=time.monotonic()+15
    while not trace.exists():
        if time.monotonic()>deadline:raise RuntimeError('No confirmed frame '+name)
        time.sleep(.1)
    r=json.loads(trace.read_text())
    assert r['success'] and r['frameFrozen'] and r['fixture']=='hand-placed-WarriorPresentationFixture',r
    assert r['frameTime']==phase and r['beforeAP']==2 and r['afterAP']==1,r
    assert r['beforeMana']==6 and r['afterMana']==4 and r['arrival']==.58 and r['duration']==1.02,r
    # Let SwiftUI commit the exact frozen clock before taking native pixels.
    time.sleep(.25)
    image=out/(name+'.png')
    run('xcrun','simctl','io',a.device,'screenshot',str(image))
    r.update(profile=a.profile,boardSize=size,owner=owner,dense=dense,reduced=reduced,
             nativeSimulator=True,physicalDevice=False,recordedAudio=False,
             poseTime='exact successful receipt freeze; static, not a played frame latency measurement',
             screenshot=str(image.relative_to(ROOT)),screenshotSHA256=hashlib.sha256(image.read_bytes()).hexdigest(),launchArguments=flags)
    (out/(name+'.json')).write_text(json.dumps(r,indent=2)+'\n');frames.append(r)
    print('Confirmed exact native pose:',name,flush=True)
unchanged=all(hashlib.sha256((ROOT/n).read_bytes()).hexdigest()==h for n,h in pin.items())
assert unchanged,'Source changed during capture'
(out/'FRAMES.json').write_text(json.dumps(dict(profile=a.profile,device=a.device,sourceUnchanged=True,frames=frames),indent=2)+'\n')
