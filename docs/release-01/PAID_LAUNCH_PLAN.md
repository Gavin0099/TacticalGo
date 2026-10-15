# 歷史方案｜1.0 付費下載買斷準備

日期：2026-10-11（Asia/Taipei）。本機準備文件；沒有變更帳戶、契約、價格、測試群組或發布狀態。

> 此文件保留當時決策與證據。Owner 後續改提免費體驗，付費或看廣告續玩；下方「已定」只描述歷史，不再是現行上架方案。新方案見 [FREEMIUM_PLAN.md](FREEMIUM_PLAN.md)。

## 當時 Owner 已定事項

| 項目 | 決策 | 尚未成立的發布證據 |
|---|---|---|
| 首版 | 1.0 付費下載、完整買斷 | 正式 App Store record、版本與 distribution archive 未確認；現有裝置候選為 0.10.11 |
| 台灣價格 | 目標 NT$60 | App Store Connect 內可選價格點、實際設定與生效日期未查；其他地域／價格未決 |
| 額外收費／廣告 | 無廣告、訂閱或內購 | 最終包與商店申報仍要核對實際一致 |
| 免費測試 | 使用 TestFlight | 尚未上傳、建立群組、送 beta 審查或邀請測試者 |

「完整買斷」指一次付費即可遊玩首版核准公開的完整內容；文案不承諾未核准的新英雄、章節、第二技能或所有未來內容。首版沿用已有玩法，停止新增內容；必要 UI／資料／發行問題依 [README.md](README.md) 收尾。

## 發行內容基線與驗證邊界

1020 新對局已正式採用沿棋群築壘＋法師己兵調度，法師原短推仍有；設定不提供規則選擇。舊存局保留自身規則與身份，固定原版練習／九個挑戰仍標示原版。來源與驗證保留在 `artifacts/release-01/skills-default-1020/`。

### 最新限定候選：1023 雙機更新，iPad 啟動待解鎖

1022 已透過 Wi-Fi 同 bundle 覆蓋安裝到 iPhone 與 iPad；iPhone 正常啟動成功，iPad 啟動仍因 Locked 待 Owner 解鎖。Owner 的 1022 實機照片顯示選取／預覽時棋盤上移、費用換行，後續採 1023 修正；照片回饋不反寫 1022 原有的來源、安裝與回歸結果。

1023 已固定摘要槽，讓行動列與方向列使用相同可縮放高度、最小 44pt；237 個來源／資源／測試輸入相較 1022 僅變更 `PlayableGameView.swift` 與 `PlayableGameTests.swift` 兩個 UI／測試檔案。最終来源五次原生設備方法執行通過、開發簽名檢查通過，兩機 Wi-Fi 覆蓋更新至 1023。iPhone 正常啟動，30 個既有檔與六項聲音偏好保持；iPad 27 個既有檔與六偏好保持，啟動因 Locked 待解鎖。390 寬板面相較 1021 面積增加 8.8%，1023 與 1022 同尺寸；375 短手機為穩定預覽保留空間，不再引用 1022 idle 的 +75%。詳見 [1023 報告](../../artifacts/ui-board-focus-1023/REPORT.md)；完整真機操作及發布驗收仍未結案。

買斷部分僅為本機文件，沒有存取 App Store Connect、接受契約、設定價格、發出邀請、上傳、送審或發布。NT$60 付費買斷、無內購／廣告／訂閱及 TestFlight 免費測試仍是已定方案。

### 歷史裝置更新：1021

歷史裝置更新 1021：iPhone、iPad 透過 Wi-Fi 同 bundle 覆蓋安裝，兩機各 27 個既有保存檔逐檔 SHA 相同，六個聲音偏好欄位包含缺省狀態一致。兩機正常啟動均回報 Locked；待 Owner 解鎖後才可補正常啟動與啟動後資料比對。詳見 [1021 安裝報告](../../artifacts/ui-result-1021/install/REPORT.md)及 `install/RESULTS.json`。

