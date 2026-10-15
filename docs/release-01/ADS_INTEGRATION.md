# MONETIZE-02｜獎勵廣告接線與發行缺口

日期：2026-10-11（Asia/Taipei）。這是程式候選與整合合約，沒有廣告帳戶設定、正式廣告展示或 App Store 驗收。

## 已實作與使用方式

`ios/TacticalGo/RewardedAdService.swift` 是共享的 `@MainActor ObservableObject`，直接使用 Google Mobile Ads／UMP 的實際 API。只在玩家點選「看廣告開一局」後更新 UMP、呈現必要同意畫面，確認 `canRequestAds`，初始化 SDK，載入及呈現 rewarded ad；沒有用倒數、點擊、關閉廣告或測試回呼冒充觀看完成。

```swift
let result = await RewardedAdService.shared.watchForOneMatch(
    onEarnedReward: { rewardID in
        // 在獨立商業 ledger 原子保存；同一 UUID 只接受一次；保存失敗必須 throw。
        try monetization.grantOneMatch(rewardID: rewardID)
    },
    onPresentationChanged: { isPresented in
        // 使用目前画面實際持有的 audio，不另外建立播放器。
        // isPresented=true：停過期播放並暫停音樂；false：按既有偏好及當前畫面恢復。
    }
)
// result=.earned 只會在 SDK earned callback 已保存、且廣告 dismiss 後返回。
// 呼叫端仍需確認 paywall／navigation epoch 沒有改變，才允許開始新局。
```

此片不提供上述範例的 `monetization` 實作；由主 Agent 的獨立權限／額度層提供。`Result` 包含 `earned(UUID)`、`dismissedWithoutReward`、`cancelled`、`unavailable(String)`。觀察 `isBusy`、`isPresentingSDKContent`、`status`、`lastError`；`isConfigured=false` 時不要把廣告描述為已可用。

`isBusy` 阻止重複請求；`isPresentingSDKContent` 只包住即將呈現至已關閉的 SDK 畫面，供 UI 禁用互動退出。UMP consentInfo／form 與廣告仍在載入時，玩家可以退出，呼叫取消而不能等待網路才允許退出。必要表單使用 Google 官方 `consentStatus == .required` 條件，再分開 `ConsentForm.load()` 與 `form.present(from:)`；不是自存同意狀態，也不是自製同意畫面。UIKit SDK 呈現期間可能讓 SwiftUI view 暫時 disappear，不以這個現象取消真實觀看；確定 sheet dismiss、導航退出或 App background 才取消 request。父畫面仍需以當前 navigation epoch／scene／實際 audio instance 處理回復音樂。

離開付款／廣告入口、付款成功、導覽替換時呼叫 `cancelPendingRequest()`。服務同時觀察 `UIApplication.didEnterBackgroundNotification`；不因普通 `inactive` 就取消，因 SDK 呈現本身可觸發該狀態。已原子保存的獎勵不因背景切換而撤回；原畫面的 await 則返回 cancelled，不能自動開始舊目標對局。SDK 的 consent／ad 畫面由 SDK 關閉，關閉前仍保留 busy；過期 load／reward／dismiss callback 不得對新的請求發獎勵。兩次 earned callback 最多呼叫一次 grant；提前關閉沒有 earned callback 就不發額度。Audio 僅在 SDK 畫面關閉且 App active 時恢復。

設定中始終保留「查看／管理廣告隱私選擇」入口，不能因本次啟動尚未看廣告、`privacyOptionsRequired` 初始為 false，就讓已購買者無法查看或修改以前的同意。玩家明確按這個入口後，呼叫 `refreshPrivacyChoices() async -> String?`，nil 表示已由 SDK 更新，非 nil 為可顯示的失敗／取消原因；required 時再呼叫 `presentPrivacyOptions(onPresentationChanged:)`。這個 refresh 只做 UMP requestConsentInfoUpdate，不啟動 MobileAds、不載入廣告，也不自動呈現 consent。它和 watch／options 共用 busy gate，退出或背景後不採用過期 callback。父畫面管理按鈕同時需依 `purchase.isBusy` 禁用，服務不持有 StoreKit。單純管理隱私不需要 rewarded unit ID，因此 options 表單不再以完整廣告單元設定作為 gate。

不將自存 consent 字串或布林值當作許可，不在 App 啟動或打開隱私頁時自動做這次網路請求。每次明確觀看／管理請求才更新本次 session 的 consent；必要入口與實際表單狀態仍依 SDK 更新結果。

## 已核對的依賴

| 官方 SPM | 固定版號／tag commit | App link product |
|---|---|---|
| `https://github.com/googleads/swift-package-manager-google-mobile-ads.git` | 13.11.0／`d1fa1f5c1dfe3b43d56c73f4de388ad3316618bc` | `GoogleMobileAds` |
| `https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git` | 3.1.0／`13b248eaa73b7826f0efb1bcf455e251d65ecb1b` | `GoogleUserMessagingPlatform` |

