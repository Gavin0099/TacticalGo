"""Record real Simulator XCTest gestures. Audio is captured as timing metadata, not loopback."""
import ctypes,json,pathlib,subprocess,signal,shutil
MEDIA=pathlib.Path(__file__).resolve().parent;ROOT=pathlib.Path(__file__).resolve().parents[4]
UDID='176A7ED7-D56A-41F7-B56C-CBEB9B9774A3'
class Base(ctypes.Structure):_fields_=[('numer',ctypes.c_uint32),('denom',ctypes.c_uint32)]
f=ctypes.CDLL('/usr/lib/libSystem.B.dylib');f.mach_absolute_time.restype=ctypes.c_uint64;b=Base();f.mach_timebase_info(ctypes.byref(b))
def uptime():return f.mach_absolute_time()*b.numer/b.denom/1e9
subprocess.run(['xcrun','simctl','install',UDID,str(ROOT/'ios/Build/Products/Debug-iphonesimulator/TacticalGo.app')],check=True)
video=MEDIA/'native-ui-silent.mov'
assert not video.exists(),'Preserve old capture; use a fresh evidence directory for retry'
clock={'beforeRecordRequestUptime':uptime(),'surface':'iPhone 390 pt Simulator / real SwiftUI / XCTest gesture input','voiceVersion':'VO-01-prototype-v3-piper-seeded'}
p=subprocess.Popen(['xcrun','simctl','io',UDID,'recordVideo','--codec=h264',str(video)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
lines=[]
while True:
 line=p.stderr.readline();lines.append(line)
 if 'Recording started' in line:break
 if not line or 'An error' in line:raise RuntimeError('Recording failed '+''.join(lines))
clock['recordReadyUptime']=uptime()
try:
 with (MEDIA/'S7-demo-native.log').open('w') as log:
  command=['xcodebuild','test-without-building','-xctestrun',str(ROOT/'ios/Build/Products/TacticalGo_iphonesimulator26.5-arm64.xctestrun'),'-destination','platform=iOS Simulator,id='+UDID,'-only-testing:TacticalGoUITests/PlayableGameTests/testGameFeelNativeSixLineRecordingWalkthrough','-resultBundlePath',str(MEDIA/'S7-demo-native.xcresult')]
  result=subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
 clock['testExitCode']=result.returncode
finally:
 clock['recordStopUptime']=uptime();p.send_signal(signal.SIGINT);out,err=p.communicate(timeout=30)
 clock['recorderExitCode']=p.returncode;(MEDIA/'native-recorder.log').write_text(''.join(lines)+out+err)
 (MEDIA/'capture-clock.json').write_text(json.dumps(clock,indent=2))
assert p.returncode==0 and result.returncode==0,'Preserve failed evidence; do not label capture PASS'
data=pathlib.Path(subprocess.check_output(['xcrun','simctl','get_app_container',UDID,'com.tacticalgo.prototype','data'],text=True).strip())/'Documents'
for name in ['game-feel-audio-trace.json','game-feel-receipts.json','cozy-render-trace.json','cozy-render-geometry.json']:
 shutil.copy2(data/name,MEDIA/name)
print(json.dumps(clock,indent=2))
