# PR #8 合併阻擋項的程式碼層分析（唯讀）

> 日期：2026-10-15（Asia/Taipei；2026-10-15 10:45 修訂）。對象：`origin/integration/1.0-1.1` @ `5a826fa`。
> **方法：只讀原始碼、已發表的整合報告與 PR #8 的 Codex 行內審查留言；沒有建置、沒有執行任何測試**（Windows 機器，無 Xcode／Swift）。
> **沒有修改任何程式碼。** 帳本、存檔、付費屬 L2；修復與驗證交給有 Mac 的 Agent（任務 `INTEG-ACCESS-01`）。
> 標示：「程式碼可見」＝我讀到的行為；「推論」＝由程式碼推導、未實測。

## 修訂說明（誠實紀錄）

本檔首版（commit `e1be213`）**漏掉了 Codex 在 PR #8 行內審查已指出的 P1 與 P2**，並把「擴充終局對帳的缺口」描述成對使用者有利、嚴重度低。原因：我當時只讀了 PR 的 issue 留言與文件，**沒有讀行內審查留言**（`gh api repos/…/pulls/8/comments`）。這個低估是錯的：P1 會造成額度**損失**，P2 會造成試玩場數**持續不一致**，都不需要「廣告寫入失敗」才會發生。本版已更正。

## 0. 結論

| 編號 | 風險 | 程式碼層結論 | 觸發條件 | 後果 |
|---|---|---|---|---|
| **P1** | 開局預留獎勵額度，但棋局尚未保存 | **程式碼可見**，Codex 先前也已指出 | 試玩額度用完，用獎勵額度開擴充局，落子前終止 App | 獎勵被保留、沒有可續玩的紀錄 → **額度損失** |
| **P2** | 擴充終局對帳只在進入擴充畫面時執行 | **程式碼可見**，Codex 先前也已指出 | 擴充終局存檔成功但帳本寫入中斷／失敗；之後只進原版畫面 | 帳本不更新 → 試玩場數不一致，可能持續多授權原版對局 |
| **R** | 看完廣告，但額度寫入失敗 | 程式碼可見；**獨立於 P1／P2，尚未實測** | 廣告完成的同時磁碟寫入失敗，且使用者離開 | 需重看廣告；不會多給額度 |
| C | 缺 CI | 事實 | — | 424 項測試只在作者機器上跑過 |
| D | 既有 UI 失敗 | 整合報告：33 個失敗名稱，多數也在乾淨 1.0 快照失敗；1 個未解釋的一次性崩潰 | — | 需要人看 |

**這份分析不能取代審查者與實測。** 以上是高可信的程式碼閱讀，仍須用失敗測試重現。

## 1. P1：開局預留額度後棋局未保存

證據（`integration/1.0-1.1`）：
- `ios/TacticalGo/GameStore.swift:19–34` `startExpansion`：先 `try authorize(id)`（`PlayAccess.authorizeNewMatch` → `AccessLedgerStore.beginMatch`，在帳本寫入 `rewardRequestID`，持久化後才返回）；成功後 `leaveMatch()`、`match.restart(keepIdentity: true)`、`expansion = match`，**函式內沒有任何存檔**。
- `ios/TacticalGo/ExpansionLabView.swift:196` `restart(keepIdentity:)` 只重建 `session`，不存檔；`saveCandidate` 只在第一次成功行動後被呼叫（約 355、374 行），寫入單一槽位 `savedURL`（約 376–394 行）。
- 帳本 `beginMatch`（`AccessLedger.swift`）在 `.rewarded` 時把 `availableRewards.first` 綁到這個 match id；`validate()` 要求每個 `rewarded` entry 的 requestID 唯一。

推論的失敗序列：
1. 試玩已用完、有 1 個已入帳的獎勵。
2. 開擴充局 → 帳本寫入：新 entry（`authorization=.rewarded`，`rewardRequestID=R`，未完成）。
3. 玩家還沒落子就關閉 App。
4. 重啟：沒有任何紀錄含該 UUID 可續玩；`availableRewards` 排除 `R`（已被保留）→ **額度回到 0，且沒有對局可打**。
5. 舊的擴充存檔仍在單一槽位（第一次成功行動前未被覆蓋）。

與 C0 契約的關係：主對戰路徑有 `PendingAdmissionJournal`（`<id>.pending`）處理「紀錄已存、帳本未寫」的視窗；**這裡是相反方向**——帳本已寫、紀錄未存。擴充路徑依整合報告「authorization happens before its save, so there is no window」被判定無視窗，而 Codex 指出正是這個順序造成額度損失。

### 修復要求（交給 Mac Agent；範圍不含政策變更）
- 先寫**會失敗的**測試：用獎勵額度開局後立即終止（重建 store），期望要不是有可恢復的零步數紀錄，要不是額度回滾／可安全重試。
- 修復必須：
  - 已預留額度的棋局一定有可恢復紀錄，**或**具備安全、可重試的交易復原；
  - **不能先覆蓋舊存檔、之後才發現準入失敗**（`startExpansion` 現在已是「先準入、失敗則保留原局」，修復不能破壞這個性質）；
  - 不允許雙重消耗、免費補發或遺失已準入的棋局。