GMA 本身已依賴 UMP 的版本範圍，但 App 仍直接 link UMP product，才能使用 `import UserMessagingPlatform`。兩個官方 wrapper package 的 License 為 Apache-2.0；二進位 SDK 的使用另外受 Google SDK／服務條款約束，不把 wrapper 授權当作所有商用權利已清。

截至核對日期，GMA 13.11.0 發布於 2026-09-29，UMP 3.1.0 發布於 2025-10-29。GMA 13.4.0 起最低 Xcode 26.2；本機唯讀核對為 Xcode 26.6（17F113），不提高專案 iOS 17 deployment target。Package manifest 的 binary SHA-256：

- GMA：`310516d18f0d600c9e45ed42b955a6b8ec52108d380f7cd8ed1e424e9d3fec22`。
- UMP：`90fe6bf3b0f4ce0d0199628c0871de58b6f673375148b98d52348aecc86db231`。

## 組態與正式版阻擋

- Info.plist `GADApplicationIdentifier`：DEBUG 明確設定 Google sample `ca-app-pub-3940256099942544~1458002511` 才使用 Google rewarded test unit `ca-app-pub-3940256099942544/1712485313`。UI 明確標示測試廣告；這是實際 SDK test ad，不是生產收入或正式觀看證據。
- Release `GADApplicationIdentifier` 與 `CrownTacticsRewardedAdUnitID` 必須為 Owner 來源可核實的正式識別；缺失、格式錯誤、Google sample publisher 均 fail closed。Release 不回退到 DEBUG test IDs。尚未提供正式 ID；不編造帳戶、收益或正式可用狀態。
- `GADDelayAppMeasurementInit=true` 建議在 Info.plist 設定；服務不在 init／首頁預載或初始化 MobileAds，必須玩家明確選擇、UMP 可請求後才做。
- `SKAdNetworkItems` 使用 50 個官方唯一值，保存於 `artifacts/monetization-02/admob-skadnetwork.json`，包含抓取日期、原網址與 HTML SHA-256。只含 Google 與其官方選定 buyers；沒有加 mediation runtime。
- 首版關閉 Publisher first-party ID，requestConfiguration 的 publisher personalization treatment 為 disabled，且每次 Google rewarded request 都註冊 `Extras.additionalParameters = ["npa": "1"]`；服務沒有呼叫 ATT。Owner AdMob Privacy & messaging 不應偷偷啟用 IDFA explainer／ATT flow。拒絕追蹤不能成為逼迫付費或禁止功能的條件。
- 非個人化廣告不等於不收集資料。最終 SDK privacy report／實際行為、AdMob account message、地區同意、年齡 treatment、最高廣告分級及 App Store privacy label，仍需核對；程式沒有替未決年齡或分級硬編碼假證明。

已直接抽取固定版號二進位的 manifest，保存在 `artifacts/monetization-02/sdk-privacy-manifests.json`，含 device／simulator 來源與 SHA-256。GMA 宣告七類收集資料，其中 DeviceID linked／tracking 都為 true；UMP 宣告粗略位置、效能與產品互動，三者 linked／tracking 為 false。兩 SDK 都沒有頂層 `NSPrivacyTracking`，缺省不能當成「false」證據。這些是實際 SDK 宣告，不是本輪封包測量或 final App Store answers。Release 隱私結果仍須依最終組態與行為審查。

2026-10-11 最後核對：Google 官方的 Publisher Privacy Treatment 說明將 PPT 與 NPA 分開。PPT 會關閉個人化，但仍允許第三方廣告服務／追蹤；NPA 對 Google demand 的第三方使用限制較強，非 Google demand 則仍取決於帳戶的 RTB creative consent 檢查設定。因此不能只憑 `.disabled` 或 publisher ID 關閉，就把它寫成「已明確請求 NPA」或「沒有 tracking」。補上的 per-request `npa=1` 沿用 Google 自己維護的 Flutter iOS adapter 對 `nonPersonalizedAds` 的轉換，來源 commit／SHA 記錄於 `artifacts/monetization-02/npa-request-audit.json`；沒有引入 Flutter runtime。

這次驗證證明 Swift request 已建立並註冊 NPA extras，不能證明正式網路／creative 一定不追蹤。NPA 不等於 limited ads、不等於零收集，也不能取代 UMP 的 `canRequestAds`、地區同意、年齡 treatment、AdMob 帳戶設定、實際 SDK／creative 資料處理審查或 Apple 資料申報。無 ATT 是首版實作方向；是否符合最終不追蹤申報，仍需正式 configuration 與運作證據，不能自行改 SDK manifest 的 DeviceID tracking 宣告。

正式帳戶、message publication、廣告單元、app-ads.txt 發布／驗證與最終網站支援資料仍需 Owner 可核實資料。上述設定完整之前，Release 不適合作為「廣告可以續玩」送審版本。

## 驗證與非主張

