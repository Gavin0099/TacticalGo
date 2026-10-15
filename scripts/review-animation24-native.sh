#!/usr/bin/env bash
# Source/build/audio regression only. Simulator output is not device quality acceptance.
set -euo pipefail
cd "$(dirname "$0")/.."
for tgo_tool in swift xcodebuild xcrun python3; do
  command -v "$tgo_tool" >/dev/null || { echo "Missing $tgo_tool; native validation NOT RUN" >&2; exit 69; }
done
git diff --quiet && git diff --cached --quiet || { echo 'Commit reviewed source before recording native evidence' >&2; exit 65; }
[[ -z "$(git ls-files --others --exclude-standard -- ios swift)" ]] || { echo 'Untracked native/package source is not pinned' >&2; exit 65; }
tgo_out="$PWD/artifacts/v11/animation-24/native/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$tgo_out"
git rev-parse HEAD > "$tgo_out/source-commit.txt"
xcodebuild -version > "$tgo_out/xcode-version.txt"
swift --version > "$tgo_out/swift-version.txt"
xcrun simctl list devices available --json > "$tgo_out/devices.json"
tgo_device="${1:-}"
if [[ -z "$tgo_device" ]]; then
  tgo_device=$(python3 - "$tgo_out/devices.json" <<'PY'
import json,sys
devices=[d for runtime,items in json.load(open(sys.argv[1]))['devices'].items() if '.iOS-' in runtime for d in items if d.get('isAvailable') and 'iPhone' in d['name']]
devices.sort(key=lambda d:d['state']!='Booted')
if not devices: raise SystemExit('No available iPhone simulator; pass an installed device UDID')
print(devices[0]['udid'])
PY
  )
fi
printf '%s\n' "$tgo_device" > "$tgo_out/device-udid.txt"
swift test --package-path swift/TacticalGoCore > "$tgo_out/swift-tests.log" 2>&1
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$tgo_out/DebugDerivedData" \
  CODE_SIGNING_ALLOWED=NO 'SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG' build > "$tgo_out/debug-build.log" 2>&1
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGoBeta -configuration Beta \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$tgo_out/BetaDerivedData" \
  CODE_SIGNING_ALLOWED=NO 'SWIFT_ACTIVE_COMPILATION_CONDITIONS=TACTICALGO_V11' build > "$tgo_out/beta-build.log" 2>&1
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo -configuration Debug \
  -destination "platform=iOS Simulator,id=$tgo_device" -derivedDataPath "$tgo_out/DebugDerivedData" \
  -parallel-testing-enabled NO -resultBundlePath "$tgo_out/AudioAudit.xcresult" \
  -only-testing:TacticalGoUITests/PlayableGameTests/testIntegratedNativeAudioCancellationAndReplay \
  CODE_SIGNING_ALLOWED=NO 'SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG' test > "$tgo_out/audio-audit.log" 2>&1
printf '%s\n' 'Native commands returned success. Inspect xcresult for test execution/skips; device listening/FPS and 90% quality remain unverified.'
printf 'Evidence: %s\n' "$tgo_out"
