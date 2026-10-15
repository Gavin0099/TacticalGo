# SAVE-1.0｜1.0 原始碼保全報告

建立時間：2026-10-14（台北時間）　分支：`safety/1.0-1025-source-snapshot-20261014`　基底：`4986805`（`codex/vfx-three-classes-01` 頂端）

## 這是什麼

這個分支把「1.0／1025 送審用 worktree」在 `4986805` 之後尚未提交的修改與新增檔案保存進 Git。
來源 worktree：`~/.codex/worktrees/autonomous-slices-1011/TacticalGo`（分支 `codex/autonomous-slices-1011`，HEAD `4986805`，本次**未被改動**）。

## 與 1.0／1025 送審版本的關係（誠實界線）

| 項目 | 結果 |
|---|---|
| 送審紀錄 | `artifacts/release-submission-1025/APP_REVIEW_SUBMITTED_1025.json`：App 6821588889、1.0（build 1025）與 IAP，2026-10-11 23:31 Asia/Taipei 提交，狀態 WAITING_FOR_REVIEW。**不代表已核准或公開。** |
| 簽署來源清單 | `SOURCE_1025_SIGNED.json`：head `4986805`、`uncommitted: true`，`files` 253 項 + `buildAndDeliveryFiles` 3 項 = 256 項 sha256 |
| 逐檔比對 | 目前 worktree 的 **256 項全部與清單一致**，0 項不同、0 項缺漏 |
| 清單之外的程式檔 | `ios/`、`swift/`、`scripts/` 下 22 個未納入清單的檔案，皆為開發工具腳本與 `ios/README.md`，不是 App 建置輸入 |
| 送審後的修改 | 只有 5 個文件類檔案：`docs/PLAN.md`、`memory/01_active_task.md`、`memory/2026-10-11.md`、`docs/release-01/FREEMIUM_PLAN.md`、`docs/release-01/account-release-evidence.json`；沒有程式碼被改 |
| 時序 | 清單內最後修改的檔案為 `UploadOptions.1025.plist`（22:43:08，僅供上傳步驟），其餘建置輸入皆早於 IPA 匯出（22:41:41）或與其一致 |
| **未能證實** | 未重新建置，因此無法證明「由此來源重建出的二進位 = 已送審 IPA（SHA256 `ebdd0727…d0d578`）」。來源與二進位的對應只依賴 1.0 agent 記錄的簽署清單。 |

**標示：`1.0 source snapshot`（256 項簽署輸入全數相符）。不宣稱為經獨立重建驗證的「精確 1025 release source」。**

## 納入 Git 的內容（133 個檔案，含 20 個既有檔案的修改）

已修改的既有檔案（20）：
- `docs/NEXT_GATE.md`
- `docs/PLAN.md`
- `ios/TacticalGo.xcodeproj/project.pbxproj`
- `ios/TacticalGo/CombatAudio.swift`
- `ios/TacticalGo/CozyAudit.swift`
- `ios/TacticalGo/CozyBoard.swift`
- `ios/TacticalGo/CozyStyle.swift`
- `ios/TacticalGo/GameStore.swift`
- `ios/TacticalGo/IntegratedAudioAudit.swift`
- `ios/TacticalGo/MagePoseReview.swift`
- `ios/TacticalGo/PlayableGameView.swift`
- `ios/TacticalGo/RecordLibraryView.swift`
- `ios/TacticalGo/TacticalGoApp.swift`
- `ios/TacticalGoUITests/PlayableGameTests.swift`
- `memory/01_active_task.md`
- `memory/04_review_log.md`
- `swift/TacticalGoCore/Package.swift`
- `swift/TacticalGoCore/Sources/TacticalGoBot/BotPlanner.swift`
- `swift/TacticalGoCore/Sources/TacticalGoContent/Tutorial.swift`
- `swift/TacticalGoCore/Sources/TacticalGoMotion/MagePerformance.swift`

