# TacticalGo 交接入口（目前產品線）

> **最後核對時間：2026-10-15 10:45（Asia/Taipei）**；狀態以 `gh api`／`git ls-remote` 當場查得。
> 本文件是 **目前專案的入口**；舊的 Windows／C# 參考線手冊已移到 [`docs/handoff/WINDOWS_LEGACY.md`](handoff/WINDOWS_LEGACY.md)（歷史、原樣保留）。
> 本文件裡每個「會變的」狀態都標了查證來源與時間；超過一天就重新查。**GitHub／本機 Git 的狀態我當場查過；Apple／AdMob 帳戶狀態我沒有查（沒有存取，也不該動），只能轉述 repo 內的紀錄與其日期。**
> 本檔屬 PR #9（`docs/handoff-recovery-01`，已推送、base=`main`、CI 成功）；**尚待 Owner 審核與合併**。合併前請以 `git log origin/main` 重新確認下列狀態。

---

## 0. 三十秒版本

1. **要維護的是 iOS／Swift 產品線**（對外名稱《皇冠戰略》；repo 名 TacticalGo）：1.0（已送審）與 1.1（TestFlight 候選）已由 **PR #8**（2026-10-15 13:33 台灣時間，`a3c1867`）整合進 `main`，擴充玩法放在同一個存取帳本（ledger）之後；Release 建置仍只含 1.0 功能。
2. **Windows／C# 線是參考實作與歷史**：`src/TacticalGo.Domain`、黃金測資 `tests/golden` 仍是 Swift 的規格參考；不要因為舊手冊寫著 G0／G1 Pending 就重新開啟那些 slice。
3. **現況**：**#7**（AI Governance）已合併為 `dca10d2`，`main` 已含完整治理；#1 因此顯示 merged。**#8**（1.0／1.1 整合）已於 Owner 要求下合併為 `a3c1867`；合併前修掉兩個計費缺口（P1／P2）與一個 Release 編譯錯誤，見 §3.2。**合併不等於發布**；合併後完整驗證（POSTMERGE-01）與整合版 TestFlight 試玩尚未完成，見 §3.3。
4. **不要做**：自行合併／推送／發布、清掉含未保全變更的 worktree、動 Apple 或 AdMob 設定、改計費語意、`--no-verify`、替 Owner 通過任何 Gate。完整清單：[`AGENTS.md`](../AGENTS.md)「Repo-Specific Forbidden Behaviors」。

---

## 1. 這個專案現在是什麼

| 項目 | 內容 | 依據 |
|---|---|---|
| 產品 | 圍棋規則為底層的小型戰術棋，三職業（戰士築壘／法師調度或推動／盜賊換位），以主將被提為勝利條件 | `ios/README.md`；`docs/RULES_DRAFT.md`（Windows 早期規格） |
| 平台 | iPhone／iPad 原生 App（SwiftUI），最低 iOS 17 | `ios/README.md` |
| 規則實作 | **Swift**：`swift/TacticalGoCore`（純 Swift Package，不依賴 UI）；**C#** 參考引擎：`src/TacticalGo.Domain`（規格參考，未被 1.0／1.1 修改） | `docs/integration/INTEG_DESIGN_01.md`（在 `integration/1.0-1.1` 分支） |
| 商業模式 | 免費前三場完整對局，之後可觀看獎勵廣告取得下一局，或購買永久解鎖（NT$60，台灣）；教學／挑戰免費 | `docs/release-01/README.md`（`integration/1.0-1.1`） |
| 發行 | 1.0／build 1025 於 2026-10-11 23:31 提交 App Store 審查，**紀錄狀態為 WAITING_FOR_REVIEW**；1.1／1112 於 2026-10-14 18:14 上傳 TestFlight（Internal Only） | `docs/save-1.0/SAVE_1.0_REPORT.md`、`docs/save-1.1/SAVE_1.1_REPORT.md`；**未即時核對 Apple 端** |

