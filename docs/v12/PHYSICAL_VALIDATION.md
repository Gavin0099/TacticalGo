# TG12 physical follow-up — 2026-10-23

結果：遠征已接上現用遊戲介面；修正版完成開發簽署，透過 Wi-Fi 更新至獨立的 iPhone 驗收 App。真機完整玩法驗收仍在進行。
原因：遠征原先重用舊挑戰介面。此次共用一般對戰的背景、人物卡、技能牌、按鈕、P02 棋盤人物與主將呈現，保留原控制器、座標投影與存檔。
下一步：Owner 依序確認取消預覽、三關最後反擊與回顧、重試及前背景，再進行 3–5 人獨立試玩。

## Scope

Base `05aa18db845e3cea8211d5fb462914d9b4f9ab7c`, branch
`codex/tg12-tactical-expedition`, Draft PR #34. Owner confirmed the physical
device could show all three expedition stages, then reported that the expedition
catalog and battle UI still used the older presentation.

`ChallengesView` now uses the existing `GameBackdrop`, `GamePanel`,
`GameButtonStyle`, current portraits and illustrated `GameAbilityLabel`.
The skill-card cost comes from the existing scenario configuration.
`CozyBoard` accepts the existing product art while keeping its receipt-driven
playback and the original board projection/hit testing. Original-rule actions,
objectives, costs, controller, journals and paid access did not change.

No bitmap/audio asset was created or edited. Reused assets are the existing
`PresentationLab/P02` pinned pack, P07/P08 clean plates, product portraits and
ability atlases. Loading the P02 pack retains its existing pin verification.
This is presentation integration, not a new art/rights approval.

## Verification

Xcode 27.1, arm64, iOS 27.0 task simulators:

| Configuration / device | Latest outcomes | Coverage |
|---|---|---|
| Beta / clean iPhone SE (3rd generation) | 2/2 passed | Skill-card cost and cancelled preview; complete three-stage flow, retry, final replies, review, next and Copy export |
| Debug / iPad Pro 11-inch (M4) | 4/4 passed | Adjacent board/picker mapping, separate chapter progress, complete landscape expedition, old chapter selection |

These are six selected configuration/test pairs, not a rerun of the previous
25-pair matrix. Each Beta run starts with a clean app on its isolated simulator;
shipping Beta intentionally ignores the Debug journal-isolation argument.
Debug/Beta test builds and the development-signed iphoneos Beta build succeeded.

Both complete-flow Copy exports contain 29 events, including 17 player actions,
three completed results and a retry. Their pause/resume activeSeconds match,
excluding the actual background interval. These are automated observations.

The existing full-flow assertions still require the reviewed final white
receipts (E4 / C1 / F2), 4/6/6 player actions, 0/6/0 consumed mana, completion
lock and at least 44 pt review/next/export targets.

## Failures retained

- Initial iPad execution failed 3/3 after the new plain catalog cards were
  introduced. The center of a wide card fell in label whitespace, so the tap
  did not choose a stage. Adding a rectangular content shape to the entire
  visible card made the same three methods pass; the board/picker method also
  passed. This was found and repaired during the presentation follow-up.
- An early fee mutation and its first restored run stopped at catalog lookup:
  Beta had correctly restored the prior selected run. Those failures do not
  prove fee-test sensitivity. The runbook now uninstalls only the test app on
  the task-owned simulator between independent Beta runs.
- With that isolation, changing only the displayed skill fee from 2 to 4 made
  the new test fail at the exact label assertion. Core costs were untouched.
  Restoring the source byte-for-byte, rebuilding and rerunning passed.

Per-run counts, source/log hashes and mutation evidence are in
[ui-followup-20261023.json](../../artifacts/tg12/native-validation/ui-followup-20261023.json).
Raw xcresults, screenshots, exports and device diagnostics remain locally in
ignored `ios/Build/tg12-ui-20261023/`. Both task simulators were deleted after
evidence preservation and verified absent; their pre-deletion allocation was
5.50 GiB. Shared runtimes and other devices were retained.

## Physical delivery and acceptance boundary

Device: iPhone 16 Pro, iOS 27.0, paired over local Wi-Fi. The candidate uses the
existing Apple Development identity and a separate bundle ID,
`com.tacticalgo.prototype.tg12verify`, displayed as **皇冠戰略 TG12 驗收**.
The signing project and development overrides are ignored local files; release
configuration, version/build settings and Apple/AdMob account settings were not
edited. Candidate version/build remains 1.1/1106 and identifies the tested source
through the evidence hashes, not a release-version claim.

Strict signature verification, development entitlements, device provisioning,
install and foreground-launch requests succeeded. The original app (build 1119)
remains installed. The expedition journal immediately before and after the
update is byte-for-byte identical. This does not claim migration compatibility
with an external 1.0 save sample.

The Owner's three-stage entry confirmation applies to the preceding candidate.
The updated UI's human confirmation, physical three-stage playthrough,
physical background/retry/export checks and 3–5 independent testers remain open.
C# replay/parity, real 1.0 save samples, physical iPad, listening/art and purchase/
ad-network acceptance were not executed here. No main merge, TestFlight upload,
release, fun/balance or overall 1.2 acceptance is claimed.
