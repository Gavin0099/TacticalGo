#!/usr/bin/env python3
"""Record normal integrated DEBUG input; no audio or physical-device timing claims."""
import argparse,hashlib,json,signal,subprocess,time
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--device',required=True)
parser.add_argument('--app',required=True)
parser.add_argument('--out',required=True)
parser.add_argument('--scenes',nargs='+',default=['warrior-basic','warrior-advanced','mage-basic','mage-advanced','rogue-basic','rogue-advanced','priest-basic'])
parser.add_argument('--body-only',action='store_true')
parser.add_argument('--reduced',action='store_true')
args=parser.parse_args();out=Path(args.out).resolve();out.mkdir(parents=True,exist_ok=True)
app=Path(args.app).resolve();bundle='com.tacticalgo.prototype'
def run(*argv):return subprocess.check_output(argv,stderr=subprocess.STDOUT).decode().strip()
run('xcrun','simctl','install',args.device,str(app))
container=Path(run('xcrun','simctl','get_app_container',args.device,bundle,'data'))
report=container/'Documents/polish-native-review.json'
pins={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['ios/TacticalGo','swift/TacticalGoCore/Sources'] for p in (ROOT/folder).rglob('*') if p.is_file()}
(out/'SOURCE_PIN.json').write_text(json.dumps(pins,indent=2)+'\n')
records=[]
for scene in args.scenes:
    hero,kind=scene.split('-');raw=out/(scene+'-full-silent.mp4');assert not raw.exists(),raw
    if report.exists():report.unlink()
    subprocess.run(['xcrun','simctl','terminate',args.device,bundle],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    log=out/(scene+'-recorder.log')
    with log.open('w') as stream:
        recorder=subprocess.Popen(['xcrun','simctl','io',args.device,'recordVideo','--codec=h264',str(raw)],stdout=stream,stderr=stream)
        try:
            deadline=time.monotonic()+8
            while 'Recording started' not in log.read_text():
                if recorder.poll() is not None or time.monotonic()>deadline:raise RuntimeError('Video recorder did not start')
                time.sleep(.05)
            # Simulator ProcessInfo.uptime and this Python runtime's monotonic clock
            # have different epochs. Use same-filesystem write times, explicitly approximate.
            video_origin=log.stat().st_mtime
            if hero in ('slime','wolf'):
                flags=['--polish-monster',scene,'--polish-autoplay']
            else:
                flags=['--integrated-practice',hero,'--polish-autoplay']+(['--polish-basic'] if kind=='basic' else [])
            if args.body_only:flags+=['--polish-body-only']
            if args.reduced:flags+=['--polish-reduced']
            (out/(scene+'-launch.log')).write_text(run('xcrun','simctl','launch','--terminate-running-process',args.device,bundle,*flags))
            deadline=time.monotonic()+15
            while not report.exists():
                if time.monotonic()>deadline:raise RuntimeError('No successful receipt trace: '+scene)
                time.sleep(.1)
            receipt=json.loads(report.read_text());assert receipt['success'],receipt
            offset=report.stat().st_mtime-video_origin
            assert 0<offset<20,(offset,receipt)
            time.sleep(2)
            run('xcrun','simctl','io',args.device,'screenshot',str(out/(scene+'-settled.png')))
        finally:
            if recorder.poll() is None:recorder.send_signal(signal.SIGINT)
            recorder.wait(timeout=20)
    metadata=json.loads(run('ffprobe','-v','error','-show_format','-show_streams','-of','json',str(raw)))
    assert metadata['streams'] and metadata['streams'][0]['codec_type']=='video'
    assert not any(s['codec_type']=='audio' for s in metadata['streams'])
    receipt.update(scene=scene,bodyOnly=args.body_only,reduced=args.reduced,videoCommitOffsetEstimate=offset,alignment='first-frame log / trace file write times, approximate; not AV latency',recordedAudio=False,physicalDevice=False,video=str(raw.relative_to(ROOT)),videoSHA256=hashlib.sha256(raw.read_bytes()).hexdigest())
    (out/(scene+'-receipt.json')).write_text(json.dumps(receipt,indent=2)+'\n');records.append(receipt)
    start=max(0,offset-.6)
    run('ffmpeg','-v','error','-ss',str(start),'-i',str(raw),'-t','2.6','-an','-c:v','libx264','-crf','20',str(out/(scene+'-clip-silent.mp4')))
    print('Recorded confirmed native scene:',scene,flush=True)
(out/'RECORDINGS.json').write_text(json.dumps(records,indent=2)+'\n')