### 你不能假設的事
- 「已送審」≠「已核准」≠「已公開」。審查結果我沒有查。
- 1.0 的可重建來源 = `safety/1.0-1025-source-snapshot-20261014`（256 項簽署輸入全數相符），**但並未證明重建出的二進位與送審 IPA 位元相同**。
- 1.1 的 `project.pbxproj` 內 build 號是 1106；1109～1112 是 `xcodebuild` 指令列覆寫。1.1 來源 = `safety/1.1-source-snapshot-20261014`（對應 1112 候選的 279 項來源清單）。
- 目前**所有人類 Gate（美術、聽感、實機操作、新手理解、平衡）都沒有由 agent 通過的資格**。測試與搜尋只是工程證據。

---

## 2. 版本與分支地圖（2026-10-15 核對；OPEN 的 PR：#2、#5、#6、#9；`main` = `a3c1867`）

| 分支／PR | SHA | 性質 | 狀態 |
|---|---|---|---|
| `main` | `dca10d2` | #7 的 merge commit；其下是 `cdab133`（PR #4：Swift 核心、R3 技能、5 步教學） | 現行基底，已含治理 hooks／workflow／驗證器 |
| PR #7 `chore/governance-full-20261014` | `3c8207b` | 完整 AI Governance 導入（取代 #1） | **MERGED** `dca10d2`，2026-10-15 02:19 UTC，由 Owner 手動合併 |
| **PR #8** `integration/1.0-1.1` → main | `5a7d8b8`（merge commit `a3c1867`） | 1.0＋1.1 整合；**1,655 個變動檔案**（`gh api …/pulls/8` 的 `changed_files`） | **MERGED** 2026-10-15 05:33 UTC，Owner 明確要求「看 review 沒問題就 MR」；CI：`Swift Core (Linux)` 433 項通過；Codex 串有兩則仍顯示 OPEN 但已書面處置（誤報一則、1.0 既有行為一則），見 §3.2 |
| `safety/1.0-1025-source-snapshot-20261014` | `d13fdfa` | 1.0／1025 來源保全 | 遠端存在；固定輸入，**不可改** |
| `safety/1.1-source-snapshot-20261014` | `8c80ceb` | 1.1／1112 來源保全 | 遠端存在；固定輸入，**不可改** |
| `docs/integ-design-01` | `99e55b5` | 整合設計草稿的分支 | 遠端存在 |
| PR #5 `codex/bot-p1` | `a09cf20` | BOT-P1 觀察用 bot 軌跡 | OPEN，`CLEAN` |
| PR #6 `codex/content-02` | `7414f27` | 六個獨立原規則挑戰 | OPEN，`CLEAN` |
| PR #1 `chore/governance-full` | `761af5d` | 舊治理分支，被 #7 取代 | **顯示 merged**（#7 含其 commits），不需處理；分支保留（#2 疊在它上面） |
| PR #2 `feature/ui-3c` | `a4ca293` | **Windows** 第 2 關（盜賊換位）UI，疊在舊治理分支上 | OPEN；Windows 舊線，暫時保留，**不阻擋 iOS** |
| 本機 `docs/handoff` | `e3a78fc`（`c55a2e1` 的下一個 commit） | 舊交接手冊＋AGENTS.md 草稿＋R1 更正；**只在本機，GitHub 沒有** | 內容已由本分支吸收（見 §9 的差異報告） |
| PR #9 `docs/handoff-recovery-01`（本檔） | 見 `gh pr view 9` | 本次交接修復；已併入 `main`（`a3c1867`）更新並改寫 #8 相關章節 | OPEN，待 Owner 審核合併（合併 #9 需要 Owner 另行明確同意） |

**舊的「先合 #1 再合 #2」已不是目前順序。** #1 已隨 #7 進 `main`；#2 只與 Windows 線有關。**合併 `main` 與發布一律由 Owner 決定**（見 `AGENTS.md`）。

> 其他本機 worktree 存在於 `git worktree list`（`codex/*` 多條開發線、`codex/r1-magic-hand`、`codex/v11-*` 等）。**其中可能有未提交的變更**；沒有逐一檢查。不要清除或重設它們。

