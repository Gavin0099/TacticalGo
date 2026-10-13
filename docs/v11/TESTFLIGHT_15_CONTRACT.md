# 1.1 TestFlight upload — 15

Owner explicitly requested upload to TestFlight for testing, superseding the previous window's no-upload constraint for this action. Scope: existing App Store Connect app 6821588889 / com.tacticalgo.prototype.herobody; 1.1 (1103), full integrated original lobby/match, Offering priest, existing accepted mage D/B and warrior B preserved. No 1.0 submission changes, App Review submission, public release, Git commit/push/merge or new gameplay.

## Build boundary

Dedicated Beta configuration/scheme uses Release optimization and TACTICALGO_V11; production Release and Debug remain distinct. Integrated feature and dependent presentation sources accept DEBUG or TACTICALGO_V11, while root lab routing and test launch injection stay DEBUG only. Include the actual 54 presentation assets and two monsters; use same previously submitted AppIcon copied read-only from 1.0 checkout. Archive/distribute with installed Apple Distribution identity and App Store profile. Export as TestFlight internal-only, unchangeable build 1103; this candidate cannot become a public App Store release.

## Validation / failure paths

Run native Beta smoke for original lobby Priest Offering (including cancel/undo) and monster/loot/resume without DEBUG flags; exercise all three second skills through actual practice menu. Validate signed archive version/bundle/get-task-allow=false/icon/resources and unchanged accepted asset bytes. Existing 239 Domain tests remain evidence because Domain source is unchanged; do not repeat solely for packaging.

Export a locally inspectable IPA, then upload with Xcode configured account. Preserve failures. Upload success is not Apple processing success, tester-group availability or human quality acceptance. Check TestFlight processing/group once authentication permits; assign only Owner internal tester group; if none exists, create one manually distributed group and add only the existing Account Holder for the requested self-test, do not invite arbitrary external users or submit Beta App Review. No credential contents logged/persisted. If login required, finish signed artifact/export preparation before asking Owner to sign in; do not create account credentials or API keys on their behalf.