新增檔案：Swift 商業與存取模組（`TacticalGoAccess`）、`ChallengesView`、`UnlockPurchase`／`UnlockView`／`RewardedAdService`／`PlayAccess`、`Monetization.storekit`、`Info.plist`、`PrivacyInfo.xcprivacy`、AppIcon 與 sell 素材、UI 測試、Bot／Content 測試與 fixtures、`scripts/archive-release.sh` 等 release 腳本、`docs/release-01/*`（含 `ExportOptions.1025.plist`、`UploadOptions.1025.plist`、`Release.1025.xcconfig`）及各項設計／驗證文件、`artifacts/release-submission-1025` 的 JSON／MD 追溯紀錄。
完整清單與 SHA256：`docs/save-1.0/SAVE_1.0_MANIFEST.sha256`。

## 刻意排除（不在 Git）

| 類別 | 原因 |
|---|---|
| `artifacts/release-submission-1025/DISTRIBUTION_PROFILE.json` | 簽署描述檔 metadata（憑證指紋、本機路徑），非原始碼 |
| `artifacts/release-submission-1025/OBSERVATIONS.json`、`docs/release-01/account-release-evidence.json` | 含網站部署識別碼等帳戶／服務識別資訊 |
| IPA、`.xcarchive`、`ArchiveDerivedData`、`.xcresult`、截圖影片 | 建置產物與大型證據，不屬原始碼 |
| `ios/DerivedData`、`swift/TacticalGoCore/.build` | 建置快取 |
| `swift/TacticalGoCore/artifacts/autonomous-1011` | 測試證據輸出（9.5MB），僅在本機快照 |
| `sites/crown-strategy-support/dist` | 被此 repo 的 `.gitignore`（`dist/`）排除；未強制加入 |
| `artifacts/release-accounts-1024` | 帳戶設定相關證據，不公開 |

排除的未追蹤檔案（依目錄）：

| 目錄 | 檔案數 | MB |
|---|---|---|
| `artifacts/autonomous-1011` | 24274 | 3859 |
| `artifacts/anim-01r` | 6270 | 3142 |
| `artifacts/release-01` | 8241 | 1984 |
| `artifacts/ui-result-1021` | 6007 | 1721 |
| `artifacts/monetization-02` | 5955 | 1529 |
| `artifacts/ui-board-focus-1023` | 2194 | 1320 |
| `artifacts/release-submission-1025` | 4563 | 1058 |
| `artifacts/ui-board-focus-1022` | 4210 | 1013 |
| `artifacts/challenge-fix-1018` | 2899 | 752 |
| `artifacts/monetization-network03` | 2980 | 613 |
| `artifacts/bot-01r` | 1646 | 368 |
| `artifacts/content-03` | 2007 | 263 |
| `artifacts/bot-p2-1011` | 2642 | 262 |
| `swift/TacticalGoCore/artifacts` | 232 | 9 |
| `ios/DerivedData` | 17 | 2 |
| `swift/TacticalGoCore/.build` | 8 | 1 |
| `artifacts/release-accounts-1024` | 24 | 0 |
| `artifacts/probe-01.log` | 1 | 0 |
| `artifacts/monetization-01` | 7 | 0 |
| `docs` | 1 | 0 |
| `artifacts/session-closeout.txt` | 1 | 0 |
| `sites/crown-strategy-support (nested repo)` | 1 | 0 |

## 不在 Git 的資料位置

repo 外完整快照：`~/TacticalGo-safety/save-1.0-20261014/`（`files/` 500 檔、`binary-evidence/` 簽名 IPA 與 xcarchive、`sites-crown-strategy-support.bundle`、`SHA256SUMS.txt`、`state/` 前後狀態紀錄）。
**這與原 worktree 在同一台機器，只能防 worktree 消失，不能防整台機器損壞。**

`sites/crown-strategy-support` 是**沒有 remote 的本機獨立 git repo**（HEAD `49b8703`，隱私與支援頁面的原始碼），已打包成 bundle；它仍是單點。

## 取回方式

```bash
git fetch origin safety/1.0-1025-source-snapshot-20261014
git worktree add ../tacticalgo-1.0-snapshot origin/safety/1.0-1025-source-snapshot-20261014
```

## 未宣稱事項

Apple 審查通過、公開上架、Sandbox 交易、正式廣告、真機 RC 驗收、二進位可重建性，以及遊戲性與美術驗收，皆**未**由本保全動作證明。
