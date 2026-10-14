#!/usr/bin/env python3
"""Capture real DEBUG store/device-clock cue metadata, not an audio recording."""
import argparse,hashlib,json,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--device',required=True);p.add_argument('--app',required=True);p.add_argument('--out',required=True)
a=p.parse_args();out=Path(a.out).resolve();out.mkdir(parents=True,exist_ok=True)
bundle='com.tacticalgo.prototype'
def run(*argv):return subprocess.check_output(argv,stderr=subprocess.STDOUT).decode().strip()
run('xcrun','simctl','install',a.device,str(Path(a.app).resolve()))
data=Path(run('xcrun','simctl','get_app_container',a.device,bundle,'data'));trace=data/'Documents/polish-native-review.json'
scenes=[(s,True) for s in ['warrior-basic','warrior-advanced','mage-basic','mage-advanced','rogue-basic','rogue-advanced','priest-basic','slime-hunt','slime-loot','wolf-hunt','wolf-loot']]
scenes += [(s,False) for s in ['warrior-basic','mage-basic','rogue-advanced','priest-basic']]
records=[]
for scene,voice in scenes:
    name=scene+('-voiced' if voice else '-no-voice');target=out/(name+'.json');assert not target.exists(),target
    if trace.exists():trace.unlink()
    role,kind=scene.split('-')
    flags=['--polish-monster',scene] if role in ['slime','wolf'] else ['--integrated-practice',role]+(['--polish-basic'] if kind=='basic' else [])
    flags+=['--polish-autoplay']+([] if voice else ['--polish-voice-off'])
    run('xcrun','simctl','launch','--terminate-running-process',a.device,bundle,*flags)
    deadline=time.monotonic()+15
    while not trace.exists():
        if time.monotonic()>deadline:raise RuntimeError('No cue trace '+name)
        time.sleep(.1)
    r=json.loads(trace.read_text());assert r['success'] and r['voiceEnabled']==voice and r['soundSchedule'],r
    assert r['acceptedCues']==len(r['soundSchedule']),r
    assert all(abs(c['gain']-c['actualPlayerGain'])<1e-6 for c in r['soundSchedule']),r
    r.update(scene=scene,voicePreference=voice,physicalDevice=False,recordedAudio=False,actualAVAudioPlayerVolume=True,launchArguments=flags)
    target.write_text(json.dumps(r,indent=2)+'\n');records.append(r)
    # Let the committed line/effects complete before the next controlled launch.
    time.sleep(1.5)
    print('Captured actual AVAudioPlayer schedule:',name,flush=True)
pins={str(f.relative_to(ROOT)):hashlib.sha256(f.read_bytes()).hexdigest() for folder in ['ios/TacticalGo','swift/TacticalGoCore/Sources'] for f in (ROOT/folder).rglob('*') if f.is_file()}
(out/'SOURCE_PIN.json').write_text(json.dumps(pins,indent=2)+'\n')
(out/'SCHEDULES.json').write_text(json.dumps(records,indent=2)+'\n')
