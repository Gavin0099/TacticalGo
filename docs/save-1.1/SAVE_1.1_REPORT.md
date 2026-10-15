# SAVE-1.1｜1.1 原始碼保全報告

建立時間：2026-10-14（台北時間）　分支：`safety/1.1-source-snapshot-20261014`　基底：`06c534c`（已推送的 `codex/v11-game-interface`）

## 這是什麼

把 1.1 開發 worktree 在 `06c534c` 之後尚未提交的修改與新增檔案保存進 Git：23 個既有檔案修改、59 個新增檔案，另加 14 個追溯用的簽署來源／交付 JSON（`artifacts/v11/` 整體被 `.gitignore` 排除，這 14 個以 `git add -f` 明確加入）。
來源 worktree：`~/.codex/worktrees/v11-monster-battlefield/TacticalGo`（分支 `codex/v11-game-interface`，HEAD `06c534c`，本次**未被改動**）。

## 快照一致性

| 項目 | 結果 |
|---|---|
| 寫入者檢查 | 取樣時沒有 xcodebuild／Xcode 上傳／swift-build 進程，`lsof` 無該 worktree 的開啟檔案；Codex app-server 仍在背景運行 |
| 最後一次寫入 | 18:25:20（`artifacts/v11/quality-35/memory-login-block-guard.json`）；開始保全時已靜止約 9 分鐘 |
| 全樹指紋 | 對 114,205 個檔案（路徑｜大小｜mtime）在快照前後共取 4 次（約 2 分鐘內），**雜湊完全一致**：`fb647f04ea696473…` |
| `git status` | 快照開始與結束後完全相同 |
| 結論 | 本快照取自單一靜止時間點，沒有混入不同時間點的修改 |

## 與各 Build 的關係（誠實界線）

| 版本 | 來源證據 | 與本快照的關係 |
|---|---|---|
| 1106 | 已推送 `e25b2d8`；`interface-18/SOURCE_PIN.json`（111 項） | 較舊；本快照新增 168 項、變更 20 項 |
| 1109／1110 | `testflight-31`／`testflight-33` 的 `SOURCE_PIN.json`（274 項） | 本快照與其相比：**11 個檔案內容不同、5 個檔案新增** |
| 1111 候選 | `feedback-34/CANDIDATE_SOURCE_PIN.json`（274 項） | 9 個檔案不同、5 個新增 |
| **1112 候選** | `quality-35/release/SOURCE_PIN.json`（279 項） | **279 項全部與本快照一致（0 項不同、0 項缺漏）** |
| 1112 上傳 | `quality-35/release/UPLOAD.json`：2026-10-14 18:14 UTC+8 以 Xcode Organizer 上傳（Internal Only）。同檔記載 Apple 處理與 Owner 群組**尚未核對** | — |

- 1109→1112 變動的 11 個檔案：`ExpansionLabView`、`IntegratedAudioAudit`、`PlayableGameView`、`PresentationLabView`、`PresentationMageBody`、`TacticalHuntPreview`、`WarriorPresentationPlan` 及其測試。新增：`CombatQualitySequence`、`CharacterVoiceCadence`（含測試）與 `record-quality-sequence-native.py`。
- **`project.pbxproj` 內的 `CURRENT_PROJECT_VERSION` 是 1106**；1109～1112 的 build 號是在 `xcodebuild` 指令列覆寫（`archive.log` 顯示 `CURRENT_PROJECT_VERSION=1112`）。
- 因此標示為 **「1.1 source snapshot（對應 1112 候選來源清單）」**。不宣稱是經獨立重建驗證的「精確 TestFlight 1112 Release Source」：沒有重建簽名二進位去比對 IPA（SHA256 `7a92995b…cf55`），build 號也在建置時外部注入。

## 資源與專案設定是否完整

- 1112 清單的 279 個路徑，**每一個**都在 `06c534c` 樹內或本快照內。
- 以 `git checkout-index` 匯出「本分支的暫存樹」（只含 Git 內容，1155 個檔案）後，不使用原 worktree 的任何檔案，另行建置驗證：

| 驗證 | 結果 |
|---|---|
| `xcodebuild build`（scheme `TacticalGoBeta`、Beta、iOS Simulator、`CURRENT_PROJECT_VERSION=1112`、不簽名） | exit 0，BUILD SUCCEEDED |
| `swift test`（`swift/TacticalGoCore`） | exit 0，Executed 310 tests, 0 failures |

