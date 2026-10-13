#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TGO_OUT=artifacts/v11/interface-18
python3 scripts/verify-interface18.py > "$TGO_OUT/verification.log" 2>&1
if python3 - <<'PY'
import json,sys
sys.exit(0 if json.load(open('artifacts/v11/interface-18/DELIVERY.json'))['uploaded'] else 1)
PY
then echo '1106 already uploaded; check processing/group instead.'; exit 0; fi
TGO_RUN="$TGO_OUT/upload-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$TGO_RUN"
TGO_EXIT=0
xcodebuild -exportArchive -archivePath "$PWD/$TGO_OUT/CrownTactics-1.1-1106.xcarchive" -exportPath "$PWD/$TGO_RUN/Export" -exportOptionsPlist "$TGO_OUT/ExportOptions-upload.plist" > "$TGO_RUN/upload.log" 2>&1 || TGO_EXIT=$?
cp "$TGO_RUN/upload.log" "$TGO_OUT/upload.log"
echo "$TGO_EXIT" > "$TGO_RUN/exit-code.txt"
python3 scripts/verify-interface18.py > "$TGO_OUT/verification.log" 2>&1
cat "$TGO_OUT/verification.log"
exit "$TGO_EXIT"