這個子任務已做 `swiftc -frontend -parse`、diff whitespace 檢查，以及對官方 SHA-256 核實的 GMA 13.11.0／UMP 3.1.0 二進位 framework，分別執行 Swift 6、iOS 17 的 arm64 simulator 與 device source typecheck，兩次 exit 0，沒有 compiler diagnostics。只讀 SDK 暫存於 `/private/tmp/tacticalgo-rewarded-sdk-1024/`。證據在 `artifacts/monetization-02/adapter-typecheck.json`。

其後已完成獨立 Debug `build-for-testing` 與實際 Google 測試廣告網路驗證；Package／Golden 與其他整合執行由主 Agent 另記。沒有實體 iPhone／iPad 廣告證據，也沒有 required consent form 的實測；來源 typecheck 不能當成實際成功觀看證據。

`ios/TacticalGoUITests/RewardedAdNetworkUITests.swift` 已接入 target，在 iPhone SE 3／iOS 18.0 Simulator（375×667 pt）實跑。network03-r1 兩個測試方法 2 PASS：真實 Google `Test mode` creative 完成後開一局、第二局再遇 gate；背景取消不自動開局。再補強同一成功方法，network03-r2-interactive 單獨重跑 1 PASS：付款頁消失、棋盤與落子鍵可操作、真的在 A1 放兵並確認，白方取得 2 AP，再重開仍遇 gate。這是重跑同一方法，不能累計成第三個不同情境。程式沒有注入獎勵，沒有點「取得」或略過同意；播放等待本身不是 earned 證據。

SDK creative 的關閉控制會在 WebView「關閉」與 native `Close`／`Close Advertisement` 之間變動。先前兩次執行各為 1 PASS／1 FAIL，原因分別是只查 Button，以及依 AX index 綁住稍後已消失的節點。原失敗 xcresult／log／媒體保留；僅修測試為標籤查詢，播放後重新取當前可點的正式關閉控制，沒有修改 production。證據在 `artifacts/monetization-network03/`，包含各別 summary、attachment manifest、完整 screenshot／AX hierarchy 與正常速度的 Simulator 原生錄影。錄影沒有擷取系統聲軌，不是實體手機或聲畫同步證據。

待測：提前關閉沒有獎勵、無填充、離線／timeout、consent refusal／required options、導覽退出、快速連點、earned 前後退出、ledger 保存失敗、舊 callback、不重播過期聲音、實體 iPhone／iPad 全屏呈現及一次付費後不再請求廣告。背景案例只驗請求後立即返回桌面，不涵蓋已保存 earned 後背景或廣告播放中途。測試廣告 PASS 不代表正式帳戶已供應廣告、所有地區同意有效、零追蹤或批准發行。

沒有修改 Domain、AP／Mana、技能、Bot、棋譜／存局格式；沒有 commit、push、merge、TestFlight、送審或發布。

## 官方來源

- [Rewarded API 與 test unit](https://developers.google.com/admob/ios/rewarded)
- [UMP：每次 session 更新、canRequestAds、privacy options](https://developers.google.com/admob/ios/privacy)
- [UMP ConsentForm：required 條件、load／present／privacy options API](https://developers.google.com/admob/ios/privacy/api/reference/Classes/UMPConsentForm)
- [GMA 安裝、Info.plist、SKAdNetwork](https://developers.google.com/admob/ios/quick-start)
- [GMA release notes](https://developers.google.com/admob/ios/rel-notes)／[UMP release notes](https://developers.google.com/admob/ios/privacy/download)
- [關閉 Publisher first-party ID](https://developers.google.com/admob/ios/privacy/strategies)／[RequestConfiguration personalization](https://developers.google.com/admob/ios/api/reference/Classes/GADRequestConfiguration)
- [PPT 與 NPA 的官方差異](https://support.google.com/admob/answer/14323214?hl=en)／[iOS Extras 註冊 API](https://developers.google.com/admob/ios/targeting#add_network_extras)
- [Google 官方 Flutter iOS 的 NPA 轉換（固定 commit）](https://github.com/googleads/googleads-mobile-flutter/blob/8af2773401a188f190feb5e8f92d3c0e36c8d71d/packages/google_mobile_ads/ios/google_mobile_ads/Sources/google_mobile_ads/FLTAd_Internal.m#L242)
- [SDK 資料揭露](https://developers.google.com/admob/ios/privacy/data-disclosure)

Google 資料揭露指出 SDK 可處理 IP、廣告互動、裝置識別及診斷等資料；實際包內 manifest 與運作核對完成前，不沿用舊版「Data Not Collected」。這是 SDK 文件說明，不是本輪的網路攔截測量。

## 最新整合證據索引

[network03 報告](../../artifacts/monetization-network03/REPORT.md)／[RESULTS.json](../../artifacts/monetization-network03/RESULTS.json) 列出先前失敗、r1 兩項網路測試、r2 同一成功項實際 A1 落子重跑，以及同份獨立建置上的 SE 兩項棋盤回歸。各 run 的 summary／xcresult／正常速度原生影片與 attachment manifest 分開保留；不累加重跑為新增方法。r1 2 PASS、r2 1 PASS（同方法）、SE 2 PASS；真機、系統聲音、required consent 與正式廣告帳戶仍未驗證。
