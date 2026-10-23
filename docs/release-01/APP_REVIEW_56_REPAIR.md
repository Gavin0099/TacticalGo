# App Review 5.6 — 1.1 (1121) repair candidate for rejected 1120

## Evidence and scope

The owner supplied a Guideline 5.6 rejection for iOS 1.1 (1120): Apple reports features that appear hidden during review, without identifying a particular feature. The source baseline is PR #33, `5617ba7`, merged as `31ac541`; the merge has no source delta. The exact uploaded archive has not been independently retrieved. Do not claim that a source finding explains Apple's decision.

The live App Store Connect review and version pages were read from the owner's authenticated Chrome session on 2026-10-24. The submission contains one 5.6 message and no named feature or screenshot. Contrary to the repository's older 1.0 draft, the **actual submitted 1.1 notes already describe four heroes, second skills, monsters, three completed free matches, IAP and rewarded ads**. The store description also includes them. Missing disclosure in the submitted notes is therefore not an established cause. No metadata was edited and no message was sent.

Read-only inspection found engineering launch arguments in the Release compilation path (`ExpansionLabStore.loadReview` and `GameStore` record isolation), and a research skill lab compiled behind a runtime entry condition. The release candidate must exclude these engineering controls at compilation, rather than depending on an unreachable menu. Public gameplay must remain accessible without a reviewer-specific account, switch, device condition, or remote activation.

The purchase screen currently shows rewarded-ad controls only when no new-match allowance remains. Keep this entitlement policy, but explain the existing voluntary-ad option from the first visit to the purchase screen. This is disclosure, not an allowance, price, or payment change.

## Repair contract

- Restrict engineering fixture loading, diagnostic launch arguments and the R2 research UI to Debug. Keep the normal product's four heroes, second skills, monsters, practice, challenges and existing records.
- Describe the three completed free matches, optional rewarded-ad continuation, permanent non-consumable unlock and restore path consistently to every user.
- Prepare an English reviewer walkthrough for the actual 1.1 UI. Preserve uncertainty about the unspecified hidden feature; request reproduction details in the response draft.
- Keep PR #40 and all 1.2 research separate. No rule, ledger, saved-game schema, account configuration, submission or publication changes are authorized by this repair.

## Verification plan and failure conditions

1. Build the baseline Release simulator app with the 1120 settings and identify the engineering argument markers in its executable. Preserve that evidence before repairs.
2. Build repaired Release and Debug configurations. A focused executable check must reject the baseline Release and accept the repaired Release for the reviewed marker list; Debug controls remain available for engineering tests.
3. On newly created iPhone and iPad simulators, exercise normal public entry points without fixture arguments: four heroes, second skills, monsters, practice, challenges, purchase/restore and privacy/support. No network ad or purchase success claim without an actual result.
4. Verify the early purchase screen explains ads while the three-match allowance is intact and still requires the original entitlement conditions before showing the ad action. Reach that screen by completing three normal local games, without fixture arguments or an artificial allowance. The completion/ledger implementation must not change.
5. Inspect the built Release resources, Info.plist and simulator entitlements, and record that signed-device archive verification remains separate. Delete only the simulators created for this task after preserving evidence.

Passing these checks is engineering evidence, not Apple approval or proof that the unspecified rejection is resolved. The response and any re-submission require separate owner authorization.

## Policy sources

