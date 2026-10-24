# PR #40 兩手試算：原生驗證紀錄（2026-10-24）

本輪延續已授權的產品候選，與 PR #39 Bot 研究、PR #41 上架修復分離。產品修正在 `058ba0e`；`7bf4517` 補充試算捲動容器的輔助識別與測試可靠性。Core、Bot、技能費用、存檔及付費語意均未改動。

## 驗證

環境：Xcode 27.1（27A9275），iOS Simulator 27.0（24A434）。Debug 與 Beta 使用不同的任務專用裝置；Beta 從一般入口或公開玩法練習操作，沒有使用 Debug 棋形入口。

| 配置／裝置 | 最新實際結果 | 範圍 |
|---|---|---|
| Swift 套件 | 471 項，0 非預期失敗；含 1 項既有 Bot 預期失敗 | 沿用本輪稍早完整套件執行；後續只改 iOS 呈現及 UI 測試，未重跑套件 |
| Debug／iPhone SE 第三代 | 5／5 通過 | 原有試算整合、空預覽隔離／前背景、修改／取消／續局、三職業、普通落兵與技能提子 |
| Beta／獨立 iPhone SE 第三代 | 5／5 通過 | 上述前四項，加放大文字／減少動態；未使用 Debug 提子 fixture |
| Beta／iPad mini A17 Pro | 1／1 通過 | 放大文字、減少動態、直轉橫、完整裝置截圖、取消不提交 |
| Beta／iPhone 17 | 1／1 通過 | 放大文字、減少動態及 44 pt 點擊區 |

合計 12 個配置／測試組合，皆以各組最新結果計算，沒有把失敗重跑次數算成新測試。Debug 5 項與 Beta SE 5 項是前段的已通過紀錄；後續只補驗新增的版面測試與測試工具修正，未重跑整套。最新程式提交 `7bf4517` 的 [CI run 40061985252](https://github.com/Gavin0099/TacticalGo/actions/runs/40061985252) 通過，內容為 7 項試算模型測試與 iOS 語法解析，不能代替 Xcode 原生結果。

本輪新建的 4 台模擬器已全部關閉並刪除；包括 SE、初輪 iPad、截圖覆核 iPad 與一般 iPhone。沒有刪除 runtime 或其他專案裝置。

三職業測試各完成盜賊、戰士、法師的公開練習技能＋落兵；每一步仍須正常確認。沒有提子的技能不得宣稱提子。Debug 提子測試另比較同一手寫棋形中的技能與普通落兵，兩者都依成功收據顯示「提敵兵 ×1」。這些是操作與呈現證據，不是戰術優勢或平衡證據。

`package.log` 的 1 項預期失敗是既有 `PriestSanctumBotTests.testBotRescuesTheCommanderAndUsesSanctumOnlyWhereItIsNeeded`：Standard Bot 在存在較便宜救援時，仍花聖所取得第四口氣。本輪不改 Bot，也不將它寫成零已知問題。

## 失敗與修正

1. **棋盤格點的輔助使用群組**：初輪 UI 測試找不到 `forecast-cell-0-0`。明確保留棋盤子項與摘要群組後，原有整合測試通過。
2. **正式預覽滲入試算**：未修版在正式選 A1 後開空試算，回歸明確失敗於「Empty draft must not display the live pending action」。移除空試算回退到 live preview 的行為後，同一回歸在 Debug／Beta 通過，且關閉仍保留正式單手選點。保留未修版失敗與修復後證據，沒有改測試去接受殘影。
3. **Beta 啟動環境**：首次命令漏填 Google 測試 App ID，4 項測試在進入玩法前因 `GADApplicationVerifyPublisherInitializedCorrectly` 崩潰。依既有原生 runbook，僅在模擬器建置命令補官方測試值後重跑；未改正式設定、廣告帳戶或單元 ID。
4. **44 pt 浮點讀值**：iPhone 17 將 44 pt 回報成 `43.99999999999997`。測試加入 0.001 pt 容差，實際低於標準的點擊區仍會被拒絕；沒有放寬產品尺寸。
5. **橫向截圖與捲動**：App 範圍截圖旋轉後出現裁切異常；改用 `XCUIScreen.main.screenshot()` 並附視窗幾何資訊。初次改寫用了不存在的 API，編譯失敗紀錄也保留，核對 Xcode SDK 後修正。旋轉後對整個 App 的捲動還曾把試算 sheet 拉掉；改為在 `forecastScroll` 內捲動。最新 iPad 操作、視窗 1133×744 pt、完整裝置截圖與獨立 `simctl` 截圖均成立。
6. **重跑的環境與可見性**：既有任務模擬器的存局會推動大廳版面；放大文字下設定開關也可能在畫面外。最新版先揭露設定開關再驗證開啟，補驗時只重裝任務模擬器的 App 回到乾淨起點；未清除 Owner 真機或其他專案資料。失敗後立即停止該測試，避免後續斷言掩蓋第一個原因。

## 重現

原始命令、執行個案與雜湊收錄在 `artifacts/tg12-two-action-native-20261024/validation.json`。大型原始 log／xcresult 保留於本 worktree 的 `ios/Build/tg12-pr40-20261024/`，未將整個建置目錄加入 Git。

```sh
swift test --package-path swift/TacticalGoCore --jobs 2
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo \
  -configuration Beta -destination 'platform=iOS Simulator,id=<TASK_DEVICE>' \
  -derivedDataPath ios/Build/tg12-pr40-20261024/beta \
  ARCHS=arm64 CODE_SIGNING_ALLOWED=NO \
  CROWN_ADMOB_APP_ID=ca-app-pub-3940256099942544~1458002511 \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  '-only-testing:TacticalGoUITests/ExpansionLabTests/testForecastLargeTextReducedMotionAndTabletRotationKeepDraftUncommitted' \
  -resultBundlePath '<UNIQUE_RESULT>.xcresult' test
```

一般 iPhone／iPad 可重用同一套 Beta 編譯產物執行 `test-without-building`。重跑前先保留失敗收據；只有任務自建模擬器可重裝測試 App。任務裝置用完就關閉並刪除，runtime 保留；不清理其他專案裝置。

## 可檢視畫面與未驗範圍

- [盜賊兩手試算結果](../../artifacts/tg12-two-action-native-20261024/screens/debug-all-forecast-rogue-two-action-result.png)：公開練習中的無提子技能對照，不冒稱 P1R ply 60 的自然歷史。
- [普通落兵的實際提子回饋](../../artifacts/tg12-two-action-native-20261024/screens/debug-all-forecast-confirmed-soldier-capture.png)。
- [小手機放大文字](../../artifacts/tg12-two-action-native-20261024/screens/beta-se-forecast-large-text-first-stage.png)。
- [iPad 橫向完整畫面](../../artifacts/tg12-two-action-native-20261024/screens/beta-ipad-display-forecast-large-text-reduced-result.png)。早期裁切圖保留於本機原始匯出，另記錄雜湊，只作截圖問題證據。

尚未執行：本 Slice 的 iPhone 真機聲畫驗收、相同真機上的 PR #34／#40 前後錄影比較、聽感、效能量測、VoiceOver 人工操作，以及 C# replay／parity。沒有新增真人試玩、沒有替 P1H 填資料；不宣稱更好玩、完成美術驗收或達到競品品質。沒有合併 main、上傳 TestFlight、送審或發布本 Slice。
