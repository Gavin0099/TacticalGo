#!/bin/bash
# Local, signed archive only. No upload, export, provisioning update or publication.
set -euo pipefail
script_root="$(cd "$(dirname "$0")/.." && pwd)"
release_config=""
archive_output="$script_root/artifacts/monetization-02/CrownTactics-1.0.xcarchive"
report_output="$script_root/artifacts/monetization-02/release-audit/ARCHIVE_PREFLIGHT.json"
account_evidence="$script_root/docs/release-01/account-release-evidence.json"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --config|--archive-path|--report|--account-evidence)
            if [ "$#" -lt 2 ]; then echo "Missing value for $1" >&2; exit 2; fi
            case "$1" in
                --config) release_config="$2" ;;
                --archive-path) archive_output="$2" ;;
                --report) report_output="$2" ;;
                --account-evidence) account_evidence="$2" ;;
            esac
            shift 2 ;;
        --help)
            echo "Usage: bash scripts/archive-release.sh --config Release.xcconfig [--archive-path artifacts/...xcarchive] [--report artifacts/...json] [--account-evidence account-release-evidence.json]"
            exit 0 ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done
if [ -z "$release_config" ]; then echo "A reviewed --config is required; the empty example cannot archive." >&2; exit 2; fi

# Validate simple reviewed settings before invoking Xcode. No env/private account scan.
python3 -B - "$script_root" "$release_config" "$archive_output" "$report_output" "$account_evidence" <<'PY'
import hashlib, importlib.util, json, re, sys
from datetime import datetime, timezone
from pathlib import Path
root, config, archive, report, account_path = (Path(x).resolve() for x in sys.argv[1:])
artifacts = (root / 'artifacts').resolve()
if not archive.is_relative_to(artifacts) or archive.suffix != '.xcarchive' or archive.exists():
    raise SystemExit('Archive must be a NEW .xcarchive under repo artifacts; existing archives are preserved.')
if not report.is_relative_to(artifacts) or report.suffix != '.json' or report.is_relative_to(archive) or report in (config, account_path):
    raise SystemExit('Report must be a JSON under repo artifacts, outside the archive and separate from inputs.')
spec = importlib.util.spec_from_file_location('release_preflight', root / 'scripts/check-release-readiness.py')
module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
allowed = {'MARKETING_VERSION','CURRENT_PROJECT_VERSION','PRODUCT_BUNDLE_IDENTIFIER','DEVELOPMENT_TEAM','CODE_SIGN_STYLE','CODE_SIGN_IDENTITY','PROVISIONING_PROFILE_SPECIFIER','CROWN_UNLOCK_PRODUCT_ID','CROWN_ADMOB_APP_ID','CROWN_REWARDED_AD_UNIT_ID','CROWN_PRIVACY_URL','CROWN_SUPPORT_URL'}
values = {}; failures = []
try:
    lines = config.read_text().splitlines()
except OSError as error:
    lines = []; failures.append('config_unreadable:' + type(error).__name__)
for number, raw in enumerate(lines, 1):
    line = raw.split('//', 1)[0].strip()
    if not line: continue
    match = re.fullmatch(r'([A-Z][A-Z0-9_]*)\s*=\s*(.*)', line)
    if not match or match.group(1) not in allowed:
        failures.append('unsupported_config_line:' + str(number)); continue
    key, value = match.groups()
    value = value.strip()
    if value.startswith('"') and value.endswith('"'): value = value[1:-1]
    value = value.replace('$()', '')
    if key in values: failures.append('duplicate_config_key:' + key)
    values[key] = value
for key in sorted(allowed):
    if not module.configured(values.get(key)): failures.append('missing_or_placeholder:' + key)
if values.get('MARKETING_VERSION') != '1.0': failures.append('marketing_version_must_be_1.0')
if not re.fullmatch(r'[0-9]+(?:\.[0-9]+){0,2}', values.get('CURRENT_PROJECT_VERSION', '')): failures.append('invalid_build_number')
if not module.valid_ad_id(values.get('CROWN_ADMOB_APP_ID'), app=True): failures.append('admob_app_id_not_production')
if not module.valid_ad_id(values.get('CROWN_REWARDED_AD_UNIT_ID'), app=False): failures.append('rewarded_unit_not_production')
if (module.valid_ad_id(values.get('CROWN_ADMOB_APP_ID'), app=True) and module.valid_ad_id(values.get('CROWN_REWARDED_AD_UNIT_ID'), app=False)
    and module.AD_APP.fullmatch(values['CROWN_ADMOB_APP_ID']).group(1) != module.AD_UNIT.fullmatch(values['CROWN_REWARDED_AD_UNIT_ID']).group(1)): failures.append('admob_publishers_do_not_match')
if not re.fullmatch(r'[A-Z0-9]{10}', values.get('DEVELOPMENT_TEAM','')): failures.append('distribution_team_invalid')
if not module.PRODUCT.fullmatch(values.get('CROWN_UNLOCK_PRODUCT_ID', '')): failures.append('unlock_product_id_invalid')
if not module.PRODUCT.fullmatch(values.get('PRODUCT_BUNDLE_IDENTIFIER', '')): failures.append('bundle_id_invalid')
for key in ('CROWN_PRIVACY_URL','CROWN_SUPPORT_URL'):
    if not module.public_url_shape(values.get(key)): failures.append('public_https_url_invalid:' + key)
