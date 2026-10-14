#!/usr/bin/env python3
"""Record a real normal-lobby XCTest journey. Video is silent Simulator evidence."""
import argparse, hashlib, json, signal, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('--device', required=True)
p.add_argument('--out', required=True)
p.add_argument('--runtime-label', required=True)
args = p.parse_args()
out = Path(args.out).resolve();out.mkdir(parents=True, exist_ok=False)
base = json.loads((ROOT/'artifacts/v11/quality-35/BASELINE_SOURCE_PIN.json').read_text())
paths = set(base) | {str(f.relative_to(ROOT)) for folder in ['ios/TacticalGo','ios/TacticalGoUITests','swift/TacticalGoCore/Sources','swift/TacticalGoCore/Tests'] for f in (ROOT/folder).rglob('*') if f.is_file()} | {'scripts/record-quality-sequence-native.py'}
pin = {n:hashlib.sha256((ROOT/n).read_bytes()).hexdigest() for n in sorted(paths)}
(out/'SOURCE_PIN.json').write_text(json.dumps(pin,indent=2)+'\n')
raw = out/'normal-lobby-to-victory-undo-simulator-silent.mp4'
rc = 1;invoked = False;started = time.time()
with (out/'recordVideo.log').open('w') as stream:
    recorder = subprocess.Popen(['xcrun','simctl','io',args.device,'recordVideo','--codec=h264',str(raw)],stdout=stream,stderr=stream)
    try:
        deadline = time.monotonic()+8
        while 'Recording started' not in (out/'recordVideo.log').read_text():
            if recorder.poll() is not None or time.monotonic()>deadline:
                raise RuntimeError('Simulator recording did not become ready')
            time.sleep(.05)
        invoked = True
        cmd = ['xcodebuild','test-without-building','-xctestrun',str(ROOT/'ios/Build/Products/TacticalGoBeta_iphonesimulator26.5-arm64.xctestrun'),
               '-destination','platform=iOS Simulator,id='+args.device,'-resultBundlePath',str(out/'Sequence.xcresult'),
               '-parallel-testing-enabled','NO','-only-testing:TacticalGoUITests/ExpansionLabTests/testQualitySequenceFromNormalLobbyToMageCastCaptureResultAndUndo']
        with (out/'native.log').open('w') as log:
            rc = subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT).returncode
    finally:
        if recorder.poll() is None:recorder.send_signal(signal.SIGINT)
        recorder.wait(timeout=20)
unchanged = all(hashlib.sha256((ROOT/n).read_bytes()).hexdigest()==h for n,h in pin.items())
meta = json.loads(subprocess.check_output(['ffprobe','-v','error','-show_format','-show_streams','-of','json',str(raw)]))
assert any(s['codec_type']=='video' for s in meta['streams'])
assert not any(s['codec_type']=='audio' for s in meta['streams'])
receipt = {'runtimeLabel':args.runtime_label,'device':args.device,'boards':[7,9],'normalProductEntry':True,
           'testInvoked':invoked,'nativeExitCode':rc,'nativePassed':rc==0,'sourceUnchangedDuringRecording':unchanged,
           'physicalDevice':False,'recordedAudio':False,'audioDescription':'Silent Simulator recording; no phone recording or physical AV timing claim',
           'rawVideo':str(raw.relative_to(ROOT)),'rawSHA256':hashlib.sha256(raw.read_bytes()).hexdigest(),
           'videoStreams':meta['streams'],'duration':meta['format']['duration'],'startedWall':started}
(out/'RECORDING.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({k:receipt[k] for k in ['runtimeLabel','nativeExitCode','nativePassed','sourceUnchangedDuringRecording','duration']}),flush=True)
sys.exit(rc if rc else (0 if unchanged else 1))
