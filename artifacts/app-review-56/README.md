# 1.1 (1121) App Review repair evidence

Local engineering verification on 2026-10-24. This folder contains no signing assets, account-page snapshots, transaction receipts or historical task memory. The exact uploaded 1120 archive was not available; its negative control is a reconstruction from main `31ac541` using the 1120 configuration.

| Check | Result | Evidence |
| --- | --- | --- |
| Reconstructed 1120 engineering-surface check | Expected failure: 13 markers + R2 fixture | `surface-red.json` |
| Repaired 1121 simulator check | Pass, no reviewed markers/resources | `surface-green.json` |
| Repaired 1121 unsigned iOS archive check | Pass, no reviewed markers/resources | `device-surface.json` |
| Device package metadata/resources | iPhone + iPad, privacy manifests present; unsigned | `device-package.json` |
| Release iPhone portrait | 3 / 3 native flow tests pass | `verification.json`, `iphone-*.png` |
| Release iPad landscape | 3 / 3 native flow tests pass | `verification.json`, `ipad-*.png` |
| Debug fixture/save and R2 exchange/undo | 2 distinct tests pass on final applicable runs | `verification.json` |

The six Release device/test combinations exercise normal UI with empty launch arguments. Each device completes three normal local games to reach the zero-allowance continuation screen. Purchase and restore controls are observed, not exercised; no ad is watched. A displayed StoreKit price is not evidence of a successful transaction or a confirmation of every storefront's price.

Raw xcresults, screenshots and build logs are retained locally under `ios/Build/review56/`. `verification.json` inventories their SHA-256 digests and includes failed attempts; retries are not counted as extra distinct passing tests. The iPad screenshot retry corrects the capture API, not game layout. Captures are genuine simulator output, not composited artwork.

## Reproduction

Use a newly created iOS simulator with no existing app data. Do not erase an owner's device. The tests use the real allowance, so rerunning the complete Release batch needs a new task-owned simulator or removal of this app from that task-owned simulator.

```sh
python3 scripts/check-release-engineering-surface.py PATH_TO_BUILT_APP
bash -n scripts/package-release-assets.sh
git diff --check
```

The marker checker must return 1 for the reconstructed baseline, and 0 for both repaired packages. Its explicit marker/resource list is a bounded regression check, not a complete security audit or proof of Apple approval.

```sh
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo \
  -configuration Release -destination 'platform=iOS Simulator,id=TASK_DEVICE_ID' \
  -xcconfig docs/release-01/Release.1.1-1121.xcconfig \
  -derivedDataPath ios/Build/review56/candidate \
  ARCHS=arm64 CODE_SIGNING_ALLOWED=NO -jobs 2 -parallel-testing-enabled NO \
  -collect-test-diagnostics never -resultBundlePath UNIQUE_RESULT_PATH \
  -only-testing:TacticalGoUITests/IntegrationUITests/testReviewPublicEntriesAndDisclosureWithoutEngineeringArguments \
  -only-testing:TacticalGoUITests/IntegrationUITests/testReviewPublicPracticeAndMonsterEntryWithoutEngineeringArguments \
  -only-testing:TacticalGoUITests/IntegrationUITests/testReviewRewardedChoiceAfterThreeCompletedMatches test
```

The actual run reused the already-resolved Google SDK package cache via `-clonedSourcePackagesDirPath`. No package version changed. Debug validation uses configuration Debug without the release xcconfig, selecting `ExpansionLabTests/testSavedMatchResumesFromFrozenReviewAndRemainsPlayableAndSaveable` and `PlayableGameTests/testR2MageExchangePreviewAndUndo`.

```sh
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo \
  -configuration Release -destination 'generic/platform=iOS' \
  -xcconfig docs/release-01/Release.1.1-1121.xcconfig \
  -derivedDataPath ios/Build/review56/device \
  -archivePath ios/Build/review56/CrownTactics-1.1-1121-unsigned.xcarchive \
  CODE_SIGNING_ALLOWED=NO -jobs 2 archive
```

That command creates an **unsigned** device archive; it is not an upload procedure. Distribution signing/profile/entitlements, physical-device validation, production transactions/ad delivery and Apple's unspecified rejection cause remain unverified. See the [repair report](../../docs/release-01/APP_REVIEW_56_REPAIR.md) for the owner actions and unsent review drafts.
