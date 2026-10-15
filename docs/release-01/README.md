## 當前狀態（後續歷史紀錄保留）

Apple 付費協議與銀行有效，三份稅務完成。App／IAP 台灣供應及免費／NT$60 價格已儲存；公開支援及政策可用，UMP 已配置、原生運行仍待核對。隱私七類草稿已完整，Apple 發布法律聲明等待 Owner 確認；審核電話及最早英雄原圖來源待回覆。1025 為正式配置與送審準備，尚未上傳或提交。最新證據：artifacts/release-submission-1025/OBSERVATIONS.json、PRIVACY_REVIEW.json、SOURCE_1025.json。

# RELEASE-01｜首版內容凍結與上架收尾

2026-10-11 最新核對：台灣、US Certificate、W-8BEN三份稅務都「已完成」，付費協議與銀行「正在處理」。不再缺稅務答案，但協議尚未有效。網站公開與NT$60／台灣供應待Owner答覆；尚未封存、上傳或送審。最新證據為 `artifacts/release-submission-1025/BUSINESS_TAX_COMPLETE.json`；下方稅務缺少的段落屬歷史。

2026-10-11 本人回覆後重新核對：台灣稅務已完成、銀行正在處理；兩份美國稅務仍缺少，付費協議未生效。已建立、驗證並本機安裝同 Bundle ID 的 App Store profile，沿用現有憑證；尚未封存或上傳。ASC 已關閉 Mac／Vision Pro 供應，首版限 iPhone／iPad；價格仍免費，國家及 IAP 價格待決。以下較早問卷／profile 狀態保留歷史，最新以 account-release-evidence.json 為準。

## 2026-10-11 最新帳戶及送審準備

App 與永久解鎖草稿、AdMob App 及 rewarded 單元已建立。ASC 1.0 商店文案、分類、年齡問卷與免費下載價格已儲存；一般分級由 Apple 計算為 13+。仍準備提交／手動發布，沒有 build 上傳或送審。

付費協議已由 Owner 簽署，但頁面仍「使用者資訊待完成」、兩份稅務問卷「缺少稅務資訊」。支援／政策／app-ads.txt 已私人部署，公開授權待決；正式 URL／UMP 不假填。永久解鎖 NT$60 與供應地區尚待 Owner 決定。正式廣告可放送、Sandbox、簽名封存、產品／權利驗收皆未完成。

1024 凍結包保留；送審素材與本輪限定原生驗證另存 `artifacts/release-submission-1025/`，此名稱不是已建立 1025 App。下面「待登入／未建立真帳戶」內容為當時歷史狀態，以上段及帳戶 evidence JSON 為目前狀態。

2026-10-11。最新本機來源為 1024 商業接線候選，真機維持 1023；不是已驗收可發布的 1.0。

## 現行方向與實作

前三場完整對局免費，之後永久購買去廣告或自行觀看 rewarded 取得下一局；教學／挑戰免費，舊局可續玩。StoreKit 2、独立 ledger、官方 GMA／UMP 已接入；真帳戶與價格未建立，不把本機測試當正式收費。

詳見 [1024 報告](../../artifacts/monetization-02/REPORT.md)、[方案](FREEMIUM_PLAN.md)、[帳戶及封存](ACCOUNT_SETUP.md)。本輪不改 Domain、AI、AP／Mana、技能、棋譜、進度與偏好。Release 排除未通過英文語音及 3D model，不等於其餘素材權利已通過。

正式商品、AdMob IDs、此遊戲公開 URLs 尚缺。ASC 待 Owner 登入；可沿用公開 Email reiko0099@gmail.com／Copyright 2026 WU JUI-YI，但不能沿用字樹花園政策網址。Sandbox、雙機／新人、素材商用、名稱、distribution archive 及問卷仍待完成。

[PAID_LAUNCH_PLAN.md](PAID_LAUNCH_PLAN.md) 與下方 1018–1023 無購買／廣告、研究入口及語音狀態只保留歷史，不描述目前 Release。未接受契約、建立真商品／廣告、commit／push／merge、TestFlight、送審或發布。

## 已採用玩法：1020 新局直接使用新版技能

2026-10-11 Owner 已採用沿棋群築壘＋法師己兵調度作為新對局預設，並要求設定不再提供規則選擇。這是明確的玩法採用決策，取代下方历史 1018／1019 的「R3 非預設」條目；不代表首版商用權利、完整平衡或 App Store 发布已通過。

