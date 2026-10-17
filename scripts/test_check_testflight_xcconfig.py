import importlib.util
import plistlib
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("chk", Path(__file__).with_name("check-testflight-xcconfig.py"))
chk = importlib.util.module_from_spec(spec); spec.loader.exec_module(chk)

GOOD = """MARKETING_VERSION = 1.1
CURRENT_PROJECT_VERSION = 1115
CROWN_UNLOCK_PRODUCT_ID = com.tacticalgo.crowntactics.unlock
CROWN_PRIVACY_URL = https:/$()/example.test/privacy
CROWN_SUPPORT_URL = https:/$()/example.test/
CROWN_ADMOB_APP_ID = ca-app-pub-4399068253512867~8970810838
CROWN_REWARDED_AD_UNIT_ID =
"""


def run(text):
    values, failures = chk.parse(text)
    return failures + chk.validate(values)


class XcconfigCheck(unittest.TestCase):
    def test_good_config_passes(self):
        self.assertEqual(run(GOOD), [])

    def test_repository_config_passes(self):
        path = Path(__file__).resolve().parents[1] / "docs/release-01/Beta.integrated-1115.xcconfig"
        self.assertEqual(run(path.read_text()), [])

    def test_comment_line_continuation_is_rejected(self):
        # The exact shape that silently swallowed the AdMob app id.
        self.assertIn("line_continuation_backslash:1", run("// xcodebuild archive \\\n" + GOOD))

    def test_missing_or_empty_admob_app_id_is_rejected(self):
        bad = GOOD.replace("CROWN_ADMOB_APP_ID = ca-app-pub-4399068253512867~8970810838\n", "CROWN_ADMOB_APP_ID =\n")
        self.assertTrue(any(f.startswith("admob_app_id_required") for f in run(bad)))

    def test_google_sample_app_id_is_rejected(self):
        bad = GOOD.replace("4399068253512867~8970810838", "3940256099942544~1458002511")
        self.assertIn("admob_app_id_is_google_sample", run(bad))

    def test_build_number_must_exceed_last_upload(self):
        self.assertIn("build_number_must_exceed_1114", run(GOOD.replace("1115", "1114")))

    def test_unknown_key_is_rejected(self):
        self.assertTrue(any(f.startswith("unsupported_line") for f in run(GOOD + "CODE_SIGN_STYLE = Manual\n")))

    def test_http_url_is_rejected(self):
        self.assertTrue(any(f.startswith("https_url_invalid") for f in run(GOOD.replace("https:/$()/example.test/privacy", "http:/$()/example.test/privacy"))))


class ExportComplianceKey(unittest.TestCase):
    """Hand-written Info.plist ignores INFOPLIST_KEY_*, which silently dropped this key from build 1114."""

    def _app(self, extra):
        values, _ = chk.parse(GOOD)
        info = {
            "CFBundleShortVersionString": "1.1", "CFBundleVersion": "1115",
            "CrownTacticsUnlockProductID": "com.tacticalgo.crowntactics.unlock",
            "CrownTacticsRewardedAdUnitID": "",
            "GADApplicationIdentifier": "ca-app-pub-4399068253512867~8970810838",
            "CrownTacticsPrivacyURL": "https://example.test/privacy",
            "CrownTacticsSupportURL": "https://example.test/",
        }
        info.update(extra)
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        (Path(tmp.name) / "Info.plist").write_bytes(plistlib.dumps(info))
        return values, Path(tmp.name)

    def test_built_app_without_key_is_rejected(self):
        values, app = self._app({})
        self.assertIn("built_plist_missing_ITSAppUsesNonExemptEncryption_false", chk.check_app(values, app))

    def test_built_app_with_key_false_passes(self):
        values, app = self._app({"ITSAppUsesNonExemptEncryption": False})
        self.assertEqual(chk.check_app(values, app), [])

    def test_source_info_plist_declares_key_false(self):
        info = plistlib.loads((Path(__file__).resolve().parents[1] / "ios/TacticalGo/Info.plist").read_bytes())
        self.assertIs(info.get("ITSAppUsesNonExemptEncryption"), False)


if __name__ == "__main__":
    unittest.main()
