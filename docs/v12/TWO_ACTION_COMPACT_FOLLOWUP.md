# TacticalGo 1.2｜兩手試算：棋盤優先的精簡候選

- **上游：** PR #40（`b87823687fb5c4a1a3ce505b010d548d663fb494`），本分支為獨立、可回退的 UI L1 候選；不直接修改上游 Draft PR。
- **範圍：** 僅調整 `TwoActionPlanningSheet` 畫面組合與原生回歸，不改 `TwoActionForecast`、`GameEngine`、Bot、技能費用、存檔／付費、Apple 發布設定。
- **原因：** 上游把棋盤、逐手操作、預覽數據、載入按鈕置於單一垂直捲動容器。隨著動態字級和兩手摘要增長，棋盤或提交前按鈕可能離開可視範圍。這是程式結構判定，並非本輪已量測真人操作耗時。

## 變動與非變動

1. 棋盤、第一／第二手分頁、目前 AP／能量、技能選擇、選點取消、加入試算與帶入第一手固定在畫面結構內；只讓說明、逐手摘要、詳細數字捲動（保留 `forecastScroll` 輔助標記）。
2. 每手摘要預設只顯示**提敵兵、能量變化與 AP**；額外的犧牲己兵、雙方主帥氣及下一手風險，按「查看詳細數字」展開。沒有把試算提子當成實際戰果。
3. `forecastBoard`、`forecastStage0/1/2`、`forecastAddStep`、`forecastLoadFirst` 等既有測試識別保持不變。新增 `forecastDetailsToggle` 與 `forecastCommandDock`。
4. Live action 的兩次獨立「確認」保持必要；第二手仍由正式棋盤帶入。選點與加入試算仍各自需要點擊，因此**不能宣稱把 9 次點擊降為 4 次**。本次只針對捲動與資訊負擔，實際耗時待 A/B 真機量測。
5. 只動 PR #40 候選，不影響 PR #41 目前獨立處理的 Apple 審查與 Release 分支。

## 必要驗證

- 靜態：`swiftc -frontend -parse ios/TacticalGo/TwoActionPlanningSheet.swift`、`swiftc -frontend -parse ios/TacticalGoUITests/ExpansionLabTests.swift`。
- 原生：跑 `testForecastCompactBoardAndPrimaryCommandsRemainVisible`；再跑原 PR #40 的取消／背景／修改第一手／三職對照／放大文字／iPad 旋轉／不自動提交組合。
- 真機：同一台 iPhone 比 PR #34 原流程、PR #40 前版、此精簡版；記錄完成兩手落兵所需點擊、捲動次數、總秒數、誤觸／取消、理解度，不要以程式推估當作使用者量測。
- **Gate：** 小螢幕或放大字級如發生棋盤點擊命中率下降、操作列遮住棋盤、原生截圖裁切、內容不可達，視為 FAIL，必須回退／調整。純 Swift parse 綠燈不能替代 Xcode。
- 本輪尚無真機影音、VoiceOver、C# parity 與效能量測；不得宣稱體驗已通過 Owner 驗收。

## 獨立後續：真實的盜賊收益重播

P1R 研究釘在 `b9-Priest-Rogue` 第 59 回合／ply 60、完整 superko 歷史。盜賊 `#5` 的第一手是 `placeSoldier(2,5)`，第二手是 `castChainSwap(first:(2,3), second:(2,2))`（座標為 0-based）；連鎖換位花 4 能量。研究在該局面及對手回應中量到**淨提敵兵 +2**，但剩餘資源及長期收益仍有代價，且不是一般開局的無提子技能對照。

進一步產品驗證應另取可重播的完整歷史與逐手 Core receipt，補單獨的 Debug 及 Beta 對照證據，檢查 **佈局 → 連鎖換位 → 真實提子 → 能量/AP → 第二手正式確認** 的先後與用語。不可只注入一張看起來相似的棋盤、不可把 P1R 研究優勢當成 AI 正式策略已改善，更不可為了演出修改規則。

Bot PR #39 仍 HOLD：7×7 牧師／盜賊兩局純 pass 數沒有下降（57→57、41→41），和局不變。`diagnosis.json` 另顯示原因必須分開：7×7 Priest/Rogue 的安全主動候選經過首手與第二手搜尋，卻在完整回合候選排名第 43、落在 reply cap 之外；9×9 P1R `#5` 的兩手戰術**已進入回應搜尋**，但最終分數不如 Bot 選擇。兩者不能一律歸咎於生成不足，也不能直接用 pass 懲罰項掩蓋，暫不接入 shipping Bot。