---

## 3. 兩個決定現況的 PR

### 3.1 PR #7（治理）— 已合併，留下的邊界

- 2026-10-15 02:19 UTC 合併為 `dca10d2`。**合併時 Owner 接受的暫行風險**：框架範本把 VS Code `Stop` 接成 `session_end` **未修**；風險由 `validators/hook_wiring_check.py`（CI 防回歸）與下方 §6 的隔離更新邊界控制。框架端修正是否排後續，仍是未決事項（§7）。
- CI 範圍：治理 drift、測資結構／詞彙／動作參數、驗證器測試、hook 接線檢查。**不含 Swift 遊戲測試與完整棋局 replay**，不可延伸為「1.0／1.1 整合通過」。
- 引用 #7 的證據時注意：其 PR 本文寫的「HEAD `cff31e8`」已過期，實際最終 head 是 `3c8207b`。

### 3.2 PR #8（1.0／1.1 整合）— 已合併（`a3c1867`）

來源：`docs/integration/INTEGRATION_RESULT.md`（合併後在 `main`）、PR #8 討論串。

| 層 | 結果 |
|---|---|
| 策略 | 保留 1.0 外殼與計量語意；1.1 外殼從大廳明確入口「擴充玩法」開啟，並在**同一個存取帳本**之後（C0 契約：`docs/integration/C0_MATCH_ACCESS_SAVE_CONTRACT.md`） |
| 規則 | 兩條線都合併；**原規則仍是預設（`expansionSkills` 關閉）** |
| 不變 | Release 設定與 Release 資源腳本不動：Release 建置只含 1.0 功能（擴充入口被編譯排除；合併前實測建置成功且 App 內沒有擴充入口字串）。啟用擴充是 `RELEASE_ENABLE_EXPANSION.md` 的「準備但未套用」 |
| 計量 | 不改商業規則：試玩於完成時扣、獎勵額度於開始時保留、重新開始＝新局新身份、無步數門檻、無單場限制、無認輸 |

**合併前修掉的問題（INTEG-ACCESS-01，皆有失敗在前的測試）：**

| 編號 | 問題 | 修正 | 證據 |
|---|---|---|---|
| **P1** | 擴充開局先保留獎勵額度、落子前終止 App → 額度損失、無可續玩紀錄 | 新局先暫存完整零步數紀錄，帳本接受後才原子替換單一存檔槽；啟動恢復補完或丟棄暫存（`ExpansionStartJournal`）；被拒絕的開局不動舊存檔 | UI 測試於未修正程式碼失敗、修正後通過；9 項套件測試，三個變異皆被抓到 |
| **P2** | 擴充終局對帳只在重新進入擴充畫面時執行 | 同一個對帳也在原版外殼啟動時執行；`completeMatch` 冪等 | UI 測試未修正時失敗（額度停 3/3），修正後 2/3 |
| Release | `ExpansionGameView.swift` 在編譯旗標外使用 `ExpansionLabStore`，**`5a826fa` 的 Release 建置編譯不過**（先前「Release 仍是 1.0」從未被實際建置驗證） | 已加編譯保護 | Release 與 Beta 建置成功 |
| 審查回饋 | 擁有者資格尚未驗證就執行恢復，可能誤刪擁有者的未下子開局；Linux `replaceItemAt` 差異 | 恢復等 `isChecking == false`；晉升改為原子寫入；新增窄版 Linux 套件 CI | 擁有者測試移除修正後 3/3 失敗；Linux CI 433 項通過 |

