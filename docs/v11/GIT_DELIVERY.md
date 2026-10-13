# 1.1 source delivery

Owner於2026-10-13明確要求「先推上去」，授權建立提交並推送codex/v11-monster-battlefield，取代先前候選no-commit/no-push限制。此次不合併main、不送App Review、不動另一1.0 agent工作樹。

範圍為目前TestFlight1.1/1106來源：四職、三职第二技能、兩魔物/戰利、一般solo/Bot與雙人、存局/復原、原畫動畫與英文語音、暖色介面與固定phone7/9布局。保留素材產生腳本、原始/候選素材及來源權利記錄，另納入最新兩輪精簡證據。

## 建置

- Swift套件：`cd swift/TacticalGoCore && swift test`
- iOS：開啟`ios/TacticalGo.xcodeproj`，選`TacticalGoBeta`（Beta組態含TACTICALGO_V11）。簽名需各開發者自己的Apple帳戶/憑證；Git不包含簽名IPA、provisioning profiles或憑證私鑰。
- 同工作樹xcodebuild必須串行執行：專案ios/Build路徑由多scheme共用，不能只靠不同DerivedData避免鎖衝突。

## 證據界線

原始約9.6GB artifacts/v11包含Derived/cache、xcresult、archive、IPA、device與upload日誌，全留本機。Git只挑選solo-17/interface-18的source pins、測試summary/測試日誌、notes/DELIVERY及必要遊戲畫面。既有文件中其他artifacts路徑可能是本機完整歷史；不宣稱乾淨clone含所有封存/影片，也不宣稱交付驗證腳本可無封存執行。驗證腳本需要本機相應archive/export或重建的新證據。

完整Swift250/0是1105歷史驗證；1106Visual10/0、Beta-main5/0、Debug-small3/0且0skip，共8次原生執行/7種方法。1106source pin核對；Core/Bot/Motion/Records/Content相對1105未變。Git來源提交不等於新手機包、真人外觀/配音/玩法接受或公開發行。

遠端分支與提交以推送後`git ls-remote`實際核對，不從本機commit推論上傳成功。

素材來源的原始CC0授權/model README及下載HTML保留原始bytes，部分含CRLF/尾端空白；不修改它們來取得全檔whitespace潔淨。自有ios/Swift/scripts/docs/memory與gitignore的staged diff檢查通過；簡式私鑰/token/簽名包掃描無命中，這不是全面安全審核。

## 來源封裝實測

本輪從準備提交的index用git checkout-index匯出乾淨來源，重新執行完整Swift252項/0失敗；unsigned Simulator TacticalGoBeta建置成功（1106），54份PresentationLab素材與source bytes一致、兩怪資源存在。這是Git封裝完整性驗證，不是重新執行8項UI或真機品質驗收。精簡收據見artifacts/v11/git-review/VALIDATION.json；建置cache/完整log仍留本機。
