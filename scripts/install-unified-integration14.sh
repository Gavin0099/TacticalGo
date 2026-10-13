#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TGO_DEVICE_ID=0F60A459-7EE8-5B1B-BDF6-6B4D6047FAB8
TGO_BUNDLE=com.tacticalgo.prototype.herobody
TGO_APP_DIR=artifacts/v11/integration-14/DeviceProducts/Debug-iphoneos/TacticalGo.app
TGO_RUN_DIR="artifacts/v11/integration-14/install-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$TGO_RUN_DIR"
codesign --verify --deep --strict "$TGO_APP_DIR" > "$TGO_RUN_DIR/codesign.log" 2>&1
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$TGO_APP_DIR/Info.plist")" = "$TGO_BUNDLE"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$TGO_APP_DIR/Info.plist")" = 1102
xcrun devicectl list devices --json-output "$TGO_RUN_DIR/devices.json" > "$TGO_RUN_DIR/devices.log" 2>&1
python3 - "$TGO_RUN_DIR/devices.json" "$TGO_DEVICE_ID" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
device=next((x for x in d['result']['devices'] if x['identifier']==sys.argv[2]),None)
if not device or device.get('connectionProperties',{}).get('tunnelState')=='unavailable':
    print('iPhone unavailable; signed candidate retained, installation not attempted.')
    sys.exit(2)
PY
xcrun devicectl device copy from --device "$TGO_DEVICE_ID" --source Documents --destination "$TGO_RUN_DIR/before-Documents" --domain-type appDataContainer --domain-identifier "$TGO_BUNDLE" --json-output "$TGO_RUN_DIR/backup-documents.json" > "$TGO_RUN_DIR/backup-documents.log" 2>&1
xcrun devicectl device copy from --device "$TGO_DEVICE_ID" --source Library/Preferences --destination "$TGO_RUN_DIR/before-Preferences" --domain-type appDataContainer --domain-identifier "$TGO_BUNDLE" --json-output "$TGO_RUN_DIR/backup-preferences.json" > "$TGO_RUN_DIR/backup-preferences.log" 2>&1
xcrun devicectl device install app --device "$TGO_DEVICE_ID" "$TGO_APP_DIR" --json-output "$TGO_RUN_DIR/install.json" > "$TGO_RUN_DIR/install.log" 2>&1
# A locked device can accept installation and reject launch; preserve both outcomes.
TGO_LAUNCH_EXIT=0
xcrun devicectl device process launch --device "$TGO_DEVICE_ID" "$TGO_BUNDLE" --json-output "$TGO_RUN_DIR/launch.json" > "$TGO_RUN_DIR/launch.log" 2>&1 || TGO_LAUNCH_EXIT=$?
xcrun devicectl device copy from --device "$TGO_DEVICE_ID" --source Documents --destination "$TGO_RUN_DIR/after-Documents" --domain-type appDataContainer --domain-identifier "$TGO_BUNDLE" --json-output "$TGO_RUN_DIR/after-documents.json" > "$TGO_RUN_DIR/after-documents.log" 2>&1
python3 - "$TGO_RUN_DIR" "$TGO_LAUNCH_EXIT" <<'PY'
import hashlib,json,sys
from pathlib import Path
r=Path(sys.argv[1]);before=r/'before-Documents';after=r/'after-Documents'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
files=[p for p in before.rglob('*') if p.is_file()]
changed=[str(p.relative_to(before)) for p in files if not (after/p.relative_to(before)).is_file() or sha(p)!=sha(after/p.relative_to(before))]
install=json.loads((r/'install.json').read_text())['info']['outcome']
launch=json.loads((r/'launch.json').read_text())['info']['outcome'] if (r/'launch.json').exists() else 'unverified'
d={'bundle':'com.tacticalgo.prototype.herobody','build':'1102','install':install,'launch':launch,'launchExit':int(sys.argv[2]),'existingDocumentCount':len(files),'changedDocuments':changed,'phoneAVRecorded':False,'humanAcceptance':False}
(r/'RESULT.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(d,ensure_ascii=False))
if install!='success' or changed: sys.exit(4)
if launch!='success': sys.exit(3)
PY
