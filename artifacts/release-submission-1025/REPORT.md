# 2026-10-11 23:31｜1.0／1025 與永久解鎖已提交，Apple 等待審查

Owner 已回覆 Xcode 登入完成、英雄原图自行生成。正式重試 upload exit0，Apple 顯示 Uploaded TacticalGo／EXPORT SUCCEEDED。1025 完成處理後，已選入 App 1.0；內容版權宣告依第三方獎勵廣告內容填「有必要權利」，不誤填為全部無第三方內容。僅使用系統加密／SHA256 的出口合規資訊已儲存，缺少合規標記清除。

在同一審查草稿加入 App 1.0（1025）與非消耗性商品 `com.tacticalgo.crowntactics.unlock`，正式提交成功。Apple 明細兩項均「等待審查」，提交時間 2026-10-11 23:31（台北）。提交 ID `9d652212-eb28-44bc-a991-2901bd0942f8`，可見證據為 `APP_REVIEW_SUBMITTED_1025.json` 與 `submitted-waiting-review-1025.jpg`。

仍為台灣免費下載、前三場完整對局免費、NT$60 永久解鎖，或自願獎勵廣告取得一局；教學與挑戰免費。保留審核後手動公開，未核准、未公開 App。App Store Connect 新版介面由商品與 App 分別 Add for Review，再在同一 submission 提交；不再依舊版 App 頁面的 IAP 區段判定未掛接。

驗證：256 個 source／delivery 輸入 SHA-256 與簽名來源清單一致，未改 runtime、Domain、AI、資源、偏好或存檔。本輪僅帳戶／上傳／Apple 後設資料操作，不重跑並累計歷史 Swift／Golden 測試。上傳有兩個 GoogleMobileAds／UMP 供應商 dSYM 缺失警告，沒有阻止 Apple 接收，可能限制這兩個 framework 的 crash 符號解析。歷史 exit70 帳戶失敗、封存失敗及較早報告完整保留。

公開前仍需真實 ASC Sandbox／TestFlight 購買与恢復、production UMP／獎勵廣告及最終雙機 RC 驗收；目前送審成功不能代替這些實測。AdMob 帳戶／App 核准與商店連結未宣稱完成。英雄自行生成是 Owner 來源確認，並非獨立著作權意見；未通過英文語音及 3D 仍排除。沒有遊戲 repo commit／push／merge，也沒有對外邀請測試者。

本輪 canonical memory writer 與 memory_workflow --check --run-guard 均 exit0，guard_ran=true／completion_claim_allowed=true，current diff 與 repo state B0 均0。仍保留 repo 內 writer／guard 未找到、缺canonical2、provenance12、artifact metadata3警示；不宣稱完整治理覆蓋。8份release JSON解析及git diff --check通過。

以下均為歷史紀錄，較早的未上傳／未提交及 Owner 登入／來源待確認已由本段與新 receipt 取代。

---

# 目前狀態：1.0／1025 已簽名匯出，尚未上傳或送審

本輪已確認 Owner 填入的審核電話與備註在 Apple 保存，隱私申報由 Owner 本人發布。完成 Apple Distribution 的 iphoneos archive（exit0）、26 項本機檢查及 App Store Connect IPA 匯出（exit0）。目前 App 仍準備提交；正式上傳 exit70，Xcode 回報 Failed to Use Accounts，不能視為已上傳或處理中。

- 正式檔案：CrownTactics-1.0-1025-run03.xcarchive、Export1025/TacticalGo.ipa；版本與商品／廣告 IDs、公開 URLs 均核對。詳見 BUILD_1025_DISTRIBUTION.json。
- 修正只限封存腳本及 App Release target 的 profile 範圍。全域 xcconfig 不再替 Swift Package 指派 profile；移除與 Xcode 封存路徑衝突的 SYMROOT／OBJROOT。兩次失敗證據保留，SOURCE_1025_SIGNED.json 記錄與前版差異，runtime Swift 未改。
- 以 1025 Release Simulator 真實操作擷取 iPhone 三張與 iPad 兩張，未重畫／裁切／调色。已上傳 Apple，重新載入後確認保存；尚不宣稱全尺寸送審要求通過。見 STORE_SCREENSHOTS_SAVED_1025.json、store-media/PROVENANCE_1025.json 與兩張商店保存畫面。
- 手機原生流程觀察到召喚預覽成本、取消不扣費、確認扣費和 Bot 換手返回；平板兩章與三個進階關卡可選。不是完整對局、真機或正式交易驗收；見 MANUAL_UI_1025.json。本輪未重跑或重複累計歷史 Swift／Golden 數。
- 還需 Owner 完成 Xcode 既有 Developer 帳戶登入／重新驗證，及確認最早 B-v01 英雄原圖來源。正式 ASC Sandbox 購買／恢復、production UMP／廣告、最終真機 RC 仍未驗證；AdMob 未宣稱核准或可放送。
- 清理僅本工作樹可重建編譯／索引快取，inventory 見 CACHE_CLEANUP.json。來源、封存、IPA、最終 Simulator App、凍結ZIP、失敗log、xcresults與媒體均保留；只關閉本輪兩個 Simulator，沒有改其他專案。