日誌位於本機快照目錄（`build-verify-*.log`）。這證明「只靠 Git 內容可重新建置與通過套件測試」，**不**證明 UI 測試、真機或聽感品質。

## 納入 Git 的內容

已修改的既有檔案（23）：
- `docs/PLAN.md`
- `docs/v11/PLAN.md`
- `ios/TacticalGo/ExpansionLabView.swift`
- `ios/TacticalGo/ExpansionSpellEffects.swift`
- `ios/TacticalGo/GameInterface.swift`
- `ios/TacticalGo/GameStore.swift`
- `ios/TacticalGo/IntegratedAudioAudit.swift`
- `ios/TacticalGo/PlayableGameView.swift`
- `ios/TacticalGo/PresentationLabView.swift`
- `ios/TacticalGo/PresentationMageBody.swift`
- `ios/TacticalGoUITests/ExpansionLabTests.swift`
- `ios/TacticalGoUITests/PlayableGameTests.swift`
- `memory/01_active_task.md`
- `memory/04_review_log.md`
- `swift/TacticalGoCore/Sources/TacticalGoBot/BotPlanner.swift`
- `swift/TacticalGoCore/Sources/TacticalGoContent/ExpansionPractice.swift`
- `swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionContact.swift`
- `swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionFeedback.swift`
- `swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionHeroPose.swift`
- `swift/TacticalGoCore/Sources/TacticalGoMotion/ExpansionPresentation.swift`
- `swift/TacticalGoCore/Sources/TacticalGoMotion/WarriorPresentationPlan.swift`
- `swift/TacticalGoCore/Sources/TacticalGoRecords/ExpansionMatchRecord.swift`
- `swift/TacticalGoCore/Tests/TacticalGoMotionTests/WarriorPresentationTests.swift`

新增：`CombatQualitySequence`、`MonsterPresentationPractice`、`TacticalHints`、`TacticalHuntPreview`、`TacticalReadiness`、`CharacterVoiceCadence`、`ExpansionCueMix`、`MonsterHuntFrame` 與對應測試；31 份 `docs/v11` 契約／審查文件；9 個 polish／quality 錄製與安裝腳本；14 個來源清單與交付 JSON。
完整清單與 SHA256：`docs/save-1.1/SAVE_1.1_MANIFEST.sha256`。

## 刻意排除（不在 Git）

| 類別 | 原因 |
|---|---|
| `artifacts/v11/` 其餘內容（約 9.6GB） | 建置快取、`.xcarchive`、IPA、`.xcresult`、截圖與影片；該目錄被 `.gitignore` 排除 |
| `ios/Build`、`swift/TacticalGoCore/.build`、`DerivedData` | 建置快取 |
| `ASC_BUILD.json`、`ASC_GROUP.json`、Distribution 資料夾、ExportOptions | App Store Connect 識別碼與簽署資訊 |
| 簽名 IPA／xcarchive（1106／1110／1111／1112） | 不屬原始碼；已複製到本機快照 |

掃描：納入檔案未發現私鑰、憑證、token、電子郵件或帳戶識別碼。

## 不在 Git 的資料位置與限制

repo 外快照：`~/TacticalGo-safety/save-1.1-20261014/`（`files/` 3,990 個檔案：來源、文件與精簡證據；`binary-evidence/` 1106／1110／1111／1112 的簽名 archive 與 IPA；`SHA256SUMS.txt`；`state/` 前後狀態與指紋）。
**與原 worktree 在同一台機器**；簽名 IPA／archive 尚無異地備份。1.1 agent 仍可能繼續開發，本快照只代表上述時間點。

## 取回方式

```bash
git fetch origin safety/1.1-source-snapshot-20261014
git worktree add ../tacticalgo-1.1-snapshot origin/safety/1.1-source-snapshot-20261014
xcodebuild build -project ios/TacticalGo.xcodeproj -scheme TacticalGoBeta -configuration Beta \
  -destination 'generic/platform=iOS Simulator' CURRENT_PROJECT_VERSION=1112 CODE_SIGNING_ALLOWED=NO
```

簽名需使用各開發者自己的 Apple 帳戶與憑證。

## 未宣稱事項

Apple 處理完成、TestFlight 群組可測、真機驗收、聽感與爐石級品質、魔物與牧師的真人價值、與 1.0 的整合與存局遷移，皆**未**由本保全動作證明。
