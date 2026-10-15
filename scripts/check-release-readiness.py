#!/usr/bin/env python3
"""Read-only local App Store preflight. Only --report writes, under repo artifacts.

It does not log in, build, sign, change entitlements, or assert external account truth.
Exit 0 means local checks passed; external Sandbox/device/review gates still apply.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
from html.parser import HTMLParser
import ipaddress
import json
from pathlib import Path
import plistlib
import re
import socket
import subprocess
import sys
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener


ROOT = Path(__file__).resolve().parents[1]
GOOGLE_SAMPLE_PUBLISHERS = {"3940256099942544"}
PLACEHOLDER = re.compile(r"\$\(|\$\{|placeholder|todo|pending|changeme|replace[_ -]?me|your[_ -]|not[_ -]?set", re.I)
AD_APP = re.compile(r"ca-app-pub-([0-9]{16})~[0-9]{10}\Z")
AD_UNIT = re.compile(r"ca-app-pub-([0-9]{16})/[0-9]{10}\Z")
PRODUCT = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{2,254}\Z")


def value_text(value: object) -> str:
    return value.strip() if isinstance(value, str) else ""


def configured(value: object) -> bool:
    text = value_text(value)
    return bool(text) and PLACEHOLDER.search(text) is None


def valid_ad_id(value: object, *, app: bool) -> bool:
    match = (AD_APP if app else AD_UNIT).fullmatch(value_text(value))
    return bool(match) and match.group(1) not in GOOGLE_SAMPLE_PUBLISHERS and set(match.group(1)) != {"0"}


def public_url_shape(value: object) -> bool:
    if not configured(value):
        return False
    try:
        url = urlsplit(value_text(value))
        host = url.hostname or ""
        if url.scheme != "https" or not host or url.username or url.password:
            return False
        if url.port not in (None, 443) or host.lower() in {"localhost", "example.com", "example.org", "example.net"}:
            return False
        if host.endswith((".local", ".localhost", ".invalid", ".test", ".example")):
            return False
        if "english-vocab-trainer" in url.path.lower():
            return False
        try:
            if not ipaddress.ip_address(host).is_global:
                return False
        except ValueError:
            pass
        return True
    except ValueError:
        return False


def safe_public_url(url: str) -> None:
    if not public_url_shape(url):
        raise ValueError("Not a product-specific public HTTPS URL")
    host = urlsplit(url).hostname
    addresses = socket.getaddrinfo(host, 443, type=socket.SOCK_STREAM)
    if not addresses or any(not ipaddress.ip_address(row[4][0]).is_global for row in addresses):
        raise ValueError("Private, local or non-public destination rejected")


class PublicRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        safe_public_url(newurl)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


class PageText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text: list[str] = []

    def handle_data(self, data: str) -> None:
        self.text.append(data)


def inspect_public_page(url: str) -> tuple[bool, dict]:
    try:
        safe_public_url(url)
        request = Request(url, headers={"User-Agent": "TacticalGo-Release-Preflight/1.0", "Accept": "text/html"})
        with build_opener(PublicRedirects()).open(request, timeout=12) as response:
            final_url = response.geturl()
            safe_public_url(final_url)
            data = response.read(262145)
            if response.status != 200 or len(data) > 262144 or "text/html" not in response.headers.get("Content-Type", ""):
                return False, {"reason": "Expected HTTP 200 HTML up to 256 KiB"}
            parser = PageText()
            parser.feed(data.decode(response.headers.get_content_charset() or "utf-8", errors="replace"))
            text = " ".join(parser.text)
            product_named = "皇冠戰略" in text or "crown tactics" in text.lower()
            draft = bool(re.search(r"草稿|尚未公開|尚未定稿|待填|本機候選|\bdraft\b|\bTODO\b|\bplaceholder\b", text, re.I))
            return product_named and not draft, {
                "httpStatus": response.status, "finalURL": final_url,
                "sha256": hashlib.sha256(data).hexdigest(),
                "productNamed": product_named, "draftMarkersPresent": draft,
            }
    except Exception as error:
        # No response bodies, cookies, credentials or SDK response identifiers in errors.
        return False, {"reason": type(error).__name__}


def command(args: list[str]) -> tuple[int, bytes, bytes]:
    try:
        result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30, check=False)
        return result.returncode, result.stdout, result.stderr
    except (OSError, subprocess.TimeoutExpired) as error:
        return 127, b"", type(error).__name__.encode()


def profile_is_app_store(profile: dict, bundle: str, team: str) -> bool:
    entitlements = profile.get("Entitlements", {})
    expiry = profile.get("ExpirationDate")
    if not isinstance(entitlements, dict) or not isinstance(expiry, datetime):
        return False
    expiry = expiry.replace(tzinfo=timezone.utc) if expiry.tzinfo is None else expiry
    return (
        expiry > datetime.now(timezone.utc)
        and entitlements.get("get-task-allow") is False
        and not profile.get("ProvisionedDevices")
        and profile.get("ProvisionsAllDevices") is not True
        and bool(team)
        and team in profile.get("TeamIdentifier", [])
        and entitlements.get("application-identifier") == team + "." + bundle
    )


def audit(app: Path, account_path: Path) -> dict:
    checks: list[dict] = []

    def add(name: str, passed: bool, detail: object) -> None:
        checks.append({"id": name, "status": "PASS" if passed else "FAIL", "detail": detail})

    source = ROOT / "ios/TacticalGo/Info.plist"
    try:
        source_info = plistlib.loads(source.read_bytes())
        add("source_info_contract", all(key in source_info for key in (
            "CrownTacticsUnlockProductID", "GADApplicationIdentifier", "CrownTacticsRewardedAdUnitID",
            "CrownTacticsPrivacyURL", "CrownTacticsSupportURL")), str(source.relative_to(ROOT)))
    except (OSError, plistlib.InvalidFileException, ValueError) as error:
        add("source_info_contract", False, type(error).__name__)

    info: dict = {}
    add("app_exists", app.is_dir() and app.suffix == ".app", str(app))
    try:
        parsed = plistlib.loads((app / "Info.plist").read_bytes())
        if not isinstance(parsed, dict):
            raise ValueError("Info.plist must be a dictionary")
        info = parsed
        add("built_info_readable", True, {"sha256": hashlib.sha256((app / "Info.plist").read_bytes()).hexdigest()})
    except (OSError, plistlib.InvalidFileException, ValueError) as error:
        add("built_info_readable", False, type(error).__name__)

    bundle = value_text(info.get("CFBundleIdentifier"))
    add("bundle_id", configured(bundle) and bool(PRODUCT.fullmatch(bundle)), bundle)
    add("marketing_version_1_0", info.get("CFBundleShortVersionString") == "1.0", info.get("CFBundleShortVersionString"))
    add("physical_ios_build", info.get("DTPlatformName") == "iphoneos" and info.get("CFBundlePackageType") == "APPL", info.get("DTPlatformName"))
    product = value_text(info.get("CrownTacticsUnlockProductID"))
    add("unlock_product_id", configured(product) and bool(PRODUCT.fullmatch(product)), product)
    app_id = value_text(info.get("GADApplicationIdentifier"))
    unit_id = value_text(info.get("CrownTacticsRewardedAdUnitID"))
    add("admob_production_app_id", valid_ad_id(app_id, app=True), app_id)
    add("admob_production_rewarded_id", valid_ad_id(unit_id, app=False), unit_id)
    add("admob_same_publisher", valid_ad_id(app_id, app=True) and valid_ad_id(unit_id, app=False)
        and AD_APP.fullmatch(app_id).group(1) == AD_UNIT.fullmatch(unit_id).group(1), "App and rewarded unit publisher must agree")
    for key in ("CrownTacticsPrivacyURL", "CrownTacticsSupportURL"):
        url = value_text(info.get(key))
        shape_ok = public_url_shape(url)
        add(key + "_https", shape_ok, url)
        page_ok, page_detail = inspect_public_page(url) if shape_ok else (False, {"reason": "URL missing or not a product-specific public HTTPS URL"})
        add(key + "_published", page_ok, page_detail)

    forbidden: list[str] = []
    privacy_manifests: list[str] = []
    if app.is_dir():
        for path in app.rglob("*"):
            relative = path.relative_to(app).as_posix()
            if (path.name.lower() in {"voice", "models"}
                    or path.suffix.lower() in {".storekit", ".usdz", ".scn"}
                    or (path.name.lower().startswith("voice-") and path.suffix.lower() in {".wav", ".mp3", ".m4a"})):
                forbidden.append(relative)
            if path.name == "PrivacyInfo.xcprivacy":
                privacy_manifests.append(relative)
    add("no_rejected_or_testing_resources", app.is_dir() and not forbidden, sorted(forbidden))
    add("app_privacy_manifest_present", (app / "PrivacyInfo.xcprivacy").is_file(), sorted(privacy_manifests))
    executable_name = value_text(info.get("CFBundleExecutable"))
    executable = app / executable_name
    executable_ok = bool(executable_name) and "/" not in executable_name and executable.is_file()
    add("executable_present", executable_ok, {
        "name": executable_name,
        "sha256": hashlib.sha256(executable.read_bytes()).hexdigest() if executable_ok else None,
    })

    code, out, err = command(["/usr/bin/codesign", "--display", "--verbose=4", str(app)])
    signing_text = (out + err).decode("utf-8", errors="replace")
    authorities = re.findall(r"^Authority=(.+)$", signing_text, re.M)
    team_match = re.search(r"^TeamIdentifier=(.+)$", signing_text, re.M)
    team = team_match.group(1).strip() if team_match else ""
    distribution = code == 0 and any(name.startswith(("Apple Distribution:", "iPhone Distribution:")) for name in authorities)
    add("distribution_signing_identity", distribution, {"authorities": authorities, "teamIdentifier": team, "commandExit": code})
    code, _, _ = command(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(app)])
    add("codesign_integrity", code == 0, {"commandExit": code})
    code, out, _ = command(["/usr/bin/codesign", "--display", "--entitlements", ":-", str(app)])
    try:
        parsed = plistlib.loads(out)
        entitlements = parsed if isinstance(parsed, dict) else {}
    except (plistlib.InvalidFileException, ValueError):
        entitlements = {}
    add("release_entitlements", code == 0 and isinstance(entitlements, dict)
        and entitlements.get("get-task-allow") is not True
        and bool(team) and entitlements.get("application-identifier") == team + "." + bundle,
        {"getTaskAllow": entitlements.get("get-task-allow"), "applicationIdentifier": entitlements.get("application-identifier")})
    profile = app / "embedded.mobileprovision"
    decoded: dict = {}
    if profile.is_file():
        code, out, _ = command(["/usr/bin/security", "cms", "-D", "-i", str(profile)])
        try:
            candidate = plistlib.loads(out) if code == 0 else {}
            decoded = candidate if isinstance(candidate, dict) else {}
        except (plistlib.InvalidFileException, ValueError):
            pass
    add("app_store_profile", profile.is_file() and profile_is_app_store(decoded, bundle, team), {
        "present": profile.is_file(), "developmentOrAdHocDevicesPresent": bool(decoded.get("ProvisionedDevices")),
        "enterpriseProfile": decoded.get("ProvisionsAllDevices") is True,
    })

    account: dict = {}
    try:
        candidate = json.loads(account_path.read_text())
        account = candidate if isinstance(candidate, dict) else {}
        add("account_evidence_present", bool(account), str(account_path))
    except (OSError, ValueError) as error:
        add("account_evidence_present", False, {"path": str(account_path), "reason": type(error).__name__})
    asc = account.get("appStoreConnect", {})
    admob = account.get("adMob", {})
    owner = account.get("ownerAccountChecks", {})
    asc = asc if isinstance(asc, dict) else {}
    admob = admob if isinstance(admob, dict) else {}
    owner = owner if isinstance(owner, dict) else {}
    add("asc_record_app_id_and_sku", bool(re.fullmatch(r"[0-9]{5,}", value_text(asc.get("appID"))))
        and configured(asc.get("sku")), {"appID": asc.get("appID"), "sku": asc.get("sku")})
    add("asc_bundle_and_product_match", bool(bundle and product) and asc.get("bundleIdentifier") == bundle
        and asc.get("productID") == product and asc.get("productType") == "nonConsumable"
        and asc.get("productMetadataComplete") is True, "Owner-recorded ASC bundle/product and metadata")
    add("admob_record_matches_bundle_config", bool(app_id and unit_id) and admob.get("appID") == app_id
        and admob.get("rewardedAdUnitID") == unit_id and admob.get("privacyMessageConfigured") is True,
        "Owner-recorded AdMob identifiers and privacy message")
    verified_at = value_text(owner.get("verifiedAt"))
    try:
        stamp = datetime.fromisoformat(verified_at.replace("Z", "+00:00"))
        date_ok = stamp.tzinfo is not None and stamp <= datetime.now(timezone.utc)
    except ValueError:
        date_ok = False
    add("owner_commercial_and_privacy_checks", date_ok and all(owner.get(key) is True for key in (
        "paidAppsAgreementActive", "bankAndTaxReady", "privacyDeclarationReviewed")),
        {"ownerRecordedVerifiedAt": verified_at, "verificationBoundary": "Recorded declaration; no account API inspection"})

    failures = [row["id"] for row in checks if row["status"] == "FAIL"]
    return {
        "schema": "tacticalgo-local-release-preflight-v1",
        "checkedAt": datetime.now(timezone.utc).isoformat(), "app": str(app),
        "status": "LOCAL_PREFLIGHT_FAIL" if failures else "LOCAL_PREFLIGHT_PASS_EXTERNAL_GATES_REQUIRED",
        "releaseReadyClaimAllowed": False,
        "bundleIdentifier": bundle, "marketingVersion": info.get("CFBundleShortVersionString"), "build": info.get("CFBundleVersion"),
        "checks": checks, "failures": failures,
        "claimBoundary": "Read-only local package/config/URL checks and Owner-recorded metadata. No account login, external transaction, device acceptance, review or submission verification.",
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, default=ROOT / "ios/Build/Products/Release-iphoneos/TacticalGo.app")
    parser.add_argument("--report", type=Path, default=ROOT / "artifacts/monetization-02/release-audit/RELEASE_PREFLIGHT_1024.json")
    parser.add_argument("--account-evidence", type=Path, default=ROOT / "docs/release-01/account-release-evidence.json")
    args = parser.parse_args(argv)
    app = args.app.resolve()
    report_path = args.report.resolve()
    artifacts = (ROOT / "artifacts").resolve()
    if not report_path.is_relative_to(artifacts) or report_path.is_relative_to(app) or report_path.suffix.lower() != ".json":
        parser.error("--report must be a JSON file under this repository's artifacts and outside the input App")
    account_path = args.account_evidence.resolve()
    if report_path == account_path:
        parser.error("--report cannot overwrite account evidence")
    report = audit(app, account_path)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(report["status"])
    for failure in report["failures"]:
        print("FAIL:", failure)
    print("Report:", report_path)
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    sys.exit(main())
