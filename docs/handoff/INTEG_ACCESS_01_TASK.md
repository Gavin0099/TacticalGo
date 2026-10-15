# INTEG-ACCESS-01｜PR #8 計費缺口修正（給有 Mac／Xcode 的 Agent）

> **狀態更新（2026-10-15）：已完成。** 修正與驗證結果在 `docs/integration/INTEGRATION_RESULT.md`（INTEG-ACCESS-01 一節）；PR #8 已合併為 `a3c1867`。以下為原任務書，僅供追溯。


> 來源：Owner 指示（2026-10-15）。本檔只是把指示與已定位的證據放在 repo 裡，讓另一台電腦的 session 不依賴對話記憶。
> 背景與證據：[`PR8_BLOCKER_ANALYSIS.md`](PR8_BLOCKER_ANALYSIS.md)、[`../HANDOFF.md`](../HANDOFF.md) §3.2。

## 起點（開工前先重新確認）
```bash
git fetch --all --prune
gh pr view 8 --json headRefOid,baseRefName,mergeStateStatus      # 期望 head 5a826fa 或更新、base main
git log -1 --format=%h origin/main                                # 期望 dca10d2 或更新（已含治理）
git worktree add ../TacticalGo-integ-access origin/integration/1.0-1.1 -b fix/integ-access-01   # 用隔離 worktree
```
- 工作分支：可在既有 PR #8 的分支（`integration/1.0-1.1`）提交修正，或從它開 `fix/integ-access-01` 再回推 #8；**以 Owner 指示為準：可在既有 PR #8 分支提交**。
- 先把 `origin/main`（含治理）併進來並確認可建置，再修缺口。
- 本機建議性 hooks 要自己裝（`--hooks-only`）；**不要在載入 agent hooks 的目錄做 F-7 apply**（見 `AGENTS.md`）。

## 範圍（只這兩件，不增加遊戲功能、不改商業額度政策）

### P1：擴充對局的準入與存檔一致性
位置：`ios/TacticalGo/GameStore.swift:19–34` `startExpansion`；`ios/TacticalGo/ExpansionLabView.swift:196`（`restart`）、約 355／374／389（`saveCandidate`）。
- 針對「使用 reward credit 開局後、尚未落子就終止 App」建立**會失敗的測試**。
- 確保已預留額度的棋局一定有可恢復紀錄，**或**具備安全、可重試的交易復原機制。
- 不能覆蓋舊存局後才發現準入失敗（目前是「先準入、失敗則保留原局」，不得破壞）。
- 不允許雙重消耗、免費補發或遺失已準入的棋局。

### P2：擴充對局終局對帳
位置：`ios/TacticalGo/ExpansionGameView.swift:150–153`；`ios/TacticalGo/ExpansionLabView.swift:382–388`（`savedTerminalIdentity`）；`ios/TacticalGo/PlayableGameView.swift:293–304`。
- 在 **App 啟動的共用層**（例如 `PlayAccess` 初始化或 App root 出現時）補做擴充終局對帳，而不是只依賴進入擴充畫面。
- 保持完成登記冪等（`completeMatch` 對已完成者回傳 `false`）。
- 驗證情境：終局存檔成功／帳本寫入中斷／重啟後只進入原版對局。
- 不改變既有 1.0 正式對局規則。

### 不在範圍（另外登記追蹤，不要混進這次修正）
- 「廣告 callback 已完成但額度寫入失敗，requestID 不保留」（`RewardedAdService.swift` 約 227–240）：獨立、尚未實測；若要補待領機制屬計費語意變更，需 Owner 決定。
- 複本 admission 的 M6 option (a)／(b) 最終決定。
- 既有 33 個 UI 失敗名稱與未解釋的一次性崩潰（見 `INTEGRATION_RESULT.md`）。

## 驗證（全部要附指令與實際計數）
1. 新增失敗重現測試（修復前會失敗），與修復後的回歸測試；並做聚焦變異確認測試真的會失敗。
2. `swift test --package-path swift/TacticalGoCore`（整合報告基準：424 項）。
3. 相關 UI 套件：`MonetizationUITests`（基準 9／9）、`RewardedAdNetworkUITests`（2／2）、`IntegrationUITests`（7／7）。既有的 33 個失敗名稱要對照基準，不要追「全綠」。
4. 與**已合併治理的 `main`** 整合後重跑上述測試。
5. 確認 Release 仍是原 1.0 功能，擴充仍由編譯旗標隔離（`TACTICALGO_V11` 不在 Release 定義）。
6. 重新請求針對**最新 HEAD** 的 Codex Review（PR 留言 `@codex review`），不要引用舊 SHA 的審查結論。

## 禁止
- 不 merge、不發布、不修改 App Store Connect／AdMob／Apple 設定。
- 不改商業額度政策；不改 1.0 正式對局規則；不改 Release 設定。
- 不 `--no-verify`；不覆寫或清除其他 worktree。
- 不把測試通過說成「可發布」：「可合併」與「可發布」是兩套 Gate。

## 完成後
停止並回報：改了哪些檔案、新增測試名稱、指令與實際計數、**未執行項目**、剩餘阻擋項、需要 Owner 決定的事。
