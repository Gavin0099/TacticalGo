# TG12 native validation — 2026-10-22

結果：PR #34 在 macOS 完成 Swift 套件測試及 Debug／Beta 的 App 與 UI 測試程式編譯。
原因：Xcode 已就緒；另修正遠征 UI 測試在 Debug 選錯首頁的啟動參數。模擬器 runtime 尚未安裝完成。
下一步：runtime 完成後執行下列 UI 驗證，再做 iPhone 與 3–5 人試玩。尚未達到原生或產品驗收。

## Source and change

Base: `e35d467687cb0c5fcfb6758b109e3096a8b61e5d`, branch `codex/tg12-tactical-expedition`.
Only the expedition product-entry UI test changes: Debug now passes the existing
`--full-game` argument. `TacticalGoApp.productRoot` otherwise launches the legacy
home, whose challenge button directly opens the introduction catalog. The test
expects the expansion home's `openExpedition` menu item. Beta already selects
`FullGameRoot` and needs no additional argument.

This is a source-confirmed test setup correction. Neither the original failure
nor the corrected UI interaction has been executed on a simulator yet. No App,
Core, Bot, save, admission, release configuration or gameplay behavior changed.

## Executed evidence

Toolchain: Xcode 27.1 (27A9275), Apple Swift 6.4, arm64 macOS.

| Check | Result | Limit |
|---|---|---|
| Original PR Debug `build-for-testing` | exit 0, arm64 + x86_64 | Compiled App and UI test bundle; did not run UI tests |
| Corrected Debug `build-for-testing` | exit 0, arm64 + x86_64 | Same execution limit |
| Corrected Beta `build-for-testing` | exit 0, arm64 | Actual product compilation path; no signing/upload |
| macOS `swift test` | 464 executed, 0 unexpected failures, 0 skipped | 463 ordinary passes and 1 test with the pre-existing expected Bot failure |
| `git diff --check` | Passed | Whitespace only |

The eight XCTest target totals are 11, 52, 13, 121, 104, 76, 53 and 34. They sum to
464; trailing Swift Testing messages containing zero tests are not additional
tests. Darwin still reports the known unnecessary Sanctum use in
`PriestSanctumBotTests` as `XCTExpectFailure`; this does not fix the Bot or establish
balance. The previous Linux result (one skip) remains separate evidence.

Existing warnings remain: forced downcast in `PlayableGameView.swift:402`, duplicate
PrivacyInfo resource, and AppIntents extraction without that framework. They were
not changed in this bounded validation task.

Machine-readable results and log hashes:
[validation.json](../../artifacts/tg12/native-validation/validation.json).
Raw logs are retained locally under ignored `ios/Build/tg12-native-20261022/`;
they are not included in the public branch. Historical memory and master-plan
files remain outside this delivery.

## Reproduce compilation

From the repository root (the temporary derived-data paths may be replaced):

```sh
swift test --package-path swift/TacticalGoCore --jobs 2
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/tg12-native-20261022/DerivedData -jobs 2 \
  CODE_SIGNING_ALLOWED=NO build-for-testing
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGoBeta \
  -configuration Beta -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/tg12-native-20261022/BetaDerivedData -jobs 2 \
  ARCHS=arm64 CODE_SIGNING_ALLOWED=NO build-for-testing
```

## Pending native execution

`xcrun simctl list runtimes --json` returned no runtimes, and
`xcrun devicectl list devices` found no devices. The iOS 27.1 arm64 runtime download
was started. Neither downloading a runtime nor compiling its SDK proves UI execution.

Once installed, select an available iPhone simulator with
`xcrun simctl list devices available`, boot it, and substitute its UDID below.
Use a fresh simulator for Beta: its challenge journal intentionally ignores the
Debug-only `--record-isolation` argument. Never reset an Owner device's data.

```sh
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo \
  -configuration Debug -destination 'platform=iOS Simulator,id=<UDID>' \
  -derivedDataPath /tmp/tg12-native-20261022/DerivedData \
  -parallel-testing-enabled NO -resultBundlePath /tmp/tg12-debug-ui.xcresult \
  -only-testing:TacticalGoUITests/AdvancedChallengeUITests \
  -skip-testing:TacticalGoUITests/AdvancedChallengeUITests/testIPadPortraitLandscapeAndRestoredSelectedRun \
  -only-testing:TacticalGoUITests/ExpansionLabTests/testMatchMenuOpensOnOneTapAndRogueSkillSurvivesSettings \
  -only-testing:TacticalGoUITests/ExpansionLabTests/testRogueLobbyListsBothSkillsAndNewMatchKeepsLockedAdvancedVisible \
  -only-testing:TacticalGoUITests/ExpansionLabTests/testRogueWhiteStandardDualNewMatchKeepsBothSkillsAfterComputerOpening \
  CODE_SIGNING_ALLOWED=NO test-without-building
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGoBeta \
  -configuration Beta -destination 'platform=iOS Simulator,id=<FRESH_BETA_UDID>' \
  -derivedDataPath /tmp/tg12-native-20261022/BetaDerivedData \
  -parallel-testing-enabled NO -resultBundlePath /tmp/tg12-beta-ui.xcresult \
  -only-testing:TacticalGoUITests/AdvancedChallengeUITests/testExpeditionProductEntryAndSeparateChapterProgress \
  -only-testing:TacticalGoUITests/ExpansionLabTests/testMatchMenuOpensOnOneTapAndRogueSkillSurvivesSettings \
  -only-testing:TacticalGoUITests/ExpansionLabTests/testRogueLobbyListsBothSkillsAndNewMatchKeepsLockedAdvancedVisible \
  -only-testing:TacticalGoUITests/ExpansionLabTests/testRogueWhiteStandardDualNewMatchKeepsBothSkillsAfterComputerOpening \
  CODE_SIGNING_ALLOWED=NO test-without-building
```

Inspect actual test counts, skips, screenshots and failures in each xcresult.
Extend to small iPhone, iPad landscape, Reduced Motion and foreground/background
as specified in `UX_INVESTIGATION.md`. Full expedition completion, final enemy
reply, review, retry, next stage and observation export still need native checks;
the existing expedition UI test covers entry and progress isolation only.

C# replay/parity was not run (`dotnet` unavailable). Focused UI mutation, real-device
acceptance and independent human playtests were not run. No merge, TestFlight
upload, release, fun or retention claim follows from this report.
