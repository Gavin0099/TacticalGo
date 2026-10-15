# CONTENT-03｜工程證據與產品邊界

## 已執行

- Swift 完整套件 `swift-full-03.log`：206 tests、0 failure；其中三關正式來源、不同合法計畫、實際反制、錯誤路線、能量／AP、復原重播、隊列續玩及新舊進度隔離有測試。正式存局測試實際寫入一份MatchRecord，逐位核對舊章與正式存局未被新章操作改動，不只是檔名不同。
- `content-evidence-04.log`：三個正式來源與12條分支逐步 Core 重播；保存 `solution-and-counterplay-with-config-04.json` 與 `fixtures-04/*.json`。04只補完整職業／原版設定標籤；所有行動、事件、結果與03相同。成功不是匹配固定答案序列。
- `golden-parity-02.log`：從 C# 與 Swift 重新輸出38組／99步／137 snapshots一致，不沿用歷史結果；Core規則沒有修改。
- `content-390-final-02` 五項、`content-se-final-02` 兩項、`content-ipad-final-01` 一項原生測試通過：實際相鄰棋盤點與大按鍵座標一致，取消／非法／復原／背景、重啟與舊六關隔離。SE是375pt viewport，320pt另為局部壓力模式，不冒充實際320pt真機。
- 三職原生正常速度影片：法師 `native-mage-with-source-03`、戰士 `native-warrior-with-source-02`、盜賊 `native-rogue-tradeoff-01`。戰士與盜賊均包含技能／普通落子的不同計畫與實際敵方回應；法師含完成後復原再下。28份真正被畫面呈現的成功收據與獨立Core重播、職業／AP／Mana／陣營／棋形／事件一致，另核對一次redo；見 `native-three-class-comparison-04.json`。不聲稱未錄欄位的Ko或精確影片幀時間已被這份比較驗證。
- iPad `ipad-native-counterplay-02` 實際直橫向、相鄰佔點非法預覽、44pt控制項、保存後重開與兩回合完成，原始無聲影片與完整XCUIScreen截圖一起保存。錄影有來源檔清單／SHA與Simulator實際執行檔SHA；不是實體iPad。
- `content-hint-regression-01` 一項通過：提示進度跨自己的提交、敵方反擊與重啟維持。程式同時阻止busy期間新增提示，避免 immutable controller 發布覆蓋提示。瞬間busy分支若XCTest未觀察到，不拿這項測試當每個競態時間點都已測到。

完整驗證命令、環境、結果包與source manifest彙整在 `artifacts/autonomous-1011/validation/`。本文件是階段紀錄；最終summary另列全部最新結果，不把重跑測試次數累加成覆蓋率。

## 證據能支持什麼

### 05：第一關合理救援反例補證

只追加測試與證據，沒有改動關卡來源、規則、Controller、保存格式、舊六關或 UI。`AdvancedChallengeTests.testFillingBothCommanderExitsLooksLikeRescueButTwoActionReplyClosesTheFrontier` 以獨立檢查的座標／棋群出口驗證 E6、D7 救援，以及實際敵方 C7、E5 回應。全部行動由 Core 成功收據決定；第一個敵方行動後三氣，第二個後兩氣。F6、G7 的邊界續走最後仍兩氣，因此既有目標失敗；同起點的 E6、F6 普通替代路線仍完成。另驗證失敗後鎖定、沒有 Core 勝方、保存 journal 重播能還原完整 state 與結果。

`artifacts/content-03/rescue-gap-05/baseline-tests-01.log`：改測試前 AdvancedChallengeTests 12 tests／0 failures。`focused-tests-02.log`：追加後 13 tests／0 failures。兩次均使用獨立 `/private/tmp/tacticalgo-content-rescue-tests-05` scratch，不共用既有 `.build`。

`evidence-replay-03.log`：三個正式 source、十三條成功／替代／失敗分支全部由 Controller 與獨立 Core 重播通過。`source-manifest-01.json` 記錄 SHA 及逐欄比較：原三個來源、設定、起始 state 和十二條舊分支完全相同；只增加一條合理失敗救援。新增輸出為 `solution-and-counterplay-with-rescue-05.json`，不覆寫 04 或既有打包檔。命令與非宣稱邊界见 `rescue-gap-05/README.md`。

這次没有重新執行 native 或 Golden：產品程式、Core、來源與舊路線沒有改動；既有 native／Golden 收據仍只支持其原本被測範圍。補證不代表 Owner 已覺得三關有適當難度，也不聲稱直接救援會在第一個敵方回合被提。

| 項目 | 工程觀察 | 不能據此宣稱 |
|---|---|---|
| 合法來源 | 正式newGame重播到初始局面，完整Ko保留 | 玩家自然會在自由對戰遇到同盤面 |
| 多回合反制 | 對手基於實際state產生完整回合，至少一個分支改變回應 | 通用Bot已升級、反應全域最優 |
| 替代計畫 | 築壘／普通接線、左右反打、早換／晚換可合法比較 | 每個選擇同樣強、職業平衡通過 |
| 取消／非法 | 沒有成功收據或扣費，正式存局與舊章不寫入 | 真機零誤觸、VoiceOver全部通過 |
| 原生布局 | 選取、提交、敵方播放、復原與旋轉有實際Simulator操作 | iPhone／iPad真人玩法或觸控驗收 |

## 已發現並處理

最初盜賊草案把兩口氣解讀為即將被提；Core自殺判斷否定，已改為行動效率與能量的真实取捨。iPad點擊標籤及橫向位置不佳已局部修正。早期 `app.screenshot()` 橫向有黑邊／錯誤裁切，改用真正的 `XCUIScreen.main.screenshot()`，保留全部舊失敗與原檔，不重新畫圖或調色冒充修復。

保存中的敵方回合從選關重新進入時，現在把同一個Reduced Motion環境值傳給resume；不使用預設false重新播放完整演出。沒有改動保存格式、章節完成語意或Core。

## 待驗收

Owner不看提示試玩三關、至少另外兩位玩家方向性回饋；是否能說出為何換計畫、是否願意重試。真機操作、VoiceOver、最大字級、內容難度及重玩价值仍Pending。沒有安裝真機、合併或發布。
