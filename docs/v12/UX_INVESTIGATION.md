# TG12-01 操作可靠性

## 對戰選單第一點
Observed: ExpansionGameView 的選單 label 原為 38×36，低於 44×44。
Candidate: 擴成 44×44 並加 Rectangle contentShape；保留原生 Menu 與原動作。
新增 native test 僅點一次後驗證選單、開關聲音設定、盜賊第二技能仍可見。
NOT CLAIMED: 小命中區就是首次點擊失效的根因；原生測試未在 Linux 執行。

## 盜賊第二技能
Source: mode rail 在 expansionSkills=true 時包含 advanced；現有
ExpansionLabTests 已覆蓋新局、白後手、雙怪、標準電腦與未召喚英雄。
本次不猜測性改動技能可見性。新增設定頁往返回歸條件，待 Xcode 執行。
若再發生，需記錄 build、棋盤完整畫面、original/expansion、黑白方、
新局/續局、設定頁開關前後與 mode-advanced 的 exists/hittable/frame。

## 原生驗證
在 macOS 用專案既有 Xcode test scheme 執行：
- AdvancedChallengeUITests/testExpeditionProductEntryAndSeparateChapterProgress
- ExpansionLabTests/testMatchMenuOpensOnOneTapAndRogueSkillSurvivesSettings
- 既有兩項 testRogue… 與 AdvancedChallengeUITests 回歸
涵蓋小尺寸 iPhone、一般 iPhone、iPad 橫向、Reduced Motion 與前背景。
未修改 Release xcconfig/build number/簽署，也未上傳 TestFlight。

## 2026-10-22 原生結果

首次點擊選單、聲音設定往返、盜賊雙技能、新局與白方標準／雙怪情境，
已在 Debug／Beta 執行；最終通過。Beta 帶有續玩列時，測試需捲至實際英雄名稱並單點，
再驗證選取；未憑此改技能顯示或宣稱原始回報的真機根因已確定。

新增完整遠征與 iPad 橫向流程，並修正回顧／下一關／匯出的 44 pt 點擊區。
小手機與 iPad 的匯出驗證包含背景停時計算；保留早期失敗與修復後結果。
完整指令、實際計數、變異與未驗項目見 [NATIVE_VALIDATION.md](NATIVE_VALIDATION.md)。
