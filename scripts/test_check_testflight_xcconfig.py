import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("chk", Path(__file__).with_name("check-testflight-xcconfig.py"))
chk = importlib.util.module_from_spec(spec); spec.loader.exec_module(chk)

GOOD = """MARKETING_VERSION = 1.1
CURRENT_PROJECT_VERSION = 1114
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
        path = Path(__file__).resolve().parents[1] / "docs/release-01/Beta.integrated-1114.xcconfig"
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
        self.assertIn("build_number_must_exceed_1113", run(GOOD.replace("1114", "1113")))

    def test_unknown_key_is_rejected(self):
        self.assertTrue(any(f.startswith("unsupported_line") for f in run(GOOD + "CODE_SIGN_STYLE = Manual\n")))

    def test_http_url_is_rejected(self):
        self.assertTrue(any(f.startswith("https_url_invalid") for f in run(GOOD.replace("https:/$()/example.test/privacy", "http:/$()/example.test/privacy"))))


if __name__ == "__main__":
    unittest.main()