if values.get('CODE_SIGN_STYLE') != 'Manual' or values.get('CODE_SIGN_IDENTITY') not in ('Apple Distribution','iPhone Distribution'):
    failures.append('reviewed_distribution_signing_required')
try:
    account = json.loads(account_path.read_text())
    if not isinstance(account, dict): raise ValueError()
except (OSError, ValueError):
    account = {}; failures.append('real_account_evidence_missing')
asc = account.get('appStoreConnect', {}); ads = account.get('adMob', {}); owner = account.get('ownerAccountChecks', {})
asc = asc if isinstance(asc, dict) else {}; ads = ads if isinstance(ads, dict) else {}; owner = owner if isinstance(owner, dict) else {}
if (not re.fullmatch(r'[0-9]{5,}', module.value_text(asc.get('appID'))) or not module.configured(asc.get('sku'))
    or asc.get('bundleIdentifier') != values.get('PRODUCT_BUNDLE_IDENTIFIER')
    or asc.get('productID') != values.get('CROWN_UNLOCK_PRODUCT_ID')
    or asc.get('productType') != 'nonConsumable' or asc.get('productMetadataComplete') is not True): failures.append('asc_record_and_product_not_confirmed')
if (ads.get('appID') != values.get('CROWN_ADMOB_APP_ID') or ads.get('rewardedAdUnitID') != values.get('CROWN_REWARDED_AD_UNIT_ID')
    or ads.get('privacyMessageConfigured') is not True): failures.append('admob_and_privacy_message_not_confirmed')
if any(owner.get(k) is not True for k in ('paidAppsAgreementActive','bankAndTaxReady','privacyDeclarationReviewed')): failures.append('owner_account_checks_incomplete')
try:
    stamp = datetime.fromisoformat(module.value_text(owner.get('verifiedAt')).replace('Z','+00:00'))
    if stamp.tzinfo is None or stamp > datetime.now(timezone.utc): raise ValueError()
except ValueError: failures.append('owner_verification_time_missing_or_invalid')
report.parent.mkdir(parents=True, exist_ok=True)
report.write_text(json.dumps({'schema':'tacticalgo-pre-archive-config-v1','checkedAt':datetime.now(timezone.utc).isoformat(),'status':'PRE_ARCHIVE_CONFIG_FAIL' if failures else 'CONFIG_CHECKED_ARCHIVE_NOT_YET_RUN','config':str(config),'archive':str(archive),'failures':failures,'releaseReadyClaimAllowed':False,'claimBoundary':'Local inputs and Owner declarations only; no account login or archive exists yet.'}, ensure_ascii=False, indent=2)+'\n')
if failures:
    print('PRE_ARCHIVE_CONFIG_FAIL: Xcode was NOT invoked.')
    for failure in failures: print('FAIL:',failure)
    raise SystemExit(1)
# A command-line xcconfig applies to package targets too. Packages have no
# provisioning profile. Route the validated profile to the app Release target
# through its dedicated build setting; preserve all other reviewed settings.
project = (root / 'ios/TacticalGo.xcodeproj/project.pbxproj').read_text()
release_target = next((line for line in project.splitlines() if line.startswith('00000000000000000000002B = ')), '')
if 'PROVISIONING_PROFILE_SPECIFIER = "$(CROWN_ARCHIVE_PROFILE)";' not in release_target:
    raise SystemExit('App Release target must scope the reviewed archive profile.')
effective = report.parent / 'Archive.effective.xcconfig'
effective.write_text('\n'.join(re.sub(r'^PROVISIONING_PROFILE_SPECIFIER\s*=', 'CROWN_ARCHIVE_PROFILE =', raw) for raw in lines)+'\n')
receipt = json.loads(report.read_text())
receipt.update(effectiveConfig=str(effective), effectiveConfigSHA256=hashlib.sha256(effective.read_bytes()).hexdigest(), profileScope='TacticalGo app Release target only')
report.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n')
PY

archive_log="$(dirname "$report_output")/archive-xcodebuild.log"
effective_config="$(dirname "$report_output")/Archive.effective.xcconfig"
archive_derived_data="$(dirname "$archive_output")/ArchiveDerivedData"
mkdir -p "$(dirname "$archive_output")"
set +e
xcodebuild -project "$script_root/ios/TacticalGo.xcodeproj" -scheme TacticalGo \
    -configuration Release -destination 'generic/platform=iOS' \
    -xcconfig "$effective_config" -archivePath "$archive_output" \
    -derivedDataPath "$archive_derived_data" -jobs 2 \
    -clonedSourcePackagesDirPath "$script_root/artifacts/monetization-02/SourcePackages" \
    CODE_SIGNING_ALLOWED=YES archive 2>&1 | tee "$archive_log"
archive_exit=${PIPESTATUS[0]}
set -e
if [ "$archive_exit" -ne 0 ]; then
    python3 -B - "$report_output" "$archive_exit" <<'PY'
import json,sys
from pathlib import Path
p=Path(sys.argv[1]);d=json.loads(p.read_text());d.update(status='ARCHIVE_FAILED',archiveExit=int(sys.argv[2]),releaseReadyClaimAllowed=False);p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
PY
    exit "$archive_exit"
fi
python3 -B "$script_root/scripts/check-release-readiness.py" \
    --app "$archive_output/Products/Applications/TacticalGo.app" \
    --account-evidence "$account_evidence" --report "$report_output"
echo "Local signed archive checked. No export, upload, submission or publication was performed."
