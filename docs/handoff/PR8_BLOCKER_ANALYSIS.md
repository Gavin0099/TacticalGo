# PR #8 合併阻擋項的程式碼層分析（唯讀）

> 日期：2026-10-15（Asia/Taipei）。對象：`origin/integration/1.0-1.1` @ `5a826fa`。
> **方法：只讀原始碼與已發表的整合報告，沒有建置、沒有執行任何測試**（這台機器是 Windows，沒有 Xcode／Swift）。
> **沒有修改任何程式碼。** 帳本、存檔、付費屬 L2（見 `AGENTS.md`），在沒有 Swift 測試能力的環境下不應動手改。
> 標示：「程式碼可見」＝我讀到的行為；「推論」＝由程式碼推導、未實測。

## 0. 結論

| 項目 | 程式碼層結論 | 嚴重度（我的判斷，需審查者確認） |
|---|---|---|
| A. 獎勵額度可能損失 | **有一條狹窄路徑**：看完廣告後，額度寫入失敗，且使用者離開前沒有重試成功 → 額度丟失。機率低（需要磁碟寫入失敗）。 | 中偏低；屬「資料不一致」類，但不會多給額度 |
| B. 終局對帳 | **主對戰路徑沒看到缺口**；**擴充對局只對帳「單一存檔槽」**，且開新擴充局會覆蓋未完成存檔（既有行為）。我沒找到會多扣或漏扣試玩場數的明確路徑，但**對帳涵蓋範圍比主路徑窄**。 | 低；需要 Owner／審查者決定是否可接受 |
| C. 缺 CI | **事實**：#8 沒有任何 GitHub 檢查。424 項測試只在作者機器上跑過。 | 流程風險，非程式缺陷 |
| D. 既有 UI 失敗 | 33 個失敗名稱，**同樣在乾淨 1.0 快照上失敗者**不是整合造成；另有 1 個未解釋的一次性崩潰 | 需要人看 |

**這份分析不能取代審查者的判斷。** 我找到的是「可能」，不是「已重現」。

## 1. A：獎勵額度可能損失

### 1.1 帳本層（程式碼可見，且有測試）
`swift/TacticalGoCore/Sources/TacticalGoAccess/AccessLedger.swift`：
- `grantReward(requestID:)` 先在候選帳本上新增、`validate()`、**再持久化**，成功後才更新記憶體；持久化失敗會拋錯、**不留下揮發性額度**。
- `beginMatch` 以 `availableRewards.first` 保留獎勵（`rewardRequestID`）；同一 requestID 不能被兩場對局保留（`validate()` 會判 `corruptData`）。
- 測試 `AccessLedgerTests.testFailedRewardPersistenceDoesNotGrantVolatileCreditOrMarkRequestUsed`（約第 259 行）涵蓋「寫入失敗不發額度也不把 request 標為已用」。

→ 帳本本身的設計是保守的：寧可不發，不會多發。

### 1.2 廣告層（程式碼可見，**無對應測試**）
`ios/TacticalGo/RewardedAdService.swift`（約 227–240、373–380 行）：
1. SDK 獎勵 callback → `earnedReward(id:)` → `current.grant(id)`（即 `access.earnedReward(requestID:)`，`UnlockView.swift:89`）。
2. 若 `grant` 拋錯：設 `rewardSaveFailed = true`、顯示「廣告已完成，但遊玩額度未能保存。請保留此畫面並稍後重試」。
3. 廣告關閉時 `adDidDismissFullScreenContent`：`rewardSaveFailed` 為真 → 回傳 `.unavailable(…)` 並 `finish`。
4. `UnlockView.cancelWork()` 在真正進入背景時會取消工作並呼叫 `ads.cancelPendingRequest()`。

**我沒有在程式碼裡看到**：把「已完成但未保存的 requestID」持久化起來、以便下次啟動重試的機制；訊息說「稍後重試」，但在第 3 步之後 attempt 被結束，requestID 沒有被保留。

**失敗情境（推論）**：使用者看完整支獎勵廣告 → 當下磁碟寫入失敗（儲存空間滿、檔案系統錯誤）→ 額度沒入帳 → 使用者離開或 App 被終止 → 需要重看一次廣告。
- 影響：使用者損失一次廣告時間，**不會**取得額外額度，也不會破壞既有帳本。
- 機率：需要寫入失敗，且與廣告完成同時發生；我無法估計實際頻率。
- 這與整合報告「Not verified」清單裡沒列；PR #8 本文也未提。

### 1.3 建議的最小驗證／修正（**待有 Xcode 的人實作，需 Owner 決定計費語意**）
1. 先寫一個**會失敗的**測試：模擬 `onEarnedReward` 拋錯後重啟，期望可重試或有明確補發；若現行行為即「不補發」，測試應記錄為既定行為並由 Owner 確認可接受。
2. 若 Owner 認為不可接受：在 `grant` 失敗時把 requestID 寫入一個獨立的小型待領檔（類似 `PendingAdmissionJournal` 的做法），啟動時重試 `grantReward`（它對相同 requestID 是冪等的，已有測試）。**這是計費語意變更，屬 L2，不得由執行端自行選擇。**

