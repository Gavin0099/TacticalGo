#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TGO_DEVICE_ID=0F60A459-7EE8-5B1B-BDF6-6B4D6047FAB8
TGO_BUNDLE=com.tacticalgo.prototype.herobody
TGO_APP_DIR=artifacts/v11/ux-26/signed-1108/TacticalGo.app
TGO_RUN_DIR="artifacts/v11/ux-26/install-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$TGO_RUN_DIR"
codesign --verify --deep --strict "$TGO_APP_DIR" > "$TGO_RUN_DIR/codesign.log" 2>&1
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$TGO_APP_DIR/Info.plist")" = "$TGO_BUNDLE"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$TGO_APP_DIR/Info.plist")" = 1108
python3 - <<'PY'
import hashlib,json
from pathlib import Path
for name,sha in json.load(open('artifacts/v11/ux-26/SOURCE_PIN.json')).items():
    assert hashlib.sha256(Path(name).read_bytes()).hexdigest()==sha,name
PY
xcrun devicectl list devices --json-output "$TGO_RUN_DIR/devices.json" > "$TGO_RUN_DIR/devices.log" 2>&1
xcrun devicectl device copy from --device "$TGO_DEVICE_ID" --source Documents --destination "$TGO_RUN_DIR/before-Documents" --domain-type appDataContainer --domain-identifier "$TGO_BUNDLE" --json-output "$TGO_RUN_DIR/backup-documents.json" > "$TGO_RUN_DIR/backup-documents.log" 2>&1
xcrun devicectl device copy from --device "$TGO_DEVICE_ID" --source Library/Preferences --destination "$TGO_RUN_DIR/before-Preferences" --domain-type appDataContainer --domain-identifier "$TGO_BUNDLE" --json-output "$TGO_RUN_DIR/backup-preferences.json" > "$TGO_RUN_DIR/backup-preferences.log" 2>&1
xcrun devicectl device install app --device "$TGO_DEVICE_ID" "$TGO_APP_DIR" --json-output "$TGO_RUN_DIR/install.json" > "$TGO_RUN_DIR/install.log" 2>&1
TGO_LAUNCH_EXIT=0
xcrun devicectl device process launch --device "$TGO_DEVICE_ID" "$TGO_BUNDLE" --json-output "$TGO_RUN_DIR/launch.json" > "$TGO_RUN_DIR/launch.log" 2>&1 || TGO_LAUNCH_EXIT=$?
xcrun devicectl device info apps --device "$TGO_DEVICE_ID" --json-output "$TGO_RUN_DIR/apps-after.json" > "$TGO_RUN_DIR/apps-after.log" 2>&1
xcrun devicectl device copy from --device "$TGO_DEVICE_ID" --source Documents --destination "$TGO_RUN_DIR/after-Documents" --domain-type appDataContainer --domain-identifier "$TGO_BUNDLE" --json-output "$TGO_RUN_DIR/after-documents.json" > "$TGO_RUN_DIR/after-documents.log" 2>&1
xcrun devicectl device copy from --device "$TGO_DEVICE_ID" --source Library/Preferences --destination "$TGO_RUN_DIR/after-Preferences" --domain-type appDataContainer --domain-identifier "$TGO_BUNDLE" --json-output "$TGO_RUN_DIR/after-preferences.json" > "$TGO_RUN_DIR/after-preferences.log" 2>&1
python3 - "$TGO_RUN_DIR" "$TGO_LAUNCH_EXIT" <<'PY'
import hashlib,json,plistlib,sys
from pathlib import Path
r=Path(sys.argv[1]);before=r/'before-Documents';after=r/'after-Documents'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
files=[p for p in before.rglob('*') if p.is_file()]
changed=[str(p.relative_to(before)) for p in files if not (after/p.relative_to(before)).is_file() or sha(p)!=sha(after/p.relative_to(before))]
preferences=[p for p in (r/'before-Preferences').rglob('*.plist')]
changed_keys=[]
for p in preferences:
    q=r/'after-Preferences'/p.relative_to(r/'before-Preferences')
    original=plistlib.loads(p.read_bytes());current=plistlib.loads(q.read_bytes()) if q.exists() else {}
    changed_keys.extend(str(p.name)+':'+k for k,v in original.items() if current.get(k)!=v)
outcome=lambda name:json.loads((r/name).read_text())['info']['outcome']
app=next(x for x in json.loads((r/'apps-after.json').read_text())['result']['apps'] if x['bundleIdentifier']=='com.tacticalgo.prototype.herobody')
device=next(x for x in json.loads((r/'devices.json').read_text())['result']['devices'] if x['identifier']=='0F60A459-7EE8-5B1B-BDF6-6B4D6047FAB8')
d={'bundle':app['bundleIdentifier'],'version':app.get('version'),'build':app['bundleVersion'],'deviceInstall':outcome('install.json'),'deviceLaunch':outcome('launch.json'),'launchExit':int(sys.argv[2]),'wifi':device['connectionProperties'].get('transportType')=='localNetwork','existingDocuments':len(files),'existingPreferenceFiles':len(preferences),'changedExistingDocuments':changed,'changedExistingPreferenceKeys':changed_keys,'phoneAVRecorded':False,'humanQualityAcceptance':False,'testFlightUploaded':False,'gitPushedThisSlice':False}
(r/'RESULT.json').write_text(json.dumps(d,indent=2)+'\n')
print(json.dumps(d))
assert d['build']=='1108' and d['deviceInstall']=='success' and not changed and not changed_keys
if d['deviceLaunch']!='success':sys.exit(3)
PY
