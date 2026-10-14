## 2026-10-11 23:31 更新：1.0／1025 已送審，未公開

正式 Xcode upload exit0；App 1.0（1025）與 NT$60 永久解鎖在同一 submission 正式提交，Apple 兩項均等待審查。Owner 已確認英雄原图自行生成，內容版權及出口合規完成。維持台灣免費下載＋前三場完整對局＋自願獎勵廣告／永久解鎖，審核後手動公開。沒有 runtime、規則、資料格式、聲音偏好或遊戲 repo merge 變更。256 個簽名來源輸入核對一致。

下一階段：Apple 審查與正式交易／廣告／雙機 RC 實測；不宣稱公開、核准或 production 服務已可用。證據：`artifacts/release-submission-1025/APP_REVIEW_SUBMITTED_1025.json`、`REPORT.md`、`submitted-waiting-review-1025.jpg`。以下舊阻擋為歷史。

---

## 正式準備更新：1.0／1025

已在 Apple 保存免費下載、台灣限定供應及 NT$60 non-consumable 永久解鎖；公開支援／policy／app-ads.txt與 UMP 訊息備妥。Owner 已發布 Apple 隱私及保存審核電話。1025 Apple Distribution archive／IPA 匯出完成，五張原生商店截圖重载保存；App 尚未上傳，因 Xcode Failed to Use Accounts 需本人既有帳戶登入驗證。正式交易、production廣告、最終真機RC及英雄上游權利尚未結案，仍非可公開發布判定。

下文是1024實作時的歷史產品合約與限制。已定案價格／帳戶建立等事實以 docs/release-01/account-release-evidence.json、artifacts/release-submission-1025/REPORT.md 為準；不修改三場計數或遊戲規則。

# MONETIZE-01／02｜前三場免費、一次解鎖或廣告續玩

2026-10-11。1024 為已實作的本機商業接線候選，未送審、未正式收費。Owner 已要求做到可上架；此方向取代 NT$60 付費下載、無廣告／內購的歷史方案。

## 產品邊界

| 項目 | 1024 行為 |
|---|---|
| 免費額度 | 前三場完整自由對戰／本機雙人；保存正式終局，同一 UUID 只計一次 |
| 未完成、放棄、重開 | 不消耗免費額度；不是前三次按開始 |
| 教學、九個挑戰 | 免費、不計額度 |
| 舊存局 | 已開始棋局可續玩，未知歷史 UUID 不追扣，不從棋譜反算 |
| 永久購買 | StoreKit 2 verified non-consumable 有效權限；恢復、pending、取消、退款分開處理 |
| 獎勵廣告 | 真正 SDK earned callback 保存一份資格，最多一次；開始新局才消耗 |
| 中途關閉／失敗 | 沒 earned 就不發資格，不改原局，可取消返回 |
| 無網路／無廣告 | 舊局、教學／挑戰可用；不假裝已看完。購買依 StoreKit 有效權限 |
| 廣告位置 | 玩家自行選擇，新局／再戰邊界；局中不中斷，永久解鎖者不必觀看 |
| 價格 | Product.displayPrice；NT$60 待定，本機測試價格不是 ASC 定價 |
| 資料 | Access-v1 獨立 ledger；不改 Domain、AP／Mana、棋譜、挑戰進度與聲音偏好 |

免費額度僅本機，無後端、指紋或反作弊；重裝及不同裝置不保證共享，不宣稱不可繞過。永久購買依 Apple 帳戶 StoreKit 權限／恢復，不自存 paid 布林值。

## 保存及過期工作

TacticalGoAccess 是 Foundation-only Package。新局先存新 UUID 棋譜再登記資格；可觀察失敗撤回該新檔，原局保持。完成只由成功保存的 terminal record 計數；啟動重試已登記 UUID 的終局，未知舊局不追扣。

棋譜及 ledger 是兩檔，非跨檔原子交易。在新棋譜保存與資格登記之間 process 被終止，可能留下一個未登記新局；保留 P2 限制，尚未精準 kill 驗證。壞 ledger 不重設三場，保留原檔並阻擋新未付費局；舊局、恢復購買仍可用，verified 購買不因 trial 壞檔失效。

StoreKit listener 重查權限，revision 阻擋舊 async 結果。付款／廣告完成遇 inactive 等 active 再繼續一次；背景、取消及離場清除過期開始意圖。已保存 reward 不因背景撤回，但不自動開過期目標局。SDK 聲音回復使用畫面共享音訊實例。

## 廣告與資料

固定官方 GMA 13.11.0、UMP 3.1.0 及 Package.resolved。明確觀看才更新 UMP，canRequestAds 允許後初始化／載入。關閉 publisher first-party ID／PPT personalization，每次 npa=1，無 ATT 呼叫。管理廣告隱私為獨立明確操作，不首頁自動請求，也不因本次未看廣告隱藏。

**NPA 不等於零資料或無追蹤。** 實際 GMA manifest DeviceID 為 linked／tracking；粗略位置、互動、廣告、診斷等仍需正式帳戶／creative／地區查核。Privacy & messaging、RTB creative、廣告分級與 ASC privacy 回答未完成，不沿用 1023 無第三方資料說法。見 [ADS_INTEGRATION.md](ADS_INTEGRATION.md) 及 artifacts/monetization-02/sdk-privacy-manifests.json。

Debug 用 Google 測試 IDs、本機 StoreKit 與隔離資料；Release 缺真實商品／AdMob IDs／policy/support URLs 不回退測試值。編譯成功仍不表示三場後正式續玩可用，本輪不覆蓋 Owner 既有 1023 真機版本。

## 驗證與發行 Gate

新證據見 [REPORT.md](../../artifacts/monetization-02/REPORT.md) 及同目錄 JSON。驗 ledger 保存／重複／失敗／壞檔、三場真正終局、第四場 gate、取消保原局、免費教學／挑戰、本機 StoreKit 購買／恢復／pending／撤銷、棋盤與真 Google test creative。Local StoreKit 不是 Sandbox；廣告出現或等待時間不是 earned。

仍需真帳戶、同來源 Sandbox／TestFlight、實體 iPhone／iPad、完整局／新人、素材商用、公開政策及 distribution archive。Release 排除未通過英文語音及 3D model，BGM／SFX／原偏好保持；排除不表示其他權利通過。

欄位、設定模板及只封存不上傳入口見 [ACCOUNT_SETUP.md](ACCOUNT_SETUP.md)。可沿用公開 reiko0099@gmail.com／2026 WU JUI-YI，不能沿用字樹花園 privacy/support URLs。未接受契約、建立真商品／廣告、commit／push／merge、TestFlight、送審或發布。

## 官方依據

- [Apple App Review](https://developer.apple.com/app-store/review/guidelines/)：內購／恢復、廣告標示／正常關閉與分級。
- [Apple IAP](https://developer.apple.com/in-app-purchase/)／[Privacy](https://developer.apple.com/app-store/user-privacy-and-data-use/)。
- [Google Rewarded](https://developers.google.com/admob/ios/rewarded)／[UMP](https://developers.google.com/admob/ios/privacy)。

來源是實作依據，不是 Apple／Google 已批准本遊戲。
