# BOT-P2｜1011 基準、有限提兵正例與重播

最初窗口在 `codex/autonomous-slices-1011` 隔離工作樹測試，斬首候選維持離線。後續已補齊一個原版規則的真實 baseline Pass／安全提兵正例；可關閉的material候選已套入原生研究入口；共享212測試、當前SwiftGolden及五項原生生命週期收據已補入，預設baseline不變。實際 1014 UI／事件接線來自本機 `ui-sell03-lobby`，不是假設遠端 main 等於已安裝版本。完整來源與 SHA 見 `artifacts/autonomous-1011/baseline-1014.json`。

真實baseline選擇等待會錯過本有限驗證的安全提兵路線；未證明等待在所有長期評估下都錯誤。
承接 PR #5 head `a09cf208e851c23dd45555612b0a4a5b50f4d5ee` 的 BotPlanner 診斷與 SearchTraceTests，未合併 PR。舊證據只讀保存在 `artifacts/autonomous-1011/prior-evidence/bot-p1/`；本輪執行日誌另放 `artifacts/autonomous-1011/validation/`。

## 已確認的基準

- 第 40 回合：完整 32 個己方回合中，31 個有下一個敵方回合的主將斬首見證；只有等待沒有找到這種反例。這是有限搜尋下的防守理由，不是永遠安全。
- 第 55 回合：96 個完整己方回合均未找到同範圍的立即斬首反例；baseline 仍等待。沒有反例不等於每個行動有長期價值。
- 完整來源必須由原開局重播，核對每步 board、AP、Mana、current、ply 與 eventPayloads。不能只用 diagram 建立沒有 Ko 歷史的近似局面。
- 原版、R3 及簡單／標準設定分開。baseline 是目前原生對局的預設；本輪候選不改 RuleConfig、難度偏好或正式存局。

## 既有斬首候選（保留的歷史版本）

`BotPolicy.forcingContinuation` 只在標準七路 baseline 選纯等待時評估；先保留最多一個直接壓縮敵方主將氣或包含英雄召喚／移動技能的完整己方回合假設。沒有這類候選時記錄 `quiet-preparation-unassessed`：普通接線、安靜準備與等待存能量仍未判定，不能宣稱沒有價值。這個篩選只控制研究成本，不判斷安全或改變選擇。它沿用 baseline 已經由 Core 驗證的完整回合，不建立第二套規則。

假設必須通過以下證據才可替換等待：對每個合法敵方完整回合，包含等待、首手後等待與兩次行動，下一己方回合都找到 **Core 實際獲勝** 的行動見證。敵方直接獲勝、和局、任一缺少見證或預算不足，均退回原決策。這是很窄的強制續攻候選，不涵蓋所有多回合布局。

資源上限是沿用 baseline 的 6000 次明列 apply，包含續攻檢查；legalActions 內部運算不計入這個數字，不能拿它當 CPU 時間保證。取消返回 nil，絕不把未完成反制搜尋當安全。

完整有限反制正向控制使用一個獨立封閉盤面，注入等待基準並確認三個完整敵方回合都有下一手獲勝見證。它驗證候選邏輯，**不證明真實 baseline 在該盤面曾不必要地等待**。

另建四個從正式開局逐步合法到達的負向控制（一般部署、既有英雄、築壘、緊密前線）：真實 baseline 已分別選出普通落子、英雄召喚或築壘，候選沒有改變它。這些來源與每步結果經獨立 Core 重播，不能拿它們冒充「修好不必要等待」。

## 可重現命令

```sh
swift test --package-path swift/TacticalGoCore --filter ContinuationTests
swift test --package-path artifacts/bot-p2-1011/experiment
swift run -c release --package-path artifacts/bot-p2-1011/experiment ComparisonProbe review artifacts/bot-p2-1011/reviewed-comparison-new.json
swift run -c release --package-path artifacts/bot-p2-1011/experiment ComparisonProbe pairings artifacts/bot-p2-1011/three-pairings-new.json
swift run --package-path artifacts/bot-p2-1011/experiment ComparisonProbe frontier artifacts/bot-p2-1011/NEW-passive-frontier-five.json
```

執行時從隔離工作樹根目錄開始，重新產物請使用新檔名，避免覆寫本輪證據。以上命令及舊對局比較針對斬首候選；不能把它們當成新 material policy 已完成的對局或原生收據。


## 新提兵候選：實際等待與完整官方來源

`BotPolicy.materialThreatContinuation` 是第二個、可選的有限工程候選；原版與既有 `forcingContinuation` 均保留。它不要求每個敵方回應後立即斬首，而要求新形成的**實際安全提兵威脅**。最多排序選取一個 baseline 已由 Core 驗證的完整己方回合：非主將敵兵棋群受壓只用作排序，不能授權行動。