**合併時的驗證數字（模擬器、未簽名；不是實機）：** Swift package 433 項（macOS 與 Linux 皆 0 失敗）；`IntegrationUITests` 9/9；`MonetizationUITests` 10/10；`RewardedAdNetworkUITests` 2/2；`MonsterLabTests` 7/7；`PresentationLabTests` 8/8；`ExpansionLabTests` 34 項／7 略過／0 失敗（其中一個音訊稽核測試在 1.1 快照與較早的整合版曾失敗，視為與時間相關，不算已修）。既有大型 UI 套件仍有 **33 個失敗名稱，與乾淨 1.0 快照同樣失敗**（既有問題，另案）；曾有 1 個一次性崩潰，後來通過，**根因未解**。

**已知風險（刻意留在獨立追蹤項目，不擴大這次範圍）：**

| 風險 | 說明 |
|---|---|
| 單存檔槽邊界 | 終局存檔的帳本補登失敗後，同一次執行中、未重啟就開下一場擴充局，會覆蓋那份終局存檔，補登證據消失。提案（未實作）：開新局前先重試已完成對局的補登 |
| 資格驗證前准入 | `PlayAccess.authorizeNewMatch` 在 StoreKit 回應前把擁有者視為未解鎖；**1.0 既有行為**，改它是商業語意變更，需 Owner 決定 |
| 廣告完成但額度寫入失敗 | `RewardedAdService.swift`：requestID 不被保留，需重看廣告；不會多給額度。獨立、尚未實測 |

**未驗：** C# replay 與 C#／Swift 逐步等價沒有重跑（沒有 `dotnet`）；沒有實機、沒有 iPad、沒有簽署 archive、沒有 TestFlight／App Store 動作；真實 1.0 產生的存檔樣本沒取得。

**需要人眼判斷（測試無法決定）：** 兩套視覺系統並存（D1）；1.1 法師動畫 `r2` 改用 1.0 共用時序（release 0.26／moveStart 0.38／arrival 0.60，原 0.28／0.30／0.54）需看過；英文英雄語音首版不隨 Release 出貨，聽感審查未結（D5）；擴充是否出現在出貨版及版本（D3／D4／D6）。**複本是否沿用父局 admission（M6）採 option (a) 實作，但「尚未正式決定」，若 Owner 選 (b) 只需改帳本中的一處。**

### 3.3 合併後狀態

`main` = `a3c1867`（#8 的 merge commit）。合併前驗證針對 `ecfa95b`（其後到 `5a7d8b8` 只改文件）。**合併後對乾淨 `main` 的完整驗證（POSTMERGE-01）：見 `docs/integration/POSTMERGE_01.md`；未見該檔或其中標示未完成者，視為尚未驗證。** 整合版 TestFlight（需高於 1112 的新 build）**尚未製作，也尚未有任何人在 iPhone／iPad 上玩過整合版**；這是下一個工程之外的 Gate，需要 Owner 另行授權任何上傳。

---

## 4. 工程狀態與可重現的驗證

### 4.1 我在 PR #9 分支（已 rebase 到 `main` `dca10d2`）實際跑過的（2026-10-15）
| 檢查 | 結果 |
|---|---|
| `python validators/hook_wiring_check.py .` | `ok=True`（2 個 hook 設定檔，無 VS Code Stop→closeout 接線） |
| `python -m unittest discover -s validators -p "test_*.py"` | 24 項 OK |
| `python validators/golden_fixture_validator.py .` | `ok=True`：24 組測資對 18 個非法原因與 10 種事件；**只查結構／詞彙／setup／動作參數，不重播** |
| 其餘（drift、memory workflow） | 見 `docs/handoff/RECOVERY_01_REPORT.md` |

### 4.2 我**沒有**跑的
- `swift test`、`xcodebuild`、`scripts/verify-ios-parity.py`：這台機器是 Windows，沒有 Xcode／Swift toolchain。
- `dotnet test`：本次只修改文件，未重跑 C# 測試；#7 的 CI 不含它們。**C# 與 Swift 兩側的 replay／parity 都不是這次驗的**。
- Apple、AdMob、App Store Connect、TestFlight、真機：沒有存取，也不應該動。

