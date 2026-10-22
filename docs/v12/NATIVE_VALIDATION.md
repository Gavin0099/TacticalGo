# TG12 native validation — 2026-10-22

結果：PR #34 已執行 Debug／Beta 原生操作；修正挑戰回顧、下一關及匯出的點擊區。
原因：新測試量到回顧控制只有 28.3 pt；另修正測試的捲動定位與系統分享選單查找。
下一步：進行真機與 3–5 人試玩；本次僅完成模擬器操作及相關修正，不宣稱整個 1.2 驗收完成。

2026-10-23 follow-up: [physical delivery and UI validation](PHYSICAL_VALIDATION.md)
records the development-signed iPhone install, the expedition presentation repair,
six targeted simulator rechecks and the remaining human acceptance steps.

## Scope and changes

Start: `478c4e1da050abb0aa2a42adddbc3220d78c1b46`, branch
`codex/tg12-tactical-expedition`, Draft PR #34. The previous native preparation
commit selected the existing `--full-game` product root for the Debug entry test.

- `ChallengesView`: give review, next-stage and observation-export labels a
  minimum 44 pt hit target, consistent with the other challenge controls.
- Native tests: replay all three reviewed witnesses through the product route;
  assert the last enemy receipt, 4/6/6 player actions and 0/6/0 mana, completion
  lock, retry reset, next stage, 3/3 progress and system Copy export.
- Check visibility before querying XCTest hittability. Before tapping a board
  intersection, scroll that point away from the system gesture region, recompute
  its position and assert the selected coordinate. Do not retry taps.
- iOS 27 exposes the system Copy action as a cell. The test uses that observed
  accessibility type instead of looking for a button.

No Core rules, prices, admission, save format, release configuration, build
number, signing or account settings changed. The helpers fix test positioning;
they do not change the product's board-to-coordinate mapping.

## Execution matrix

Toolchain: Xcode 27.1 (27A9275), Apple Swift 6.4, arm64 macOS. All devices below
were created for this task. Beta uses its own clean device and normal product
root; its production journal intentionally ignores `--record-isolation`.

| Configuration / device | Actual result | Coverage / limitation |
|---|---|---|
| Debug / iPhone Duo 27.1 | Baseline 2/2 and 13/14; one mage harness failure subsequently repaired | Product entry, separate chapters, menu first tap, rogue, old challenge regression; do not relabel the original failure |
| Debug / iPhone Duo, Reduce Motion | 2 completed passes, then device shutdown interrupted the third test | Full expedition flow and board/picker mapping passed; remaining interrupted cases resumed on SE |
| Debug / iPhone SE (3rd gen), 27.0 | 8/8; affected hero cases later 3/3 | Small screen, full expedition, board-hit regression, menu and both rogue setups |
| Debug / iPad Pro 11-inch (M4), 27.0 | 3/3; restored mutation control 1/1 | Full expedition in landscape, portrait/landscape saved-run restore, both old catalogs |
| Beta / independent iPhone Duo 27.1 | Full flow 1/1; entry/rogue batch 3/4 before helper repair, final hero cases 3/3 | Latest outcome for all five selected Beta methods passed; includes a saved-match lobby row |
| Final unique configuration/test pairs | **Debug 20; Beta 5; all latest outcomes passed** | Aggregated across the above targeted runs, not a single 25-test suite; no skips |

Debug and Beta final App/UI-test builds succeeded on arm64. The earlier Debug
arm64/x86_64 builds and macOS package result remain in the evidence. A temporary
simulator-only Objective-C probe called `UIAccessibilityIsReduceMotionEnabled()`
and returned true before the Duo Reduce Motion run.

The baseline Debug batches ran the compiled `478c4e1` tests. Later source hashes,
configuration-specific builds, per-run counts and negative runs are retained in
[validation.json](../../artifacts/tg12/native-validation/validation.json).
Re-runs overlap earlier tests and must not be summed as unique coverage.

## Failure and repair evidence

1. The original mage board-hit test failed while asking for an offscreen
   confirmation button's hittability. After preventing that query, the trace
   exposed a subsequent board point near the top system gesture region: only
   three player actions were accepted. Scroll the actual target into the visible
   region and verify the selected coordinate before confirming.
