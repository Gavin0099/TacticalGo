# 發行基本資料／隱私／包內素材核對

日期：2026-10-11。這是本機預檢，不是法律意見、商用授權核准或已填 App Store Connect 申報。

## 最新商業方向與隱私版本邊界

Owner 改提免費體驗，之後付費或看廣告續玩，取代付費下載方案。免費額度已選前三場完整對局；一次解鎖商品／价格與廣告 SDK 仍待定，[FREEMIUM_PLAN.md](FREEMIUM_PLAN.md) 為現行計畫。1023 尚無 StoreKit 或廣告 SDK；下方既有 manifest 與政策草稿只描述未加入服務的候選。

廣告版本須查核實際 SDK 的資料收集、分享、追蹤、manifest、分級與條款，重新完成公開政策及 App Store Connect 申報；不能直接沿用 Data Not Collected。追蹤或 IDFA 存取才需要 ATT，拒絕追蹤不得成為功能限制或強制付款理由。來源：[Apple 使用者隱私與資料使用](https://developer.apple.com/app-store/user-privacy-and-data-use/)。目前未選或安裝 SDK，沒有帳戶變更。

## R1：本機隱私清單補齊（2026-10-11）

後續收尾已新增 `ios/TacticalGo/PrivacyInfo.xcprivacy` 並加入 App 的 Resources build phase。下方 1018 盤點保留為歷史基線，不將「1018 缺清單」反寫成它當時已有。

| 實際用途 | 宣告類別／理由 | 查核邊界 |
|---|---|---|
| CombatAudio 使用自己 App 的 UserDefaults，讀寫既有六項聲音偏好 | UserDefaults／CA92.1 | 沒有 App Group、MDM 或其他 App／系統偏好存取；DEBUG 音訊測試的獨立 suite 也屬本 App |
| BoardPlayback、GameStore、CombatAudio 使用 systemUptime 安排成功演出、相對 cue、選取聲節流 | SystemBootTime／35F9.1 | 僅作 App 內事件時間差／timer；內存中有有界播放紀錄。DEBUG 的本機聲畫記錄不是 Release 功能，沒有找到向外傳送 uptime 的程式 |
| 目前候選沒有廣告、追蹤與收集服務 | tracking=false、trackingDomains=[]、collectedDataTypes=[] | 與目前本機行為一致；這是候選 manifest 宣告，不是已完成網路流量稽核或 App Store Connect 申報 |

具體 reason code 已核對 [Apple 的 Required reason API 類別與理由](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)。CA92.1 限於自身 App 偏好；35F9.1 用於事件間隔與計時，不允許藉此向外傳送原始 uptime。

清單不能代替公開政策／支援 URL、素材商用確認或最終封存審查。建置與包內檔案比對結果另記於 `artifacts/release-01/r1-native/`；不以這份文字先宣稱 Apple 已接受。

## 觀察到的資料與 API

來源與建置一致性見 `artifacts/release-01/PREFLIGHT.json`。本輪只掃主 App 與其七個本機 library target，不把離線 BotRunner 計時直接當 App 行為；文字結果仍包含部分 DEBUG 區塊，最終需按 Release 編譯與實際用途核對。

| 項目 | 本輪觀察 | 首版前處理 |
|---|---|---|
| 棋局／棋譜／教學／兩章進度 | 使用既有本機保存，未加服務 | 保留格式與原局，驗續玩／壞檔；政策寫清用途與可刪除方法 |
| 聲音與語音偏好 | CombatAudio 使用 UserDefaults，其他 UI 可用 AppStorage | Required-reason UserDefaults 類別需對應適用理由；與是否外傳資料是兩件事 |
| 演出時鐘 | BoardPlayback、CombatAudio、GameStore 使用 systemUptime 安排時間差 | 核對 SystemBootTime required-reason 的實際用途／理由；不因是動畫就漏填 |
| 外連／分析／廣告 | 本輪關鍵字未找到 URLSession／URLRequest／追蹤 SDK 使用；Package 無第三方遠端 dependency，主程式 imports 為 Apple／本機模組 | 只是靜態初步結果，不等於已做流量稽核或零收集證明；最終 RC 驗證後再申報 |
| 自訂字型 | 現行 App 找不到 ttf／otf | 使用系統字型／SF Symbols 仍按平台許可，不能把截圖中參考字體當包內字型 |
| 隱私清單 | 已建置1018 App內沒有任何 `.xcprivacy` | 依適用 API 補清單並確認真正封存包内存在；本輪不先選未经用途查核的 reason code |
| 隱私／支援入口 | 主 App 文字／程式檢索未找到連結 | 待真實 URL 與支援資料；App 内和商店皆需可達，不放空頁／假 URL |

目前「Data Not Collected」最多是待確認的申報方向，不能直接替 Owner 勾選。系統備份／使用者自行分享紀錄與開發者外傳要分別說明；不為上架加分析、帳號或雲端。

## 只查實際隨 App 分發的材料

Manifest 的候選／HOLD 是歷史紀錄，不回寫成已核准；若 Owner 日後明確核准，新增具來源 SHA、版本與用途的發行批准紀錄。

| 材料組 | 證據／現況 | 需要補的可追溯項目 |
|---|---|---|
| 原三職立繪與角色小圖 | Assets.xcassets、Cozy/B-*-v02.png；Cozy/source-pins.json 仍 integration_candidate_only | 實際輸入參考、生成方式、提供者／條款版本、Owner 公開使用核准；不重畫人物 |
| B2-B 兵卒／法師演出／拆層補圖 | Anim01/anim01-manifest.json 的 rights=pending_confirmation、productionApproved=false；HeroBody 有來源 SHA | 原圖到拆層／補圖的來源鏈、商用條件與必要 attribution；只放大／拆層不自動產生新權利 |
| 木盤／桌面／紙張／icon | 当前 asset catalog 和 Cozy 包 | 複核真正使用的每個檔案；設計風格 GO 不等於來源權利確認。現有 AppIcon SHA見1018SOURCE |
| AUDIO-01 的原合成 BGM／11 SFX | Audio/manifest.json：自寫 Python 合成、無外部取樣，但 publication_status=prototype only | 生成器／檔案 hash與Owner正式聽感／使用核准；不因未用外部取樣就替Owner結案 |
| B 動態音樂 | Audio/b-manifest.json：rights_quality=Owner listening and commercial review pending | 找回對應 source-manifest、合成方式、輸入／授權、五音檔與混音版本；本輪不替換／重置BGM |
| 六句英文 TTS | Audio/Voice/manifest.json、CREDITS.md：來源／attribution留存，品質及完整權利未核准 | 首版建議不用。引擎 GPL／模型宣告／訓練資料授權與輸出權利須分清；本輪不作法律推定。關閉預設不代表移出分發包 |
| 舊模型／legacy素材 | Models/manifest.json仍candidate；1018 bundle仍有Models目錄 | 即使正式入口沒顯示也查包內來源。建議只打包實際需要且核准的材料；移除前核對legacy references，不擅改其他候選 |

目前包內資源檔數只用於清冊，不當權利證據。`Audio`含29檔、`Models`含13檔（其中有manifest）、`Cozy`8檔、`HeroBody`3檔、`Anim01`34檔；compiled Assets.car 另含圖片與icon，需要核對其來源 catalog。沒有宣稱這些全部已獲商用许可。

## 待取得的發行資料

- 對外開發者／版權名稱，支援 Email／URL，公開隱私政策URL。
- 免費體驗／付費或廣告方向已提出；免費額度已選前三場；內購商品／價格與廣告服務未定，待查 Paid Apps Agreement、稅務／銀行狀態及首發地域／語言。付費契約須由 Account Holder 接受，帳戶狀態未查；[Apple 設定價格說明](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/)是要求依據，不是本 App 已設定完成。
- App Store Connect 中實際 record、bundle ID、1.0正式版本、名稱可用性與簽名識別；目前未登入／讀取帳戶。現有開發候選 0.10.11 不因商業決策自動變成正式 1.0 封存。
- 分級問卷按實際奇幻內容回答，不猜固定年齡、不為可愛風格直接選 Kids Category。
- BOT研究入口／語音首版配置、包內素材商用確認及真人驗收仍未結案。1020 新局技能已採用；舊存局依自身規則、固定原版九關標示保留。不可用公開上架代替候選驗收。

## 未加廣告版隱私政策草稿（歷史候選，不可帶占位符送審）

此段不能直接用於新增廣告／內購版；須加入經實際服務核實的資料用途、接收者、權利與聯絡方式，並與正式包一致。

《皇冠戰略》隱私政策

生效日期：待正式候選確認。營運／支援者：待填。

皇冠戰略是一款棋盤戰術遊戲。目前候選把棋局、棋譜、教學／挑戰進度與聲音偏好保存在 App 的本機資料空間，用於續玩、重播與保留設定。正式版是否不向開發者／第三方傳送這些內容，將以最終版實際資料行為確認後寫定。

目前程式盤點未包含登入、廣告、分析或遠端對戰服務。若玩家自願聯絡支援，僅處理玩家自行提供的問題與資料；實際支援渠道、保留時間與聯絡資訊在正式發布前填妥。

本機資料保留至玩家使用既有刪除功能或移除 App；哪些進度可個別刪除須按最終 UI 核對，不承諾尚未實作的「全部重設」。作業系統的備份及恢復依使用者的 Apple／裝置設定處理，與本 App 是否有自建雲端服務分開。

隱私聯絡：待真實 Email／URL。政策更新方式與最終日期：待填。

這段刻意保留未查項，供補齊后修改為明確政策，不能直接公開占位符。上述官方申報／政策要求链接見 RELEASE-01 README。