## 2. P2：擴充終局對帳只在進入擴充畫面時執行

證據：
- `ios/TacticalGo/ExpansionGameView.swift:150–153`：`onAppear` 內 `store.onMatchCompleted = …` 並呼叫 `access.reconcileCompletedMatches(ids: [ExpansionLabStore.savedTerminalIdentity()])`。
- `ios/TacticalGo/ExpansionLabView.swift:382–388` `savedTerminalIdentity()` 只讀**單一存檔槽**，且要求 `matchID` 存在、`expected.status != .ongoing`。
- `ios/TacticalGo/PlayableGameView.swift:293–304`：主畫面 `onAppear` 的對帳來源是 `store.savedRecords`（原版 `MatchRecord`），**不含擴充存檔**。

推論的失敗序列：
1. 擴充局終局，終局存檔寫入成功，`onMatchCompleted` → `completeMatch` 因寫入失敗或 App 被終止而未完成。
2. 使用者重啟後只進入原版畫面，不再開啟擴充畫面。
3. 帳本中該局仍為未完成；`completedTrialMatches` 少計一場 → `remainingTrialMatches` 偏高，**可能持續授權額外的原版對局**，直到使用者再次進入擴充畫面。

補充（先前的低估）：這不是「對使用者有利所以可接受」——它讓計費狀態依賴使用者是否再次進入某個畫面，結果不可預期。另外，開新擴充局會覆蓋單一槽位（既有 1.1 行為），若在補登前覆蓋，這個終局將**永遠**不會被對帳。

### 修復要求
- 在 App 啟動的**共用層**（例如 `PlayAccess` 初始化或 App root 出現時）補做擴充終局對帳，而不是只靠開啟擴充畫面。
- `completeMatch` 保持冪等（目前對已完成的 id 回傳 `false`，已有此性質）。
- 驗證情境：終局存檔成功／帳本寫入中斷／重啟後只進原版畫面 → 對帳完成。
- 不改變 1.0 正式對局規則。

## 3. R：廣告 callback 已完成但額度寫入失敗（獨立、尚未實測）

證據：`RewardedAdService.swift`（約 227–240、373–380 行）：`grant` 失敗只設 `rewardSaveFailed` 並顯示訊息；`adDidDismissFullScreenContent` 回傳 `.unavailable` 並結束 attempt；**沒有看到持久化待領 requestID 的機制**。帳本層本身保守（先持久化才生效；測試 `AccessLedgerTests.testFailedRewardPersistenceDoesNotGrantVolatileCreditOrMarkRequestUsed`），缺口在廣告層，**沒有對應測試**。

後果：需重看廣告；不多給額度、不破壞帳本。若要補待領機制，屬計費語意變更（L2），須 Owner 決定。**不要與 P1 混為一談，也不應塞進 `INTEG-ACCESS-01` 的範圍**，另外登記追蹤。

## 4. C：CI（事實與提案，未實作）
- #8 無任何檢查；#7 的 `governance-drift` 只涵蓋治理與測資結構，**不含 Swift 測試**。
- 提案（Owner 決定，我沒動）：手動觸發（`workflow_dispatch`）的 macOS workflow，只做 `swift test --package-path swift/TacticalGoCore`。repo 的 Actions 設定僅允許 `actions/checkout@*` 與 `actions/setup-python@*`，此 workflow 只需 checkout＋`run:`。macOS runner 計費較高；我無法保證首次可直接通過，須先跑一次。即使有了，仍不涵蓋 C#／Swift parity 與 UI 測試。

## 5. D：既有 UI 失敗
來源：`integration/1.0-1.1:docs/integration/INTEGRATION_RESULT.md`。33 個失敗名稱中，與乾淨 1.0 快照相同者視為既有；`BoardInteractionTests.testOriginalIdentityCandidatesLoadPlaySwitchAndReturn` 一次性崩潰（重跑 2／2 通過）**未解釋，不算通過**。

## 6. 範圍與停止條件（對應 Owner 的 INTEG-ACCESS-01）
- 只處理 P1、P2；不增加遊戲功能、不修改商業額度政策。
- 驗證：新增失敗重現與回歸測試；跑 Swift package 測試與相關 Monetization／Integration UI 測試；與已合併治理的 `main` 整合後重跑；確認 Release 仍是 1.0 功能（擴充由編譯旗標隔離）；重新請求針對最新 HEAD 的 Codex Review。
- 禁止：合併、發布、修改 App Store Connect。完成後停止並回報剩餘阻擋項。
- 「可合併」與「可發布」是兩套 Gate；發布另需 Apple 審查、聽感／美術驗收與 D1／D3／D4／D6 決定（見 `docs/HANDOFF.md` §7）。

## 7. 這份分析的盲點
沒有執行任何程式；沒有讀 `PendingAdmissionJournal` 實作與 `GameStore.newMatch` 的完整流程；沒有檢查是否還有其他重新授權路徑。修復後須由有 Xcode 的人實測。