新對局與選角／規則說明採用同一既有 config；法師原有短推仍保留。舊存局保持原规则、历史与身份，固定原版練習／九個挑戰仍明確標示原版，沒有在這項修改中重做。1020 來源與實際驗證見 `artifacts/release-01/skills-default-1020/`。1019 的来源 ZIP 与历史结果保持不变。

## 最新限定候選：1023 雙機更新，iPad 啟動待解鎖

1022 已透過 Wi-Fi 同 bundle 覆蓋安裝到 iPhone 與 iPad；iPhone 正常啟動成功，iPad 啟動仍因 Locked 待 Owner 解鎖。Owner 隨後提供的 1022 實機照片顯示選取／預覽時棋盤上移、費用換行；這是後續問題證據，不反寫 1022 當時的來源、安裝或工程回歸結果。

1023 已固定摘要槽，讓行動列與方向列使用相同可縮放高度、最小 44pt；237 個來源／資源／測試輸入相較 1022 僅變更 `PlayableGameView.swift` 與 `PlayableGameTests.swift` 兩個 UI／測試檔案。最終来源五次原生設備方法執行通過、開發簽名檢查通過，兩機 Wi-Fi 覆蓋更新至 1023。iPhone 正常啟動，30 個既有檔與六項聲音偏好保持；iPad 27 個既有檔與六偏好保持，啟動因 Locked 待解鎖。390 寬板面相較 1021 面積增加 8.8%，1023 與 1022 同尺寸；375 短手機為穩定預覽保留空間，不再引用 1022 idle 的 +75%。詳見 [1023 報告](../../artifacts/ui-board-focus-1023/REPORT.md)；完整真機操作及發布驗收仍未結案。

當時的付費下載文件為歷史，已由免費體驗／付費或廣告續玩方向取代；目前程式仍無購買或廣告功能。沒有存取 App Store Connect，也沒有接受契約、設定價格、發出邀請、上傳、送審或發布。

## 歷史安裝狀態：1021（既有證據）

iPhone 與 iPad 已透過 Wi-Fi 同 bundle 覆蓋安裝 1021。兩機更新前後各 27 個既有保存檔逐檔 SHA 相同；六個聲音偏好欄位連同缺省狀態一致，iPhone 原有六個持久欄位、iPad 原有五個，沒有補寫缺省值。兩機正常啟動均因 Locked 待 Owner 解鎖，啟動後資料比對與完整真機操作尚未完成。

1021 為開發簽名、version 0.10.11、iOS 17 起的裝置候選，不是 distribution archive。來源與歷史原生回歸見 `artifacts/ui-result-1021/SOURCE.json`、`VALIDATION.json` 及 [安裝報告](../../artifacts/ui-result-1021/install/REPORT.md)／`install/RESULTS.json`。當時 1021 文件同步沒有重新建置、測試或安裝；後續手機棋盤比例修正仍需另存來源與驗證，不沿用 1021 當成新候選已通過。

Owner 最新方向：以已有內容準備首版，停止新增玩法；只修妨礙首次使用、完整對局與送審的問題。既有「好玩、操作順手」回饋保留，不重新推翻核心玩法，也不推論為陌生玩家與所有模式均通過。

## 歷史候選：1019／R1

Owner 已核准繼續收尾。首頁現在可直接看到「開始對戰／新手入門／戰術挑戰」，續玩仍優先；存局與棋譜移入既有設定與工具選單，沒有刪除。挑戰進入技能入門目錄後，可切換邊境攻防三關。封面、選角、規則、AI、聲畫、存檔與偏好保持。

UserDefaults／動畫計時的 PrivacyInfo 清單已加入真正 App 資源。1019 使用相同 bundle、version 0.10.11 與 iOS 17 deployment target；237 個來源／資源／測試輸入已鎖定，簽名與包內清單比對通過。這是裝置開發候選，仍非 distribution archive。

當時驗證：212 項 Swift、38 組 Golden／137 狀態比對，以及 9 次原生 UI 執行（390、375 大字級、iPad 直橫向，包含三關完成）。Simulator 與實體 Release 的不同 build configuration／測試入口仍分開記錄，不宣稱相同二進位已全部真機驗收。

R2 工程補測：六場正式開局Bot對Bot均合法終局與完整重播相同；標準三個樣本仍有61純等待／58最長連續、100回合和局。這是本輪來源的新風險證據，不代替真人對局，也不宣稱AI停滯已解決。完整局、三關樂趣及新人驗收仍待執行。

iPhone 已更新1019，安裝前後26個既有存局／進度檔、6項聲音偏好相同；正常啟動遭 Locked 拒絕，解鎖後的啟動與完整試玩待驗。iPad Wi-Fi info 連線逾時，本輪尚未更新。詳見 `artifacts/release-01/r1-native/`；後續解鎖／連線證據另追加，不反寫舊結果。