### 4.3 指令（來源：`ios/README.md`，在 macOS 上）
```bash
swift test --package-path swift/TacticalGoCore
TACTICALGO_DOTNET=<path-to-dotnet> python3 scripts/verify-ios-parity.py   # 需要 .NET SDK 9
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO \
  -only-testing:TacticalGoUITests/PlayableGameTests test
```
- scheme：`TacticalGo`（Release／正式）、`TacticalGoBeta`（Beta，含擴充資源）。
- **不要在已知會失敗的 UI 套件上追「全綠」**：先對照 `INTEGRATION_RESULT.md` 的既有失敗清單（同樣在乾淨 1.0 快照上失敗者不是整合造成的）。
- Windows 端（C#）：`dotnet test TacticalGo.sln`；細節見舊手冊 §5。

### 4.4 Swift Package 結構（`swift/TacticalGoCore/Package.swift`，`integration/1.0-1.1`）
Library：`TacticalGoCore`（規則）、`TacticalGoAccess`（存取帳本）、`TacticalGoOnboarding`、`TacticalGoRecords`（棋譜）、`TacticalGoBot`、`TacticalGoContent`（教學／挑戰）、`TacticalGoMotion`（演出時序）、`TacticalGoVisuals`。
執行檔：`tacticalgo-golden`（Golden 重播）、`tacticalgo-r2`、`tacticalgo-bot`、`tacticalgo-content`、`tacticalgo-records`、`tacticalgo-monsters`。
App：`ios/TacticalGo/`（SwiftUI）；UI 測試：`ios/TacticalGoUITests/`；Golden：`tests/golden/`（C# 手寫，24 組）、`tests/ios-golden/`。

---

## 5. 規則：哪裡是權威（**不要用 Windows 早期草稿代表現行 iOS 規則**）

| 層 | 內容 | 位置 |
|---|---|---|
| 基礎機制（AP／Mana、棋串、生存空格、提子、自殺、superko、勝負） | 由 Windows 早期規格定案，Swift 已移植並以 Golden 對照 | `docs/RULES_DRAFT.md`（v0.2）、`docs/DECISIONS.md`、`tests/golden` |
| 後期技能實驗 R1／R2／R3 | Owner 在 iOS 線採用過：法師魔法之手（推動）、R2 異色交換、R3 戰士沿棋群築壘＋法師調度己兵 | `docs/r2/`、`docs/r3/PLAN.md`、`ios/README.md` |
| 現行預設玩法 | 2026-10-11（1020）Owner 採用「新局直接使用新版技能」，並要求設定不再提供規則選擇；舊存局保持原規則 | `docs/release-01/README.md`「已採用玩法：1020」（`integration/1.0-1.1`） |
| 1.0／1.1 整合後的預設 | 原規則為預設，`expansionSkills` 關閉；擴充從獨立入口進入 | `INTEGRATION_RESULT.md` |

**我沒有逐項核對 Swift 實作與這些文件一致**，這裡只是指路。若你要改任何規則：先向 Owner 提出、改 Core、改 Golden，並**同時**跑 Swift 與 C#（若 C# 仍是參考）兩側的 replay。

---

## 6. 治理（AI Governance）怎麼運作

