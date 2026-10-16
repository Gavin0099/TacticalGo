#!/usr/bin/env python3
"""Read-only check of the integrated TestFlight xcconfig (and, optionally, a built app's Info.plist).

It exists because of two silent failure modes found on 2026-10-15:
  * a trailing backslash in an xcconfig *comment* is a line continuation and silently swallowed the AdMob app id,
  * an empty GADApplicationIdentifier makes the linked Google Mobile Ads SDK throw at launch.
Exit 0 means the local checks passed. It does not log in, build, sign or upload anything.
"""
from __future__ import annotations

import argparse
import plistlib
import re
import sys
from pathlib import Path

LAST_UPLOADED_BUILD = 1113   # last build known to be uploaded for this app; raise if App Store Connect shows more
ALLOWED = {
    "MARKETING_VERSION", "CURRENT_PROJECT_VERSION", "CROWN_UNLOCK_PRODUCT_ID", "CROWN_PRIVACY_URL",
    "CROWN_SUPPORT_URL", "CROWN_ADMOB_APP_ID", "CROWN_REWARDED_AD_UNIT_ID",
}
SAMPLE_PUBLISHER = "3940256099942544"
AD_APP = re.compile(r"ca-app-pub-[0-9]{16}~[0-9]{10}\Z")
AD_UNIT = re.compile(r"ca-app-pub-[0-9]{16}/[0-9]{10}\Z")
PRODUCT = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{2,254}\Z")


def parse(text: str) -> tuple[dict[str, str], list[str]]:
    values: dict[str, str] = {}
    failures: list[str] = []
    for number, raw in enumerate(text.splitlines(), 1):
        if raw.rstrip().endswith("\\"):
            failures.append(f"line_continuation_backslash:{number}")
        line = raw.split("//", 1)[0].strip()   # URLs are written https:/$()/host so they contain no "//"
        if not line:
            continue
        match = re.fullmatch(r"([A-Z][A-Z0-9_]*)\s*=\s*(.*)", line)
        if not match or match.group(1) not in ALLOWED:
            failures.append(f"unsupported_line:{number}")
            continue
        key, value = match.group(1), match.group(2).strip().replace("$()", "")
        if key in values:
            failures.append(f"duplicate_key:{key}")
        values[key] = value
    return values, failures


def validate(values: dict[str, str]) -> list[str]:
    failures: list[str] = []
    if not re.fullmatch(r"[0-9]+\.[0-9]+(\.[0-9]+)?", values.get("MARKETING_VERSION", "")):
        failures.append("marketing_version_invalid")
    build = values.get("CURRENT_PROJECT_VERSION", "")
    if not build.isdigit() or int(build) <= LAST_UPLOADED_BUILD:
        failures.append(f"build_number_must_exceed_{LAST_UPLOADED_BUILD}")
    if not PRODUCT.fullmatch(values.get("CROWN_UNLOCK_PRODUCT_ID", "")):
        failures.append("unlock_product_id_invalid")
    app = values.get("CROWN_ADMOB_APP_ID", "")
    if not AD_APP.fullmatch(app):
        failures.append("admob_app_id_required_sdk_throws_at_launch_without_it")
    elif SAMPLE_PUBLISHER in app:
        failures.append("admob_app_id_is_google_sample")
    unit = values.get("CROWN_REWARDED_AD_UNIT_ID", "")
    if unit and (not AD_UNIT.fullmatch(unit) or SAMPLE_PUBLISHER in unit):
        failures.append("rewarded_unit_id_invalid")
    for key in ("CROWN_PRIVACY_URL", "CROWN_SUPPORT_URL"):
        if not re.fullmatch(r"https://[A-Za-z0-9.-]+(/[^\s]*)?", values.get(key, "")):
            failures.append(f"https_url_invalid:{key}")
    return failures


def check_app(values: dict[str, str], app: Path) -> list[str]:
    try:
        info = plistlib.loads((app / "Info.plist").read_bytes())
    except (OSError, plistlib.InvalidFileException):
        return ["built_info_plist_unreadable"]
    expected = {
        "CFBundleShortVersionString": values.get("MARKETING_VERSION"),
        "CFBundleVersion": values.get("CURRENT_PROJECT_VERSION"),
        "CrownTacticsUnlockProductID": values.get("CROWN_UNLOCK_PRODUCT_ID"),
        "CrownTacticsRewardedAdUnitID": values.get("CROWN_REWARDED_AD_UNIT_ID", ""),
        "GADApplicationIdentifier": values.get("CROWN_ADMOB_APP_ID"),
        "CrownTacticsPrivacyURL": values.get("CROWN_PRIVACY_URL"),
        "CrownTacticsSupportURL": values.get("CROWN_SUPPORT_URL"),
    }
    return [f"built_plist_mismatch:{k}" for k, v in expected.items() if info.get(k) != v]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("xcconfig", type=Path)
    parser.add_argument("--app", type=Path, help="built .app whose Info.plist must match the xcconfig")
    args = parser.parse_args()
    values, failures = parse(args.xcconfig.read_text())
    failures += validate(values)
    if args.app:
        failures += check_app(values, args.app)
    for failure in failures:
        print("FAIL:", failure)
    print("OK" if not failures else "NOT OK")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