維持台灣免費下載＋NT$60 永久解鎖與手動公開。沒有遊戲 repo commit／push／merge、TestFlight、送審或公開 App。網站的既有公開發布與隱私申報發布不等於 App 已上架。以下保留較早的歷史紀錄；其中曾待填電話／待發布隱私／未封存／媒體未上傳等內容，已由本段與新 JSON 取代。

驗證補記：封存腳本 bash -n、九份新／更新 JSON 解析及 git diff --check 通過。canonical writer 與 memory_workflow --check --run-guard 已執行，guard允許本輪memory完成、B0阻擋0；仍有缺canonical2、provenance12、artifact metadata3及repo內writer/guard未找到警示。使用既有外部framework runtime，不宣稱repo全面memory覆蓋或治理更新。新guard見memory-guard-signed-screens.log。

---

## 本輪驗證補記

Canonical memory writer及 memory_workflow --check --run-guard 均exit0；current diff／repo state B0均0，仍保留缺canonical2、provenance12、artifact metadata2警示，不宣稱全儲存庫記憶覆蓋完成。JSON解析与git diff --check通过。仅关闭本轮的Crown Release Screenshot 1025模擬器以回收资源，正式App、来源和证据保留。

## 正式配置建置結果與目前阻擋

1.0／1025 的 arm64 Release Simulator 建置與啟動已成功。10 項配置核對全部符合可見帳戶與公開網址；包內含 App、GMA、UMP 隱私 manifest，沒有被拒絕的語音／3D／StoreKit 測試資源。253 個輸入於建置前後 hash 一致。首頁實際顯示 3/3 免費完整對局、開始對戰、新手入門、戰術挑戰，見 BUILD_1025_SIMULATOR.json 與 1025-release-simulator-home.png。

第一個雙架構建置主動中止，不計 PASS；第二個 -arch 指令被 Xcode 拒絕（exit70）；改用 ARCHS=arm64 與隔離 SYMROOT/OBJROOT 後成功（exit0）。所有失敗／中止 log 保留。沒有以這次 build 充當239 Swift或38 Golden的新執行證據。

Apple 審核表單實際拒絕缺少電話的儲存，名字／公開 Email／備註保留草稿，不宣稱保存成功。Mac已鎖定，CUA 無法繼續原生互動；已請 Owner 解鎖。Owner 另外待回覆：Apple 隱私發布法律確認、審核電話、B-v01 原始英雄圖源。Privacy 草稿完成，尚未發布。

本轮没有正式 distribution archive、外部 StoreKit Sandbox、最終商店媒體上傳或審查提交。AdMob account/app 審核與原生 UMP 仍未驗證。維持台灣首發與手動公開；沒有新玩法、美術、語音、commit、merge 或 App 公開发布。

## 最新進度：正式配置與送審資料

付費協議、收款及三份稅務表單已在 Apple 可見頁面確認有效／完成。免費下載、台灣限定供應、NT$60 非消耗性永久解鎖已儲存。公開支援／隱私政策／app-ads.txt 可匿名讀取；UMP 歐洲訊息已發布。內購審核截圖成功上傳並重載確認，備註明確標示本機 StoreKit 測試來源，並非正式購買證據。

隱私七類資料草稿已填完；Google 泛用 manifest 與本 App 設定差異、裝置 ID 非追蹤申報的推論界線存於 PRIVACY_REVIEW.json。Apple 的發布法律聲明仍等待 Owner 針對此步確認，沒有按下最終發布。審核聯絡電話與最早英雄 B-v01 圖源仍待 Owner 回覆，不代填。