- `main` 已含 #7 的完整導入（pinned submodule `additional/ai-governance-framework` @ `2a09d54`、本機建議性 hooks、F-7 更新、repo 專屬驗證器）。狀態是 `full_candidate`：**runtime enforcement 未被證明**。
- 管理區塊（`AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 的 BEGIN/END 之間）不要手改；repo 專屬規則在 `AGENTS.md` 的四個區塊（本次已填，見 `docs/handoff/RECOVERY_01_REPORT.md` 的依據表）。
- **隔離更新邊界（來自 PR #7）**：框架範本可能把 VS Code `Stop` 接成 `session_end`；`hook_installer`（不帶旗標）、`--copilot-only`、`--copilot-vscode-only` 與 `f7_full_update --apply` 都可能重新部署這個接線，只有 `--hooks-only` 不會。→ **不要在載入 agent hooks 的工作目錄直接做 F-7 apply**；在隔離 clone 做，並跑 `python validators/hook_wiring_check.py .`。
- hooks 是每個 clone 自己裝的（在 `.git/hooks`，不隨 clone）；pre-push 要求 `governance/external-tree-inventory-guard.json`。#7 已合併，**現在從 `main` 開分支即可**；仍在舊基底（`cdab133`）上的分支要先與 `main` 對齊。
- 記憶用正式寫入器 `governance_tools.memory_record`，不要把 `memory/` 當一般 markdown 手改；改 `memory/**` 前後跑 `governance_tools.memory_workflow --check`。
- 已知警告（#7 本文，已歸因未解除）：`test_evidence_provenance_not_found`（10/8、10/14 記錄）、`missing_canonical_memory`（2026-10-09：`main` 有該日 commit 卻沒有 `memory/2026-10-09.md`）、`framework-version` ×2（submodule 型導入不寫 `framework.lock.json`）。
- 引用任何 memory 條目前先驗證它仍成立。例如 `memory/01_active_task.md` 在 `main` 上仍是 10/8 的 Windows 狀態並後續追加了許多條，**頂部的「Next Steps」已過期**。

---

## 7. Owner 待決事項（我整理的清單；**不要替 Owner 選**）

| # | 事項 | 來源 |
|---|---|---|
| 1 | 框架端修正（VS Code `Stop` 範本、`hook_install_validator`、`session_end_hook` 在 Python 3.9 崩潰）是否列為有範圍的後續工作？ | PR #7 本文 |
| 2 | 兩套視覺系統（D1）；整合版 TestFlight 試玩與是否授權製作新 build | INTEGRATION_RESULT |
| 3 | 擴充是否隨出貨版出現與版本號（D3／D4／D6）；`RELEASE_ENABLE_EXPANSION.md` 是否套用 | INTEGRATION_RESULT |
| 4 | 複本 admission：option (a)（現行實作）或 (b)（M6） | INTEGRATION_RESULT |
| 5 | 英文英雄語音聽感審查（D5）；Release 目前排除 | INTEGRATION_RESULT、`docs/release-01/RELEASE_GAPS_1024.md` |
| 6 | 公開英文名稱（Crown Tactics 曾記錄 Steam 有同名作品）、專案授權、AI 生成素材的權利清冊 | `RELEASE_GAPS_1024.md`、`THIRD_PARTY_NOTICES.md` |
| 7 | PR #2（Windows 舊線）、#5、#6 的處置與順序 | 本文 §2 |
| 8 | Apple 審查結果與後續（我沒查） | `docs/PLAN.md` 的 2026-10-11 條目 |

---

## 8. 如果你是接手的 Codex：開工檢查清單

1. `git fetch --all --prune`；`gh pr list --state open`；`git worktree list`——**重新確認 §2 的表**，再開始。
2. 讀 `AGENTS.md`（含四個 repo 專屬區塊與管理區塊）、本文件、`docs/integration/INTEGRATION_RESULT.md`（在 `integration/1.0-1.1`）。
3. 問 Owner 本次任務屬於哪條線；**不要自己從舊手冊的 G0／G1 選任務**。
4. 新分支用隔離 worktree，**從最新 `origin/main` 開**（已含治理與 `external-tree-inventory-guard.json`），不要在有 submodule 的既有目錄切分支。
5. 變更分類見 `AGENTS.md`：規則核心、帳本、存檔、發布設定一律 L2。
6. 回報格式：指令＋實際計數＋**未執行項目**＋人類 Gate 狀態（Pending）。
7. 日常工程授權與主線授權分兩層，見 `AGENTS.md`「Repo-Specific Forbidden Behaviors」第一項：已核准 slice 內可 commit／push 指定分支；合併 `main`、計費語意、發布一律需 Owner。

---

## 9. 本次交接修復做了什麼

見 [`docs/handoff/RECOVERY_01_REPORT.md`](handoff/RECOVERY_01_REPORT.md)：每個改動、依據、未驗項目，以及與舊手冊的差異。
