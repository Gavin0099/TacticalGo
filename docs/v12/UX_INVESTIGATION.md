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