新的 Release.1025.xcconfig 使用 1.0／1025 及已確認的正式 IDs、URL，與 1024 凍結來源分開。253 個輸入存於 SOURCE_1025.json；1024 runtime 無變更。Simulator Release 建置正在進行。正式 archive 前檢查唯一缺項為 privacyDeclarationReviewed，因此 Xcode archive 未啟動；結果存 ARCHIVE_PREFLIGHT_FORMAL.json。未 export、upload、送審、合併或公開 App。

只清理本工作樹可重建的編譯快取，完整測試 xcresult、影像、原始素材及 frozen ZIP 保留，見 CACHE_CLEANUP.json。新配置不等於正式交易、真機或產品驗收通過。

# 皇冠戰略｜送審準備紀錄

2026-10-11。工作來源 `codex/autonomous-slices-1011`／HEAD `4986805316ee99576d9f4b933eec6e557134027e` 加既有未提交工作。目錄 1025 是準備批次，沒有建立或上傳 1025 App。狀態：準備進行中，尚未送審。

## 目前狀態更新：Owner 確認上架後

Apple 商務的付費／免費協議現在均「有效」、銀行「使用中」、三份稅務「已完成」。先前處理中與缺少稅務描述為歷史，不再作當前阻擋。支援／隱私／app-ads.txt 網站已獲 Owner 公開授權並匿名 GET 驗證200；App免費、永久解鎖TWD60、App與商品台灣限定已儲存。

UMP歐洲訊息已發布並確認拒絕／選項可用；預設英文（管理介面未提供繁體中文），尚未作正式原生同意表單驗證。內購審核截圖已由原生檔案選擇器上傳、儲存及重新載入確認；備註明確標示為實際UI＋本機StoreKit商品，不能代表正式ASC交易。Chrome擴充功能檔案URL上傳失敗已改用原生選擇器解決，未擴張權限。

App隱私URL已儲存、7項SDK資料類型已選，目前仍為草稿；裝置識別碼與實際設定仍在核對。審核聯絡電話與最上游B-v01參考來源已分別詢問Owner。沒有上傳App、提交審核、遊戲repo合併或公開App；仍以手動發布準備。

## 2026-10-11 本輪稅務完成核對

Owner 回覆「都簽完了」後，商務表實際顯示三份稅務均「已完成」；付費協議與銀行仍「正在處理」。Apple提示銀行更新可能24小時後顯示，不再要求重新填寫稅務。狀態與觀察範圍保存在 `BUSINESS_TAX_COMPLETE.json`；不保存地址、帳戶號碼或稅務答案。網站公開與解鎖價格／供應地區的兩項問題仍待Owner回覆。後續分頁關閉及CDP focus逾時使新ASC準備頁未成功開啟；沒有額外網頁儲存、簽約、build、送審、commit或發布。以下較早的缺少美國稅務內容保留歷史，不代表當前狀態。

## 已完成且可核對

- App Store Connect 1.0 已儲存繁體中文介紹、宣傳文字及關鍵字；副標題為「英雄棋盤對戰，兩步安排攻守」。分類為遊戲／策略遊戲／桌上遊戲。
- 免費下載價格已儲存，台灣基準 TWD 0。價格對應 175 地區不代表已選定供應地區；供應狀況仍未設定。永久解鎖價格也尚未設定。
- 年齡問卷依廣告、奇幻戰鬥、可見劍匕等武器與技能競賽回答；Apple 計算一般 13+、部分地區 16+／12+。沒有申請兒童分類或自訂降低年齡。
- 版本仍「準備提交」、手動發布，沒有要求遊戲帳號登入。沒有 build 上傳、審核提交、TestFlight 或公開發布。
- 此遊戲專屬支援頁、隱私政策與 app-ads.txt 已完成本機內容與私人部署。網站含目前真正的三場免費、永久購買或自願獎勵廣告、恢復購買及本機資料說明；不宣稱無資料收集。

網站為獨立巢狀 source repo：`sites/crown-strategy-support`，提交 `49b8703a8899022a287a3970ca865dbc014341ca`；helper 私人來源上傳及私人部署成功。專案 `appgprj_6acb6a55bf348191b8a061d2e58b890f`，部署 `appgdep_6acb6c85fde8819188ca59978447d369`。公開權限尚待 Owner 回覆，不能將候選 URL 當可供 Apple／AdMob 使用的公開連結。遊戲 repo 沒有 commit／push／merge。