1021 是開發簽名，不是 distribution archive，也不是完整真人驗收。1019／1020／1021 證據維持各自來源與當時結果；當時 1021 文件同步沒有重新建置或測試。後續手機棋盤比例變更要用自己的來源與驗證，不移植舊候選通過結果。

## Apple 要求與待核帳戶欄位

官方頁於 2026-10-11 唯讀核對，僅作準備依據；未讀取本 App 的帳戶狀態。

| 準備項 | 官方要求／適用邊界 | 本 App 現況 |
|---|---|---|
| Paid Apps Agreement | 提供付費內容前，Account Holder 須接受最新付費契約；送審前須設定價格。[設定價格](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/) | 契約、稅務／銀行資訊與 NT$60 可選價格未查；沒有代 Owner 接受或填寫 |
| TestFlight build | 每個 build 可測試最長 90 天；外部測試首個 build 須審查，後續 build 可能仍需審查，批准後才開始測試。[TestFlight 概覽](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) | 尚無本輪 TestFlight 上傳或批准證據 |
| 外部測試群組 | 建外部群組前須先建內部群組；對外 build 要加入外部群組，才可安排邀請。[邀請外部測試者](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/) | 群組與測試者未確認，沒有發邀請或公開連結 |
| Small Business Program | 合資格者可申請付費 App 的 15% 佣金；須核准並到適用生效日，不會因首次發行自動適用。[Small Business Program](https://developer.apple.com/app-store/small-business-program/) | 未查資格、關聯帳戶、申請、核准或生效狀態；不使用 15% 推算收入 |

此文件不做市場售價比較、下載量或收入預測。實際價格、佣金與結算依帳戶當時狀態確認。

## 首版仍未結案

| 項目 | 完成所需證據 |
|---|---|
| Bot 研究入口 | 明確的首版公開配置與相容策略；既有研究結果不能替代正式完整對局／真人體驗 |
| 英文英雄語音 | Owner 品質決定、首版接線／打包配置與權利紀錄；預設關閉不等於移出包或取得授權 |
| 包內素材商用 | 逐項來源、hash、適用條款／用途及批准；圖像、音樂、音效、動畫、語音和歷史模型均依實際分發包核對，見 [PRIVACY_AND_RIGHTS.md](PRIVACY_AND_RIGHTS.md) |
| 真人／設備驗收 | 固定候選的完整三職／黑白、新人獨立操作、三進階關及 iPhone／iPad 實際操作與聽感；Agent 不替真人填結果，見 [PLAYTEST.md](PLAYTEST.md) |
| 商店與隱私資料 | 真實開發者／支援／政策 URL、名稱／icon、分類／年齡問卷、資料行為申報、原生截圖及版本識別，見 [STORE_DRAFT.md](STORE_DRAFT.md) |
| 最終 RC | 明確來源與資源 hash、distribution 簽名／封存、最終包檢查及對應同一候選的回歸，另保留 Apple 處理結果 |

## 執行順序與授權邊界

1. 先完成可在本機審閱的文案、權利清冊、隱私／支援資料及固定候選驗收紀錄；對仍缺的資料保留缺口。
2. 待首版內容與素材結案，鎖定最終來源，另行核准正式封存／帳戶操作；核對真實 record、bundle、1.0 版本、契約及台灣價格。
3. 按另行授權準備並上傳 TestFlight build、建立群組及外部測試審查；獲准後才安排免費測試與邀請。
4. 最終缺口結清後才另行核准 App Store 送審及公開；手動發布設定也是帳戶操作，須確認授權。

本買斷方案的帳戶與發布工作目前只完成文件準備。此計畫不授權接受契約、改價、上傳、邀請測試者、送審、merge 或發布；每項操作要有對應 Owner 授權與真實執行收據。買斷決策、開發簽名安裝與文件完成均不能作為已可上架的結論。
