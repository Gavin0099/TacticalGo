# CONTENT-02：六個英雄戰術挑戰

基線 `main cdab133`。在選角畫面加入「英雄戰術挑戰 · 六關」，讓既有六個兩手戰術題成為可操作的 iOS 入口。沿用 A0 圖片与原版規則，沒有等待 AI 或新美術，也沒有改變 `TutorialCatalog`、`TutorialSession` 的目標判定。

## 可玩的內容

戰士救援、築壘反攻、法師切串、己兵救援、盜賊換位破形、兩手最後一擊。每關先顯示局面目標，玩家自己選擇落子／本職技能；提示按需求逐則揭露，既有括號座標轉成與棋盤一致的 A1 格式。

玩家可以預覽合法性、AP／能量與提子，取消不扣資源。所有預覽、提交及合法目標都經 Core；沒有假提子、假勝負或 UI 的第二套氣數規則。保留盤面點擊與至少48pt高的大按鍵選點，SE 可捲動讀取提示，iPad 可横向操作。

這是**兩次行動的戰術題**，没有一般 Bot 或自主反擊回合。既有對手反制分支仍用於測試，不能把它描述為會自主攻守的關卡對手。三職候選 R3 及第二技能未進入此入口。

## 完成、失敗與資料安全

新增 `ChallengeController` 在每次成功提交後立即讀取 `assessment`。完成與失敗都鎖定選取、預覽及提交，顯示下一關／重試／復原。底層 `TutorialSession.apply()` 保持原合約；透過控制器防止完成後意外接受敵方動作。

復原會重新建立來源 Session，重播保留的已接受動作，因此盤面、AP、能量、施法紀錄、提子統計與 Core Ko 歷史一同恢复。没有只還原畫面或任意更改盤面。重試清除本關活躍動作及提示；過去的完成徽章由可重播的成功收據支持，復原／重試不会抹去歷史成就。

進度另存 `Application Support/TacticalGo/Challenges/challenges-v1.json`，與正式棋譜及基礎教學目錄分開。只重用 `TacticalGoRecords.RecordedAction` 的動作編碼，沒有使用 `MatchRepository`、`GameStore` 或 Bot。未知關卡、版本、非法紀錄、偽造完成與完成後追加動作皆拒絕；壞檔保留，須明確選擇重設挑戰進度才會覆寫。測試使用各自 UUID 的隔離目錄，不碰 Owner 存局。

原生檢查發現完成後 Core 自動換方，而畫面曾混用白方 AP 與黑方能量。交付版改成「本關已結束 · 黑方能量」，不顯示不存在的下一玩家操作回合；六關測試逐一檢查此標籤及輸入鎖定。

截圖檢查另發現 iPad 橫向若只壓低棋盤高度，密集棋列會重疊。交付版保持棋盤寬高比例，在橫向一起調整寬高；操作區可捲動，沒有壓扁盤面或更換 A0 素材。原生回歸包含棋盤比例及旋轉後的實際點擊。

## 驗證

- `package-tests.log`：150項 Swift 測試、0失敗。新增6項控制器測試，涵蓋六關既有解、合法替代、錯誤分支、預覽一致、不扣資源、立即鎖定、完整狀態／Ko重播、獨立存檔、復原、續玩及壞紀錄保留。
- `golden.log`：38組共享 Golden、99步，原版狀態、拒絕與事件不退步。C#／Swift 輸出對照及固定參考版本見 `parity.log`、`validation.json`。
- 原生交付回歸：SE與iPad各4項，涵蓋全六關真實點擊、可選提示、失敗／成功鎖定、復原、取消、大按鍵、重啟續玩、原對局保留及 iPad 橫向；詳細次數及結果見 `SE-candidate.log`、`iPad-candidate.log`。
- 先前畫面驗證與資源標籤修正前的結果保留於本機，但交付證據使用修正後截圖及原生回歸。完整 xcresult、裝置模擬器錄影與建置輸出保留本機，不提交大型建置或個人裝置資料。

```sh
swift test --package-path swift/TacticalGoCore -j 2
TACTICALGO_DOTNET=/tmp/tacticalgo-dotnet/dotnet python3 scripts/verify-ios-parity.py artifacts/content-02/parity
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo -configuration Debug -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' CODE_SIGNING_ALLOWED=NO build-for-testing
```

实际可用的模擬器名稱可能不同，可替換 destination；原生測試方法保存在 `ios/TacticalGoUITests/PlayableGameTests.swift`，也可以直接從 Xcode 執行四項 Challenge 測試。正式入口无需 Debug 參數；Debug `--challenges` 仅為測試直接開啟選關，`--record-isolation UUID` 使用獨立測試進度。

## 驗收邊界

工程交付通過後送獨立 Draft PR，不自動合併／發布。真機觸控、真人學習效果与好玩度仍待驗收；模擬器不是 iPhone／iPad 實機。

六關均要求本職技能，不能證明玩家學會了「何時不要用技能」。下一輪真人測試應先玩戰術題，再進自由對戰，記錄普通落子与技能的選擇理由、卡關位置、提示次數；不能以六關全通替代這項產品驗收。本 PR 不新增第七關，也不擴充規則平衡。
