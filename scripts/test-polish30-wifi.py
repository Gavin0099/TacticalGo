#!/usr/bin/env python3
"""Hand-written data/receipt fixtures; these do not claim a physical installation."""
import importlib.util
import json
from pathlib import Path
import plistlib
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('delivery', Path(__file__).with_name('install-polish30-wifi.py'))
delivery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(delivery)


class PreservationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='tgo-p30-data-fixture-')
        self.root = Path(self.temp.name)
        for name in ['before-doc', 'after-doc', 'before-pref', 'after-pref']:
            (self.root / name).mkdir()
        (self.root / 'before-doc/save.json').write_text('reviewed original record')
        (self.root / 'after-doc/save.json').write_text('reviewed original record')
        self.original = {'combatAudio.muted': False, 'combatAudio.musicVolume': 0.3}
        (self.root / 'before-pref/user.plist').write_bytes(plistlib.dumps(self.original))
        (self.root / 'after-pref/user.plist').write_bytes(plistlib.dumps(dict(self.original, **{'combatAudio.castVoiceVolume': 0.85})))

    def tearDown(self):
        self.temp.cleanup()

    def report(self):
        return delivery.preservation(*(self.root / name for name in ['before-doc', 'after-doc', 'before-pref', 'after-pref']))

    def test_additions_preserve_existing_data(self):
        self.assertEqual(self.report(), dict(existingDocuments=1, existingPreferenceFiles=1,
                                            changedExistingDocuments=[], changedExistingPreferenceKeys=[]))

    def test_changed_original_document(self):
        (self.root / 'after-doc/save.json').write_text('changed')
        self.assertEqual(self.report()['changedExistingDocuments'], ['save.json'])

    def test_missing_original_document(self):
        (self.root / 'after-doc/save.json').unlink()
        self.assertEqual(self.report()['changedExistingDocuments'], ['save.json'])

    def test_changed_and_missing_original_preferences(self):
        (self.root / 'after-pref/user.plist').write_bytes(plistlib.dumps({'combatAudio.muted': True}))
        self.assertEqual(set(self.report()['changedExistingPreferenceKeys']),
                         {'user.plist:combatAudio.muted', 'user.plist:combatAudio.musicVolume'})

    def test_only_explicit_success_receipt_is_accepted(self):
        (self.root / 'success.json').write_text(json.dumps({'info': {'outcome': 'success'}}))
        (self.root / 'failure.json').write_text(json.dumps({'info': {'outcome': 'failure'}}))
        (self.root / 'malformed.json').write_text('not json')
        self.assertTrue(delivery.successful_receipt(self.root / 'success.json'))
        for name in ['failure.json', 'malformed.json', 'missing.json']:
            self.assertFalse(delivery.successful_receipt(self.root / name))


if __name__ == '__main__':
    unittest.main()