## 帳戶仍需本人完成

Owner 回覆「填好了」後重新核對：台灣稅務「已完成」、銀行「正在處理」，但美國 Certificate 與 W-8BEN 仍顯示「缺少稅務資訊」，付費協議仍「使用者資訊待完成」。已打開美國 Certificate 供本人確認並提交；不代填財務／稅務答案，不保存銀行帳號、稅務表格或地址。本人入口：

[App Store Connect 商務](https://appstoreconnect.apple.com/business/atb/2f1f2ef4-a561-4191-a850-84d23bc9a503)

網站公開範圍、永久解鎖 NT$60 及台灣首發地區已提出具體候選供 Owner 決定，尚未取得答案。AdMob App／rewarded 已建立，但帳戶／App 審查、商店連結與 UMP 配置未通過；建立單元不等於正式廣告可供應。

## 已補發行簽名及平台設定

Apple Portal 已建立「Crown Strategy App Store 20261011」，同一 `P358EB3X9H.com.tacticalgo.prototype.herobody` App ID、既有 Distribution 憑證；到期 2027-08-14。下載後核對 get-task-allow=false、無 ProvisionedDevices、憑證指紋與本機現有憑證相同，安裝至 Xcode profile 目錄。公開核對欄位见 `DISTRIBUTION_PROFILE.json`，不保存私鑰或新增憑證。Release.accounts-draft.xcconfig 僅補 profile 名稱，其他 Gate 保持未完成；沒有執行正式封存。

ASC 已儲存取消 Mac 與 Vision Pro 供應，首版維持目前 iPhone／iPad 的開發及驗證範圍。國家供應尚待決，沒有改免費下載价格或其他分發方式。外部證據為 `distribution-profile-created.jpg` 與 `mobile-platform-saved.jpg`。

## 本輪驗證

以現有 1024 Debug 原生 App 擷取新媒體，不將生成圖當遊戲畫面；手機為 iPhone 17 Pro／iOS 26.5 Simulator，1206×2622。截圖 attachment 舊名稱中的 1018／1021／1023 是测试標籤，不是本輪 binary 版本。

第一個 obsolete xctestrun 路徑執行失败「no test bundles」；保留 `store-phone.log`，沒有計為通過。改用實際存在的 `ios/Build/Products/TacticalGo_iphonesimulator26.5-arm64.xctestrun`，四個方法三通過、一失敗：

| 方法 | 結果 | 可證明範圍 |
| --- | --- | --- |
| 挑戰首頁與兩章切換 | PASS | 六入門與三進階可從實際首頁選取 |
| 技能各階段棋盤尺寸 | PASS | 成功合法預覽、取消與棋盤位置／尺寸的斷言 |
| 合法開局至勝負、復原與再戰 | PASS | 實際 Core 行動產生終局與後續操作 |
| 首頁設定、離場、存局與續玩 | FAIL | iOS 26 alert 動作被 XCTest 暴露為巢狀同名按鈕，全域 selector 不唯一；尚不能沿用此執行宣稱完整首頁通過 |

僅修改 `ios/TacticalGoUITests/PlayableGameTests.swift`：先等待具名「離開目前對戰？」alert，將退出按鈕 selector 限於該 alert 並取 firstMatch。正式 UI／離場語意沒有修改。觀察證據來自此次失敗的 accessibility hierarchy；沒有刪除後續保存／偏好／續玩斷言。新的建置／再測結果另存，不覆寫首輪失敗。

`TEST_SOURCE.json` 保留測試變更雜湊。實際結果與日誌見 `store-phone-summary.json`、`store-phone-02.xcresult`、`build-testing-selector.log`，以及後續 `VALIDATION.json`。本輪未修改 Domain、AI、技能、AP／Mana、ledger、音訊或存局格式，沒有重跑並重複累計舊 239 項 Swift／38 組 Golden。

再測過程也保留失敗：`store-phone-rerun.xcresult` 因指令使用不存在的 PlayableGameUITests 類別，實際執行0測試；Xcode exit0不作通過證據。`store-phone-rerun-02.xcresult` 真正執行1方法仍FAIL，檢查指出先前同型 selector 修改落在另一個 legacy-resume 方法，實際失敗首頁仍使用全域查詢。已還原錯誤位置並限定修正首頁方法，`build-testing-selector-02.log` 新建置成功；其後重跑另存03結果。只以實際測試數與結果判定，不掩蓋這兩次未通過。

最终 `store-phone-rerun-03.xcresult` 執行1方法PASS、0失敗、process exit0；`store-phone-rerun-summary.json` 證明真實方法執行，保存／聲音偏好／續玩斷言保留。iPad Pro13 M4／iOS18 Simulator 的 `testTabletLandscapeSharedBoardAndChapterSelection` 亦1PASS、0失敗、exit0，橫向視窗、等比棋盤、可點控制、入門及進階切換均有斷言。此前三個手機方法PASS不重複累計；這些仍不是正式RC、真機或實際ASC Sandbox。

本批準備五張未修改原生候選圖，来源與SHA見 `store-media/PROVENANCE.json`。手機1206×2622；iPad原始PNG2064×2752，eXIf的orientation8使其呈現2752×2064橫向。保留原檔，未旋轉重繪或假裝原始尺寸不同；最終RC媒體及實際商店上傳方向仍待核。圖片尚未上傳商店。

profile補齊後重跑pre-archive，以 `ARCHIVE_PREFLIGHT_AFTER_PROFILE.json` 明確保留缺少公開政策／支援URL、完整IAP、UMP及本人帳戶Gate的拒絕結果（exit1）。不再缺profile，但仍未呼叫Xcode archive。準備英文審核操作說明 `docs/release-01/APP_REVIEW_NOTES.md`，尚未填入ASC，須對最後簽名版與聯絡資料重核。

網站本機支援／政策已閱讀及截圖；嘗試 390×844 viewport override 後實際 DOM 仍回報 1470 寬，故 `support-mobile-preview.jpg` 不能當手機 QA 通過證據。保留這個限制，不以設定呼叫成功代替實際尺寸驗證。

## 正式送審之前剩餘

1. 三份稅務已完成；等待Apple處理銀行資料及付費協議啟用。
2. 網站公開決定與匿名 HTTPS 驗證，正式 URL、UMP 及真實資料隱私申報。
3. IAP 價格、供應地區、審核畫面、實際 ASC Sandbox。
4. 資產權利與商店名称确认；B-v02 的歷史原始參考來源仍需收尾，不因歷史 HOLD 自動宣告侵權，也不假宣告全部權利已確認。
5. 發行 profile 已完成；接續1.0封存、同一候選雙機生命週期與商業流程、最終商店畫面、本人提供的審核聯絡電話、build上傳及審核。

保留穩定 1023 真機與 1024 凍結包。本輪媒體是 Simulator／Debug，不能代替真機、聲畫同步、收費服務或廣告供應驗收。網站來源 push 不等於遊戲已上傳；目前沒有送審、merge 或發布。

## 證據入口

- `OBSERVATIONS.json`：實際帳戶狀態、已儲存範圍、待決事項。
- `store-copy-saved.jpg`、`app-info-saved.jpg`、`age-rating-saved.jpg`、`free-download-price-verified.jpg`：外部頁面儲存證據。
- `privacy-page-preview.jpg`、`support-page-preview.jpg`：本機網站內容，非公開可達證據。
- `phone-attachments/manifest.json`：原始 XCTest 截圖來源。
- `ARCHIVE_PREFLIGHT.json`：缺少正式輸入時拒絕封存，不視為 Xcode archive 失敗。
- `ARCHIVE_PREFLIGHT_AFTER_PROFILE.json`、`DISTRIBUTION_PROFILE.json`：發行profile已補齊，但其他正式輸入仍阻擋封存。
- `store-phone-rerun-summary.json`、`store-ipad13-summary.json`、`VALIDATION.json`：本輪最終兩個限定方法的真實結果，前次失敗及零測試保留。

本輪里程碑已經 canonical memory writer 保存，guard 執行 exit0、目前diff與repo B0阻擋均0；既有 missing canonical／provenance 警告保留，不宣稱整體治理導入完整。新證據見 memory-record-tax-profile.log 與 memory-guard-tax-profile.log。

本輪三份稅務完成的里程碑已由 canonical writer 保存；memory guard exit0、目前diff與repo B0阻擋0。JSON解析與git diff --check通過，未執行新遊戲測試。Guard仍有missing canonical 2、provenance 12及artifact metadata 1警告；帳戶UI紀錄不是canonical test receipt，使provenance比前輪多1，不宣稱完整memory coverage。見memory-record-tax-complete.log、memory-guard-tax-complete.log及VALIDATION.json的taxCompletionUpdate。
