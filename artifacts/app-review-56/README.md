# 1.1 (1121) App Review repair evidence

Local engineering verification on 2026-10-24. This folder contains no signing assets, account-page snapshots, transaction receipts or historical task memory. The exact uploaded 1120 archive was not available; its negative control is a reconstruction from main `31ac541` using the 1120 configuration.

| Check | Result | Evidence |
| --- | --- | --- |
| Reconstructed 1120 engineering-surface check | Expected failure: 13 markers + R2 fixture | `surface-red.json` |
| Repaired 1121 simulator check | Pass, no reviewed markers/resources | `surface-green.json` |
| Repaired 1121 unsigned iOS archive check | Pass, no reviewed markers/resources | `device-surface.json` |
| Device package metadata/resources | iPhone + iPad, privacy manifests present; unsigned | `device-package.json` |
| Initial local IPA checks | Limited checks pass; subsequent server validation rejects SDK requirements | `signed-distribution-check.json` |
| Signed package engineering surface | No reviewed markers/resources | `signed-surface.json` |
| Signing/export content equivalence | 49 file-backed sections and listed assets unchanged | `signing-content-equivalence.json` |
| Rejected upload signature requirements | Negative control: app passes, both SDKs fail | `signatures-rejected.json` |
| Fully signed archive export | All three app/framework requirements pass | `signatures-corrected.json` |
| Exact retry transport package | All three requirements pass; engineering surface passes | `signatures-upload-corrected.json`, `surface-upload-corrected.json` |
| Full rebuild comparison | 47/49 sections match; full equality fails; main text/source unchanged | `corrected-content-check.json` |
| Apple upload and processing | Retry accepted, observed processing status in receipt | `upload-receipt.json` |
| Authorized App Review resubmission | 1121 + existing unlock both Waiting for Review; manual release preserved | `submission-receipt.json` |
| Release iPhone portrait | 3 / 3 native flow tests pass | `verification.json`, `iphone-*.png` |
| Release iPad landscape | 3 / 3 native flow tests pass | `verification.json`, `ipad-*.png` |
| Debug fixture/save and R2 exchange/undo | 2 distinct tests pass on final applicable runs | `verification.json` |

The six Release device/test combinations exercise normal UI with empty launch arguments. Each device completes three normal local games to reach the zero-allowance continuation screen. Purchase and restore controls are observed, not exercised; no ad is watched. A displayed StoreKit price is not evidence of a successful transaction or a confirmation of every storefront's price.

Raw xcresults, screenshots and build logs are retained locally under `ios/Build/review56/`. `verification.json` inventories their SHA-256 digests and includes failed attempts; retries are not counted as extra distinct passing tests. The iPad screenshot retry corrects the capture API, not game layout. Captures are genuine simulator output, not composited artwork.

## Reproduction

Use a newly created iOS simulator with no existing app data. Do not erase an owner's device. The tests use the real allowance, so rerunning the complete Release batch needs a new task-owned simulator or removal of this app from that task-owned simulator.

```sh
python3 scripts/check-release-engineering-surface.py PATH_TO_BUILT_APP
python3 scripts/check-release-signatures.py PATH_TO_DISTRIBUTION_APP
bash -n scripts/package-release-assets.sh
git diff --check
```

The marker checker must return 1 for the reconstructed baseline, and 0 for both repaired packages. Its explicit marker/resource list is a bounded regression check, not a complete security audit or proof of Apple approval.

The signature checker must return 1 for the first rejected transport package (two SDK requirement failures) and 0 for the corrected export and actual retry package (three bundles pass). Earlier `codesign --verify --deep --strict` and main-app/profile checks did not detect this failure. The checker additionally evaluates each bundle's own designated requirement using a literal `-R '=REQUIREMENT_SOURCE'`, following [Apple TN3127](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).

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
  -xcconfig docs/release-01/Archive.1.1-1121.xcconfig \
  -derivedDataPath ios/Build/review56/device \
  -archivePath ios/Build/review56/CrownTactics-1.1-1121-signed.xcarchive \
  CODE_SIGNING_ALLOWED=YES -allowProvisioningUpdates -jobs 2 archive
```

That command creates a fully signed Release device archive. Its public config resolves to the same settings used for the successful build (recorded in `upload-receipt.json`). Xcode signs the archive with the existing development identity, then signs the exported App Store package with Apple Distribution. Export locally with `-exportArchive -allowProvisioningUpdates`, the signed archive path and these options:

```text
method = app-store-connect
destination = export
signingStyle = automatic
teamID = existing reviewed team
manageAppVersionAndBuildNumber = false
uploadSymbols = false
```

The first unsigned-archive export path and its receipts are retained only as failure evidence. Do not use its IPA for distribution. The corrected local IPA is `ios/Build/review56/AppStore-1121-corrected/TacticalGo.ipa`; the preserved exact retry package is `ios/Build/review56/TacticalGo-1121-upload-corrected-package.ipa`. Signing assets and IPA files are not committed. No private key is extracted.

The owner later explicitly authorized upload. Only that retry changed the export destination to `upload`; version management stayed disabled, retaining 1121. The first validation rejection, retry success and observed App Store Connect status are in `upload-receipt.json`.

After the owner's explicit resubmission instruction, build 1121 and the exact [plain-text Review Notes](../../docs/release-01/APP_REVIEW_NOTES_1.1_SUBMITTED.txt) were saved, then the app and existing non-consumable unlock were resubmitted at 2026-10-24 11:47 Asia/Taipei. Both items show Waiting for Review. A fresh page read confirms notes/build/manual release; `submission-receipt.json` contains that evidence. Earlier receipts describe their own stages and remain unchanged. No separate review reply or publication was performed.

Physical-device acceptance, production transactions/ad delivery and resolution of Apple's original unspecified 5.6 concern remain unverified. See the [repair report](../../docs/release-01/APP_REVIEW_56_REPAIR.md) for pending review acceptance and the unsent reply draft.
