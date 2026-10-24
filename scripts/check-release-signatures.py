#!/usr/bin/env python3
"""Check the app and embedded frameworks, including explicit requirement evaluation.

An unsigned archive exported with cloud signing can pass a broad integrity check
while embedded SDKs retain requirements inconsistent with their identifiers.
The rejected 1121 upload is the negative control for this check. No account or
keychain data is read, and no signatures are changed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
import subprocess
import sys


def command(*args):
    return subprocess.run(["/usr/bin/codesign", *args], capture_output=True, text=True)


def inspect(app):
    bundles = [app] + sorted((app / "Frameworks").glob("*.framework"))
    rows = []
    for bundle in bundles:
        info = plistlib.loads((bundle / "Info.plist").read_bytes())
        display = command("--display", "--verbose=4", str(bundle))
        metadata = display.stdout + "\n" + display.stderr

        def value(key):
            match = re.search(r"^" + key + r"=(.*)$", metadata, re.M)
            return match.group(1) if match else ""

        requirements = command("-d", "-r-", str(bundle))
        requirement = next((line.split("designated => ", 1)[1]
                            for line in (requirements.stdout + "\n" + requirements.stderr).splitlines()
                            if line.startswith("designated => ")), "")
        # A leading '=' makes codesign compile literal source, not read a file.
        explicit = command("--verify", "--strict", "-R", "=" + requirement, str(bundle)) if requirement else None
        checks = {
            "metadataReadable": display.returncode == 0 and requirements.returncode == 0,
            "identifierMatchesInfo": value("Identifier") == info["CFBundleIdentifier"],
            "appleDistributionAuthority": "Authority=Apple Distribution:" in metadata,
            "teamPresent": bool(value("TeamIdentifier")) and value("TeamIdentifier") != "not set",
            "designatedRequirementSatisfied": explicit is not None and explicit.returncode == 0,
        }
        rows.append({
            "bundle": "." if bundle == app else str(bundle.relative_to(app)),
            "bundleID": info["CFBundleIdentifier"],
            "signatureIdentifier": value("Identifier"),
            "team": value("TeamIdentifier"),
            "requirementSHA256": hashlib.sha256(requirement.encode()).hexdigest(),
            "checks": checks,
        })
    root_team = rows[0]["team"]
    same_team = bool(root_team) and all(row["team"] == root_team for row in rows)
    integrity = command("--verify", "--deep", "--strict", str(app)).returncode == 0
    return {
        "schema": "tacticalgo-release-signature-check-v1",
        "bundles": rows,
        "embeddedTeamsMatchApp": same_team,
        "deepIntegrity": integrity,
        "passed": same_team and integrity and all(all(row["checks"].values()) for row in rows),
        "claimBoundary": "Local app/framework signing requirements only; not App Store Connect processing or Apple review approval.",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    args = parser.parse_args()
    try:
        result = inspect(args.app)
    except (OSError, ValueError, KeyError, plistlib.InvalidFileException) as error:
        print(json.dumps({"passed": False, "error": str(error)}))
        return 2
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
