# Interface 19 — 全遊戲介面候選

2026-10-13，Owner 要求底部 UI 與整體呈現向《爐石戰記》品質靠近，授權自主迭代。本輪在 `codex/v11-game-interface`，以 Owner 指定 `origin/codex/v11-monster-battlefield` 的 `004ed4cdc661bc20261a587e11d91e54dc649b9d` 為基線；沒有套用舊 main 的 AV-STYLE 候選。

## 已實作

- `GameInterface.swift` 共用暖木／皮革面板、古銅邊、奶油文字、切角按鈕、職業色、技能圖集與能量寶石。原創生成兩個資產，來源與 hash 在 `artifacts/game-interface-19/provenance.json`。
- 四職同一個操作區：44pt 英雄標頭、64pt 圖像技能、16pt 狀態、44pt 指令列，連同間距與 padding 固定 200pt。沒有改 `PhoneMatchLayout`、棋盤投影或 Domain。
- 所有職業的召喚／主技能／第二技能讀取現行 config 費用；牧師不顯示不存在的第二技能。戰利有可見入口，法師方向／取消仍保留。
- 合法預覽才亮起金色確認，結束回合用獨立的棕金按鈕。不可用保持可讀；減少動態停用按壓縮放與滑動動畫。
- 結算取代技能牌，提供符合實際歷史的復原與再玩一局。勝負只在結算主標題說一次；棋盤位置不隨結算改變。
- 選角／HUD 使用同一材料；教學、棋譜、規則、格點清單與聲音設定套用共用外觀。原生 picker、toggle、slider 的語義保留。
- `tacticalgo-game-feel` 更新為 1.2，記錄整體 UI 契約、四職、正確分支、runtime 接線與未驗界線，並同步本機安裝版。

## 兩輪觀察

第一輪把使用者原圖的文字按鈕牆換成插畫技能牌。選取、費用與主動作已有不同層級，背景與木棋盤能連成同一場景；保留 `iteration-1-phone.png`。

第二輪修正標頭44pt觸控區與技能列的重疊風險，補戰利入口，取消重複結算標題；browser 的第二技能費用原誤寫3，依 `RuleConfig.expansionSkillManaCost` 的既有規格修為4。原生費用一直讀 config。選角和支援頁面沿用共用材質，不再各自設計。

仍有的美術差距：第二技能目前沿用主技能插畫加 II，還不是獨立技能構圖；框邊以程序漸層為主，離成熟商業遊戲的專門 UI 美術仍有距離。這些是候選比較結論，不是競品品質百分比或玩家接受證明。

## 驗證

| 證據 | 本輪結果 | 能證明的範圍 |
|---|---|---|
| Browser 375／402、四職、正常／預覽／戰利／鎖定／結算／選角、法師方向 | 50 個布局情境通過 | browser 內無水平溢出、固定200高度、各狀態棋盤frame相同、主要操作至少44px |
| Browser 互動 | 9類操作通過 | preview、cancel、fixture 資源顯示與undo、戰利可達、解鎖狀態、說明／Escape、降低動態、鍵盤重開 |
| 視覺檢查 | 已逐一觀看四職、375正常／結算、402選角 | browser 候選插畫辨識、文字、間距與主次；不代表SwiftUI像素相同 |
| Skill validation、資產／project 靜態檢查、git diff --check | 見checks記錄 | 檔案結構與接線，不能代替編譯 |
| 原生 SwiftUI build、UI tests、VoiceOver、Dynamic Type、iPad、真機 | **NOT RUN** | Windows 沒有 Xcode／iOS SDK；未沿用1106舊結果當本輪結果 |

Browser 預覽是獨立 HTML 排版／互動 fixture，使用當前圖像資產。棋盤是固定7×7示意；選角保留部分比較控制，未移植完整設定流程或遊戲規則。它不是 iOS 截圖，也不能用來驗證9×9點擊、規則、聲音或原生效能。

首輪 browser harness 因說明定位器同時匹配頂部選單和技能說明而停止；改成操作區內的說明按鈕後重跑。這是測試定位錯誤，不是遊戲成功證據。最終結果見 `artifacts/game-interface-19/browser-checks.json`。

## 開啟與重現

在本 checkout 啟動 `python -m http.server 8771 --bind 127.0.0.1`，開啟 `http://127.0.0.1:8771/tools/game-interface-preview/`。依環境指定 Playwright 的 `NODE_PATH`，執行 `node scripts/review-game-interface.cjs`。圖片、HTML、JS、CSS 都使用本機檔案，無外部 CDN。

Mac 接續時，先以當前改動編譯 Debug／Beta，再執行 `ExpansionLabTests.testFixedPhoneBoardAcrossFourClassesModesPreviewHelpHandoffAndUndo`、`testFixedBoardTerminalBannerAfterComputerCapture` 及 PlayableGame 的四職練習／終局復原、法師舊規則切換、iPad 旋轉回歸。這些測試已更新，**尚未執行**。另看375／402實際native截圖與放大字體，核對圖集裁切、皮革明度、文字截斷、控制44pt及棋盤frame，不以browser截圖當通過依據。

本輪未更動聲音／動畫排程。前輪分析指出的終局聲音路由與牧師奉獻演出語義仍待後續切片；UI 改善沒有自動解決它們。沒有 commit、push、merge、建置號遞增、安裝或TestFlight上傳。
