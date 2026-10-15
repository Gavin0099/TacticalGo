#!/usr/bin/env python3
"""Verify retained engineering evidence; never turn an offline phone into installed."""
import hashlib, json, re, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "artifacts/v11/integration-14"
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
summary = json.loads((OUT / "native-delivery-summary.json").read_text())
assert summary["passedTests"] == 9 and summary["failedTests"] == 0
assert re.search(r"Executed 239 tests, with 0 failures", (OUT / "swift-final.log").read_text())
for name, marker in [("simulator-delivery.log", "TEST BUILD SUCCEEDED"), ("device-delivery-build.log", "BUILD SUCCEEDED"), ("release-delivery-build.log", "BUILD SUCCEEDED")]:
    assert marker in (OUT / name).read_text()
phone = OUT / "DeviceProducts/Debug-iphoneos/TacticalGo.app"
release = OUT / "ReleaseProducts/Release-iphoneos/TacticalGo.app"
sim = ROOT / "ios/Build/Products/Debug-iphonesimulator/TacticalGo.app"
import plistlib
info = plistlib.loads((phone / "Info.plist").read_bytes())
assert info["CFBundleIdentifier"] == "com.tacticalgo.prototype.herobody"
assert info["CFBundleVersion"] == "1102" and info["CFBundleShortVersionString"] == "1.1"
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(phone)], check=True)
assets = ROOT / "ios/TacticalGo/PresentationLab"
count = 0
for source in assets.rglob("*"):
    if source.is_file():
        relative = source.relative_to(ROOT / "ios/TacticalGo")
        for app in [phone, sim]:
            assert (app / relative).is_file() and sha(app / relative) == sha(source), relative
        count += 1
assert not (release / "PresentationLab").exists()
pixels = []
for name in ["slime-token-v02.png", "shadow-wolf-preview-v02.png"]:
    source = ROOT / "assets/candidates/v11-monsters/v02-preview" / name
    for app in [phone, sim]:
        result = json.loads(subprocess.check_output(["swift", str(ROOT / "scripts/verify-native-png-pixels.swift"), str(source), str(app / name)]))
        assert result["equal"]
        pixels.append({"source":str(source.relative_to(ROOT)), "compiled":str((app/name).relative_to(ROOT)), "sourceFileSHA":sha(source), "compiledFileSHA":sha(app/name), "pixels":result})
    assert not (release / name).exists()
entry = (ROOT / "ios/TacticalGo/PlayableGameView.swift").read_text()
assert "openExpansion" not in entry and "showExpansion" not in entry
assert "ExpansionBoard(store:match" in entry and "choose-" in entry
manifest = json.loads((OUT / "native-attachments/manifest.json").read_text())
shots = [{"name":a["suggestedHumanReadableName"], "file":a["exportedFileName"]} for t in manifest for a in t.get("attachments",[]) if "unified-" in a.get("suggestedHumanReadableName","")]
assert len(shots) == 6
for shot in shots:
    shot["SHA256"] = sha(OUT / "native-attachments" / shot["file"])
assert len({s["SHA256"] for s in shots}) == 6
assert (OUT / "unified-lobby.png").is_file()
runs = sorted(OUT.glob("install-*"))
assert runs
latest = runs[-1]
devices = json.loads((latest / "devices.json").read_text())["result"]["devices"]
device = next(d for d in devices if d["identifier"] == "0F60A459-7EE8-5B1B-BDF6-6B4D6047FAB8")
installed = (latest / "install.json").exists() and json.loads((latest / "install.json").read_text())["info"]["outcome"] == "success"
launched = (latest / "launch.json").exists() and json.loads((latest / "launch.json").read_text())["info"]["outcome"] == "success"
paths = subprocess.check_output(["rg", "--files", "ios/TacticalGo", "ios/TacticalGoUITests", "swift/TacticalGoCore/Sources", "swift/TacticalGoCore/Tests"],cwd=ROOT).decode().splitlines()
sources = {p:sha(ROOT/p) for p in paths if p.endswith(".swift")}
receipt = {
    "status":"candidate_ready" if installed else "software_verified_phone_pending",
    "softwareVerification":"PASS", "Swift":{"passed":239,"failed":0}, "nativeFinal":{"passed":9,"failed":0,"summary":"native-delivery-summary.json"},
    "stageSixNotAddedToFinalCount":True,"bundle":info["CFBundleIdentifier"],"version":"1.1","build":"1102",
    "binarySHA256":sha(phone/"TacticalGo"), "sourceHashes":sources, "unchangedPresentationAssets":count,"compiledMonsterPixels":pixels,
    "phone":{"installed":installed,"launched":launched,"state":device["connectionProperties"]["tunnelState"],"evidence":str(latest.relative_to(ROOT)),"liveAVRecorded":False},
    "screenshots":shots,"lobbySHA256":sha(OUT/"unified-lobby.png"),"visualReview":"lobby and six retained images inspected separately; human acceptance pending",
    "newMode":"local two-player; original bot retained","legacySanctuaryMeaning":"preserved by replay compatibility test","newOffering":"removal only; no destination or placement",
    "mainMerged":False,"published":False,"humanGameplayArtVoiceAcceptance":False,
    "failedEvidenceRetained":["Native-first.xcresult","Native-unified.xcresult","swift-first.log","failed-summary-concurrent-empty.json"],
    "historicalVoiceMixVideos":"prior 1.1 lab layout; priest clip uses legacy sanctuary, not current offering"
}
(OUT/"DELIVERY.json").write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+"\n")
print(json.dumps({k:receipt[k] for k in ["status","softwareVerification","Swift","nativeFinal","unchangedPresentationAssets","phone"]},ensure_ascii=False))