## 1018 是驗收起點，還不是正式 RC（R0 歷史盤點）

- 實際來源：`codex/autonomous-slices-1011`，HEAD `4986805316ee99576d9f4b933eec6e557134027e` 加未提交來源。此次重核 `artifacts/challenge-fix-1018/SOURCE.json` 的 236 檔，零差異；既有 App 執行檔亦與 BUILD.json 相同。
- 顯示名稱「皇冠戰略」／Crown Tactics、現有皇冠棋子 icon 先保留；不重開品牌或美術研究。名稱可用性及正式商用確認尚未完成。
- 已安裝版：build 1018、version 0.10.11、bundle `com.tacticalgo.prototype.herobody`、iOS 17 起。送審識別與正式版本號另確認，不默默更換 bundle 造成另裝一個 App／丟失續局。
- Xcode project 的預設 bundle 仍是 `com.tacticalgo.prototype`；1018 使用 build command override。重建時必須沿用實際 bundle／版本設定，不能只按預設 Build 就當成同一更新候選。完整既有命令見 `artifacts/challenge-fix-1018/signed-build.log` 開頭；本輪沒有重新執行簽名或建立新 App。
- 目前 App 使用 Xcode 26.6／iOS SDK 26.5 與裝置開發簽名（get-task-allow=true）；不是 App Store distribution archive。2026-10-11 唯讀 `git ls-remote` 核到遠端 main 仍 `cdab133cd469dd185fd8ca3f47fea2e217cfb139`，沒有此候選遠端分支；本輪沒有上傳。
- iPhone 正常啟動已有證據；iPad 安裝完成但自動啟動 Locked，尚無本輪解鎖回覆／完整操作證據。兩機更新前後各 25 舊資料檔、6 聲音偏好相同，是前輪安裝證據，不冒稱本輪新測。
- 新的完整來源快照／逐檔 SHA 在 `artifacts/release-01/SNAPSHOT.json` 與 ZIP。原 1017 封存包不改寫。這是本機保存，不是 Git 提交、遠端備份、IPA 或正式上架。

## 固定內容與未定的發布配置

首版收尾限於現有三職與 1020 已採用的新局技能（法師原短推保留）、7×7 單人、7×7／9×9 本機雙人、五步基礎教學、六關技能入門、三關邊境攻防、存局／棋譜、現行聲畫與輔助操作。固定練習／九關維持原版並標示規則；三關正式納入與真人驗收仍待結案。不新增紅龍、新英雄、第二技能、章節、養成或 3D；BOSS-00 清除候選文件保留，但 BOSS-01 runtime 暫停。

| 部分 | 本機實際狀態 | 收尾原則／仍需決定 |
|---|---|---|
| 新局技能 | 1020 起預設沿棋群築壘＋法師己兵調度，原短推仍有 | 已採用；設定不提供規則選擇。舊存局依自身規則，完整平衡與真人驗收另查 |
| 原版技能／固定關卡 | 舊存局、固定原版練習與九關保留 | 保留規則與身分並清楚標示，不把新局採用決策當成關卡規則也已更新 |
| 簡單／標準 AI | 既有對戰選項保留 | 固定規則驗完整局；不為少 Pass 強迫亂下，不宣稱高手 AI |
| BOT-P2 研究策略 | 非預設，Release「AI 研究」選單仍可選 | 不升格預設；建議隔離出正式首版操作，不能以 DEBUG 決策紀錄已隱藏推論整個研究入口都隱藏 |
| 邊境攻防三關 | 能選入，原版規則、工程交付 | 目前仍顯示「候選」。先走完、確認取捨，再核准正式章節；不只刪掉候選字樣就當驗收完成 |
| 英文英雄語音 | 預設關閉，但既有偏好可啟用；6 WAV 仍在包內 | Owner 不接受其演技，仍 HOLD。建議首版不提供這批語音；需限定接線／包裝變更，保留玩家偏好、不重做配音、不影響 BGM／SFX |
| 音樂、圖像與動畫 | 已接線，來源紀錄有 pending／candidate | 商用核對只針對實際隨 App 分發的材料；預設關閉、未展示或只有歷史研究用途，均不等於可略過包內素材 |

上表的建議不是已核准移除功能，不在本輪修改程式。正式配置確定後，產生新 RC 並重新驗證；1018 的測試不能直接移植成新 RC 的結果。

## 上架收尾的固定順序

