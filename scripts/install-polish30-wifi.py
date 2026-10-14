#!/usr/bin/env python3
"""Owner-authorized window-end update; check-only never contacts or changes the phone."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / 'artifacts/v11/polish-30'
APP = ARTIFACTS / 'signed-1109/TacticalGo.app'
BUNDLE = 'com.tacticalgo.prototype.herobody'
DEVICE = '0F60A459-7EE8-5B1B-BDF6-6B4D6047FAB8'
INSTALL_START = datetime(2026, 10, 14, 1, 34, 8, tzinfo=timezone.utc)
INSTALL_END = datetime(2026, 10, 14, 1, 54, 8, tzinfo=timezone.utc)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def successful_receipt(path):
    try:
        return json.loads(path.read_text()).get('info', {}).get('outcome') == 'success'
    except (OSError, ValueError):
        return False


def preservation(before_documents, after_documents, before_preferences, after_preferences):
    """Check every original document and preference key; additions do not erase old data."""
    files = [p for p in before_documents.rglob('*') if p.is_file()]
    changed = []
    for p in files:
        q = after_documents / p.relative_to(before_documents)
        if not q.is_file() or hashlib.sha256(p.read_bytes()).digest() != hashlib.sha256(q.read_bytes()).digest():
            changed.append(p.relative_to(before_documents).as_posix())
    preferences = list(before_preferences.rglob('*.plist'))
    changed_keys = []
    for p in preferences:
        q = after_preferences / p.relative_to(before_preferences)
        old = plistlib.loads(p.read_bytes())
        new = plistlib.loads(q.read_bytes()) if q.exists() else {}
        changed_keys.extend(p.name + ':' + key for key, value in old.items() if key not in new or new[key] != value)
    return dict(existingDocuments=len(files), existingPreferenceFiles=len(preferences),
                changedExistingDocuments=changed, changedExistingPreferenceKeys=changed_keys)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check-only', action='store_true')
    args = parser.parse_args()
    now = datetime.now(timezone.utc)
    if not args.check_only and not INSTALL_START <= now <= INSTALL_END:
        print('No phone action: outside the authorized window-end installation interval.')
        return 75
    run = ARTIFACTS / ('check-' if args.check_only else 'install-')
    run = run.with_name(run.name + now.strftime('%Y%m%dT%H%M%SZ'))
    run.mkdir(parents=True, exist_ok=False)
    stage = 'verify-candidate'
    report = dict(bundle=BUNDLE, version='1.1', build='1109', checkedAt=now.isoformat(),
                  checkOnly=args.check_only, installAttempted=False, deviceInstall=False,
                  deviceLaunch=False, phoneBuildVerified=False, dataPreservationVerified=False,
                  phoneAVRecorded=False, humanQualityAcceptance=False, testFlightUploaded=False)

    def command(name, arguments, allow_failure=False):
        with (run / (name + '.log')).open('w') as log:
            result = subprocess.run(arguments, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=55)
        report[name + 'Exit'] = result.returncode
        if result.returncode and not allow_failure:
            raise RuntimeError(name + ' failed; see its retained log')
        return result.returncode

    def device_command(name, arguments, allow_failure=False):
        return command(name, ['xcrun', 'devicectl', '--timeout', '45', '--json-output', str(run / (name + '.json'))] + arguments, allow_failure)

    try:
        pin = json.loads((ARTIFACTS / 'SOURCE_PIN.json').read_text())
        mismatches = [name for name, sha in pin.items() if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != sha]
        if mismatches:
            raise RuntimeError('Source changed after verification: ' + ', '.join(mismatches))
        info = plistlib.loads((APP / 'Info.plist').read_bytes())
        if (info.get('CFBundleIdentifier'), info.get('CFBundleShortVersionString'), info.get('CFBundleVersion')) != (BUNDLE, '1.1', '1109'):
            raise RuntimeError('Unexpected signed app identity/version')
        command('codesign', ['codesign', '--verify', '--deep', '--strict', str(APP)])
        signed = json.loads((ARTIFACTS / 'SIGNED_BUILD.json').read_text())
        sha = hashlib.sha256((APP / info['CFBundleExecutable']).read_bytes()).hexdigest()
        if not all(signed.get(k) is True for k in ['developmentSigned', 'registeredDevice', 'sourcePinMatches']) or signed.get('binarySHA256') != sha or signed.get('sourcePinSHA256') != hashlib.sha256((ARTIFACTS / 'SOURCE_PIN.json').read_bytes()).hexdigest():
            raise RuntimeError('Signed receipt does not match this registered development candidate')
        report.update(candidateVerified=True, binarySHA256=sha)
        if args.check_only:
            write_json(run / 'RESULT.json', report)
            print(json.dumps(report, ensure_ascii=False))
            return 0

        stage = 'wifi-connection'
        device_command('devices', ['list', 'devices'])
        devices = json.loads((run / 'devices.json').read_text())['result']['devices']
        phone = next((d for d in devices if d['identifier'] == DEVICE), None)
        if phone is None or phone['connectionProperties'].get('transportType') != 'localNetwork':
            raise RuntimeError('Paired iPhone is not available over Wi-Fi; candidate remains saved')
        report['wifi'] = True
        stage = 'fresh-backup'
        common = ['--device', DEVICE, '--domain-type', 'appDataContainer', '--domain-identifier', BUNDLE]
        for name, source, target in [('backup-documents', 'Documents', 'before-Documents'), ('backup-preferences', 'Library/Preferences', 'before-Preferences')]:
            device_command(name, ['device', 'copy', 'from'] + common + ['--source', source, '--destination', str(run / target)])
            if not successful_receipt(run / (name + '.json')) or not (run / target).is_dir():
                raise RuntimeError('Fresh backup not confirmed; installation is blocked')
        report['freshBackupVerified'] = True
        stage = 'install'
        report['installAttempted'] = True
        device_command('install', ['device', 'install', 'app', '--device', DEVICE, str(APP)])
        report['deviceInstall'] = successful_receipt(run / 'install.json')
        if not report['deviceInstall']:
            raise RuntimeError('Installation did not report success')
        stage = 'launch-and-phone-identity'
        device_command('launch', ['device', 'process', 'launch', '--device', DEVICE, BUNDLE], allow_failure=True)
        report['deviceLaunch'] = successful_receipt(run / 'launch.json')
        device_command('apps-after', ['device', 'info', 'apps', '--device', DEVICE])
        installed = next(a for a in json.loads((run / 'apps-after.json').read_text())['result']['apps'] if a['bundleIdentifier'] == BUNDLE)
        report.update(phoneVersion=installed.get('version'), phoneBuild=installed.get('bundleVersion'))
        report['phoneBuildVerified'] = report['phoneVersion'] == '1.1' and report['phoneBuild'] == '1109'
        if not report['phoneBuildVerified']:
            raise RuntimeError('Installed phone version/build could not be confirmed')
        stage = 'data-preservation'
        for name, source, target in [('after-documents', 'Documents', 'after-Documents'), ('after-preferences', 'Library/Preferences', 'after-Preferences')]:
            device_command(name, ['device', 'copy', 'from'] + common + ['--source', source, '--destination', str(run / target)])
            if not successful_receipt(run / (name + '.json')) or not (run / target).is_dir():
                raise RuntimeError('After-install data copy not confirmed; preservation not claimed')
        data = preservation(run / 'before-Documents', run / 'after-Documents', run / 'before-Preferences', run / 'after-Preferences')
        report.update(data)
        report['dataPreservationVerified'] = not data['changedExistingDocuments'] and not data['changedExistingPreferenceKeys']
        if not report['dataPreservationVerified']:
            raise RuntimeError('Original data changed; inspect the retained before/after backups')
        stage = 'complete' if report['deviceLaunch'] else 'installed-but-launch-unavailable'
        return 0 if report['deviceLaunch'] else 3
    except (OSError, ValueError, KeyError, StopIteration, RuntimeError, plistlib.InvalidFileException, subprocess.TimeoutExpired) as error:
        # Keep the successful install boundary even if a later launch/copy times out.
        report['deviceInstall'] = successful_receipt(run / 'install.json')
        report['deviceLaunch'] = successful_receipt(run / 'launch.json')
        report['error'] = str(error)
        return 1
    finally:
        report['stage'] = stage
        write_json(run / 'RESULT.json', report)
        print('Delivery result saved:', run / 'RESULT.json')


if __name__ == '__main__':
    sys.exit(main())
