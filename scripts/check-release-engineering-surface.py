#!/usr/bin/env python3
"""Inspect a built app for reviewed engineering-entry markers, not App Review approval."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import sys

# Engineering controls are not public modes. This explicit contract is independent
# of the source's conditional compilation and must reject the 1120 reconstruction.
MARKERS = (
    b"--exp-review", b"--exp-autoplay", b"--record-isolation",
    b"--review-controls", b"--presentation-", b"--warrior-autoplay",
    b"--warrior-board-", b"--warrior-lifecycle-audit", b"--warrior-voice-",
    b"--identity-models", b"--package-models", b"--monetization-exhausted",
    # NUL-delimited Swift type metadata, not a harmless source filename in DWARF.
    b"\0R2LabView\0", b"\0PresentationLabStore\0", b"\0WarriorLabStore\0",
)


def inspect(app):
    info = plistlib.loads((app / "Info.plist").read_bytes())
    executable = app / info["CFBundleExecutable"]
    data = executable.read_bytes()
    found = [marker.decode().strip("\0") for marker in MARKERS if marker in data]
    resources = [p for p in ("R2Positions.json", "Audio/Voice", "Audio/V30", "Models") if (app / p).exists()]
    return {
        "schema": "tacticalgo-release-engineering-surface-v1",
        "version": info.get("CFBundleShortVersionString"),
        "build": info.get("CFBundleVersion"),
        "executableSHA256": hashlib.sha256(data).hexdigest(),
        "engineeringMarkersFound": found,
        "excludedResourcesFound": resources,
        "passed": not found and not resources,
        "claimBoundary": "Reviewed executable markers and resources only; not proof of runtime equivalence, uploaded-archive identity or Apple approval.",
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
