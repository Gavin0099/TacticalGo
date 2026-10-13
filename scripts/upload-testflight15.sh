#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TGO_OUT=artifacts/v11/testflight-15
python3 scripts/verify-testflight15.py > "$TGO_OUT/verification.log" 2>&1
if python3 - <<'PY'
import json,sys
sys.exit(0 if json.load(open('artifacts/v11/testflight-15/DELIVERY.json'))['uploaded'] else 1)
PY
then
  echo '1103 already uploaded; not uploading again. Check Apple processing and Owner group.'
  exit 0
fi
TGO_RUN="$TGO_OUT/upload-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$TGO_RUN"
# Preserve the earlier account rejection before the next authorized attempt.
if [[ -f "$TGO_OUT/upload.log" ]]; then cp "$TGO_OUT/upload.log" "$TGO_RUN/previous-upload.log"; fi
TGO_EXIT=0
xcodebuild -exportArchive -archivePath "$PWD/$TGO_OUT/CrownTactics-1.1-1103-distribution.xcarchive" -exportPath "$PWD/$TGO_RUN/Export" -exportOptionsPlist "$TGO_OUT/ExportOptions-upload.plist" > "$TGO_RUN/upload.log" 2>&1 || TGO_EXIT=$?
cp "$TGO_RUN/upload.log" "$TGO_OUT/upload.log"
echo "$TGO_EXIT" > "$TGO_RUN/exit-code.txt"
python3 scripts/verify-testflight15.py > "$TGO_OUT/verification.log" 2>&1
cat "$TGO_OUT/verification.log"
exit "$TGO_EXIT"