| 步驟 | 限定工作 | 可檢查交付／結束條件 |
|---|---|---|
| R0：保存與盤點（本輪） | 核對 1018、凍結來源、素材／隱私／發行缺口 | PREFLIGHT.json、來源 ZIP、此計畫、試玩表、商店文案草稿。文件完成不等於發布通過 |
| R1：找得到內容 | 首頁可直接看到「開始對戰／新手入門／戰術挑戰」；有存局保持續玩優先。設定與棋譜保持可達，避免再堆開局選項 | 最小 UI 修正，真正首頁選入兩章；375／390／iPad、大字級與原局保存。保留現行章節 item 路由與取消 Bot 邊界 |
| R2：固定候選驗收 | 同一規則、AI 與來源跑完整局、三進階關、雙機與新人測試 | `PLAYTEST.md` 表填入真實證據與問題；只修阻擋項，不因一次想法加內容 |
| R3：發行資料與權利 | 實際 API 隱私清單、公開隱私／支援連結、實際包內素材商用核對、名稱／icon 確認、準確文案與原生截圖 | `PRIVACY_AND_RIGHTS.md` 缺口結清；STORE_DRAFT 待填項完成；不使用 Mockup 假裝正式畫面 |
| R4：鎖定正式 RC | 明確 commit／資源 hash／簽名 build／版本，最後回歸與雙機試玩對應同一送審來源 | 經核准後建立 distribution archive；上傳、送審、合併與手動公開各自保留授權邊界 |

R1 已完成本機原生候選，不重畫大廳。R2 不能由 Agent 替 3–5 名真人填結果；可補自動完整對局與既有合法測資，但不替代真人。沒有 Apple 帳戶／資料時先做離線草稿，不假裝 App Store Connect 已建立或申報完成。

## 目前送審阻擋項

0. 新模式尚無試玩額度、購買／恢復或廣告流程；必須先確認方案，再補實作、失敗路徑與 SDK 隱私驗證。

1. 1019 已補 PrivacyInfo.xcprivacy（自身 UserDefaults 與相對演出計時理由已核對）；正式配置確定後仍需以最終封存核對。沒有完成 App Store Connect 隱私申報或網路流量稽核。
2. 找不到 App 內隱私政策／支援入口，也尚未取得對外政策 URL、開發者／支援資料及 App Store Connect 識別確認；內購價格／商品、廣告供應商與付費契約／稅務／銀行狀態未查，先前 NT$60 只保留為新方案的價格候選。
3. 包內圖像、BGM、SFX、語音與歷史模型仍有 pending 來源／發布註記。來源有 SHA 不等於商用授權成立。
4. 完整三職／黑白抽測、新人獨立操作、三進階關與 iPad 本輪實機操作未完成。旧 BOT-P1／P2 證據只用來挑選風險場景，不替新版判死刑或宣布修好。
5. 開發簽名不能替代上架封存與 Apple 處理結果；Bot 研究入口／語音發布配置未決。新局新版技能已採用，不再列為未決。

## 範圍與回復

R0 僅來源封存、盤點及草稿；其 REPORT／ZIP 保留不變。R1 新增首頁可見入口與隱私資源，更新兩份 UI 測試，建置並安裝 iPhone 1019。沒有改 Domain、AI、存檔、素材、聲音偏好或 App Store。沒有 commit、push、merge、TestFlight、送審或發布。

後續只修：崩潰／鎖死、資料損壞、錯誤資源或勝負、無法進入／結束內容、重要操作不可達，以及必要發行資料／權利缺口。一般美術偏好與新內容留到後續。若回復，從新來源 ZIP 在另一隔離目錄建置，不 reset 其他工作樹、不卸載／清空現有 App。

## 查核來源

官方頁於 2026-10-11 核對；是要求依據，不是 Apple 已審查本 App：

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)：2.1 裝置穩定性、2.3 真實 metadata／截圖、4.2 足夠娛樂價值、5.1.1 App 內與商店隱私政策。
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)：依實際資料行為申報，公開政策 URL 必填；本機保存與外傳要區分。
- [Required reason APIs](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)：R1 已核對完整類別／理由定義與實際用途；UserDefaults CA92.1／SystemBootTime 35F9.1 的用途及限制見 PRIVACY_AND_RIGHTS.md。
- [SDK 最低要求](https://developer.apple.com/news/?id=ueeok6yw)：2026-04-28 起 iOS／iPadOS 26 SDK 以上；現有 SDK 26.5 不需為此提高 iOS 17 deployment target。仍需查當時可上傳的工具鏈與封存。
- [Manual release](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/)：審核與手動公開可分開。此處僅記為目標，未替 Owner 選定 App Store Connect 發布設定。
