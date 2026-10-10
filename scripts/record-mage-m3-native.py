"""Record actual Simulator/XCTest input. No reconstructed audio or synthetic animation frames."""
import ctypes
import json
import pathlib
import shutil
import signal
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
MEDIA = ROOT / "artifacts/ios/anim-mage-m3/media"
UDID = "176A7ED7-D56A-41F7-B56C-CBEB9B9774A3"

class Base(ctypes.Structure):
    _fields_ = [("numer",ctypes.c_uint32),("denom",ctypes.c_uint32)]
lib = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
lib.mach_absolute_time.restype = ctypes.c_uint64
base = Base()
lib.mach_timebase_info(ctypes.byref(base))
def uptime():
    return lib.mach_absolute_time()*base.numer/base.denom/1e9

MEDIA.mkdir(parents=True,exist_ok=True)
raw = MEDIA / "native-ui-silent.mov"
assert not raw.exists(), "Keep failed and prior captures; select a new directory for a retry"
clock = {"beforeRecordUptime":uptime(),"surface":"Actual iPhone 390pt Simulator / SwiftUI / XCTest gestures", "audio":"silent; no postmix", "effects":"body-first review; final directed FX sample separately identified"}
recorder = subprocess.Popen(["xcrun","simctl","io",UDID,"recordVideo","--codec=h264",str(raw)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
lines = []
while True:
    line = recorder.stderr.readline()
    lines.append(line)
    if "Recording started" in line: break
    if not line or "An error" in line: raise RuntimeError("Recording failed: "+"".join(lines))
clock["recordReadyUptime"] = uptime()
try:
    with (MEDIA / "native-record-test.log").open("w") as log:
        command = ["xcodebuild","test-without-building","-xctestrun",str(ROOT/"ios/Build/Products/TacticalGo_iphonesimulator26.5-arm64.xctestrun"),"-destination","platform=iOS Simulator,id="+UDID,"-only-testing:TacticalGoUITests/PlayableGameTests/testMageM3SameBoardM2M3Recording","-resultBundlePath",str(MEDIA/"native-record.xcresult")]
        result = subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
    clock["testExitCode"] = result.returncode
finally:
    clock["recordStopUptime"] = uptime()
    recorder.send_signal(signal.SIGINT)
    out,err = recorder.communicate(timeout=30)
    clock["recorderExitCode"] = recorder.returncode
    (MEDIA/"recorder.log").write_text("".join(lines)+out+err)
    (MEDIA/"capture-clock.json").write_text(json.dumps(clock,indent=2)+"\n")
assert recorder.returncode == 0 and result.returncode == 0, "Retain the failed recording; do not mark PASS"
docs = pathlib.Path(subprocess.check_output(["xcrun","simctl","get_app_container",UDID,"com.tacticalgo.prototype","data"],text=True).strip())/"Documents"
for name in ["game-feel-receipts.json","cozy-render-trace.json","cozy-render-geometry.json","game-feel-audio-trace.json"]:
    if (docs/name).exists(): shutil.copy2(docs/name,MEDIA/name)
print(json.dumps(clock,indent=2))
