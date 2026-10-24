# PR #40 固定棋盤與合法盜賊連鎖：2026-10-24 證據

本輪在 `b87823687fb5c4a1a3ce505b010d548d663fb494` 上完成 Owner 已核准的試算介面與合法盜賊連鎖練習。沒有改規則引擎、Bot、技能費用、帳本、存局格式或正式發布設定。這是工程與模擬器證據；不代表真人趣味、美術、聽感或 Apple 審查通過。

## 可觀察的改變

- 試算主頁沒有垂直捲動，三個階段共用固定棋盤區；主要按鈕在畫面內。明細另頁展開，保留完整 AP、能量、提子、犧牲與雙方主帥氣數。模式列仍可水平捲動。
- 小手機與放大文字時棋盤縮小以保留操作空間；新增最小 44 pt 的大按鍵格點清單。沒有宣稱點擊數或玩家決策時間下降。
- 公開「玩法練習 → 盜賊 · 兩手連鎖」從原 P0 正常開局重播 117 個合法行動，保留 superko 歷史。先 F3 落兵，再 D3→C3 連鎖換位，當回合提敵兵 2、白方能量 6→2，交棒後顯示的是黑方 AP。未執行敵方回應，不預告下回合 3 能量或保證勝利。
- 原成功事件驅動的盜賊換位、提子與聲音保持原實作；新增來源與回歸驗證，不聲稱本輪重製角色或聲音。普通落兵的真實提子回饋仍適用。
- 練習沿用既有不可寫入保護，保存按鈕停用。原生測試證明兩手確認、撤銷後，退出並重新啟動仍可續接原本正常存局。

## 同裝置影像

| 檔案 | 內容 |
|---|---|
| [before-result.png](before-result.png) | 舊版試算排列，完整摘要與操作需捲動 |
| [after-result.png](after-result.png) | 新版固定棋盤、精簡兩手與主要按鈕 |
| [after-confirmed-capture.png](after-confirmed-capture.png) | 真正確認後提敵兵 2、能量 6→2 |
| [small-phone-large-text.png](small-phone-large-text.png) | 小手機放大文字；可另開大按鍵格點 |
| [ipad-landscape.png](ipad-landscape.png) | iPad 直轉橫後草稿仍未提交 |
| [baseline-silent-original-speed.mp4](baseline-silent-original-speed.mp4) | 舊排列原速無聲 Simulator 片段 |
| [candidate-silent-original-speed.mp4](candidate-silent-original-speed.mp4) | 新排列原速無聲 Simulator 片段 |

兩段使用同一 iPhone SE 模擬器、同一合法來源與相同行動。為隔離排列差異，舊版比較只替換 `TwoActionPlanningSheet.swift` 為 `b878236`，**兩版都共用本輪新增的練習入口**；不可稱舊提交原本已有這個入口。錄影只剪頭尾、等比例壓縮，沒有加速、重建動作或後配聲音。XCTest 等待時間不同，片長不得作為玩家速度或效能改善量測。來源雜湊、還原與剪輯資訊見 `comparison-source.json`、`video-edit.json`、`screenshots.json`。

## 驗證

### Swift 套件

1. `swift test --package-path swift/TacticalGoCore --jobs 2`：完整執行 474 個測試；新加演出測試錯把既有單一英雄移動看成兩個 transfer，造成 1 個失敗。既有牧師 Bot 的不必要聖所使用另記為 1 個 expected failure；不是這次新增的缺陷。
2. 檢查既有演出契約後，修正測試的預期：英雄由 E3 經 D3 至 C3 是 1 個 transfer，加 2 個敵兵 transfer 共 3 個，不修改產品動畫來配合錯誤測試。
3. `swift test --package-path swift/TacticalGoCore --filter 'RogueChainPracticeTests|ExpansionPresentationTests.testArchivedRogue' --jobs 2`：相關 3 個測試通過。合併最新結果為 474 個測試已覆核、無未解決新增失敗，保留 1 個既有 expected failure。**不是修正後重新完整跑過一遍的宣稱。**
4. 聚焦變異把原重播第一手 E7 召喚改為 A1；來源檢查確實失敗（exit 1）。還原後兩項內容測試通過（exit 0），見 `mutation.json`。

期望值固定來自 PR #37 `2399cbc` 的 root / ownAfter、原始 117 個行動與成功收據；非從新程式輸出倒填。`rogue-source.json` 保存來源雜湊及本輪比對值。

### 原生 UI：11 個裝置／組態／測試組合的最新結果通過

| 組態 | 數量 | 證據 |
|---|---:|---|
| Debug / iPhone SE | 7 | `layout-initial-summary.log` 1 項；`debug-flow-summary.log` 中其餘 5 項；`debug-refined-summary.log` 的新盜賊完整流程修正後通過（另重驗放大文字） |
| Beta / 獨立乾淨 iPhone 17 | 3 | `beta-refined-summary.log` |
| Beta / iPad mini A17 Pro | 1 | `ipad-final-summary.log`，包含直轉橫 |

覆蓋固定棋盤位置（階段切換及詳細返回保持 1 pt 以內）、主要按鈕在窗內且可點、不滑動主頁的兩手規劃、兩次正式確認、實際兩兵提子與能量、撤銷兩手、正常存局重啟不變、更換第一手使第二手失效、取消與前背景、普通提子與無提子對照、戰士／法師／盜賊、放大文字／減少動態／格點清單。

比較錄影各另跑 1 項相同流程，僅作影像來源，不灌入上述 11 的正確性計數。

原生測試透過 `xcodebuild ... -only-testing:TacticalGoUITests/ExpansionLabTests/<test> test-without-building` 執行；Debug 用 `TacticalGo` scheme，Beta 用 `TacticalGoBeta` scheme。原始命令、完整 XCTest 動作與 `.xcresult` 留在本機忽略目錄 `ios/Build/tg12-feel-20261024/`。本目錄摘要保存每項結果與原始 log SHA-256（`test-logs.json`），不提交大量 DerivedData 或帳戶資料。

### 早期失敗與修正

- Debug 原生新測試先遇到退出對話框相同 identifier 的重複 AX 節點；將測試選取限定為 alert 中第一個按鈕。
- Beta 再揭露舊測試資源 helper 只讀黑方 HUD，誤以白方盜賊當前 AP 為 0；新流程改為同時讀雙方 HUD，不改產品資源。
- 截圖發現新主按鈕的背景仍只有文字寬；將 label 在套用 button style 前撐滿，重新執行 Debug／Beta 與影像擷取。原失敗摘要保留，不宣稱一路全綠。
- 初次裝置簽署嘗試把 Xcode 管理 profile 當手動 profile 且傳到 package resource target，建置失敗。改為本機忽略的獨立 signing project，只對 App 的 Beta target 沿用既有自動開發簽署；相對 scheme 路徑也在該副本固定。正式 project、憑證與帳戶設定未更動。

### 清理與未驗範圍

本輪自建 iPhone SE、Beta iPhone 17、iPad mini 三台模擬器已 shutdown / delete，見 `simulator-cleanup.json`；其他任務裝置與 runtime 保留。

C# replay / parity 未驗（無 .NET SDK）。沒有重新驗證完整購買／廣告／付費流程、真實 1.0 存檔或全模式整合；本輪沒有改這些路徑。沒有真機影像、聽感、玩家趣味或美術接受證據。iPhone 開發版安裝已成功；自動啟動被 iOS 以裝置鎖定拒絕，需要解鎖後自行開啟「皇冠戰略 TG12 驗收」。結果見 `device-install.json`；安裝成功不能替代真人驗收。未合併、未 TestFlight 上傳、未發布。