正例由官方 `GameSetup.newGame(.board(size:7), Rogue, Mage)` 開始，43 個接受的動作完整重播，每一步核對 before／after 盤面、AP、Mana、current、ply、召喚／技能狀態及順序事件；沒有 fromDiagram、注入 Pass 或調整資源。完整來源在 `artifacts/bot-p2-1011/noncommander-threat-09/controls-02.json` 的 `Rogue / one-AP-after-A7`。最後的 A7 是實際已接受的當回合第一手，留下 ply23 的一 AP：

```text
.ooooo.
oooOooo
ooooooo
xxxxxxx
xxxxxH.
xxxXx.o
xx.xxx.
```

真實 baseline 等待，分數 -1228、144 次顯式 apply；其 G7 候選分數 -1231。G6 白兵有 F6、G5、G7 三氣。候選 G7 使用剩餘的一 AP、零 Mana，主將棋群由四氣變三氣；氣數只描述棋形，安全由所有完整敵方回合核對。

授權改變等待的證明依序為：

1. 原版等待後若敵方也等待，窮舉下一己方完整回合，未找到同等安全的實際敵兵提子；缺少完整搜尋就退回原決策。
2. G7 後窮舉 35 個合法敵方完整回合，包含直接等待、一手後等待與兩手，均保留完整 Core 歷史、不剪枝。每個回合保住己方主將，且各有下一己方完整回合的實際提兵事件。
3. 每個選用的提兵見證，再窮舉其後完整敵方回合，確認己方主將仍存在、敵方未獲勝。抽和或沒有下一己方回合的分支不能當作提兵改善。
4. G7 → 敵方等待後，**真實 planner** 再選 G5、F6，提交後 Core 提掉 G6；這條實際執行另核對完整後續敵方主將安全。其他 34 個分支證明存在安全提兵路線，沒有宣稱 planner 實際都會選該路線。

部分防禦會救下或移走 G6，但會損失其他兵或主將棋群。證明是任一實際敵兵提子，不是每分支都提 G6，也不是每分支斬首。相同戰士來源等待後也能靠築壘提兵，已保留為負向比較，不能將 Mana 節省冒稱新提子威脅。

## 新候選的成本、回退與重現

完整 API 決策包含原版搜尋、等待對照、35 回應與見證後的安全性，實際 796 次顯式 apply、192 次 legal enumeration，沿用總上限 6000。Core 在 legalActions 內部的驗證不計入顯式 apply 上限；此數字不是總 Core 工作或 CPU 保證。預算不足退回原版完整 actions；取消回 nil，維持既有生命週期。預設、easy、舊斬首候選及規則／正式存局語意不變。

沙盒 Package 的 37 個 Bot 測試通過。root已補共享全Package212tests零失敗與當前SwiftGolden38組／99步PASS，material traced／untraced對照亦通過；此次未新增canonical C#run。當前material新跑三組六場／600回合全部CoreDrawn，行動／終盤與baseline相同、接受新候選0次，完整GameState含歷史／事件獨立重播通過。新原生研究切換／真G7逐手呈現／晚到取消／undo／restart／exit五個唯一方法通過，0failure、11張原生截圖、4筆新收據；其中只有1筆是Bot G7，其餘3筆是測試啟動思考用的人類D5。新的正例與既有 40／55 負例均有可重播來源；40／55 保留 Pass，不宣稱 55 已修復。

從已套入修正版patch的工作樹根目錄可重現：

```sh
swift test --package-path swift/TacticalGoCore --filter MaterialContinuationTests
swift test --package-path swift/TacticalGoCore --filter TacticalGoBotTests
swift run -c release --package-path artifacts/bot-p2-1011/noncommander-threat-09/sandbox-perf-runner-15 --scratch-path /private/tmp/tacticalgo-material-NEW-perf MaterialPerf swift/TacticalGoCore/Tests/TacticalGoBotTests/Fixtures/material-rogue-source.json swift/TacticalGoCore/Tests/TacticalGoBotTests/Fixtures/material-reviewed-source.json artifacts/bot-p2-1011/noncommander-threat-09/NEW-material-perf.json
```

來源、實際 API、SHA、完整回應、沙盒回歸與成本分別見 `controls-02.json`、`safety-and-threat-08.json`、`sandbox-review-manifest-16.json`、`sandbox-bot-regression-13.log`、`sandbox-release-perf-14.json`。新原生正式證據在`artifacts/bot-01r/material-native-07/completion-summary.json`、`RESULTS.md`與155檔`evidence-manifest.json`。這是iPhone13／iOS18模擬器；1017簽名／安裝由root處理，不能當作真機成本或人類趣味通過。