2. A fresh Beta app built with the target's empty CROWN values terminated with
   `GADInvalidInitializationException`. For simulator execution only, build with
   the same Google test application ID already used by Debug, keeping the
   rewarded-unit ID empty. This is a runbook correction, not an account or release
   configuration change. The original failing launch and system log are retained.
3. Both initial full-flow tests completed three stages and opened the real share
   UI, then failed because Copy was a cell rather than a button. Correct the
   locator and verify the copied JSON through `simctl pbpaste`.
4. The 44 pt regression assertion failed at 28.333 pt before the view fix. Preserve
   that result separately from the successful candidate.
5. While the iOS 27.0 runtime became available, both task devices stopped and two
   batches lost their sessions. Keep their partial results; resume only unfinished
   tests. The cancellation does not count as a successful run.

The hero regression also exposed a harness assumption when Beta retained a
saved-match row: the oversized card-art accessibility frame could be considered
hittable while only its top edge was visible. Target the hero name, let XCTest
bring it into view, tap once, and assert the named hero becomes selected. An
intermediate attempt incorrectly required the child label itself to report
hittability; those failed runs are retained. Both final Debug and Beta hero
batches passed 3/3. No skill visibility or hero-selection product logic changed.

Focused mutation: change only the review label minimum height from 44 to 20 pt.
The iPad full-flow test failed at 28.5 < 44 pt. Restore the view byte-for-byte,
rebuild, and rerun that same full-flow method: passed. The final test also brings
the last white receipt into view before the screenshot, so mere accessibility
existence is not treated as visible review content.

System Copy produced valid JSON. Beta exported 27 events: 17 player actions,
three completed results and one retry with a reset clock. The SE and iPad exports
each had 29 events, additionally including one pause/resume pair with identical
activeSeconds, proving their real background interval was excluded. The Duo
quick Home/activate pair produced no pause event; background accounting is
claimed from the SE/iPad runs, not that quick pair. These are automated test
observations, not human playtest data.

## Reproduce

```sh
swift test --package-path swift/TacticalGoCore --jobs 2
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/tg12-debug ARCHS=arm64 CODE_SIGNING_ALLOWED=NO build-for-testing
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGoBeta \
  -configuration Beta -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/tg12-beta ARCHS=arm64 CODE_SIGNING_ALLOWED=NO \
  CROWN_ADMOB_APP_ID=ca-app-pub-3940256099942544~1458002511 build-for-testing
```

Run `test-without-building` with the matching configuration/derived-data path,
`-destination 'platform=iOS Simulator,id=<TASK_DEVICE>'`,
`-parallel-testing-enabled NO`, a unique `-resultBundlePath`, and the explicit
`-only-testing:TacticalGoUITests/<class>/<test>` selections in `validation.json`.
Use `-collect-test-diagnostics never` to avoid the ten-minute sysdiagnose after
an expected negative run; test logs, screenshots and xcresults are still kept.
Run the methods prefixed `testIPad` and `testTablet` only on iPad.

Inspect `xcrun xcresulttool get test-results summary --path <xcresult> --format json`.
Screenshots and failure traces live in those bundles. On iPhone Duo, the active
LCD is `simctl io <UDID> screenshot --display=1`; the default LCD-1 can be black.
Raw logs, exported payloads, screenshots and xcresults are retained locally under
ignored `ios/Build/tg12-native-20261022/`; they are not public branch content.

## Boundaries

The prior macOS Swift package run remains 464 executed, 463 ordinary passes,
1 test with the known expected Sanctum Bot failure, 0 unexpected failures and
0 skips. No package implementation changed during this native follow-up, so that
suite was not rerun. The Linux one-skip result remains separate evidence.

C# replay/parity was not run (`dotnet` unavailable). No real iPhone/iPad hardware,
real 1.0 save sample, human playtest, listening/art approval, purchase/ad network
acceptance or release acceptance follows from this scoped UI validation.
Existing forced-cast, duplicate PrivacyInfo, AppIntents and audio-session warnings
remain. No main merge, TestFlight upload, publication, fun or retention claim.