## 2. B：終局對帳

### 2.1 主對戰路徑（程式碼可見）
- `PlayableGameView.swift:293–300`：`store.onMatchCompleted → access.completedMatch(id:)`；啟動時 `access.reconcileCompletedMatches(ids: store.savedRecords.compactMap{…})` 以**所有已存的終局紀錄**補做中斷的完成登記。
- `completeMatch` 對已完成的 id 回傳 `false`（冪等）；未登記的舊局不會被追溯計量。
- 啟動前的 C0 R1 視窗（紀錄已存、帳本未寫）由 `PendingAdmissionJournal`（`<id>.pending`）處理：未開始且未授權的紀錄於下次啟動移除，不計費也不保留為免費局；已有著手或帳本已知者不動。有 7 項 package 測試與 2 項 UI 測試（整合報告）。

### 2.2 擴充對局（程式碼可見）
- `ExpansionGameView.swift:150–153`：`store.onMatchCompleted = …`；`onAppear` 時只呼叫一次 `reconcileCompletedMatches(ids: [ExpansionLabStore.savedTerminalIdentity()])`，而 `savedTerminalIdentity()`（`ExpansionLabView.swift:382–388`）只讀**單一存檔槽** `savedURL`，且要求 `matchID` 存在、狀態非 `.ongoing`。
- 整合報告自己列出：「starting a new expansion match replaces an unfinished saved expansion match（既有 1.1 行為）」。

**推論的邊界情境**：擴充局終局且帳本登記失敗 → 使用者在補登前就開新擴充局覆蓋存檔槽 → 該終局不會再被對帳。
- 結果：該場**不會被記為完成**（計入試玩場數的是 `completed && trial`），也就是**對使用者有利、對試玩額度計數偏寬**；若是獎勵局，保留的獎勵仍綁在那個未完成的 entry 上（不會被第二場重複使用）。
- 我沒有找到會「多扣」的路徑。是否可接受是商業決定，不是我能下結論的。

## 3. C：CI（事實與提案，**未實作**）
- #8 無任何檢查；#7 的 `governance-drift` 只涵蓋治理與測資結構，**不含 Swift 測試**（#7 本文自己明說）。
- 提案（需 Owner 決定，我沒動）：新增一個 **`workflow_dispatch`（手動觸發）** 的 macOS workflow，只做 `swift test --package-path swift/TacticalGoCore`，不含 UI 測試與簽署。
  - 受限於 repo 的 Actions 設定：目前只允許 `actions/checkout@*` 與 `actions/setup-python@*`（`github_owned_allowed=false`），這個 workflow 只需 checkout＋`run:`，不新增 action。
  - 成本：macOS runner 計費較高；手動觸發可控。
  - 我不能保證它在 GitHub 的 macOS image 上可直接通過（Swift 版本、Package 依賴）；**需要先跑一次**。
- 即使有了這個 CI，仍**不涵蓋** C#／Swift parity（需 .NET）與 UI 測試。

## 4. D：既有 UI 失敗
來源：`integration/1.0-1.1:docs/integration/INTEGRATION_RESULT.md`。33 個失敗名稱中，與乾淨 1.0 快照相同者（如平板尺寸測試在 iPhone 模擬器上、過時期望）視為既有；另有 `BoardInteractionTests.testOriginalIdentityCandidatesLoadPlaySwitchAndReturn` 一次性崩潰（重跑 2／2 通過）——**未解釋，不算通過**。

## 5. 建議順序（給 Owner／審查者）
1. 審查者確認 A 是否為可接受風險，或要求補待領機制（L2，需 Owner 決定語意）。
2. 確認 B 擴充局的對帳範圍是否可接受（對使用者有利的偏寬）。
3. 有 Mac 的人：重跑 `swift test` 與整合報告列的 UI 套件，補上 A 的測試。
4. 決定是否加手動觸發的 Swift 測試 workflow。
5. 以上完成再談合併；**「可合併」與「可發布」是兩套 Gate**：發布另需 Apple 審查、聽感／美術驗收、D1／D3／D4／D6 等決定（見 `docs/HANDOFF.md` §7）。

## 6. 這份分析的盲點
沒有執行任何程式；只讀了 `AccessLedger.swift`、`PlayAccess.swift`、`RewardedAdService.swift`（片段）、`UnlockView.swift`（片段）、`ExpansionGameView.swift`（片段）、`ExpansionLabView.swift`（片段）。沒有讀 `GameStore.swift` 的 `newMatch`／`startExpansion` 完整流程與 `PendingAdmissionJournal` 實作，也沒有檢查是否還有其他重新授權路徑。