- [App Review Guidelines 5.6 and 2.3.1](https://developer.apple.com/app-store/review/guidelines/): accurate representation and specific, reviewable feature descriptions.
- [Reply to App Review messages](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/reply-to-app-review-messages): provide the feature walkthrough and request clarification through App Review.

## Verified repair evidence

The release candidate is based on main `31ac541`, separately from PR #40 and the 1.2 research branches. App Store Connect's TestFlight list showed 1120 as the latest 1.1 build on 2026-10-24; the new local configuration uses **1.1 (1121)**. It preserves the existing bundle ID, commercial identifiers and account settings.

- Reconstructed 1120 Release: the focused executable check rejects 13 engineering markers and `R2Positions.json`. This is a regression negative control, not a claim about the exact uploaded executable.
- Repaired 1121 Release simulator and unsigned arm64 iOS archive: build succeeds; the same check finds none of the reviewed engineering markers or excluded research resources.
- Release iPhone 16 Pro portrait / iPad Pro 11-inch (M4) landscape, iOS 27.0: three public-flow tests pass on each device, with **no app launch arguments**. They cover public heroes/skill controls, all four practice entries, monsters, challenges, purchase/restore controls, privacy/support entry, first-visit ad disclosure, and the continuation choices after three genuinely completed local matches. They do not perform a purchase or watch an ad.
- Debug: the frozen-fixture save/resume test and the R2 mage exchange/undo test both pass on the final applicable runs. These are two distinct checks of retained engineering tools, separate from the six Release device/test combinations.
- The device package retains iPhone/iPad support, the app privacy manifest and the Google Mobile Ads / UMP privacy manifests. No `.storekit`, `.usdz` or `.scn` files are packaged. The app archive is unsigned; distribution entitlements are not verified.

Canonical checks, test receipts, source hashes and selected screenshots are in [artifacts/app-review-56](../../artifacts/app-review-56/README.md). Raw build logs and xcresults stay local under `ios/Build/review56/`; the authenticated account-page snapshot and signing information are not published.

## Failure history retained

1. The first Release repair build failed because `RecordRules.variant` had been excluded along with the R2 editor. Historical record labels still need it. It remains compiled in every configuration; only fixture/editor descriptions are Debug-only. The subsequent simulator and device builds succeeded. No record schema changed.
2. The first native Release run passed 2 tests and failed 1 because iOS 27 exposes nested accessibility nodes for the same alert button. The test now selects the first matching visible action; the three-completed-match assertions are unchanged. The final iPhone batch passed all 3.
3. The old R2 test used the public setup screen and then expected obsolete standalone banner/AP labels. Its current route is the Debug engineering shell, with the selected variant checked through its fixture message and AP through the actual resource display. Failure receipts remain in the evidence inventory.
4. iPad app-cropped screenshots used a stale portrait capture rectangle even though the tests operated in landscape. A separate `simctl` full-screen capture confirmed the actual layout. The screenshot helper now uses `XCUIScreen.main`; only the affected evidence flows are rerun.

## Remaining distribution steps

This is a local engineering candidate, **not yet an upload-ready signed build**. The current Mac has no usable Apple Distribution signing identity and no locally installed matching App Store provisioning profile. The unsigned archive is retained locally at `ios/Build/review56/CrownTactics-1.1-1121-unsigned.xcarchive`.

1. Obtain the owner's approval to create/download the required signing assets in Xcode, or use the Mac that uploaded 1120. Do not revoke existing certificates or export private keys as part of this repair. [Apple's certificate management instructions](https://help.apple.com/xcode/mac/current/en.lproj/dev154b28f09.html).
2. Produce/validate the signed 1121 distribution archive, then verify signature, matching profile and distribution entitlements. The repository's older `archive-release.sh` / `check-release-readiness.py` are explicitly locked to 1.0; their results must not be represented as a passed 1.1 release gate. Use Xcode's reviewed 1.1 archive/distribution workflow and retain its validation receipt.
3. Review the local [review notes](APP_REVIEW_NOTES_1.1.md) and [response draft](APP_REVIEW_REPLY_5.6.md). Apple has not identified the allegedly hidden feature; request its reproduction steps before claiming that this candidate resolves the actual rejection.
4. Upload, replace Review Notes, send the response and resubmit only with the owner's explicit authorization. No such external action has been performed here.

No Core, Bot, skill costs, saved-game schema, allowance rules or purchase policy changed. C# replay/parity, real-device acceptance, production purchase/restore/ad delivery and Apple approval are not claimed by this repair.
