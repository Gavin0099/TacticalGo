## 2026-10-11 23:31 更新：1.0／1025 已送審，未公開

正式 Xcode upload exit0；App 1.0（1025）與 NT$60 永久解鎖在同一 submission 正式提交，Apple 兩項均等待審查。Owner 已確認英雄原图自行生成，內容版權及出口合規完成。維持台灣免費下載＋前三場完整對局＋自願獎勵廣告／永久解鎖，審核後手動公開。沒有 runtime、規則、資料格式、聲音偏好或遊戲 repo merge 變更。256 個簽名來源輸入核對一致。

下一階段：Apple 審查與正式交易／廣告／雙機 RC 實測；不宣稱公開、核准或 production 服務已可用。證據：`artifacts/release-submission-1025/APP_REVIEW_SUBMITTED_1025.json`、`REPORT.md`、`submitted-waiting-review-1025.jpg`。以下舊阻擋為歷史。

---

## 1.0／1025 正式封存與商店媒體里程碑

審核電話已保存，Apple 隱私由 Owner 本人發布；Apple Distribution archive、26 項本機核對及 IPA export 全部成功。五張 1025 原生 Release Simulator 商店截圖已上傳並重載確認。此輪僅修改封存腳本及 App Release target 簽名範圍，未改 runtime／棋規／玩法；先前封存失敗和舊證據保留。

上傳 exit70：Failed to Use Accounts，等待 Xcode 既有 Developer 帳戶登入／驗證；最早 B-v01 原圖來源亦待 Owner。正式 Sandbox／production UMP和廣告／最終真機RC未驗。繼續保持台灣首發、手動公開、原存局與穩定版本，未提交審查／merge／公開 App。證據：artifacts/release-submission-1025/BUILD_1025_DISTRIBUTION.json、STORE_SCREENSHOTS_SAVED_1025.json、MANUAL_UI_1025.json；以下為歷史。

## 1.0／1025 配置驗證里程碑

Release arm64 Simulator 已建置、配置核對及首頁啟動；正式簽名/交易/真機/上傳/送審未完成。Mac 鎖定及 Owner 的隱私發布確認、審核電話、英雄原始圖源為當前阻擋。保留 Apple 草稿、素材證據及手動發布，未 merge。詳見 artifacts/release-submission-1025/BUILD_1025_SIMULATOR.json 與 REPORT.md。

## 上架準備最新進度（2026-10-11）

Apple 商務有效、台灣免費下載與 NT$60 永久解鎖、公開政策及 UMP 訊息已備妥。內購審核圖已存 Apple；1.0/1025 正式配置及來源 hash 已準備。隱私發布法律確認、Apple 審核電話、英雄最早圖源待 Owner；正式 archive／外部 Sandbox／最終媒體／送審尚未完成。不以本機測試替代公開上架。

## 2026-10-11 發行帳戶啟用里程碑

Owner 明確確認上架；Apple付費協議／銀行已有效、三稅務完成。公開支援與政策匿名可達；免費App＋台灣TWD60非消耗解鎖＋台灣供應已保存。UMP訊息與內購審核圖已保存，隱私草稿／實際服務驗證／正式RC及審核聯絡仍需完成。保持手動發布、1023穩定真機與1024凍結來源；未上傳或送審。證據：`artifacts/release-submission-1025/REPORT.md`及`docs/release-01/account-release-evidence.json`。

## 2026-10-11 21:11｜三份稅務完成，協議與銀行待處理

Owner 回覆「都簽完了」後，實際 App Store Connect 商務表確認台灣、US Certificate 與 W-8BEN 均「已完成」；付費協議及銀行均「正在處理」，不再要求本人重填。Apple 提示銀行更新可能24小時後顯示；尚不能宣稱協議有效、收款或首版可發布。保存去識別化狀態於 artifacts/release-submission-1025/BUSINESS_TAX_COMPLETE.json，沒有保存表格答案或銀行資料。網站公開範圍、NT$60解鎖與台灣供應已重新提出兩項具體問題，仍待答覆；不假填正式URL或擅定商品地區。後續瀏覽器分頁被關閉／CDP連線逾時，沒有新增ASC表單儲存、build或送審。現有發行profile與已通過限定原生測試保留，不重跑或重複累計；遊戲未commit/push/merge/發布。

## 2026-10-11 18:42｜AdMob App／獎勵廣告已建立

已在登入的 AdMob UI 建立 iOS、尚未上架的「皇冠戰略」App，及自願觀看的獎勵廣告；重新開啟設定確認獎勵為 1 場對戰。公開識別已同步至帳戶證據及 Release.accounts-draft.xcconfig，沒有接到 Xcode 預設配置，也沒有修改或重建凍結1024包。AdMob帳戶驗證仍待完成，App需上架後連結商店並接受審查；建立單元不是可正式放送的證據。Apple商務重載後付費協議仍為「新」，頁面要求本人在簽署前更新法律實體。未調查或提交銀行／稅務、未接受契約。接續完成此遊戲policy/support與UMP、商品定價metadata、Sandbox、發行簽名／雙機及產品權利驗收；未上傳、送審或發布。實際證據見 artifacts/release-accounts-1024/ADMOB_APP_UNIT.json。

## 2026-10-11 AdMob 付款診斷更新

Owner 已完成 AdMob 註冊；首頁任務確認「付款資料設定完成，您的帳戶已就緒，可送交審核」。原紅色未完成提示在重新載入後消失。姓名／地址已有值，電話明確標為選填；身分驗證目前未要求。帳戶仍審核中，銀行／稅務未查，遊戲 App／rewarded unit／UMP 尚未建立；Apple 商務仍依前次未完成狀態，不能視為全部帳戶 Gate 通過。僅查看與重新載入，沒有填寫／儲存／提交收款資料。[診斷證據](../artifacts/release-accounts-1024/ADMOB_PAYMENT_DIAGNOSIS.json)。

## 2026-10-11 帳戶接續：App 與永久解鎖草稿已建立

Owner 已登入；已核對 Team P358EB3X9H 並登記既有真機 bundle com.tacticalgo.prototype.herobody。ASC「皇冠戰略」App ID 6821588889、SKU CROWNTACTICS-IOS-01；non-consumable com.tacticalgo.crowntactics.unlock（IAP ID 6821589396）及中文說明已建立。版本1.0草稿已核對手動發布、不要求遊戲登入；不是已上傳1.0 build。

Apple 付費協議顯示「新」；法律實體／稅務銀行由 Owner 完成。AdMob 仍停註冊條款頁，未接受或建立帳戶。定價／地區、正式廣告IDs／UMP、公開頁面、Sandbox、簽名封存及產品／權利 Gate 未完成。本次只有帳戶草稿與交接文件，沒有程式、真機、commit／push／merge、上傳或發布。[實際帳戶紀錄](../artifacts/release-accounts-1024/REPORT.md)。

以下1024工程證據與更早決策保留為歷史，不把「ASC待登入／商品尚未建立」當最新狀態。

## 2026-10-11 最新進度：1024 商業接線候選

Owner 核准持續做到可上架，免費額度前三場完整對局。1024 已實作獨立 ledger、StoreKit 2 永久解鎖／恢復、真正 Google rewarded／UMP 接線；舊付費下載與「無 SDK」盤點僅適用歷史 1023。

教學／九個挑戰免費、舊局可續玩；不改棋规、AI、存局格式、已接受 UI 或聲音偏好。Release 排除未通過英文語音／3D model／研究入口，BGM／SFX 保留。不以 fake reward 或 paid 布林解鎖。新測試／限制見 [1024 報告](../artifacts/monetization-02/REPORT.md) 及 [方案](release-01/FREEMIUM_PLAN.md)。

正式商品／AdMob IDs／遊戲公開 policy/support URLs 尚缺，Release 不回退 sample。ASC 待 Owner 登入；已核字樹花園公開 Email／Copyright，工程 Team 不等於契約就緒。Sandbox、distribution archive、雙機、產品與權利 Gate 未結案。沒有 commit／push／merge、TestFlight、送審或發布；不覆蓋既有 1023 真機。

以下保留歷史；現行狀態以上段與 1024 報告為準。

> 2026-10-10 Owner 最新回饋：三職細線／光圈 VFX「有點弱」，視覺不通過。依據 Vortex 有限多段粒子及 Pow 分層研究，製作更清楚的蓄能／方向傳遞／局部撞擊強化候選；不增加音樂、語音、規則或第二技能。唯一法師演出時間表調整，但總長仍950/760ms。研究及驗證：artifacts/ios/vfx-three-classes-01/research/DECISION.md；Native/Owner Gate 分開回報。

# Tactical Go｜職業導向戰術原型 PLAN

## 2026-10-10 — 三職 VFX 開工授權（取代先等全部本體核准的啟動限制）

Owner 明確要求「開始做三個職業的特效」：在既有 Cozy-02、B-v02 與已完成本體上依序執行 VFX-W1 築壘、VFX-M1 原版一格魔法之手、VFX-R1 換位。只接成功 before/action/outcome 收據，預覽輕量、捕獲依正式 payload、共用既有演出時鐘；取消／復原／重開／背景／Bot／Reduced Motion 回歸。三職完成後交正常速度完整棋盤、7×7／9×9 稀疏密集、黑白及條件提子原生影片供 Owner 看，不自動延伸第二技能。

此授權只開啟特效工作，不代表戰士／三職本體、整體美術或英雄語音已正式驗收。英文英雄語音維持 HOLD／關閉；不修改 Domain、Bot、AP/Mana、技能、人物原畫或投影，不新增配音。隔離分支 codex/vfx-three-classes-01 可必要 commit/push，不 merge、TestFlight 或發布。工程與真人觀感、模擬器與真機分別報告；完整候選證據見 artifacts/ios/vfx-three-classes-01/REPORT.md。

以下日期相同的舊「本輪不開 VFX」條目為歷史決策，不覆蓋這次 Owner 新授權。

## 2026-10-10 — 角色動作與特效順序（最新 Owner 決定）

先將 M3 原畫分層與成功收據播放流程寫為 `tacticalgo-cutout-animation` Skill，再完成 ANIM-W1 戰士及 ANIM-R1 盜賊本體候選。本輪到此停止，交正常速度完整棋盤原生錄影給 Owner；不直接開始 VFX。

後續依序：VFX-01 法師魔法之手（蓄能、短符文、方向能量、目標衝擊、落定）→ VFX-02 戰士盾牌震波／雙兵登場及盜賊短殘影 → SFX、輕量觸覺與英文語音時點整合。M3 人物呈現方向已接受，正式美術及本輪動作仍待人工驗收。本輪英文語音關閉、既有 SFX 可留；不修改 Domain、Bot、AP、Mana、提子、技能或投影。保持黑白薄底座／外側形狀標記；隔離分支可 commit/push，不 merge、TestFlight 或發布。完整 Slice 與 Gate 見 `docs/ios/SLICES.md`。

## 2026-10-14 最新TestFlight交付1110

Owner完成Xcode登入後，1110（含P32提示修正及1109聲畫改善）已成功上傳/Apple處理/加入既有Owner1.1群組，實際正在測試。源274/簽名/54素材/兩怪像素核對與P30/P32既有測試分開保留；Owner從TestFlight更新，手機實際安裝與真人品質未驗。舊1103/4/5/6保留，不新tester、不動1.0審查/Git/公開發布；heartbeatPAUSED、成功包不重傳。交付證據testflight-33/DELIVERY與ready screenshot。

## 2026-10-14 八Slice品質計畫核對／UI首修

1106歷史TestFlight、1108最後Owner接受手機與1109最新未交付候選已分開；十小時窗口已結束，heartbeat維持PAUSED。依Owner新八Slice方向，先保留1109來源274和兩簽名包，恢復1106 Simulator八圖，核對已有UI20/動作/混音而不倒退重作。UI首修只消除法師合法預覽後仍要求選點的同屏矛盾；1110正式Beta主2/小1（兩種方法）0fail0skip、主小圖與獨立只讀review保存，無字級/棋盤/規則/聲畫素材變更。完整八項映射PRESENTATION_32_PLAN、實際交付PRESENTATION_32_REVIEW；PRES-00真機含聲、FPS、真人品質仍未完成。1110僅Simulator未簽名/手機/TestFlight，原1109上傳仍待Xcode帳戶權限；無新Git發布，不重啟舊窗口。

## 2026-10-14 持續聲畫優化窗口

Owner回報1108畫面／音效好很多，授權十小時UI／動畫／音效優化至台北09:54:08；AUTONOMOUS_27_PLAN.md與最新v11/PLAN為接續合約，heartbeat已更新ACTIVE。P27受限技能牌／共用只讀原因完成，282Swift／Beta3／小Debug2通過且0skip，原生圖與同局面1108對照已保存；P28動作／P29聲音／最終真機交付仍待，不能當全部完成。iPhone保持1108到窗口末，無規則／AI策略或Git／TestFlight發布。

## 最新交付：2026-10-13 Mac整理與UX26手機1108

Native25完成UI20／AV21–24原生整理並Wi-Fi交付1107；Owner三項回饋進入UX26，恢復合法綠色落點、技能逐步引導／限制，直接預設沿棋群築壘＋調度己兵，solo／雙人／Bot／新存局一致。舊紀錄保留原規則。Swift277/0、Beta6/0＋小Debug3/0及49個真AVAudioPlayer審核通過；1108已簽名、Wi-Fi安裝及啟動，既有7存局／5偏好檔全保留。來源06c534c＋當前本機修正，未新增commit／push／main合併／TestFlight上傳。完整交付見docs/v11/OWNER_REVIEW_26.md、最新docs/v11/PLAN.md與artifacts/v11/ux-26；真人清晰度、聲畫品質／FPS及90%品質目標仍待驗收，heartbeat保持暫停。以下保留歷史計畫，不以舊狀態覆蓋此交付。

## 目前工作：BOT-01 單人電腦對戰（2026-10-09）

Owner 核准第一版 Swift 電腦對手，取代早期「不做 AI／等待真人」限制；只限 BOT-01。已有核心與 SwiftUI 可玩版直接沿用，不重做移植。Bot Agent 負責獨立 TacticalGoBot、有限完整回合搜尋、固定戰術測試；本 Agent 負責必要單人入口、背景執行、逐步下棋演出、過期決策防護與原生驗證；Visual Agent 繼續獨立美術。

工作隔離於 `codex/bot-01` managed worktree；以現行未提交 Swift/iOS 凍結快照為基線，來源與 SHA 見 artifacts/bot-01/baseline-source-manifest.json，不能聲稱這些基線檔案已在 Git HEAD。正式 7×7 玩家執黑、電腦執白；兩方可選現有三職。原 Domain、候選素材、R2 預設與第二技能均不改。

交付合約與重現指令見 docs/ios/BOT_01.md；最終測試、合法對局與限制見 artifacts/bot-01/REPORT.md。工程交付不等於 Owner 遊戲性通過：密集盤面跳過回合、有限反應搜尋漏招、固定英雄位置皆保留觀察。BOT-02／03 待 Owner 驗收，不自行開工；不 commit/push/merge/發布。

## 2026-10-09 — iOS／Visual雙軌：IOS-V2-ASSET-01

Owner要求V1完成後继续Swift／SwiftUI程式，不繼續畫静態比較稿。已核對SW1／SW2都有实际可执行交付，直接做V2素材接線：独立TacticalGoVisuals metadata validator、原生整包載入／拒絕fallback、板面／陰影／黑白單位／三職Token／人物卡接線。另一Visual Agent負責美術與動畫素材；共用交接規格docs/ios/V2_ASSET_CONTRACT.md，尚未替換未核准素材。第二技能不實作、R2不改預設；动画adapter后续独立Slice，既有MotionPlan沒有Magic Hand cue不能冒稱完整支持。验證见artifacts/ios/v2-asset-interface-v01/REPORT.md。

## 最新 UI 工作：V1 A0 靜態畫面與技能資訊層級（2026-10-09）

Owner 正面試玩回饋為好玩度高，核准開始 UI 進化；G5仍保留後期技能可用性缺陷與真人驗收待辦。此輪只交付 V1 畫面規格、一般／技能預覽／主將危險的390×844與320×568對照，并补7×7／9×9，共12張靜態設計稿。第二技能進入獨立 Draft，先試高 Mana 4–5、1 AP、與普通技能共用一次限制，效果尚未核准或實作，稿面沒有假大招按鈕。另一Agent製作棋盤／Token美術，這裡僅做資訊層級／尺寸與合法狀態示意，不重啟3D人物。

現有Swift核心／iOS可玩版不重做移植，UI整合排單獨V2。文档 `docs/ios/V1_A0_UI_SPEC.md`、`docs/r2/SECOND_SKILL_DESIGN_BRIEF.md`；交付 `artifacts/ios/v1-a0-ui/`。Owner也核准iPad安裝，但Mac尚未偵測到iPad、Owner回覆稍後再連接；未安裝、未宣稱平板驗收。390／320全覽設計不代替9×9真機密集選點，需原生放大／格點清單验证。

## 最新試玩後工作：R2 技能候選（2026-10-09）

Owner 試玩發現戰士／法師在密集局面失去作用，核准小型 R2 候選，沒有核准正式替換技能。已完成 A／B／C／D opt-in Swift 核心、八個固定局面 32 對照、13 項 R2 回歸與一段雙英雄回應腳本；原預設跨語言 Golden 一致，手機版 UI／安裝版本維持。戰士前置相連棋串築壘有一個 AP 效率例子與單子補氣反制；法師異色交換有遠程直接提主將及有限反制不足的風險。結論與驗證見 `artifacts/r2/REPORT.md`，合約見 `docs/r2/PLAN.md`。不做正式規則採納、大型平衡搜尋、英雄一般移動或 G1–G4 UI 擴充。

## 當前優先工作：iOS 可玩版（2026-10-09）

實作完成候選：選角、本機雙人、三職、四個練習、7×7／9×9、勝負與完整復原。Owner 試玩回饋已補常駐行動方／職業、行動中／等待，並統一黑白方命名、主將／英雄底座與文字標記。驗證與尚待 Owner 實機可讀性判斷見 `artifacts/ios/playable-a0-v01/REPORT.md`。

Owner 已玩過 Windows，明確要求直接完成 iOS。採 A0 原始 B-v02 卡＋A Token；移植已實作的 Windows G1–G4（codex/gameplay-g1-g4 @ 54deef97），不以 main 舊 UI 判定 Gameplay 尚未實作。Swift 核心補 Magic Hand，正常啟動改為選角／新對戰，舊 3D 只保留研究入口。實作計畫、跨語言與原生驗證記錄於 `artifacts/ios/playable-a0-v01/`。不宣稱 G5 遊戲性、正式素材權利或 App Store 發布驗收。下方先前排程以此指示為準。

> **最後更新**: 2026-10-09
> **Owner**: Gavin0099
> **Freshness**: Sprint (7d)

> 版本：Draft v0.1（2026-10-08）  
> 定位：規則與遊戲性驗證計畫，不是 v2.0 全量實作承諾  
> 來源：使用者提供的《Tactical Go — Official Rulebook v2.0》與既有 Notion Unity 原型  
> 決策：**保留戰士、法師、盜賊三種職業差異；暫緩卷軸、聖物、12 件紅龍神器與大量美術。**

## 1. 產品目標與待驗證假設

**核心概念：** 在圍棋「氣／包圍／提子」的共同規則上，利用每回合有限行動點（AP）及不同職業的獨特操作，做出值得取捨的戰術決策。後續才加入可預測、可誘導的紅龍環境威脅。

**核心假設 H1：** 不同職業能讓相同棋局出現不同但合理的解法，而非只有數值差別。  
**H2：** 2 AP 能創造「進攻／防守／技能」的抉擇，而非讓先手不公平地連續提吃。  
**H3：** 即使尚未加入紅龍、神器、動畫，玩家仍願意討論或重試戰術。  
**H4（後續）：** 紅龍的行為可預測、可誘導，會改變走法而不只是增加隨機懲罰。

**非目標：** 第一版不追求完整地盤計分、AI 對手、線上配對、13×13、職業被動全套、DC 擲骰、抽卡掉寶、技能樹與正式商業化。

## 2. 首個可玩版本：Tactical Go Lite

| 設定 | Draft v0.1 規格 |
|---|---|
| 棋盤 | 9×9，起始雙方主將對稱預置；具備可選的中盤情境盤面 |
| 玩家 | 本機雙人輪流；無 AI 對手 |
| 行動 | 每位玩家每回合 2 AP；落子、召喚、施法各 1 AP；可提前結束 |
| Mana | 初始各 3，每位玩家回合開始 +1，上限 6；暫不加星位收益 |
| 職業 | 戰士／法師／盜賊三選一；每方場上最多一名英雄；英雄和士兵依同一套氣規則被提吃 |
| 技能 | 每方每回合最多施放一次；技能先不用 DC／骰子，結果必須可預測 |
| 勝利 | 提吃敵方主將立即獲勝；測試局達約定回合上限仍未斬首則記和局，不把暫定規則冒稱正式地盤計分 |
| 提子時機 | **每個原子行動後立即結算**，不可同時保留「整回合才提」的另一套規則 |
| 紅龍 | 暫不加入 v0.1 的第一輪 A/B 測試，等職業核心通過再新增 |

備註：9×9、Mana 上限、起始座標、回合上限與下列技能數值皆為**試玩候選**，不是已確定平衡的正式規則。

### 職業設計：三職都保留，但每職先只做一招

| 職業 | 戰術定位 | Draft 招牌技能 | 初始成本／技能成本 | 想驗證的決策 |
|---|---|---|---|---|
| **戰士 Warrior** | 前線擴張與防守 | **築壘**：選擇戰士上下左右相鄰的兩個合法空點，於同一原子行動放置兩顆己方士兵 | 召喚 2 Mana；技能 1 AP + 2 Mana | 花資源取得局部行動效率，是否值得犧牲其他行動？ |
| **法師 Mage** | 區域控制與封路 | **封印**：指定距離法師曼哈頓距離 ≤2 的一個空點，禁止對手在下一回合於該點落子；該點仍算空點／氣，敵方回合結束後解除 | 召喚 3 Mana；技能 1 AP + 2 Mana | 是立即包圍，還是封住對手下一步的補氣點？ |
| **盜賊 Rogue** | 換位與破陣 | **換位**：與上下左右相鄰的一顆敵方普通士兵互換位置，再依標準順序結算提子；不可換主將或英雄 | 召喚 2 Mana；技能 1 AP + 2 Mana | 是否值得犧牲自身位置，破壞對方既有棋形？ |

**能力約束：** 三招都必須提供可視化施放範圍、結果預覽與明確失敗原因；任何不合法施放都不得扣 AP、Mana 或部分改變棋盤。戰士的雙落子、法師封印與盜賊換位須被視為單一原子行動，先驗證，再一次套用，再結算。技能強度尚待實戰調整，尤其要留意築壘可能過強。

**暫緩原規則：** 戰士「兩條命」、法師「隕石／時間扭曲」、盜賊「煙霧彈」、所有職業 DC 判定，均留在 v2.0 backlog，不能暗中與 Lite 混用。

## 3. P0：先凍結可執行規則（未過不得加內容）

- [ ] 統一 **每個 AP 行動立即提子** 或改採回合末提子；此計畫暫選前者，需先檢查 2 AP 平衡。
- [ ] 定義同色不同單位（主將、英雄、士兵）如何連成同一棋串與共用氣；本案暫採四方向正交連通。
- [ ] 明確自殺著、打劫／重複盤面禁止、Pass、平局與主將死亡的判定順序。
- [ ] 明確主將初始座標、星位用途、召喚英雄的合法位置；原「必須接氣」須改寫成可測試的格位條件。
- [ ] 定義兩顆棋同時放置、敵我換位、封印狀態到期的原子性與回滾。
- [ ] 盤面上提示目前 AP、Mana、棋串氣數、技能可選目標與威脅，不能要求玩家記憶隱藏規則。
- [ ] 暫不實作「永久 +1 虛擬氣」、紅龍受傷／死亡、無限 0 AP 卷軸等未閉合規則。

## 4. 開發切片與驗收 Gate

### 2026-10-09 正式主線調整（Owner 已核准）

**V1 ∥ SW1 → SW2a → SW2b → V2 → A1–A5**。iOS／Swift 為正式產品；Windows／C# 保留玩法實驗、規則基準與回歸驗證。下列 S0–S5 的規則與真人玩法 Gate 保留，但舊的「Windows 動畫先行／S1 Accepted 才移植」執行前提作廢。

逐 slice 交付、依賴與驗收見 [Swift slices](ios/SLICES.md)，視角與素材配置見 [V1 規格](ios/VISUAL_SPEC.md)。本輪已建立純 Swift 核心、共用 Golden／完整事件對照、7×7／9×9 復原與原生雙渲染比較原型；正式視覺、真機與完整產品流程仍待驗收。原有 A1–A5 範圍保留，執行平台改 iOS。

2026-10-09 Owner 後續要求先接美術：SwiftUI／SpriteKit 棋盤導入戰士、法師、盜賊既有全身候選，人物卡保留半身圖；士兵為黑／象牙棋石，主將為皇冠棋石。保留交叉點 anchor 與點選判定。iPhone SE 的 9×9 角色較小，細節與真機辨識仍待驗收；來源與檢查見 `artifacts/ios/art-integration/`。


2026-10-09 Owner 再明確要求皇室戰爭式真正建模：新增 RealityKit 原生真 3D 候選作預設，三職為程序網格與實際光照／材質，提供近距離前後旋轉檢視，保留兩個 2D 渲染器比較。新切片 V1-3D-01／SW2a-3D-01／V1-3D-02；規則不動，正式模型精修、骨架、動畫與真機 Gate 仍待驗收。


### S0｜純規則引擎（不做美術）

**交付：** 獨立 C# Domain：`GameState`、`BoardRuleEngine`、`TurnEngine`、`ActionValidator`、`ActionResolver`、`ActionEvent`；可不啟動 Unity 執行測試。每個行動採 `Validate → Apply atomically → Resolve captures → Emit events`。

**驗收：** 正確處理連通群組與氣、合法落子／自殺、打劫、提子、回合切換、2 AP、Mana、主將死亡、失敗行動不改狀態；固定情境可重播且得到相同結果。至少包含「同一回合連下兩手是否造成無法反應的提子」的測試情境。

**決策 Gate：** 先比較 1 AP 與 2 AP 的基本棋局；若 2 AP 造成顯著的無解先手斬首，應調整行動規則，不強行保留 2 AP。

### S1｜三職業招牌技能

**交付：** 戰士築壘、法師封印、盜賊換位；召喚成本、技能成本、施放範圍與限制。每職至少準備兩個可展示差異的中盤局面，包含成功、非法操作與反制方式。

**驗收：** 三職業技能結果正確、無免費無限施法、英雄死亡後不能再施法、重複盤面不破規則；戰士與法師、法師與盜賊、盜賊與戰士都能形成可預測的相互制衡情境。不得以「每職技能都能成功觸發」充當「職業好玩」證據。

### S2｜9×9 可觸控試玩介面

**交付：** 棋盤、主將與三職識別、點擊落子、技能選目標、合法位置提示、氣數提示、AP／Mana 顯示、簡單結算動畫、上一步事件紀錄、本機兩人切換。

**驗收：** 手機縱向操作不依賴精準像素點擊；玩家不看規則書也能分辨「現在誰走、剩幾 AP、技能能做什麼、為什麼不能下」。動畫不能阻塞過久，首輪只做清楚的提子、技能與主將落敗回饋。

### S3｜真人策略驗證（第一個產品 Gate）

**交付：** 6–8 場有紀錄的試玩／對局；盡可能混合有圍棋經驗、策略遊戲玩家與新手。以固定中盤局面比較「無職業」、「不同職業」，記錄提示、選擇、對局時長與理解情況。

**觀察重點：**
- 玩家能否不靠提示，描述自己選戰士／法師／盜賊的原因？
- 同一局面是否出現兩種以上合理策略，而不是永遠有單一最佳解？
- 職業是否真的改變選擇，還是只是在同一棋局多按一個技能鍵？
- 輸掉後是否想用不同職業或策略再戰，並能說出想修正之處？
- 是否存在明顯的必勝開局、技能循環、先手優勢或無法理解的禁著原因？

**Gate：** 由 Owner 根據實際行為判定 `GO / REVISE / NO-GO`；軟體測試全部通過不得自動升格為「好玩」。樣本少，只作原型方向判斷，不外推為市場接受度。

### S4｜紅龍實驗（僅在 S3 通過後）

**交付：** 天元紅龍、怒氣、明確預告的火焰方向、一次三格直線推擠／撞擊。第一版不含紅龍生命、掉寶、神器、機率加權。先用固定事件讓玩家確定能推理及誘導。

**驗收：** 玩家能在噴火前指出危險格；至少存在「保住自己」與「利用龍息攻敵」兩種合理選擇；各職業有不同應對方式，且龍息不造成無預警斬首。若紅龍只是隨機清子，就不進下一階段。

### S5｜決定完整遊戲方向（需要另外核准）

只在 S3／S4 得到正面玩家證據後，才依序評估：13×13、征服地盤計分、職業被動與第二技能、紅龍受傷與神器、卷軸、主將聖物、AI 對手、線上對戰、角色動畫與美術。每次只增加一種會改變決策的機制，不以內容數量作進度指標。

## 5. 工程與測試原則

- **規則先行、畫面後行：** UI、音效、動畫都是 Domain 事件的呈現，不反向決定提子與勝負。
- **不可部分提交：** 非法落子／技能失敗須完整回滾，不得事先發送怒氣或視覺事件。
- **事件可重播：** 記錄玩家、座標、AP、Mana、技能、提子、回合編號與結果，方便定位平衡與規則錯誤。
- **測試分兩層：** 規則正確性由自動測試守護；是否有趣、是否能理解由人類試玩守護。
- **不沿用錯誤假設：** 既有 Notion `GoBoard.cs` 每次落子立即提子；規則書第 5 章寫在 Resolution 提子，必須統一。`BoardInput.cs` 目前是輪流點一子的測試輸入，未形成完整 2 AP；`TurnManager`／`SkillManager`／`RageSystem` 在可見頁面主要是架構圖而非完整程式。
- **獨立產品：** 不直接合併至 `SnackDelivery`；避免兩款玩法互相污染。

## 6. Stop / Pivot 條件

如遇以下任一狀況，停止增加內容，先修正核心：

1. 玩家選擇職業後，最佳走法幾乎沒有不同。
2. 2 AP 讓一方難以合理反制，且調整成本過高。
3. 大量時間花在記住例外規則、DC、狀態標記，而不是做戰術選擇。
4. 紅龍造成主要是不可預測的壞運氣，而非可利用的風險。
5. 玩家看懂規則、能完成對局，卻不想再試其他戰術局面。

## 7. 下一個最小行動

**直接執行 V1＋SW1，Swift／iOS 為正式主線。** 已核准三種 iPhone 比例畫面、純 Swift Package 與 Golden 等價驗證；先完成本輪候選的視覺核准與規則等價，再進 SW2a 真機點選／渲染技術 Gate。規則 Draft 與真人策略驗證保留，不因移植測試通過就視為平衡正確。

---

### Design Decision Record

- **2026-10-09 接受：** iOS 正式主線；Windows 驗證平台；V1／SW1 並行，SW2 分為棋盤技術與完整玩法兩個 Gate。
- **2026-10-09 候選：** SwiftUI 介面＋SpriteKit 棋盤；實際選型待與 SwiftUI 原型、真機操作比較。視角參考皇室戰爭的斜俯視與厚底座。
- **2026-10-09 驗證風險：** 9×9 小螢幕手指選點、正式人物 token 遮擋與性能仍待真機；本機 Golden 等價不能證明 Windows toolchain 執行或職業平衡。


- **接受：** 職業差異是產品重要賣點；三職都進第一個職業原型。
- **接受：** 每職先有一招改變盤面狀態的招牌能力，而不是三職各做兩招和被動。
- **待驗證：** 2 AP、職業技能數值、9×9 雙人對戰與原定的主將勝利模式。
- **延後：** 紅龍的完整版本、所有神器／卷軸、隨機 DC、職業被動與 13×13 正式規則。

## 2026-10-09 建模與動畫優先進度

Owner 附件指定目標後，約 10 小時窗口改以模型與動作先行。已完成程序幾何精修及 rigid-part hierarchy 候選；落子、召喚、提子、三職技能、主將退場／勝利及封印到期從真實核心結果播放。七動作原生影片已抽幀檢查；最新八情境 iPhone17 行為 test PASS，SE compact 修正後完整5項 PASS。首次進入 model inspector 殘留 outgoing board 的缺口另加 lease 修正，focused 原生 screenshot 確認正确。

仍待：最新影片、近距離動作 QA、角色品質與三畫面 Owner 核准、完整對戰、真機／9×9 選點；不宣稱 UV／蒙皮／骨架 asset masters 已完成。狀態與失敗證據保留在 docs/ios/OVERNIGHT_WORK.md 與 artifacts/ios/animations-v01。持續執行至台北11:09:54的已授权窗口，不提交／推送／發布。

2026-10-09 02:31：建立真實網格與 rigid-pose USD候選匯出／native reload。三職面數25544／20904／22784，native static bounds與mesh count等價，pose資源各识別2个1.4秒动画；仍非skinned production master。面數預算與可編輯資源詳見 artifacts/ios/model-resources-v01/VALIDATION.md；模型品質工作繼續至既定窗口。

- 2026-10-09 02:54：三職 Blender 四骨工程與 native USDZ pose 候選已完成 round-trip，rigid single-bone weights；原生可見盾擊／抬杖／下蹲及返回對戰 UI 通過。工程／證據 assets/candidates/ios-3d-v01/resources/blender、artifacts/ios/blender-rigs-v01。Owner／真機／柔性關節 Gate 仍 pending。M2 閉合兜帽、面罩、披風、胸甲及握持造型修飾進行中，另存 v02。

- 2026-10-09 03:21：v02 三職骨架模型與閉合服裝造型已整合 iOS，兩尺寸 full UI 各7/7、Python11/11、實際八 shell topology、rig round-trip 通過。ModelLibrary 使用 .blend export package、ModelMotion 操作／還原關節；純 Core 未改。原生錄影和 M3 骨架／陰影／棋盤構圖續作；Owner、真機、9×9 手指與完整對戰 Gate pending。

### 2026-10-09 04:00 — M3 partial skin 與人物卡一致化

三職原創模型沿用 v02 meshes，法師／盜賊各192個衣袖頂點混合 body/arm，.blend 保留命名 edit selection groups；actual USD 權重最大1/2影響及六時間點 round-trip 通過。packed skeleton 法杖 socket 五 phase 原生對照通過，解決合併 mesh 後無 crystal Entity 的投射來源問題。此次 iPhone17 focused UI 2/2 PASS、Python validators14 PASS，55秒八動作 native tour 及大角度肩部 stress renders 已保留。人物卡改由相同模型 native render（3D renderer only）。證據 artifacts/ios/model-skin-v03/VALIDATION.md。下一片做場景建模／手機構圖；Owner、真機、完整有機 rig/UV 和玩法正確性 Gate 仍 pending，無 commit/push/release。

- 2026-10-09 04:05：新增原創 modeled garden arena，7×7/9×9 actual runtime mesh 匯出為 editable USD/.blend（46796/57932 triangles）；native點選／旋轉與模型 focused tests：iPhone17 2/2、SE1/1 PASS。相機新增透視 corner fit 保留旋轉邊界。SE9×9仍偏小，維持操作 Gate pending；繼續 native skill FX。evidence artifacts/ios/arena-v01/VALIDATION.md。

- 2026-10-09 04:35：手機試玩 layout 預設同屏顯示資源、3D棋盤、同模型人物卡、氣與技能操作；驗收工具收進設定選單。17 focused2/2；SE和局PASS、zoom首次closing-menu hitability FAIL保留，等待原生選單收起後focused1/1 PASS。兩尺寸各六張真實一般／技能／危險 ×7/9畫面人工 review；放大1.6倍保持中心規則坐標。evidence artifacts/ios/phone-layout-v01/VALIDATION.md。真機手指、panning、大字／VoiceOver、Owner核准仍pending，無提交／推送／發布。下一片加強投射／落點FX、對戰結果及近距離動作。

- 2026-10-09 04:37：封印白芯/光暈/18 mesh弧線尾跡/落點脈衝原生影片確認；native emitter貢獻未隔離不宣稱完成粒子驗收。SE八動作方法1/1、Skip/離場1/1；Swift15 PASS。真實last-turn和局與主將capture勝負UI、undo/new-match已加入，17win1/1 PASS、SEwin進行中。v03近距離影片見披風穿腰帶，因此v04修正clearance並接續UV/材質；不改Core/Windows規則。evidence artifacts/ios/effects-v01/VALIDATION.md。持續至11:09，不提交發布。

- 2026-10-09 05:08：v04披風clearance/背袋與1024 UV原創色彩圖已bundle；初次薄面漏色與第二次linear→byte sRGB偏色保留，明確transfer修正後有限coverage 0缺口。19 Python、兩尺寸各full10 UI PASS、native4骨bounds/socket/sha對照通過。SE Documents的imported review仍舊v03，接續v04 focused回歸。evidence artifacts/ios/model-surfaces-v04/VALIDATION.md。近距離self-shadow specks／完整organic rig／Owner與真機仍pending；連續27個真實動作跨回合回放進行中，不改Core。

### 05:15 — 從開局到兩方勝負的連續動畫已驗證

戰士／法師16步9回合、盜賊／戰士11步6回合均從newGame沿actualGameSession結果播放，原生兩段影片／完整trace保留。兩尺寸各focused1/1 UI PASS，覆蓋Skip、undo、Reduced、reset、返回原棋局；Swift17 PASS。SE最新v04 imported model另focused1/1 PASS，修正先前拼錯method selector未執行之缺口，原命令／logs保留。證據 artifacts/ios/full-match-v01/VALIDATION.md。

配合走法只支持presentation QA，真人完整對戰與Owner／真機Gate不升格。接續實際腿部關節／腳底定位、boot輪廓與職業造型精修，另存新版本；11:09截止前繼續不提問、不提交發布。

### 05:40 — v05 十骨腿部／腳底定位完成候選驗證

三職thigh/calf/foot鏈與新靴底已bundle，Blender nested-parent evaluation首輪8.48mm偏差修正後六時點全頂點<4.8e-7m，原failure保留。Swift19／Python20 PASS、三職native10骨bounds與36foot samples＋3reset PASS；兩尺寸完整UI各11/11（imported Documents均v05）。同一native view的八動作×三phase×三種結束共72狀態還原PASS，三職技能27樣本確實變形後回穩。12張新版normal/skill/danger ×7/9 ×兩尺寸人工review通過；v04 SE SpringBoard失敗保留，新capture用unique readiness token與installed hash guards，不能把結構ready當pixel PASS。evidence artifacts/ios/leg-rig-v05/VALIDATION.md。

十骨rig仍是有限剛性腿與肩袖blend，表情個性、近距離shadow specks、9×9定位／真機／Owner風格Gate仍待。接續三職面部輪廓與原生光影精修，保持source／UV／pack／native對照；Core與C#規則不改。窗口11:09:54前不提問、不commit/push/發布。

### 06:00 — v06 整合中與 iOS18 啟動風險
三職獨立閉合臉型、斜眉、戰士偏側髮型、法師鬍髮已匯出並完成實際蒙皮／UV／原生前背面 QA。原 SE 手動啟動有 Metal 與 CFPreferences 兩種崩潰 stack，乾淨隔離 SE 八次啟動均成功，但根因未證實，原紀錄／資料保留。capture 在 ready 後也驗證 process 存活，避免 SpringBoard 被當成模型交付。shadow bias 三組未顯著改善黑點，正式照明保持原設定；新版 bundled 回歸接續。

### 06:07 — v06 三職個性與同模型卡片完成候選
三職閉合臉型／斜眉／戰士偏側髮型／法師白鬍髮已整合；同USDZ透明人物卡與32/48/64原生token review保留。native10骨／36腳+3reset／5杖頭socket／72實際中斷還原PASS，cleanSE full11、17 focused3 PASS，兩尺寸12張完整畫面人工查看正確。bias1/2.5/4未消除零星shadow specks，正式設定不改；原SE兩種啟動crash風險仍開啟，cleanSE八次啟動與fullUI成功不是根因修正。evidence artifacts/ios/face-light-v06/VALIDATION.md。接續普通棋子／主將原創模型與密集棋盤動畫，Core/C#不改，11:09:54前繼續、不提問提交發布。

### 06:16 — native封印光暈崩潰
cleanSE native tour在UnlitMaterial.blending觸發ShaderCache assertion，App ModelEffects.swift11在堆疊中；原影片／ips／incomplete trace保留，不能稱完整八動作錄影成功。改用透明emissive PBR halo，下一步重複原生封印／完整tour與實際pixel review。此風險與先前Metal／CFPreferences EXC_BAD_ACCESS分开，不宣稱共同根因。

### 06:30 — 原創士兵／主將與材質崩潰候選處理
PBR於06:22也在blending setter觸發同類assertion，先前PASS不能證明修正；改預載原創440triangle單一opacity0.25 USD光暈，cleanSE完整八動作與17封印原生trace及白芯／透明球／尾跡／落點實際影格通過候選。四款士兵／主將保留可編輯工程；runtime按材質合併30→8、38→9，native全頂點／actual extents誤差<6.2e-8m、72中斷還原PASS。首輪錯誤fixture与conservative AABB差異FAIL保留；兩尺寸完整UI及最新12畫面接續，不宣稱FPS/真機/Owner或global crash fix。evidence artifacts/ios/unit-compaction-v01、unit-models-v01/halo-crash.md。

### 06:36 — 普通單位／預載光暈完成候選驗證
17與cleanSE完整UI各11/11零fail/skip，12正常/技能/危險×7/9原生畫面人工review，compact units全頂點與72還原PASS。imported heroes Documents均v06，bundle/test hashes保留。原ShaderCache兩次failure仍在，預載halo可見封印飛行及命中但不宣稱global fix。evidence artifacts/ios/unit-compaction-v01/VALIDATION.md。下一片v07披風body-pinned skin＋follow-through已按計畫實作source，pure motion20Swift／27Python PASS；asset與native驗證未完成，不改純規則。

### 06:48 — v07披風實際視覺缺口
11骨候選Blender七phase各100肩部頂點固定於body誤差<1.2e-7m、native3rig/39腳/21cape sockets/5staff/72還原均PASS，但12側背render發現Rogue後腰包穿透swing cape。原render/native輸出保留；將後腰包改側腰[-.27,.40,-.13]，另存resources/final。W/M保持v06rest等價；Rogue主動位置變更，不能宣稱v06全頂點等價，仍需對final native source驗證與實際clearance。预載halo三次独立native seal process完整trace PASS，不宣稱框架全域修復。

### 07:07 — v07asset與native已過，資源影片時間複查
Final三職11骨／cape上緣body-pinned／Rogue側腰包已bundle；3rig/39feet/21cape/5staff/72restore、cleanSEfull11、weighted/UV/package通過。6個最大擺幅背側圖無原後腰穿模。模型tour固定elapsed抽幀沒有明顯姿態，actualnativeclip-binding audit18cases兩clip及rename/wrapper皆有jointdelta，故不支持rootrename故障；補debug實際start/sample/controllercomplete timing後再pixel判定。另撤回9×9overlay不見之判讀：原始17/SE圖皆可見。獨立44pt zoom控制屬布局改善，首SE父層identifier覆蓋childFAIL原log保留，移除parentID再驗證。Owner／真機／organic Gate維持待辦，Core/C#不改。

### 07:25 — v07披風與手機整合完成候選驗證
Final三職11骨／固定肩部cape混合skin、戰士latefollow-through與Rogue側腰包通過native／Blender／UV／strictUSD資源檢查。實際clip24組與6次controller完成trace、對應12個抽幀人工review確認姿態／披風／回穩；猜測elapsed抽幀沒有動作不是clip故障，未改動畫資源binding。兩尺寸12張最新完整手機畫面人工review、17full11與SEfocused3 PASS，44ptzoom獨立row正確。原9overlay缺失診斷撤回，首parentAXidentifier覆蓋FAIL保留並修正。Owner／真機／性能／organic Gate仍pending。evidence artifacts/ios/cape-motion-v07/VALIDATION.md、zoom-controls-v02/VALIDATION.md。接續arena-v02細草地、chippedstones與lobedfoliage建模，source已實作待實際export/native驗證；截止11:09:54前繼續，不提問提交發布。


2026-10-09 07:46 建模里程碑：arena-v02 閉合石緣／群簇樹冠／細草地已完成候選整合（完整頂點匯入、12 原生畫面、SE 3/3、Release、16 時碼對齊動畫影格）。陰影 culling 未改善孤立黑點，維持原設定；同 rig 貼圖隔離与法師領口幾何精修接續。Owner／真機 Gate 不升格；不 commit/push/發布。


2026-10-09 08:02：v08 法師領飾穿下巴修正完成候選。兩尺寸 native imports/foot/cape/socket/72 interrupt PASS，SE imported 首 Metal startup crash 保留、匹配資源後1/1 PASS不等於根因修復。模型抽幀工具修正 PTS seek 偏 .6 秒，改 frame index＋PNG 自身時碼核對；12正背面動作影格人工通過，arena16原影格再驗一致。後續既定 9×9 拖移定位；Owner／真機與rare startup風險仍open。

2026-10-09 08:32：原生pan/locate候選完成，兩尺寸final focused3及8pan ends，17precedingfull13、38Python、Release通過；初版空白／四角orthogonal snap設計與shadow-off首失敗保留。陰影on/off小黑點不變，根因未定，預設不改。接續三職待機動作候選，Owner/真機Gate維持pending。


### 08:56 — 三職待機循環與独立動作工程候選

模型檢視新增 opt-in 3.4秒呼吸／頭手微動／披風延後擺動，11骨腳底反向定位；103 phase source與v08 rest/25 meshes精確等價。23 Swift／40 Python PASS，可編輯.blend／實際weighted六時點／UV／strict USD包裝通過。兩尺寸各327 native pose/ending PASS；44pt實際啟停／換職／local Reduce／離場後final focused UI各1/1，六張畫面人工看過。24 code-driven與12 imported first-clip時碼影格逐張人工查看，decoder frame index與PNG自身clock一致。首測試語法、API名稱及UI hit-target失敗保留；new idle rig為獨立候選，正式bundle仍v08技能資源。Release編譯通過，沒有發布。證據 artifacts/ios/idle-motion-v01/VALIDATION.md。

idle工程103幀不代表完整organic rig或兩個available clips均驗證；系統Reduce／VoiceOver／真機／效能及Owner風格Gate仍pending。接續精修可編輯實體裝備造型，純規則核心不改；持續至11:09:54，不向睡眠Owner提問，不提交上傳發布。


### 09:13 — Owner 明確否決目前模型造型，改為先驗大形

Owner 覺得建模太醜，要求查網路做法更符合皇室戰爭附件。v09裝備source/weighted/native既有驗證及17完整15方法結果保留作工程證據，不能當視覺成功；未完成的向外腰包修正停止整合。先研究官方作者與Blender雕塑流程，重做單一角色的大形／眼窩／下顎／胸肩／握持，再以真實3D渲染和手機匯入審品質，保持Core不變。窗口11:09:54與不commit/push/發布維持。證據 artifacts/ios/sculpt-style-v10/PLAN.md、RESEARCH.md。

## 2026-10-09 09:50 — Owner 要求回到原角色身份

Owner 追加「至少要有這樣的程度」並提供 Plants on Fire 手機畫面，隨後明確要求「按照之前設計的圖片來建模」。身份依據固定為 character-style 三職 v01 全身圖與 VIS-FEEL-01 的 B-v02 卡片：戰士栗髮／無頭盔／奶油衣／青綠披風／左盾右劍；法師年輕紫髮／紫帽奶油邊／右手晶杖；盜賊銅髮／靛藍開臉兜帽／苔綠背心／赭圍巾／右短刀。所有六張已逐一看圖，v01 SHA 已核對。皇室戰爭與 Plants on Fire 是完成品質、體積光影與手機可讀性的標準，不能據此換角色。

v09 與 v10 騎士雕塑均不算視覺通過；新河流城堡場景僅保留為獨立構圖研究。官方 KayKit Adventurers 2.0 FREE 實際下載、CC0 許可已讀，僅可作拓撲／骨架／動畫做法與合法施工基底，不可原樣換入新人物或宣稱全原創。原設計 v01 與 B-v02 仍 candidate，並未擅自升格 exact-file production approval。

切片：ID-M1 戰士原設計的臉／髮／衣／左右裝備重建及正側背對照 → ID-M2 法師與盜賊一致性 → ID-A1 相容骨架動作與原生載入／還原 → ID-V1 iPhone 三種完整畫面。先看模型是否像原图，再做整合。第一輪戰士 source 渲染仍有浮眼、硬髮、姿態偏差，保留失敗圖並修正，不替換 main bundle、不宣稱品質 Gate。期限 11:09:54 不變，無 commit/push/發布，模擬器不替代真機。


## 2026-10-09 11:06 — 原圖身份候選與原生動作證據（品質尚未通過）

ID-M1／M2 已有三職原圖身份候選：栗髮左盾右劍戰士、紫髮紫帽晶杖法師、銅髮開臉靛帽苔綠衣盜賊。最新 source 為 ios-identity-motion-v05，各有可編輯 .blend、23骨、43幀自編造型動作與 strict USDZ；KayKit CC0 僅施工基底，不替代身份，不宣稱全原創。iOS 模型檢視可 opt-in 原圖候選與原全身縮圖對照；主棋盤仍 v09/11骨，23骨 gameplay adapter 未做。首 source 烘焙／staff零權重選取／native後腦透眼失敗均保留，五個實際 mesh 的法師 staff 修正 pass/fail regression 通過；最新補閉合頭與內袖後，原生眼睛透後腦消除，但袖口縫、握持、背髮帽殼與平板披風仍存在。

v05 build-for-testing與12 USD流程步驟exit0；SE/iOS18 focused UI 1/1 PASS。17六正背截圖與六動作的十二對齊影格全部人工看過，max clock誤差 .0166秒，6 controller完成18 joint samples，31,301,946-byte native movie。Warrior importer片段1.2s而source1.4s未定位原因；兩資源是global/subtree重複入口，非兩套獨立動畫。最新17 UI／SE正面像素補驗正在收尾，另以 final evidence 結果為準。Core本輪未改，模擬器不等於真機，不宣稱品質Gate。ID-V1三種完整局面、7/9新模型比例及規則技能／落子／提子／勝負完整整合尚未完成。證據 artifacts/ios/identity-model-v01/REVIEW.md、VALIDATION.md。

11:09:54期限維持；到期停止新切片，整理既有結果及Owner待決，不commit/push/發布，不將候選升格完成。

11:08 收尾補驗：最新17／SE focused UI各1/1 PASS，SE3職正面也人工看過；9張静止＋12動作影格。final-input-consistency.json 核對源工程／USD／包／bundle／installed17及原圖bytes一致。美術與完整場景仍未通過，見 identity-model-v01/REVIEW.md、VALIDATION.md。

11:09:54窗口到期：停止新增切片。三職原圖模型與造型動作仍為候選，所有美術／完整場景／真機 Gate 保持未通過；可檢查交付與待修項見 identity-model-v01/REVIEW.md、VALIDATION.md、window-end.json。無commit/push/發布。


## 2026-10-09 — Owner 戰士 B-v02 頭胸像限定修正

Owner新一輪明確要求唯一身份基準B-warrior-v02、只做靜態頭胸像、固定光源並排/3quarter/side/128/64檢查；Owner核准前不做下半身與動畫。不是恢復已到期十小時全角色/場景任務，也不調整Gameplay/Domain/G0–G4。實際前版為Blender可編輯mesh、CC0頭四肢施工base、23骨與USDZ、iOS實際渲染，不是AI圖片；前版混用v01+B-v02並誤讀盾徽為castle，身份失真成立。

本機僅512B-v02衍生PNG，源provenance記載1254原圖但實際檔與本機/ZIP搜尋未找到；已更正早先以metadata誤稱找到高解析原檔。先以同一B-v02 identity的實際PNG製作可逆靜態mesh候選，reference SHA50885855dc9faee8966558ea854f99d24bd0ffd0ed93c03bb6b87c8643d42298。原圖gold component內區域描邊為分岔浮雕，非新造城牆icon；新造眉角/almond lids/下顎/外翹栗髮、silver shoulder rim、厚teal folds/gold roundclasp、連續手部劍柄護手寬刃。不得靠更多細節或換light報identity完成。

可檢查工程在 assets/candidates/warrior-bust-bv02-v01，計畫 artifacts/ios/warrior-bust-bv02-v01/PLAN.md。沒有替換现有bundle/角色卡；原圖未定義的側背深度只candidate。高解析master回補與Owner同角色核准待驗證。


戰士B-v02靜態頭胸像首輪交付：warrior-bust-bv02-v02可編輯.blend/靜態USD/七張fixed视角與native尺寸render、並排QA，artifact path warrior-bust-bv02-v01/REVIEW.md、VALIDATION.md。v01浮眼/端口/盾邊問題保留，v02單件mesh0非流形0退化、101物件106132vertices、0rig/actions/lowerbody，USD strict PASS。main app資源/binary12 SHA與本輪前一致，Gameplay/Domain/G0–G4未改。所有实际png與原圖並排人工看過；P0身份修正仍FAIL/PENDING：oversize curl/頭髮剪影、臉部氣質仍偏差，不因engineeringPASS升格。唯一B-v02身份reference是現存512衍生圖，1254原檔缺失；Owner需先看頭胸像且回補master，未核准前不延伸全身或動畫。本輪沒有commit/push/發布。

## 2026-10-09 — Owner 新授權：Warrior Identity Recovery 頭部最小實驗

Owner 貼文否決前版身份，要求先研究reference-to-3d、validator、Blender Studio與MCP；只做頭部，先相同視角／原畫／3D／50%疊圖／灰階輪廓，再由Owner判斷。借用來源鎖定及overlay方法，不照搬正交假設，不安裝第三方程式，不恢复過期排程，不製作裝甲、盾劍、下半身、骨架或動畫。

獨立head-v01與一次針對修正head-v02保留；最新assets/candidates/warrior-identity-head-v02/warrior-head.blend及artifacts/ios/warrior-identity-head-v02/REVIEW.md。使用512B-v02手工輪廓／五官控制籠與固定透視投影，連續臉曲面含鼻、貼面眼部、寬曲面髮塊；不是手工美術精雕或從單圖精確解相機。首次嘴線修補因Blender tessellation回傳型別exit1，錯誤與修補exit0均保留，凹嘴線fan填色失敗已改多邊形三角化。36頭部mesh、0rig/actions/圖片材質，13份前版blend／原圖／app資源SHA未改；本輪未改玩法，未跑遊戲回歸。

四格實際比較與側面完成，輪廓診斷IoU約.926只代表大剪影，不代表身份接受。主要偏差仍是硬葉片髮束／頂部尖角、簡化眼皮耳頰、推定粗胚側背深度。Owner identity Gate未通過，production unavailable；依要求停在本輪候選，Owner评估前不继续髮絲、裝備或動畫。1254缺失不是巨大造型差距的主因。

## 2026-10-09 — Owner 正式否決 head-v02 身份；停止此建模方法

head-v02接受為技術研究，角色身份驗收與正式人物模型不接受。Owner要求停止修改该Mesh、髮丝、下半身、装备、动画及新建模框架；不是再做一次參數修補。已原樣保存.blend和全部渲染，审查状态记入owner-review.json与artifact-manifest.json。没有新增模型或游戏实现。

失真原因区分为：单视图几何重建无法唯一确定曲率／深度；缺少正侧背与表情设计；本流程欠缺专业头雕、髮束节奏、眼皮／表情、手绘材质与描线设计。第三项是实现不足，不能归因于解析度或多视角缺失。

下一轮仅提出A/B成本可行性，见docs/ios/CHARACTER_PRODUCTION_ROUTES.md。推荐A0先用既有B卡＋A Token支持G0–G4；A1拆层局部动画与B0专业单头雕塑分别估算。人日是规划区间，不是报价或Agent承诺；没有取得路线选择、制作或采购授权。G0–G4既有Gameplay路线维持，不因美术研究阻塞。Owner决定前不执行A/B的新素材或技术框架，过期续作排程继续停用。

## 2026-10-09 — A0 路線已決定；G0 Pending，G1 尚未開始

Owner正式選A0：原始B-v02角色卡＋A版棋盤Token，搭配2.5D木質棋盤／底座／柔和陰影，先供Windows 7×7可玩版本開發與試玩；候選素材不升格正式發布。A1拆層動畫暫緩，B0專業3D雕塑暫停，head-v02身份仍不通過，不新增Mesh／骨架／全身／裝備／動畫或新框架。

G0先驗盜賊教學操作，不新增圖片整合要求；仍Pending，等Owner確認沒有重大阻礙才開始G1。G1只接既有B卡到選角／人物資訊、A Token到棋盤並調整尺寸，不擴充動畫系統、不改Domain。G2–G4依既有玩法路線完成三職技能與本機雙人；G5真人驗遊戲性後再評估動態。

iPhone實機視覺／觸控驗收是後續SwiftUI素材接入階段的Gate，不是目前A0／G1前置条件。G0–G4不因角色美術流程卡住。

本輪完成範圍僅決策文件更新，未授權或開始程式修改／素材接線／生成角色／安裝Skill／建模；不新增美術Slice。docs/ios/CHARACTER_PRODUCTION_ROUTES.md已更新，先前「A/B待決」為歷史狀態，現由本次A0決定取代。G0驗收與G1開工仍分開，過期排程不恢復，無commit/push/發布。


## 2026-10-09 — 現行可玩 iOS 與 Owner 追加範圍（取代前述 G0 Pending／SwiftUI 未開始的歷史狀態）

Owner 已實際玩過 Windows 與 iPhone 單人版本，確認電腦逐步落子可辨認。Swift Core／SwiftUI 本機雙人與三職第一技能、7×7 Bot、V2 接線均已有工程交付；G5 完整真人／平衡驗收仍未通過。A0 原卡＋Token 維持，不重啟 3D、美術或第二技能。

本輪最小追加：選角可選黑／白和簡單／標準，預設簡單。簡單保留己方完整回合、直接勝負與主將救援，減少候選並略過對手完整回合搜尋；不保證人類獲勝，也未測勝率梯度。選白時電腦黑方自動首回合 1 AP；复原保留電腦開局。局中改難度作廢舊決策，保留已提交 AP／Mana／技能旗標，僅重新規劃剩餘回合。

Owner 另授權將 Audio Agent 的音樂／音效整合進此候選並安裝 iPad。只接入原程序合成 BGM＋11 SFX、AVAudioPlayer、成功事件時間表與持久化聲音設定；不覆蓋 Bot、Domain、A0 素材或引入完整 CombatBoard 視覺改版。undo／restart／離場／背景／難度切換取消舊 cue。無聲的正常 endTurn 保留已成功技能的落定音；勝負聲在單人模式依玩家方別選 victory／defeat。iPad 目前使用 iPhone 相容呈現，非平板原生布局验收。

目前獨立 worktree codex/bot-01，不 commit/push/merge 或正式發布。來源、測試、失敗／修復與雙裝置安装以 artifacts/bot-01/REPORT.md 為準。BOT-02、完整 BOT-03 與 R2 未開始。


## 2026-10-09 — 原生 iPad 排版與雙裝置 Wi-Fi 更新

Owner 回報 iPad 排版不適合，指定 Wi-Fi 更新並追加 iPhone 安裝。本輪僅修改 PlayableGameView、app/test 裝置設定與原生 UI 測試；原生支援 iPhone/iPad，平板四方向、手機直向。iPad 直向置中放大棋盤與按鈕，橫向棋盤左／雙方資源與操作右；選角橫向分欄。旋轉保留局面與行動預覽，既有 Domain、Bot、音訊與 A0 素材 SHA 未變。

原生 mini6/iOS18 三項測試、SE/iOS18 三項回歸通過，7/9 點擊、白方電腦開局、旋轉預覽確認／復原、選角與聲音設定有實際截圖。初版容器識別覆蓋子項、旋轉測試過早讀取與 app 局部截圖方向問題均保留紀錄並修正；最終全螢幕截圖按 EXIF 轉正，沒有更動畫面內容。歷史 68 Package/38 Golden 未重跑，本輪規則無改。

Release strict codesign 通過，同一 binary 已透過 localNetwork 安裝到 iPad mini6 和 iPhone16Pro；兩者啟動因重新鎖定被拒絕，解鎖後可自行點開，未宣稱真機操作或聽感驗收通過。這取代前一里程碑的「iPad 相容模式／iPhone 尚未更新」現況。完整驗證 artifacts/ios/ipad-layout/REPORT.md、validation.json。未 commit/push/merge/發布，不展開 BOT-02、第二技能、美術或新 Slice。


## 2026-10-09 — 不等待建模：存局、棋譜與技能試驗

Owner 授權將可玩功能先完成；SAVE-01 / REPLAY-01 已接入大廳與局中選單。正式局成功動作原子存本機版本化 journal，Domain 重播還原完整 GameSession／AP／Mana／Ko／undo；壞檔保留、失敗警告、電腦中途續玩只規劃剩餘 AP。唯讀棋譜逐手看事件與資源，可匯出 JSON，不改 live game。

BOT-03b 有限校準已交付候選：滿 Mana pass 評分及簡單近最佳選擇；兩局 100 回合模擬仍和局且長期 pass，因此不聲稱已解決密集盤面或人類難度梯度。R2 既有八個固定局面 A/B/C/D 新增 opt-in 原生試驗入口；正式新局原版規則不變，不做第二技能。A0 卡／Token、音訊與 Core 保持原 SHA；V2 新美術仍等待 Owner 確認素材，不重新建模。

本輪 79 Package、手機 9／平板 5 原生操作測試通過，38 Golden／99 steps／137 snapshots 等價，R2 32 probes；存局按 L2 完整性檢查。Release 已 Wi-Fi 更新 iPad，啟動因 Locked 拒絕；iPhone unavailable，本輪新版手機更新尚未完成。先前雙裝置安裝不能代表本輪手機已更新。工程候選完成不代表 G5、R2 正式採納或真機驗收。詳見 artifacts/ios/product-playability/REPORT.md、validation.json、final-source-manifest.json。仍於 codex/bot-01 未提交，不 commit/push/merge/發布；以上現況取代舊條目，不增加新 Slice。


## 2026-10-09 AUDIO-02 B integration (Owner authorized)

B dynamic battle music is now connected in the frozen AUDIO-B candidate. Three synchronized 76.8s PCM layers, commander threat/stable relaxation, successful-skill -5dB duck, human-relative six-second endings, independent music/SFX controls and cancellation lifecycle are covered. A menu/tutorial remains a candidate. Previous App-integration HOLD is superseded by Owner request; quality/long listening/commercial release are not approved.

Frozen BuildSnapshot excludes in-progress BOT-P0/CONTENT-01 targets; 84 Package tests, SE 3/Pad 2 native tests, each 34 native player checks pass. Release/strict codesign pass; iPad localNetwork install succeeded, launch Locked; iPhone first install failed (CoreDevice1011, Xcode Offline/-27 browsing). Owner says phone is online; wireless development connection remains pending actual verification. See artifacts/ios/audio-b-integration/REPORT.md, validation.json and release-manifest.json. No commit/push/merge/publication.

Owner subsequently authorized BOT-P0 + CONTENT-01 in parallel gameplay work: diagnose legitimate versus avoidable pass, and six formal-newGame reachable 7x7 tactical challenges with Core goals/solutions/counterplay. These are separate from this music binary; CONTENT-02 selection/progress UI awaits gameplay review, no second skills or default R2 changes. Visual source work remains separate.


## 2026-10-09 — B 音樂雙裝置交付、單人內容與後期技能候選（最新現況）

B 對戰音樂已整合，frozen music binary 經 Wi-Fi 安裝到 iPad mini6 與 iPhone16Pro；手機 localNetwork／connected、安裝與啟動 success，取代先前 Offline 待更新記錄。iPad 已安裝、先前啟動 Locked，不宣稱真機聽感／G5。這個已安裝二進位不含下述後續源碼。

BOT-P0 已完成原因診斷與有限定位評分修正。簡單樣本13回合獲勝且0 pass；標準兩個100回合樣本仍和局且61／66 pass，因此整體後期停滯未解決。部分落子會讓主將剩一氣、下一手被吃，不能硬禁 pass。詳 artifacts/bot-p0/REPORT.md；不聲稱修正使所有英雄後期可用或已建立難度／勝率梯度。

CONTENT-01 純 Swift 六個原版規則教學關卡已交付63合法來源動作、30分支67步；預設說目標、提示分開、合法替代兩手解法可過，真實敵兵反制在提前讓出回合後发生。敵人沒有英雄職業，合作建局證明合法可達而非自然對抗發生；無自動敵手、手機選關、持久通關或趣味验收。即時 assessment 在後續 CONTENT-02 必須於完成邊界保存並停止輸入。詳 artifacts/content-01/REPORT.md。

Owner 回報自由對戰戰士沒鄰接空點、法師身旁全己兵，並明確選「戰士沿棋群築壘＋法師調度己兵到棋群外緣」固定候選。R3 L2驗證完成：戰士沿用施放前棋群邊界；法師選射程2內同一群己方普通兵調到原群空邊界，共用1AP＋2Mana／每回合一次。預設關閉、獨立候選API，不接標準GameAction／legalActions／Bot／原生／存局，不改自由對戰或第二技能。共有結算維持原子提子、自殺、Ko及事件。

人工密集探針戰士0→66、法師0→144；正式開局138手棋譜第31／42回合戰士0→6、法師0→12調度。不是Owner本局，也不代表技能有益；實際法師候選可使英雄只剩1氣，仍需站位取捨與玩法驗收。詳 docs/r3/PLAN.md、artifacts/r3/REPORT.md。全包113/0、原版C#／Swift38組99步137snapshots等價與原生編譯PASS；音樂版另有84 Package、手機3／平板2原生操作、各34播放器檢查。

仍在本地 codex/bot-01，無新提交／push／merge／正式發布。下一關為 Owner 審查技能候選與音樂聽感、內容玩法；尚未授權 CONTENT-02 或候選全對局整合。A0原畫與Token保留，Visual Agent素材獨立，不重啟3D。

## 2026-10-09 — Owner 戰士 G5／G7 截圖追加

已按截圖確認原版G5普通落子合法，舊版築壘G5/G7超範圍，connected候選成功提G6但整串剩1氣。新增1 focused Core回歸通過；不是原存局/Ko歷史證據。手機仍frozen音樂版，R3未接可玩入口。Owner待選完整候選續玩副本或固定試驗範圍，不把預選當授权，待回答再做接線；證據 artifacts/ios/skill-live-preview/REPORT.md。


## 2026-10-09 — R3 候選完整對局（取代固定試驗限定）

Owner 已明確回覆「接入候選對局，保留原版與原局」。因此現在接入 opt-in 候選 GameAction／legalActions／Bot／GameSession／存局及 SwiftUI；原版仍為預設，並保留原局檔案與逐手收據。對戰選單「複製此局測候選技能」先完整驗證、使用新 ID 保存後才切換；新局也可選候選。戰士沿施放前棋群築壘，法師可選原推動或射程2內相連己兵調到原群外緣，共用1AP＋2能量／每回合一次。候選名稱清楚顯示，支援預覽、取消、確認、復原與終止重開續玩。未採納為正式預設；第二技能與 CONTENT-02 不在本輪。

驗證：全包131/0；原版Golden38組99步137snapshots一致；SE原生5/0、iPad原生4/0，含截图G5/G7提G6／法師調度／原局與副本分開保存及重開／電腦剩餘AP／平板旋轉。63來源測試前後SHA一致，Release／strict codesign通過。音樂B及既有音效保留。裝置最新狀態以 artifacts/r3-playable/validation.json 為準：iPad已Wi-Fi安裝，手機初次unavailable待恢復連線；不以舊音樂版代替本輪手機安裝。詳 artifacts/r3-playable/REPORT.md。這段授權與交付取代先前「尚未授權候選全對局」的現況，舊記錄保留為歷史階段。

技能合法仍可能造成己群一氣，Bot標準後期停滯未全面解決，等待Owner候選對局及聽感試玩。不新增Slice、美術、3D、第二技能、AI評分或關卡介面；未commit/push/merge/正式發布。
# 2026-10-09 GAMEPLAY-R3 收斂（最新優先順序）

Owner 以實際候選技能趣味及完整對局為下一里程碑。不擴充功能／正式美術／第二技能／動畫BGM。先維持原局安全及原版預設，收集戰士值得／不值得築壘、法師救援／撤退／反攻與三職取捨；人類Gate仍待Owner（0/5）。本輪只補隔離診斷與本地快照，沒有修改正式程式或AI評分。

標準原版與候選仍分别61／65純Pass，到100回合上限和局，候選未解決AI後期停滯。簡單候選17回合提主將，三局305動作獨立重播通過；樣本不是勝率或樂趣證明。AI固定可達局能選新法師調度，亦有壞調度與防守Pass的具體反制。下一AI修正必須辨識保守停滯与真正不能安全進攻，不以強逼非Pass作通過。

已保存本地 codex/gameplay-r3-p1 實作快照5a08cd82e2ed362b0c13fbba79525fec477d0f60，源碼與測資可重現；不上傳、不建立PR、不合併發布。原131項測試來源未改，新增實驗見 artifacts/r3-p1/REPORT.md、validation.json；Owner試玩表見PLAYTEST.md。iPad現有安裝版保持，手機仍待無線連線；候選不升格正式規則。


## 2026-10-09 ONBOARD-01 交付範圍

本輪只執行 TUT-0 與 TUT-1。Owner 要求的三職技能教學、對局內提示設定與真人測試仍分別屬 TUT-2、TUT-3、TUT-4，尚未完成。

新增大廳入口「新手教學 · 不需要懂圍棋」，五個小目標依序教主將勝負、交叉點落子、棋群共享氣、提子與主將救援。預覽、結算及氣數均來自既有 Core。教學固定盤面不宣稱是正式對抗中自然出現的棋形。

教學 journal 在獨立 Onboarding 目錄；取消、复原、背景、重新啟動不改正式存局。新增大按鍵選點，提供小螢幕操作替代；不以棋盤交叉點的可點擊範圍宣稱觸控已舒適。

原版／候選技能仍隔離，R3 真人驗收仍 Pending；標準電腦密集盤面停滯仍未全面解除。沒有新平衡、技能、B1 素材、3D 或音樂改動。

成果在本地 codex/onboard-01 隔離分支，沒有上傳、合併或發布。工程測試與模擬器操作不能證明零經驗玩家已在五分鐘內理解。

Specification: docs/onboarding/ONBOARD_01.md. Evidence: artifacts/onboard-01/REPORT.md and validation.json.

### 2026-10-10 Cozy-02 整合候選里程碑

Owner 核准的 Cozy-02＋V1.1 B＋B2-B＋原 B-v02 已接入隔離分支 codex/cozy-02-integration，法師 ANIM-01／既有 AUDIO-01 僅呈現成功事件，不變更 Core、Bot、技能或資源。Swift151／0、Golden38組99步、390原生模擬器5／0、SE320內容約束1／0、iPad真機2／0。iPhone真正前景播放器audit17／17；Xcode手機手勢測試因啟動worker失敗仍BLOCK。雙裝置Wi-Fi候選0.7.0（702）安裝成功，最後重開iPadLocked／手機失聯，不當成目前都可啟動。聲畫片為原生錄影＋明示後製音效；美術、人耳聽感及BGM正式整合HOLD。未提交／上傳／合併／發布；此為工程里程碑，非Owner驗收完成。詳 docs/ios/COZY_02_INTEGRATION_PLAN.md 及 artifacts/ios/cozy-02-integration/REPORT.md。

### 2026-10-10 GAME-FEEL-10H-v2 工程候選

Cozy原生基線保存後，完成6句可替換離線英文語音、三職召喚／技能／普通落子提子及主將退場。Package156／Golden38組99步／原生phone22、SE2、iPadV3 4與真實手勢影片通過；iPad直向操作區擠出畫面已修正。iPhone Hero Voice 0.8.0（802）Wi-Fi安裝成功但Locked阻擋前景；V3真機及人耳、美術、正式BGM仍Pending。成果隔離 codex/game-feel-voice-01；Owner授權commit/push，無merge、發布或第二技能／Domain／Bot變更。交付及推送以 artifacts/ios/game-feel-voice-01/REPORT.md、DELIVERY.json 為準。

### Hero Voice 交付後聲音表演審查

Owner 判定現版六句英文 TTS 死板，角色表演 Gate FAIL；S0–S7 工程接線結果不撤銷，聲音不採納為正式配音。下一輪先評估 Hold the line! 堅定喊聲與 Off you go! 俏皮施法的兩句實際表演，不以調音／更多平讀版本取代演出。見 docs/ios/HERO_VOICE_PERFORMANCE_REVIEW.md。本回饋未生成新音訊、修改程式或授權費用。

### VO-PERF-01｜兩句表演乾聲試驗

Owner 授權繼續。隔離 codex/hero-voice-performance-01，先以本機 Qwen3-TTS VoiceDesign、逐句表演指示生成戰士／法師各兩個乾聲候選，先聽感、不換遊戲內六句。模型僅開發端，不導入App新引擎，不用付費服務或演員／遊戲聲音參考，不擴充三職全套。驗證來源／內容／聲音檔案，表演與同職長期聲線一致性留待Owner。前版接線保留，正式BGM HOLD。

VO-PERF-01 工程試聽完成：戰士A/B、法師A2/B3，獨立Whisper台詞4/4與PCM/SHA4/4。法師3個初期長度／字詞HOLD實驗保留，不當可整合語音。舊版→A→B乾聲比較已交Owner，聲音品質Pending；新素材未接入App，不重跑既有Swift/Golden冒充聲音證據。報告 artifacts/audio/hero-voice-performance-01/REPORT.md。

### 2026-10-10 ANIM-M1／M2｜法師本體候選

Owner 授權先做法師分層登場與原版一格魔法之手，以關閉語音、粒子與光圈後仍能看出蓄勢／出手／收勢為演出目標。隔離 codex/anim-mage-body-01：保留 B-v02 原畫，使用原圖頭身／手杖遮罩與有限遮蔽補圖，手與法杖共用握點轉換，底座保持 anchor。此為可編輯 2D cutout，不是 3D 或逐幀手繪；近景尚有少量拆層接縫，角色表演與美術 Gate 仍 Pending。

單一 MageTiming 驅動本體、士兵、提子、音效與鎖定，完整／緊湊施法950／760ms，出手早於士兵移動。成功 Domain receipt 才播放；不改 Domain、Bot、候選技能或語音素材；候選遠距調度不套此一格演出。Reduced Motion 保留即時結算與必要 SFX。

驗證：Swift162／0，Swift新重播與既有經審查 C# transcript 比較38組99步137 snapshots一致；此次 C# exporter 未成功重跑（現有SDK8無法target9）。390原生3／0、SE320原生2／0、正常速度六收據錄影1／0、320減少動態錄影重跑1／0，以及實際畫面 GameStore／Audio audit97／97。錄影是 Simulator真實操作、靜音、未變速；checkpoint圖與近景造型頁另標示，不冒充真機或一般對局。

iPad Wi-Fi 已安裝獨立 TacticalGo Mage Body 0.9.0（903）；鎖定拒絕前景啟動，真機動態仍待驗證；iPhone unavailable。無本輪 commit／push／merge／發布，主 checkout 保持不動。詳 docs/ios/ANIM_MAGE_BODY_01.md 及 artifacts/ios/anim-mage-body-01/REPORT.md。

### 2026-10-10 ANIM-M3｜小尺寸法師與英雄底座標記

Owner 授權主要 Agent 協調 Visual 只讀檢視及 SwiftUI 整合，隔離 codex/anim-mage-m3；M1/M2 先驗 SHA 保存於 4e15078，原畫、clean plate 及舊交付不覆寫。英雄字牌與大徽章移至薄底座外緣，黑為實心圓、白為空心菱形；法師 canvas 0.70→0.92 pitch、ground source 448，移除舊裁切。加大本體重心及手杖姿勢差異，維持共享 950／760ms 時鐘、成功收據及原版一格推動。Domain、Bot、AP/Mana、投影與命中不改。

工程候選：164 Swift 測試；38 Golden、99 actions、137 snapshots 與既存 C# 基準一致（本輪未新跑 C#）；97 原生收據、取消、復原及中斷檢查。390 M2/M3 同盤面、同尺寸及正常速度、320/9 dense／Reduced Motion 錄影，第二 AP、Bot 及 iPad 旋轉與命中回歸通過；Release、簽名建置通過。最初第二 AP 測試誤以為顯示 0 AP，依 Core 自動換手契約修正為白方 2 AP 後新跑通過，保留初次失敗。

風險與驗收：32pt 細節及 320/9 實際 28.52pt pitch 仍是極限；固定原畫法杖側向揮動不是全方向手繪出手，方向以受術者與短促效果輔助。工程通過不宣稱角色演技、所有密集棋形或三個 Owner Gate 通過。兩台真機已安裝 Mage M3 1.0.0(1001)，鎖定拒絕啟動，動態驗收待解鎖。本輪允許必要提交與 push，禁止 merge、TestFlight 或發布。交付 artifacts/ios/anim-mage-m3/REPORT.md；正式美術與產品 Pending。

2026-10-10 W1/R1 候選交付：Skill已保存與安裝、角色本體／原生證據已完成。Owner盜賊動作回饋正面；戰士修正後動作較好、技能氣勢仍不足，保持待驗收。先停在本輪，不以工程通過開啟VFX；後續順序仍為VFX-01法師、VFX-02戰士／盜賊，最後SFX／語音／觸覺整合。詳見docs/ios/SLICES.md與artifacts/ios/anim-warrior-rogue-01/REPORT.md。

2026-10-10 Owner進一步決定：先續修戰士獨立本體動作及盾牌遮罩接縫；三職動作全部經Owner確認後才可進VFX。英雄語音仍未通過產品聽感／情緒表演，保留HOLD。本輪不做特效、語音或規則變動。

ANIM-W1續修候選交付：codex/anim-warrior-body-02，單次蓄勢停拍／連續下擊／雙兵480ms同拍落定及原畫盾邊、完整握劍手遮罩；法師／盜賊本體保持。170 Swift、137 Golden快照、4原生Simulator測試與108狀態檢查通過；正常速度靜音完整棋盤與同局面對照見artifacts/ios/anim-warrior-body-02/REPORT.md。iPad Wi-Fi build1005安裝與OS啟動接受；真機UI認證取消、iPhone unavailable，實機驗收未通過。Owner氣勢／表演Pending；三職Owner確認前VFX未開始；英雄語音HOLD／關閉，情緒／人耳聽感／同步仍待核准。


### 2026-10-10 SELL-01A｜原生對局質感樣板

Owner 授權單一 SwiftUI 對局候選：桌面全畫面環境、HUD 與木棋盤分層、依選取／預覽切換操作重點、就地展開說明、iPad 側欄及較大字級上下排列。保持人物、現有 CozyBoard／投影／成功收據／三職動畫；不開 SELL-02、大廳、選角或結算改版，不改規則、Bot、存檔、聲音偏好。

基線為 cozy-02-integration 的 codex/brand-01 HEAD 4986805 加未提交 iOS 差異及 AppIcon，不是假設 main 最新；157 個來源檔逐一驗證，原目錄保持不動。新隔離分支 codex/ui-sell-01a。Apple 官方遊戲布局指引、dickwu／AvdLee／twostraws 三份 Skill 只讀參考並鎖 commit，未安裝或執行第三方腳本。

交付與實際證據見 artifacts/ui-sell-01a/REPORT.md、COMPARE.md。產品吸引力、真機觸控舒適度與完整輔助使用仍 Pending；Simulator 工程檢查不能代替 Owner 及真機驗收。未 commit／push／merge／發布。完成單一候選後停止。

### 2026-10-10 SELL-01B｜對局美術方向草稿

Owner 要求保留 SELL-01A 操作基底、先看同一七路局面的單一美術目標；將兩張原生一般／技能預覽圖片直接顯示於對話。使用既有素材與 Owner 的 Stormbound 圖作參考，內建 imagegen 產出暖木／深青桌布／羊皮紙操作台草稿及素材拆分清單，不新增 SwiftUI Skill 或改遊戲程式。

草稿可供方向審閱，但生成圖未達精確格線／ground anchor 配準、人物仍有生成重畫偏差，不能直接整屏或裁切接入，也不能宣稱商業美術驗收通過。原生整合須沿用核准角色原像素、原 BoardProjection／命中與成功收據。等待 Owner 決定方向後才製作獨立素材及接線，不展開其他頁。

詳 artifacts/ui-sell-01b/REPORT.md、COMPARE.md；SELL-01A 凍結交付及兩個程式檔 SHA 保持。本輪沒有新執行測試、安裝、commit／push／merge／發布。

### 2026-10-10 SELL-01C｜原生對局美術完成度候選

Owner 授權保留 SELL-01A 原生操作，將同一對局的底座、主將、戰鬥 HUD、確認層級及場景材質補強。隔離 codex/ui-sell-01c，從 4986805 加 SELL-01A 真實 iOS 差異／AppIcon 保存 158 檔基線。新增獨立桌面與透明木盤，不將生成整屏或人物接入；投影、命中、角色原像素、Domain／Bot／Motion／Records／音訊與存局保持。

四狀態實際 Simulator 截圖及同局面前後比較，覆蓋 390、375、iPad 直向。375 首輪 footer 被擠出畫面，改短版標題與操作區後新測；控制項至少44pt，較大字級另用可捲動版。177 Swift、38 Golden／99 steps、6最終原生UI執行與unsigned Release通過；真機／商業美術／完整輔助使用與效能尚未驗收。詳 artifacts/ui-sell-01c/REPORT.md、COMPARE.md。完成單一對局候選後停止；不自動開SELL-02、大廳／選角／結算，不commit／push／merge／發布。


### 2026-10-10 SELL-01C 限定修整（revision-01）

Owner 已看原生媒體並接受保留方向，本輪只補預覽效果／費用摘要、四狀態底部留白、操作台紙張／小圖示及 iPad 橫向場景。摘要讀 Core 成功預覽的 resourcesSpent／推動／部署／提子事件，不用 state 差額推算費用；沒有更動 apply、棋盤投影、GameStore、音訊、人物、動畫、AI 或存局。修改前來源与媒體另凍結，歷史 REPORT／包保持。

新執行 177 Swift 測試、38 Golden／99 steps、最終 7 次原生 UI 測試（390 四項／375 兩項／iPad 一項）與 unsigned Release 通過。375 首輪確認距底端僅11.15pt，補保留高度及共用行動鍵高度後，四狀態同為20.65pt；390四狀態同為50.15pt。取消／非法／重複確認／復原／背景／召喚與候選調度成本、較大字級／Reduced Motion及旋轉選取保留已驗。

交付 artifacts/ui-sell-01c/revision-01/REPORT.md、COMPARE.md、原始完整 Simulator PNG及正常速度無聲影片。375正常視窗為375×667pt，320局部九路另標壓力模式；不拿 Simulator 或影片證明真機觸控／聲畫同步或美術核准。完成本次限定候選後停止；未安裝實機、commit／push／merge／TestFlight／發布，未開始下一Slice。

### 2026-10-10 SELL-01C revision-01｜真機試玩交付 1011

Owner 授權停止美術追加，安裝同一 revision-01 至 iPhone／iPad。33個凍結來源SHA及45檔ZIP保持；只新增限定媒體查證與签名／裝置證據，不宣稱新美術修正或新測試數。既有Simulator影片的確認文字只在轉場短暫疊合，13.8667秒後與14.3／14.8秒停定畫面清楚；可能涉及enabled隱式動畫，但未以A/B證明根因，保留候選供真機判斷。

Release簽名建置／strict codesign通過；相同bundle com.tacticalgo.prototype.herobody、build1011，透過Wi-Fi更新iPhone16Pro（iOS27.0）與iPadmini6（iPadOS26.6.1）。兩機均已由OS接受正常啟動；iPad首次因Locked拒絕，Owner解鎖後重試成功。原iPhone5筆／iPad9筆棋局、進度與音訊偏好在更新前後逐檔雜湊核對，未卸載／重設，私人備份只存本機。仍待Owner完整對局、觸控、閱讀、聲音與產品體驗驗收；不開始下一Slice，不commit／push／merge／TestFlight／發布。詳 artifacts/ui-sell-01c/device-review-01/REPORT.md、evidence/delivery-summary.json及data-preservation.json；歷史177／38／7結果不重複累計。


### 2026-10-11 SELL-03｜開頭與對戰風格接續

Owner 在 build1011 真機回饋對戰畫面已改、開頭仍是舊版；本輪將既有SELL-01C桌面、紙張與按鈕帶入原生大廳，保留同一人物／規則／流程。有存局優先續玩，對戰設定可展開、黑白選角常駐、同一聲音設定入口，手機開始鍵與捲動內容分開，iPad橫向分欄。

隔離 codex/ui-sell03-lobby，HEAD4986805加原候選未提交來源222檔逐檔保存；不以HEAD冒充完整候選revision。不修改原ui-sell-01c或主checkout。產品差異只在PlayableGameView；原GameStore、Swift Domain/Bot/Motion/Records、投影／命中、動畫與音檔保持。UI測試依新設定展開方式更新。

最終7項聚焦原生測試通過：390大廳／續玩、對戰四狀態及白方人機；375設定／續玩及最大字級Reduced Motion教學；iPad直向流程及橫向開局。初次失敗保留：375設定可能落在固定開始鍵後方，改獨立上下區域；iPad測試在系統Home恢復縮放期間點擊，增加穩定畫面等待；最大字級測試改為小段捲動以避免越過目標。沒有重跑Domain或Golden，不重複累計177／38。正式美術／完整輔助使用／真機體驗未驗收。

簽名Release build1012，iOS17與相同bundle保持。Wi-Fi裝置交付及存局／偏好對照以artifacts/ui-sell03-lobby/REPORT.md、evidence/data-preservation.json及各device JSON為準。未commit／push／merge／TestFlight／正式發布；完成本輪候選後等待Owner，不自動開其他頁改版。

1012裝置交付補記：Owner解鎖iPad後，OS已接受正常啟動；兩機均可開啟新版。既有原局保留；快照間有新對局與續步，不能宣稱所有檔案逐位元一致。兩機BGM/SFX及靜音偏好一致；iPad語音開關快照間變動而本輪未覆寫，產品聽感仍未驗收。


### 2026-10-11 SELL-03 revision-02／03｜封面保留，開局分步

Owner肯定1013封面，但進入後仍選項太多；原revision-02保留歷史證據，未算產品通過。1014保留封面，先選電腦／本機雙人，再選英雄。單人只選自己的英雄可直接開始；雙人按黑方、白方兩步，前一步不建立棋局。黑白先後手／難度／棋盤／原版候選及可選電腦英雄移至原生設定sheet；技能说明預設收起，原選項語意與選擇保留。

本輪222來源比較，產品僅PlayableGameView改動，另更新UITest；Core／Bot／GameStore／投影／音訊／素材不變。九個最終裝置／測試組合通過（390六、375一、iPad二），首輪harness失敗與後續修正保留，不累計重跑次數。沒有重跑歷史177 Swift／38 Golden；簽名Release1014及strict codesign通過，iOS17保持。

Wi-Fi更新相同bundle至iPhone／iPad，兩機驗到1014；iPhone正常啟動，iPad因Locked尚未自動啟動。原iPhone8／iPad16紀錄完整相同保留，手機快照間新增1局。聲音偏好沒有程式修改／reset，iPad偏好copy逾時，完整比對未能取得。Owner否決既有Piper TTS演技，語音仍HOLD，沒有新配音，表演需求見revision-02/VOICE_REVIEW.md。

詳artifacts/ui-sell03-lobby/revision-03/REPORT.md、COMPARE.md、evidence/test-executions.json、delivery-summary.json及data-preservation.json；完整原生Simulator圖與正常速度無聲操作影片保留，不能替代真機觸控／聽感／產品驗收。完成分步候選後停止，不擴其他頁或新研究，不commit／push／merge／TestFlight／發布；main及原美術worktree保持。revision-02磁碟滿事故及失敗錄影明記，清理只限可重建暫存，初期結果逐檔SHA驗證封存。

### 2026-10-11 自主五項 Slice｜隔離工程候選

Owner授權台北01:08:14–11:08:14自主推進附件五份合約；可逆問題自行處理、待決事項留到窗口結束。主線及實際1014來源保持原狀。工作於 `codex/autonomous-slices-1011`，基底4986805加實際1014未提交來源；PR5／6必要來源逐檔匯入，兩PR仍未合併。

| Slice | 本輪交付／狀態 | 仍需獨立驗收 |
|---|---|---|
| BOT-P2 | 單一opt-in強制續攻候選、40／55完整歷史、六場Release對局；實際決策未改善，改善Gate HOLD，預設baseline不變 | 真實安全進度、整體真機成本、Owner完整兩局 |
| CONTENT-03 | 原版三關、多回合棋形反制、12條獨立Core分支、新舊章／正式存局隔離、三職與iPad原生影片 | 不看提示的策略取捨、Owner與另兩名玩家、實機觸控 |
| ANIM-01R | 既有法師分層姿勢／收勢精修；同收據、同時鐘M3／R1影片、32／48／64樣本及原生生命週期 | 小尺寸演技、固定portrait的方向限制、Owner與真機觀看 |
| BOSS-00 | 五份文件、成對回合與四個紙上例；沒有Boss程式或美術 | Owner選定效果及另授權BOSS-01 |
| 3D-00 | 五份身份／來源／視角／路線／Gate文件；沒有Mesh或模型製作 | 1254master缺口、身份／側背面規格與另授權3D-01 |

本輪206 Swift零失敗、重新C#/Swift38組／99步／137快照一致、離線實驗9項通過；原生證據按各實際執行列出，不累加重跑次數。未簽名Release候選1015保持iOS17、實際1014交付的bundle `com.tacticalgo.prototype.herobody` 與0.10.11版本族；未安裝真機。第一個通用未簽名建置僅作編譯證據，不當作1014設備升級包。

來源、scope稽核、日誌、影片與Gate見 `docs/autonomous-1011/`、`artifacts/autonomous-1011/`。不改Core棋規、聲音／語音素材及偏好、正式存檔或原版預設；不commit/push/merge/發布。完成已授權候選後凍結範圍，在窗口截止後統一交付待驗收事項，不追加新Slice。

### 2026-10-11 窗口後｜既有合約缺口續行（不新增 Slice）

原十小時窗口與封存包保持凍結。本輪只補既有合約缺口及已授權手機更新，新證據另列，不改寫原窗口結果。

- CONTENT-03：第一關增加 E6、D7 貌似救援、遭合法 C7、E5 反制後未达六氣目標的分支；Core 沒有虛構主將死亡。同起手 E6、F6 替代路線可完成。三關現在十三條可重播路線，舊十二條分支保持。
- ANIM-01R：直接勝利收據發現 HUD 過早呈現結果，只延後演出層終局資訊，不改 Core 判勝或扣費。SE、390 iPhone、iPad 各十六情境，共三十二支援版面及十六手機旋轉後直向穩定性檢查；手機橫向未開放，不宣稱已通過橫向版面。
- BOT-P2：正式 Rogue／Mage 四十三手來源 baseline Pass→候選 G7，三十五完整敵方回應均有安全實際提兵見證；敵方 Pass 後下一 planner 真正走 G5、F6 提 G6。可關閉 material 候選放在對戰選單 AI 研究；正式預設、簡單難度與存檔格式不變。40 防守 Pass 及 55 未判定保留，六場新 policy 對照仍和局，不宣稱全部停滯修好。本機候選成本增加，真機成本及 Owner 接受 Pending。
- 本輪完整 Swift Package 212 項零失敗；fresh Swift Golden 38 組、99 步。C# 137 快照比較是較早固定來源結果，不當成此次新執行。新候選五個不同原生生命週期方法通過，十一張照片、四份收據中僅一份是候選 G7，其餘為人類測試落子。限定工程正例可檢查；成本中位 +452.32% 超過規劃 25%，Owner 接受／真機效能與真人趣味仍 Pending。
- 手機同屏修正保留 44 pt 按鈕；正常字級棋盤與控制同屏，大輔助字級保留可捲動替代。已簽名 Release 1017 並同 bundle 更新 iPhone，裝置確認 1017；二十三個既有資料檔案及六項聲音偏好保持。正常啟動因螢幕 Locked 被 OS 拒絕，Owner 解鎖後再確認；不以安裝成功宣稱實機操作或音訊驗收。

詳 `artifacts/autonomous-1011/CONTINUATION_07.md`。BOSS-00／3D-00 仍純文件，沒有紅龍或新 Mesh。身份、演技、完整對局趣味及聽感待 Owner；未 commit、push、merge、TestFlight 或發布。

1017 交付後 Owner 直接回覆「確認過畫面已經正常」。保留先前 Locked 自動啟動收據，另記手機正常畫面確認；不將其當作完整對局、AI 成本／平衡或語音驗收。Source v1 封存包凍結在此回饋前，程式無變更。

Owner 隨後確認已實際玩過、操作順手，記為 1017 真機操作正面回饋；沒有將未指定的模式／職業／整局覆蓋推論成全面驗收。此輪只整理十一小時改動說明，無新程式或遊戲測試。

### 2026-10-11｜1017 後驗收優先

Owner提出先PLAYTEST-03、再BOSS-01最小原型，聲音小幅品質改善、BOT-P3根因分析與暫緩3D量產。已核對並保留1017封存來源，補上三關真人記錄表；目前順手回饋只對實際操作，不將它代簽三關取捨、AI或聲音。

BOSS-00既有推薦是三格暫時限制落子，與「推動／直接清除」龍息不同；已整理BOSS01_PREFLIGHT_1017並提出效果選擇問題。待龍息效果與三關回饋，不先寫未知結算或修改自由對戰。新方向、依賴與回復基線見 `docs/autonomous-1011/NEXT_1017_PLAYTEST.md`。本輪只文件／核對，不重跑遊戲測試、改聲音偏好、開新模型或合併發布。

### 2026-10-11｜1018 挑戰入口與現行棋子呈現修正

Owner 回覆尚未試三關，並指出三關選不到、六關仍呈現舊版。已在實際首頁路由重現首次選進階卻開入門；對局選單確實沒有先前文件說的挑戰入口。採單一 chapter item 的原生 cover 路由，補對局共用入口及選關頁兩章切換；進入／退出只暫停或恢復既有對局工作，不另建原局。新舊章仍以既有獨立 Repository 保存，原版規則維持。

挑戰的 CozyBoard 啟用現行商業棋盤／底座，同 8:9 容器與投影，保留既有兵卒、B-v02 三職身份及演出。對照凍結 1017 的 236 個來源／資源，僅三個 UI 檔與一個 UI 測試改動；Core／Bot／資料格式／音檔與圖片未變。原生 6 方法、10 設備方法組合零失敗（390 五、SE 二、iPad 三含橫向），含舊 Bot 決策真正晚到而作廢，本輪 Content 34 項零失敗、Swift Golden 38／99；不累計歷史完整測試。

簽名 1018 同 bundle Wi-Fi 更新兩機；iPhone 原 1017、iPad 實際原 1014。各 25 既有資料檔案與 6 聲音偏好更新前後相同。iPhone 正常啟動，iPad 自動 launch 因 Locked 待 Owner 解鎖；安裝不當作完整真機挑戰／趣味驗收。見 `artifacts/challenge-fix-1018/REPORT.md`、`RESULTS.json`、`SOURCE.json`；未 commit／push／merge／發布。

另保留 Owner 龍息選擇「直接清除線上棋子，另定提子與勝負規則」；新的原子清除、單／雙主將勝負與 Ko 候選只寫文件，不改寫 BOSS-00 歷史 OPEN 決策表或開始 Boss runtime。先讓三關可試，趣味回饋仍待 Owner。

### 2026-10-11｜RELEASE-01 首版內容凍結與上架收尾盤點

Owner 提出以現有內容準備首版，停止擴充玩法；保留既有好玩／操作順手回饋，補陌生玩家、完整對局、三進階關與雙機一致候選的驗收，不把1018升格可發布。紅龍實作、新英雄／第二技能／章節、3D與大型AI改寫移出首版範圍，歷史文件保留。仍不替候選技能或研究AI作正式採納。

本輪同隔離分支唯讀核對實際1018：236檔來源與前輪SOURCE零差異，既有已簽名App執行檔SHA相同；另存282檔來源／Golden／必要比較腳本與歷史證據ZIP，逐檔雜湊／ZIP完整性通過，沒有原局、偏好或簽名App。遠端main唯讀核到cdab133，候選分支尚未上傳；未用Git HEAD代表所有未提交來源。

具體收尾缺口：首頁主要入口仍只有開始／續玩、教學與棋譜，兩章挑戰藏在齒輪／對局選單；1018 App無PrivacyInfo.xcprivacy，但App使用UserDefaults／AppStorage及systemUptime；未找到政策／支援連結；音樂／圖像／動畫／語音及舊包內模型有candidate／pending紀錄。實際Release使用開發profile（get-task-allow=true，兩台設備），不是distribution archive。靜態59檔查詢未發現網路／追蹤關鍵字，不能因此替Owner宣告零收集或商用权利通过。

交付 `docs/release-01/` 的固定收尾合約、六局三職黑白抽測／雙機／新人表、隱私與權利缺口、商店文案和截圖草稿；盤點 `artifacts/release-01/PREFLIGHT.json`、来源ZIP／SNAPSHOT。建議首頁直接教學／挑戰、首版隔離研究入口與未接受語音，均未在本輪實作或視為已批准移除；舊候選存局兼容仍要保留。開發者、支援URL／Email與價格已提出單一缺少資料問題，未填假資料。

本輪僅文件／本機封存與盤點，不修改UI／Core／Bot／資源／存檔或偏好，不建置／安裝新版本、不跑新遊戲測試，不重複累計1018或更早數字。未commit／push／merge／TestFlight／送審／發布。R1內容可發現性及正式RC尚未開始；iPad解鎖／真人試玩與權利仍待確認，工程收尾与正式发布各自驗收。

### 2026-10-11｜RELEASE-01 R1候選1019與R2工程補測

Owner核准繼續首版收尾。保留封面，首頁直接開始對戰／新手入門／戰術挑戰，續玩保持優先，存局與棋譜收進既有工具選單。使用現行單一章節路由，兩章皆可達；不修改規則、AI、技能、資源、存檔、聲音偏好或新增內容。

新增PrivacyInfo.xcprivacy與Resources接線；UserDefaults自身偏好CA92.1、systemUptime事件間隔與timer35F9.1已核對Apple原文與實際用途。沒有政策URL／商用权利／ASC申報完成宣稱；維持iOS17最低版本。

新執行212項Swift、38組Golden／99步／137完整狀態，9次原生UI（8不同method，390／375較大字級／iPad直橫；包含兩章九關入口、續局／棋譜／偏好，以及三進階關完成）通過。Golden首次系統.NET8與一次SDK路徑錯誤保留失敗紀錄；改用已存在9.0.318重新匯出比對通過，未改fixture／reference target或安裝SDK。

237來源／資源／測試輸入鎖定；相對1018僅兩個shipping檔、兩個UI測試及新增plist。1019／0.10.11／相同bundle開發簽名建置、隱私資源hash、嚴格codesign通過，證據artifacts/release-01/r1-native/。不是distribution archive，未commit／push／merge／TestFlight／送審／發布。

iPhone經Wi-Fi已更新1019，安裝前後26舊資料檔、6聲音偏好相同；因Locked未正常啟動，解鎖／完整操作仍待。整個Library的SplashBoard快照不可讀，改為只備份App自己的資料與偏好後驗證；原始資料只留/private/tmp。iPad本輪info逾時，未更新，保持其1018不冒稱新安裝。

六場原版baseline Bot對Bot從正式開局合法結束、完整state重播一致；簡單三場13回合獲勝，標準三場100回合和局，各61純等待／58最長連續。這是新測仍停滯的風險，不推論整體和局率或人機樂趣，不新增Pass懲罰／規則。本輪只作R2工程補測，真人三關、完整局、新人、雙機／聲畫、公開資料與權利仍待驗收；下片只修阻擋項，不重開美術／Boss／3D／大AI工程。


## 2026-10-11 Owner 決策：新版技能直接用於新對局（1020）

Owner 明確要求「技能規則改成新版，設定那邊不用選擇」。此決策取代先前 R3 不升格新局預設的限制：新 iOS 自由對戰／本機雙人／人機對戰採用既有 `RecordRules.redeployment`，戰士沿施放前相連棋群築壘、法師保留一格推動並可調度己兵，盜賊換位不變；費用、AP、結算、Ko 與 AI 邏輯不變。移除新局技能規則 Picker，說明依實際 config。

舊存局保留 rules／id／歷史；從舊局重新開始仍沿用其 rules，首頁新開或終局再玩使用新版。旧局可另建新版續玩副本。固定六關／三關仍使用已標示的原版規則，未在本輪擴充關卡、未宣稱新版已通過全職業平衡驗收。

1020 使用原隔離 worktree；1019 凍結包與證據不改寫。新來源、驗證及裝置結果在 `artifacts/release-01/skills-default-1020/`。iPad 安裝先備份 App 自有存局與六項聲音偏好，再以同 bundle 更新；正式發布、合併及權利驗收仍待另行核准。

## 2026-10-11 UI 結算候選1021：保留場景，操作隨對局階段改變

Owner 回報目前 UI 還可以更符合遊戲 App 風格，附上終局仍保留失效戰鬥表單的實機截圖。本輪僅修對局／結算：終局集中勝負、提將原因與勝方既有角色，主要入口再玩一局，次層棋譜與復原；收起終局 AP、行動方底線、重複結果橫條與技能表單。沿用 presentedResult 等成功動畫結束，不提前替換演出。另發現終局仍可點盤產生選取／非法預覽，僅 UI callback 和格點清單限制終局只讀，仍可閱讀棋子。

以完整1020來源凍結為基線，比對237項輸入僅兩個UI shipping檔與一個UITest檔不同；Domain、AI、資源、動畫、素材、聲音、存檔輸入 hash 不變。保留三檔原始副本與 scoped patch。新來源／畫面／建置在 artifacts/ui-result-1021/，未commit、push、merge、發布或裝到實體裝置。

首輪390模擬器五項執行：四PASS；法師終局附件helper直接讀已隱藏AP而FAIL，已修先檢查存在再讀值，保留失敗證據。加入終局只讀及棋譜前後D2／D3核對後重跑受Mac鎖定／系統idle等待阻擋，保留中斷收據，不宣稱最終原生回歸通過。最終來源1021未簽名iOS Release建置PASS、iOS17與隱私資源維持一致。小手機、iPad橫向／大字級、最終只讀行為及真機驗收Pending；解鎖後只補有限測試與正常速度錄影，不擴大廳／選角／新風格。


### 2026-10-11｜Owner 核准 1021 雙機更新

Owner「好，幫我更新」授權將結算候選安裝 iPhone／iPad，仍無 merge／發布授權。最終 UI 生產檔不再改動；UITest 因 Lazy Grid 的 D3 尚未實現而補捲動，保留盤面結果與終局只讀斷言，focused retry 通過。390 六不同方法滿足，375 三、iPad 一方法含橫向／accessibility XXXL，共十次成功設備方法執行、七不同方法；本輪390一failed、歷史FAIL與鎖定INTERRUPTED完整保留。沒有重跑或重複累計先前212 Swift／38 Golden。

237 輸入比对仍只有兩UI與一UITest差異；開發簽名Release1021、iOS17／bundle／隱私hash／profile未過期及兩設備／team檢查通過。iPhone原1019、iPad原1020均Wi-Fi同bundle覆蓋更新至1021；各27舊資料檔以及六聲音偏好欄位含缺省狀態一致，原始資料只留/private/tmp。兩台自動啟動均遭OS Locked拒絕，已提出單一雙機解鎖問題；正常啟動與啟動後比對待Owner。

新證據 artifacts/ui-result-1021/install/REPORT.md、RESULTS.json 與上層VALIDATION.json；本輪完整原生Simulator照片已匯出，沒有新增真機影片或聲畫同步證據。保留1020與所有原工作；不commit／push／merge／TestFlight／發布，不開始新Slice。


## 2026-10-11｜1022 棋盤主導畫面與 Owner 實機回饋

Owner 要求字更少、板面比例更高。1022 保留單一回合標題／AP／能量／氣數，把重複規則與操作說明收進44pt資訊入口，空閒下方只保留行動／確認。390板面由374×420.75增為390×439（面積+8.8%），短手機idle曾增大但預覽會縮小／移動，Owner兩張實機照片指出此問題。1022兩台Wi-Fi已裝，iPhone正常啟動，iPadLocked；1022原證據保留，不改成已修正。

## 2026-10-11｜1023 選取／取消棋盤固定與付費首版文件

選取文字造成控制區增高，MatchViewportLayout再置中／縮板；固定38pt隨字級摘要槽，效果／費用／結果或非法原因共用。行動圖示與名稱一行、費用一行，法師操作列保留槽。XXXL還抓到模式兩行與方向一行列高差、板面移動1.67pt，改兩種按鍵共用可縮放高度並clamp最小44pt，XXXL／XS重驗。只修正常手機呈現，iPad既有label、renderer、投影／命中、Domain、AI、技能、素材、音訊與存檔相較1022输入hash不變。

237凍結輸入仅UI View與UITest兩檔不同；本機可恢复来源ZIP239項通过hash與CRC，不是Git提交。最終來源390兩／375兩／iPad旋轉一方法，5成功0失敗；此前各階段合計17成功、1真實字級失敗已保留與修正。無效Simulator destination於測試前中斷；一次iPhone啟動CLI參數順序在啟動前遭拒，改正後成功，不重新安裝。沒有重跑或重複累計212Swift／38Golden。

開發簽名Release1023／version0.10.11／同bundle／iOS17／237source／PrivacyInfo／profile兩機檢查通過。Wi-Fi更新兩台，iPhone正常啟動，更新及啟動後30舊檔與六聲音偏好保持；iPad27舊檔與六偏好保持但啟動Locked，正常啟動待解鎖。390各正常狀態板面390×439，375固定328×369.5（比1021面積+40.5%），不再以1022idle+75%宣稱所有狀態。

買斷方案已定：1.0付費下載、台灣目標NT$60、無廣告／訂閱／內購，TestFlight作免費測試。完成本機計畫／商店草稿／權利與隱私清單更新，4文件11相對連結核對；未存取AppStoreConnect、接受契約、設定價格、邀請、上傳、送審。Owner的好玩／順手回饋保留，1023實機選取／取消、完整局、新人、聲畫、語音與素材權利未冒稱通過。

證據 artifacts/ui-board-focus-1023/REPORT.md／VALIDATION.json／GEOMETRY_COMPARE.json／install/RESULTS.json／paid-doc-validation-final.json。原1022與所有隔離成果保留；未commit、push、merge、TestFlight或發布。下一步僅Owner實機選取／取消驗收與固定首版收尾，不再加玩法或大美術。
## 2026-10-11 19:20｜送審草稿、免費價格及支援頁準備

ASC 1.0 已儲存繁體中文介紹、關鍵字、副標題「英雄棋盤對戰，兩步安排攻守」、遊戲／策略遊戲／桌上遊戲分類及免費下載價格。年齡問卷依實際廣告、奇幻戰鬥、武器與競賽填寫，Apple 計算一般 13+；地區差異另記。仍採手動發布，沒有上傳 build 或提交審核。

Owner 已簽付費協議，但目前實際頁面為「使用者資訊待完成」，兩份問卷仍「缺少稅務資訊」。已交本人商務頁連結；不填寫、推測或保存稅務／銀行答案。永久解鎖 NT$60 與台灣首發仍待 Owner 明確決定。

皇冠戰略專屬支援、隱私政策及 app-ads.txt 已以独立 Sites 專案部署為私人候選，來源提交 49b8703；公開存取待 Owner 授權，尚不能填入正式 App 或 AdMob。這不是遊戲 repo 的 commit／push，1024 凍結包保持不變。新原生截圖及限定回歸另存 artifacts/release-submission-1025/，1025 只是送審準備目錄，不代表已有 1025 App。

首次手機擷取四方法為三通過、一失敗：iOS 26 的 SwiftUI 離場 alert 將同一動作呈現為巢狀同名按鈕，XCTest 全域 selector 不唯一。僅將測試限於具名 alert 並取 firstMatch；不修改正式離場流程、棋規或偏好。新執行結果另記，不把原失敗抹去。正式商品 metadata、UMP、隱私申報、權利確認、Sandbox、發行封存及雙機產品驗收仍待完成。
## 2026-10-11｜本人稅務回覆後的送審續辦

Owner 表示填寫完成後已重新核對 Apple 商務：台灣稅務「已完成」，銀行「正在處理」，美國 Certificate 與 W-8BEN 仍「缺少稅務資訊」，付費協議仍未生效。已打開美國聲明供本人填寫；Agent 不代填或提交財務／稅務答案。支援網站公開、永久解鎖 NT$60 與首發地區的先前問題仍待具體回覆。

已建立並下載「Crown Strategy App Store 20261011」發行 profile，沿用現有 Distribution 憑證，核對相同 Bundle ID、get-task-allow=false、無裝置名單及憑證指紋後安裝至本機。正式設定仍為 draft，公開 URLs、商品／UMP／帳戶 Gate 未通過，沒有封存或上傳。ASC 已儲存關閉 Mac／Vision Pro 供應，首版限現行 iPhone／iPad 範圍；不改免費下載價格或自行設定國家供應。

首頁限定回歸已完成：第一次重跑選錯測試類別、實際零測試，不計通過；接著一次真實執行仍失敗，查明前次 selector 修正在另一個 legacy-resume 方法。已還原該處並只修實際失敗的首頁方法，重新建置成功；03執行1方法PASS／0FAIL、exit0，保留存局／偏好／續玩斷言。iPad Pro 13 M4／iOS18橫向兩章與棋盤／控制項方法亦1PASS／0FAIL、exit0。正式 runtime、Domain、AI、資源及存檔不變。原失敗／零測試日誌保留，最新結果追加至 `artifacts/release-submission-1025/`，不覆寫1024凍結包。

五張未修改原生候選圖已準備，均來自1024 Debug Simulator，不冒充最後1.0真機。iPad原生PNG為2064×2752、EXIF orientation8，呈現2752×2064橫向；保留原檔與此差異，正式RC上傳時再核。profile補齊後pre-archive仍因公開URL、IAP／UMP與本人帳戶Gate拒絕執行，沒有以輸入草稿繞過封存限制。


## 2026-10-11 — 1.1 魔物戰場獨立原型

Owner 要求切出 slice 後往下做。於 codex/v11-monster-battlefield 工作樹先做 MOB-01 中立占位與 MOB-02 主動 0／1 AP 討伐比較；不更改 1.0 checkout、不納入發布。合約／驗證與後續黏彈／影步 gate 見 docs/v11/PLAN.md。真人好玩度與投入回報未驗收。

Owner 表示現在沒空測、要求繼續。真人比較不作為工程阻擋；MOB-03a 黏彈與 MOB-03b 單隻暗影狼／影步按候選合約接續實作並自動驗證。雙怪同場、Bot、正式存局與真人平衡仍另待辦。能力與取得重播見 artifacts/v11/mob-03/REPORT.md。

### 2026-10-11：1.1 MOB-04 雙怪原型

Owner「再往下做，下次才測」：雙怪同場／多份戰利能力在 codex/v11-monster-battlefield 獨立工作樹推進。合約與驗證見 docs/v11/PLAN.md；真人取捨延後，不作為工程 gate。未授權發布、提交或推送。

MOB-04 已完成工程驗證：188 項 Swift／7 項 UI 操作、62 組 Golden／164 steps、雙怪 14 分支與原單怪 28 分支通過；Debug／Release 編譯通過。人工好玩度與成本平衡留至下次。

### 2026-10-11：魔物圖樣依角色風格 skill

生成史萊姆／暗影狼兩張透明棋盤候選，已接入隔離 1.1 Debug Lab；最新兩項操作與 Debug／Release build 通過，候選 PNG 排除 Release。原圖、完整 prompt、reference／RGBA hashes、32/48/64px QA 保存於 assets/candidates/v11-monsters/v01。真人辨識待下次；production=false，無提交／推送／發布。

## 2026-10-11 怪物圖樣 v02 預覽里程碑

依 Owner 看效果要求，完成新版史萊姆簡化候選＋Owner 新狼原圖、32/48/64 px 對照與 9×9 明暗靜態棋盤示意。三檔透明／邊界／來源 hash 驗證通過；尺寸與示意已目視。現有 App 仍沿用 v01；本次沒有更換消費端資源或遊戲規則。來源與完整提示在 `assets/candidates/v11-monsters/v02-preview/`，證據 `artifacts/v11/monster-art-v02-preview/REPORT.json`。正式採用與真人辨識仍待後續決定／測試。

## 2026-10-11 v02 圖樣載入測試版

依 Owner「載入進去讓我測試」，已替換獨立 Debug MonsterLab 引用與 Release 排除檔名；兩檔實際 Debug 資源存在／Release 排除、來源 hash、Debug／Release build 通過。App 已啟動，新史萊姆單怪画面確認。兩個 UI tests／16 失敗斷言；雙怪畫面與操作尚未確認。CUA 回報 Mac 鎖定，已請 Owner 解鎖；原因尚未定案，不提前報驗證完成。證據 artifacts/v11/monster-art-v02-integration/REPORT.json 與 DIAGNOSIS.md。遊戲核心、1.0 checkout 與正式發布未修改。

## PRESENT-01 — 魔法之手聲畫候選

2026-10-11 Owner 授權先做動畫與聲音。以本機保存 M3 commit c13f23e019eef6d5492a511c93e55df6dd6007f7 作 A（非正式 main），B 共用原畫與 Domain receipt，700ms 時序及 CC0 音層。獨立 Debug lab、候選資源與 iPhone bundle。Motion 30 tests 已通過；native build／UI／小尺寸錄影／device delivery 待驗證。第一次 Swift 編譯小數字面值已修正；native build ENOSPC 已保留失敗 log，只清可重建 own cache，未刪素材／原始證據。Game Feel 草稿補同時間軸及音訊來源／取消流程，未安裝新 Skill。

最終法師候選工程驗證：Motion 30／0、原生 UI 4／0、最終 Debug／Release／簽署 device build 通過，獨立 iPhone App「TacticalGo 聲畫」最新安裝成功。七個資源 hash 一致，Release 排除；本輪 Domain／規則 hash 不變。A／B 原生模擬器錄影與清楚標示的後混 SFX 預覽、320 pt 密集 9 路及 32／48／64 px QA 保存。出手前取消保留 0.22 秒门檻，測試先等首屏布局；早期失敗與修正見 artifacts/v11/present-01/REPORT.md。手機啟動回報 Locked，實機 A/B 錄影、真人聽感／辨識、iPad、其他職業／怪物聲畫及一般對局整合仍 pending；不以工程 PASS 宣稱完整演出系統或 Owner 驗收完成。無新提交／推送／合併／發布。


## PRESENT-01 Owner 品質驗收退回（最新狀態）

Owner「比之前更難看 聲音也很差」。工程通過仍保存，但演出與聽感明確 rejected，撤下推薦；尚未改寫或安裝新候選。原比較 A 是未驗收 M3，沒有包含 Owner 原本一般對局，基準需確認。下一修正版須先比較真正原版、body-only 演出與孤立音效短樣，再接完整 Lab；不以更快時序、更多粒子或來源 license 當作品質證據。已詢問 Owner「之前」指一般對局或 A，待明確基準後進行依賴修改。記錄 artifacts/v11/present-01/OWNER_REVIEW.json。

## PRESENT-02 — 手機 1.0 基準已確認

Owner 回答「手機1.0的版本」，取代上一節基準待確認的狀態。裝置原一般 App 為皇冠戰略 build1023；从簽署 SOURCE-1023 封存唯讀取得真正 R1 時序、原角色／兵卒／底座／棋盤及音效。隔離 Debug Lab A 恢復此固定法師基準，上一版 B 保留為已退回診斷。還原不是演出或聽感改善；新藝術候選仍待製作及 Owner 驗收。

已保存原生模擬器短樣，後混原 SFX，明示非實機錄音、不含 BGM／語音。Motion31/0；原生4/0涵蓋減少動態／靜音／背景／復原及提子。首次背景復原失敗與診斷保留；XCTest tap 發生在回前景縮放中的視窗，改待視窗恢復原幾何後通過，未修改 Domain 或復原邏輯。最終 A/B 測試另補明確選 B，專項1/0通過。Debug／Release編譯、20來源hash／8Debug素材／Release排除與保留證據收據通過。手機原1.0與其他 agent checkout 未更動，本輪沒有新手機安裝、提交／推送／合併／發布。證據 artifacts/v11/present-02/REPORT.md。

## PRESENT-03 — 依手機原版製作法師候選 C

2026-10-12 Owner「透過這版來改」。保留1023原畫、立體棋盤、0.95秒節奏與原四音效；C握杖持續到落定、收斂身體位移、披風跟隨，改用稀疏晶體／牽引／落點光效及可關閉的CC0氣流音層，無語音／BGM。A仍可切回基準。原生模擬器五段正常速度片段與32／48／64姿勢已目視；手機獨立「TacticalGo 聲畫」安裝及啟動成功，原一般App沒有被本輪修改。

Motion33/0，原生4/0及小尺寸／音層開關專項1/0，Debug／Release／device build、簽署、來源及device hash、Release排除、Core／規則不變與保存證據收據通過。第一次取消0.695秒不符0.22秒門檻，改非同步Canvas後原門檻重驗通過；不宣稱跨裝置首播性能。新增專項首次0 tests未計入，專用test runner重新安裝後真正執行1/0。原失敗、0項xcresult、VFR短尾初版與原錄影保存。預覽音訊後混，非實機收音；真人品質未驗收，完整一般對局及其他職業／怪物演出尚未完成。無提交／推送／合併／發布。證據 artifacts/v11/present-03/REPORT.md。


## PRESENT-03 退回／PRESENT-04 新方向

Owner 指出 C「還是差不多，沒有學到爐石戰記的精隨」。C 品質 rejected；既有工程證據不作為藝術驗收。D 改用原創有形魔法手的伸出／抓穩／推開／放手、士兵受力與撞擊，重新設計三段材質聲音，而非稀疏粒子或微调。基準 A 保留1023；新時序與素材、聲音来源／驗證計畫見 artifacts/v11/present-04/PLAN.md。仍限隔離 Debug Lab，Owner品質待验收，無提交／推送／合併／發布。

PRESENT-04 native36 Motion/6 UI, Debug/Release/device builds and separate phone Lab delivery verified. Owner accepts animation; audio remains rejected as weak. AUDIO-05 keeps accepted visual assets/poses/timing unchanged, researches primary public sound-design methods and adds an isolated stronger audio profile with level-matched comparison. No release authorization.


## VOICE-06 — prioritize English casting voice

Owner prioritizes casting voice and chooses English. D animation remains accepted
and unchanged. Two new offline Qwen VoiceDesign `Move aside!` takes, 0.862/1.040s,
normalized dry at -18dBFS RMS; independent unprompted Whisper recognizes both.
Separate Lab defaults voice on, retains A baseline, offers two takes and voice
volume, ducks E/D SFX to42% during speech. Raw/prompt/seed/model/license/source
pins retained; no cloning, paid inference, rules or release changes. Native
verification and separate device delivery underway; acting quality Owner pending.
AUDIO-05 prior native suite actually executed7 tests/0 failures; its stronger SFX
is supporting work, not the complete answer to the new voice priority.


VOICE-06 final Owner steering: second take is relatively better; default B with
A retained. B-default native8/0, Debug/device builds and separate phone install
and launch passed. Raw/processed speech uses pinned existing offline model and
no reference speaker; voice underlays no rules. Accepted D animation source
pins unchanged. Final Release/resource saved-evidence receipt passed; listening
quality still pending, no general-match integration or release.


## WARRIOR-07 — English Bastion and visible shield effects

Owner accepts continuing after mage voice B; next class is warrior Bastion.
Second warrior `Hold the line!` take B is relatively preferred and becomes
default. Original phone1023 hero art and existing cutout garment backing are
identity-pinned; shields split into two visible projections at confirmed
summon targets, strike with both pawn landings at .58, dissipate by .98.
No gameplay buff or rule change; accepted mage D/B remains selectable.
43 focused Motion tests pass after Owner steering. Final native captures,
both-class UI lifecycle/voice verification and separate device delivery are
in progress. Owner effect/acting quality remains pending; no commit/push/release.
Plan/source/provenance/failure evidence: artifacts/v11/warrior-07/PLAN.md and
assets/candidates/warrior-07/.

WARRIOR-07 final:43 Motion/0,12 native UI/0 (8 mage +4 warrior), final
Debug/Release/device builds and separate phone install/final launch succeed.
Five actual native scenes and labelled postmix, original32/48/64pt and derived
1x pixel review retained. Saved delivery verification checks baseline pins,
resources, WAV headroom, Release exclusion and source/receipt integrity.
Source/provenance and prior failures retained; report artifacts/v11/warrior-07/REPORT.md.
Owner B voice is relatively preferred; new shield effects await viewing.
No full-match/Bot integration, general App1.0 change, commit/push/merge/release.

## 2026-10-12 1.1 十小時候選開發

依Owner十小時自主授權，在codex/v11-monster-battlefield獨立工作樹執行。完整順序與截止見 [AUTONOMOUS_12_PLAN.md](v11/AUTONOMOUS_12_PLAN.md)。EXPANSION-08/PLAY-09/FEEL-10/CONTENT-11已具工程候選，235/0 Swift與首輪20/0原生驗證；DELIVERY-12尚需新的v02輪廓、戰士/反制回歸、正常速度影片、Release隔離與獨立手機安裝。沒有提交、上傳、合併或發布。

02:49候選交付：上述功能、14張有效原生動作圖、6段正常速度原生畫面/後製混音、獨立候選存局及牧師真眼/法師反制完成；235/0 Swift和27項不同原生UI測試通過。Debug/Release/簽名真機build、Release素材排除、來源pins及編譯魔物像素一致、獨立手機安裝通過。手機鎖定造成啟動未驗證，無真機聲畫錄影；真人聲音/美術/玩法待窗口後。兩組無效截圖與失敗驗證保留；scene定格資料與正常播放取消分離、存局解除定格均有新回歸。範圍提前完成後不擴大，11:37:48後由既有heartbeat統一回報並暫停。完整邊界與影片：v11/OWNER_REVIEW_12.md。

## 2026-10-12 08:31 Owner 要求安裝

依 Owner「幫我安裝」，重新安裝現有已簽名的獨立 com.tacticalgo.prototype.presentationlab 至配對 iPhone 16 Pro，devicectl 安裝與啟動均成功（PID 35718）。此前手機鎖定的啟動失敗保留為歷史證據；當前已可啟動。未重新建置、未改規則/聲畫來源、未動普通手機1.0；沒有真機聲畫錄影或真人驗收證據。新證據 artifacts/v11/feel-10/device-install-owner-20261012-0031.json 與 device-launch-owner-20261012-0031.json。既有235 Swift/27原生UI結果未重跑。十小時窗口其餘安排不變；11:37:48台北後統一回報並暫停 heartbeat，不需要再重複安裝或啟動。

## 2026-10-12 08:46 同一手機App的1.1整合

依Owner「直接合併進去讓我測試」，Debug普通首頁新增1.1新玩法入口與返回首頁；重新建置 com.tacticalgo.prototype.herobody／皇冠戰略1.1/1101，安裝與啟動成功PID35893。3項原生UI通過（無flag新入口→技能預覽確認/Undo→回原對戰、既有擴充首頁、原召喚取消/確認/Undo），Simulator/Release/簽名手機build和codesign通過。既有54份聲畫資源hash一致。安裝前Documents/Preferences已備份，更新後六份Documents hash未變；不宣稱全部設定runtime驗收。已接受法師D/英文B、戰士英文B保留。

本次是同一手機測試App整合，不是Git main合併或1.1公開發布；未修改另一agent的1.0上架工作樹/封存，未commit/push。Core與聲畫素材未改，235 Swift/27不同原生UI保留為前輪證據，不重复累計。新證據 artifacts/v11/integrated-phone-13/DELIVERY.json；试玩入口更新至OWNER_REVIEW_12.md。截止後统一回報並暫停heartbeat；現在已有成功啟動，無需再重複安裝/啟動。真人趣味/聲畫/美術/平衡及真機錄影仍待。

## 2026-10-12 09:22 Owner 修正：完整接入原對戰（進行中）

Owner要求四職/第二技能/魔物直接接入原選角與棋盤，不能另開一頁；13版openExpansion已撤銷。14版以GameStore提供同一界面的目前對局，擴充session為新模式唯一盤面擁有者，原規則session/Bot仍獨立保留。新牧師奉獻為1 AP/2能量，只移除兩格內己方普通兵，不搬移或補子；新castOffering action保留舊castSanctuary存局重播意義。已跑完整239 Swift/0；6項階段原生UI/0後，補齊技能標題、BGM復原/施法ducking，正跑Native-delivery九項最後回歸，不提前宣稱通過。

已修正Timeline外層識別標籤覆蓋格點、直接格點操作未更新預覽訊息；Mute測試需點實際switch thumb並斷言值，修復後通過；牧師測試合法開局增加敵方回應與召喚後再奉獻，避免試圖重返舊盤面的Ko。失敗日志與xcresults均留存。當前Debug Simulator/Release/已簽名herobody1.1/1102均建置通過；手機離線、備份未成功，1102未安裝（先前1101有成功紀錄）。剩餘：九項結果、畫面/素材/簽名核對、可用時備份後更新手机。入口與聲畫採用仍待真人，未改1.0上架checkout/封存或Git main，未commit/push/發布。詳見INTEGRATION_14_CONTRACT.md、artifacts/v11/integration-14/。

## 2026-10-12 09:28 同一選角／棋盤候選完成，手機待連線

14版已撤銷另頁入口；四職選角、三職第二技能、魔物/戰利、英文聲畫、背景音樂ducking、保存/續玩/Undo直接走原PlayableGameView。牧師奉獻為1 AP/2能量只移除兩格內己方士兵，不位移或補子；舊Sanctuary重播意義保留。完整239 Swift/0，最終同一build九項原生UI/0；階段六項不重複加總。六張操作圖與四職首頁已觀看。54份聲畫素材byte相同，兩隻魔物的原生解碼像素相同；Release排除真實檔名slime-token-v02.png/shadow-wolf-preview-v02.png與PresentationLab。Debug Simulator/Release/簽名herobody1.1/1102與codesign通过。

剩餘唯一工程交付阻擋是iPhone unavailable；artifacts/v11/integration-14/install-20261012T012446Z/devices.json明確未嘗試安裝。1102已簽名保存，不能沿用1101成功紀錄宣稱1102已在手機。後續heartbeat若手機可用，可執行bash scripts/install-unified-integration14.sh備份再更新；成功後重新執行python3 scripts/verify-unified-integration14.py更新DELIVERY.json並記錄實際結果，不重跑來源未變的239/9、不重複已成功安裝。手機持續離線/鎖定則保存成品，不等待或向Owner提問。無新增功能待辦，不以填滿窗口擴大範圍。

工程驗證不等於真人樂趣/配音演技/美術/平衡/素材採用；新玩法目前本機雙人，原Bot仍三職原規則；沒有真機声画录像。未修改1.0agent checkout/封存，未commit/push/main合併或發布。最新試玩/畫面/真實邊界OWNER_REVIEW_14.md；最終證據artifacts/v11/integration-14/DELIVERY.json。11:37:48台北後統一整理並暫停heartbeat。


## 2026-10-12 09:53 Owner授權TestFlight（15）

Owner新指令「幫我上傳到TestFlight讓我測試」授權本輪1.1 beta上傳，取代十小時窗口的no-upload限制，沒有授權App Review/公開發行或Git整合。建立Beta組態/scheme以TACTICALGO_V11包含完整原選角/原棋盤擴充，保留Release組態；App Release最佳化，DEBUG根Lab/啟動測試注入不開啟。簽名herobody1.1/1103 archive及internal-only IPA匯出通過；signature/get-task-allow=false/icon/privacy54聲畫byte/兩魔物原生像素通過。Beta原生2+1項/0實際原首頁與玩法練習操作，239Swift套件來源逐檔一致沿用14結果。

實際上傳exit70 Failed to Use Accounts；Xcode Apple Accounts為空、ASC瀏覽器也回登入頁。上傳未成功、Apple處理和Owner群組可下載均未核對。簽名IPA保存，已請Owner在Xcode登入完成後回覆，不向聊天索取密碼。接續bash scripts/upload-testflight15.sh會先驗SOURCE_PIN並防重複成功上傳；成功後查看既有App6821588889的內部TestFlight群組。最新OWNER_REVIEW_15.md與artifacts/v11/testflight-15/DELIVERY.json。沒有修改1.0agent工作樹/封存/送審、沒有commit/push/main merge/公開發布。1102真機離線未安装是另一項歷史交付，不冒充1103 TestFlight。


## 2026-10-12 10:28 TestFlight登入界線

Owner回覆登入後ASC網頁已驗證登入成功，Xcode上傳帳戶仍空；續傳exit70 Failed to Use Accounts，未上傳1103。已開Xcode登入sheet並請Owner在此完成驗證；不再要求重登網頁。ASC原無內部群組，按自測目的新建手動分發Owner 1.1（d4c66485-705a-45b7-8e5f-9aaf5bbefe54），僅現有帳號持有人1名；0build/沒有可用建置版本。未加入1025或其他使用者，未啟用自動分發、公開外部連結或送審。來源/簽名IPA未變，不重建/重跑測試。下一步Xcode登入後upload-testflight15.sh續傳，再查處理並加1103到Owner群組；最新OWNER_REVIEW_15.md/ASC_GROUP.json。


## 2026-10-12 10:39 TestFlight 1103 已交付

Owner完成Xcode登入後，1.1/1103續傳exit0/Upload succeeded，Apple處理完成。內部only build8549d8db-ff8a-4692-9a3d-35c862638766已加入Owner 1.1，群組1人/1build正在測試，Owner已邀請；僅1103、不加入1025/其他使用者。此build繁中試玩內容已保存。最終DELIVERY.json三項true（uploaded/Apple處理/Owner群組可測試）；手機安裝及真人聲畫/平衡驗收未由此證明。簽名來源/54素材/2魔物/Beta3項與239來源未變證據保留，未重建/重跑。成功辨識腳本修正小寫Upload succeeded並跑真實失敗/本機export/成功upload三fixture，不重複成功上傳。

上傳請求完成，Owner可從Apple邀請信開TestFlight安裝皇冠戰略1.1/1103並試本機雙人/玩法練習。最新OWNER_REVIEW_15.md及testflight1103-ready.png/owner-invited.png。未修改1.0上架checkout/封存/送審、未commit/push/main merge/公開發布。窗口剩餘不新增功能或重複成功交付；11:37:48台北後原定整理並暫停heartbeat，工程PASS不等於真人品質已接受。


## 2026-10-12 11:09 Owner回饋：iPhone 9×9太小（16）

新授權回饋進入獨立可逆Slice16：原投影/規則不變，手機9×9以focused視窗裁外框留白、增加棋盤空間，行動區精簡，完整技能說明在info sheet；所有81格/邊角/底部行動/法師方向保留。7×7與iPad原框不變。Visuals8/0、主手機乾淨串行4/0＋小手机1/0；402pt格36.67pt，小375pt為28×28.5，未聲稱44pt/真人已接受。七張當前原生圖已檢視。先前fixture模式/按鈕大小寫錯誤與兩主runner重疊非正常退出均保留且不作交付依據，修正後serial通過。

1104簽名archive/IPA、54聲畫byte與兩魔物像素、來源固定PASS。只變Visuals/Anim01Geometry，Core/Content/Bot/Motion/Records來源未變；239為前輪完整Swift，不報當前全部重跑。已在進行upload-phone-board16.sh，成功後查Apple處理並只加1104到既有Owner1.1；1103保留，不重複傳成功包。最新OWNER_REVIEW_16.md、artifacts/v11/phone-board-16/DELIVERY.json。未動1.0agent checkout/封存/送審或Git發布；真人手機可讀性仍Owner驗收，截止後不再新增實作。


## 2026-10-12 11:18 手機9×9放大版1104已交付

1104已成功上傳/Apple處理完成，build93af286d-5699-4d1f-add8-b51915d16764，既有Owner1.1只Owner1人/1103及1104兩build正在測試；1104試玩說明已保存，1103保留。DELIVERY三項true。主native串行4/0＋小1/0、Visual8/0、54声画/两魔物/签名/源固定PASS；圖與量測已核：402pt手機格36.67pt，小375pt格28×28.5。Core/Content/Bot/Motion/Records未變，239完整Swift為歷史結果，不報全套重跑。

手機9×9布局改善請求的候選完成，Owner可TestFlight更新1104，比較畫面與觸控大小。ASC顯示Owner已裝1103/16Pro/iOS27，1104真機安裝/真人可讀性驗收仍待；不把Simulator當iOS27真機。最新OWNER_REVIEW_16.md及phone-board-16/DELIVERY.json、testflight1104-ready.png。沒有新增角色技能聲音或修改1.0送審/Git發布，截止前剩餘只保存/讀取有意義的新輸入，不重複已完成驗證/上傳；截止後整理並暫停heartbeat。


## 2026-10-12 11:56 Owner新回饋：電腦對戰1.1與戰士重量（17）

十小時自動窗口已結束，heartbeat已按既定要求暫停。Owner11:42/11:43明確指出solo仍舊規則/舊棋盤，要求新技能預設、取消切換；另要求戰士重量感。此輪新授權只在1.1工作樹修正，不動1.0 checkout/送審、Git發佈。

根因是 lobby solo 強制useExpansion=false、三職/7x7，再由legacy GameSession/SwiftBoard/CombatAudio執行；Bot拒絕expansion/monster。現在solo也走同一ExpansionLabStore/ExpansionBoard與英文B確認事件，四職/第二技能預設；大廳版別切換撤銷，魔物/盤面/執色/難度保留。Bot搜尋Core合法技能/討伐/戰利，配對上限256，先排序主將戰線且不移走貼主將的牆；規則完整列舉預設不變。solo元資料存局可選且舊1.1預設雙人，舊1.0重播保留。undo跨過AI回覆、世代/盤面守衛、輸入鎖、聲畫尾韻等待保留。戰士原畫weight蓄力/快速下擊/60ms停格回彈；接觸.58/SFX/英文B保持。

250完整Swift/0（swift-delivery.log）；階段Beta4/0，最終6 UI正在跑。Debug與Beta同時建置發現ios/Build共用DB鎖，Debug失敗保留，不作交付證據；改串行後重跑Debug安全2項。原階段測試fixture怪物未配置/瀕死邊角救援實際仍必敗/舊拒絕Bot期待與初次cap漏遠端勝機均保留，修正fixture與主將優先排序後250/0。下一步finalBeta/Debug、新1105簽名/素材/源固定及原TestFlight內部Owner交付，真人AI/動畫品質待Owner。


## 2026-10-12 12:12 17完整工程候選1105已上傳

完整Swift250/0，最終Beta6/0（實際大廳/雙執色/四職/魔物/第二技能/放大棋盤/奉獻/復原續玩），DEBUG安全2/0且0skip。Debug target未定義DEBUG導致兩工程test skipped，不冒稱pass；重跑明確定義DEBUG後先發現測試錯誤期望動畫未落定就顯示勝負，按原契約修正測試，最終2/0。原失敗/skip/DB鎖/早於export的驗證全部保留不加總。250為最新完整套件，無沿用239/235當本輪測試。

原畫戰士重量姿勢與英文B確認事件共享，原始54素材byte對1104及新archive/IPA皆相同，兩魔物原生像素相同。戰士前後正常速度Simulator無聲影片同局面/資源/結果，非手機聲畫；角色/AI/樂趣仍Owner待驗。主原生圖已檢視，solo新版棋盤可用。署名/Privacy/圖標、來源固定與archive/IPA核對PASS。TestFlight1105實際upload exit0/Upload succeeded在12:10:10台北完成；Apple處理/Owner群組可下載尚待網頁核對，不由上傳成功推論。

唯一後續小字改動為電腦討伐Caption区分暗影狼/史萊姆，無新控制/規則/時序；簽名archive重新編譯當前來源，原生已驗證玩法行為不變。SOURCE_PIN涵蓋當前app/套件/測試/project。最新OWNER_REVIEW17與solo17 DELIVERY；接續Apple處理後只加1105到現有Owner1.1，保留1103/1104，不重傳。1.0 checkout/封存/送審與Git發布未動，原十小時heartbeat已暫停，本輪新Owner回饋修正。


## 2026-10-12 12:20 17完成：1105已TestFlight可測

Apple已處理1105（build0c69c29f-572f-46d9-a749-42356512a668），只加入既有Owner1.1內部手動群組，1人/1103、1104、1105三建置正在測試；繁中個別build試玩說明已保存。ASC看見Owner目前裝1104/16Pro/iOS27，但1105真機安裝與真人重量感/聲畫/AI品質未證，不能用Simulator影片代替。

完整Swift250/0、最終Beta6/0、Debug2/0且0skip；签名/源固定/54素材對1104+新archive/IPA一致/兩怪像素PASS。失敗、skip、DB鎖、早於export的驗證與DEBUG測試預期修正保留，階段Beta4不加總。最後討伐狼/史萊姆標題小字修正由最終簽名archive重編譯，無控制/規則/時序變化，驗證界線記在VALIDATION_BOUNDARY。正常速度Simulator無聲戰士前後同一receipt，來源原畫/英文B不變。

Owner回饋請求的可逆17候選完成，不再自行擴scope/重傳。從TestFlight更新1105，新開一般電腦對戰試玩；舊1.0局仍原規則、舊1.1缺solo元資料按雙人還原。最新OWNER_REVIEW17與solo17 DELIVERY/ASC_BUILD/ASC_GROUP、testflight1105-ready.png。1.0 checkout/封存/送審、Git commit/push/main merge未動；十小時heartbeat已暫停。工程PASS不等於真人品質接受。


## 2026-10-13 Owner 授權全遊戲介面重做（19）

Owner 指定新推送的 codex/v11-monster-battlefield，並指出底部仍像一般表單，要求整體以爐石呈現品質自主迭代。此新指令授權共用外觀和操作呈現，沒有 Git／TestFlight 發布授權。以004ed4c建立codex/v11-game-interface，保留其他checkout。

本輪新增GameInterface共用材料／插畫圖集／技能卡／能量寶石，四職200pt操作区、戰利入口、結算替換，以及選角／HUD／教學／支援頁面樣式。規則、PhoneMatchLayout、原棋盤素材、聲音／動畫排程未改。Browser50布局與9類fixture互動通過；原生UI回歸已更新但Windows無Xcode，build、native UI、iPad、VoiceOver／Dynamic Type與真機未跑，不能沿用1106測試。報告docs/v11/GAME_INTERFACE_19.md；下一關是Mac編譯與同局面375／402原生畫面核對，音畫整體品質尚未達成驗收。沒有提交／上傳／合併／安裝。

## 2026-10-13 UI20：主畫面與 icon 先完成

Owner認可新風格並指定先主畫面與icon、再動畫。沿用004ed4c來源及codex/v11-game-interface隔離工作樹，自主完成安靜背景／霧面HUD／手繪木框、44pt英雄徽章、能量晶石與AP標記；七技能各有獨立構圖，保留牧師只有奉獻。大廳選角增加勾選、開始對局置於主要位置、續玩和棋譜入口沿用44pt共用樣式。

圖集先後修正跨格串色，框先後調薄並減少外緣留白；完整prompt、原始來源／hash、前版與當前375／402圖保存artifacts/game-interface-20。Browser50布局／9類fixture互動與21個32／48／64圖示樣本通過，這不是原生執行或玩家品質驗收。Windows沒有Xcode，native build／UI／VoiceOver／Dynamic Type／iPad及真機仍NOT RUN。報告docs/v11/GAME_INTERFACE_20.md。

先前開始的AV21七個tracked檔案及兩個新Motion檔案已完整保存在artifacts/av21-pending，並自本輪active runtime撤下；混合UI19測試只移除AV21新增的敗北assert。奉獻語義／終局cue路由仍是下一切片待修，不能宣稱已解決。接續先Mac核對UI20原生畫面，再以同一UI做四職完整演出；未提交／push／merge／安裝／TestFlight發布。

## 2026-10-13 AV21：Owner 明確授權開始四職動畫

Owner在UI20候選完成後指示「然後開始做動畫，以爐石品質為目標」，因此恢復保存中的AV21候選並開始可逆呈現實作；缺少Mac不阻塞候選開發，但原生整合仍待驗。七技能加入棋子受力、落地壓縮／回彈、交換弧線、兩段連鎖、奉獻原點消散；提子／主將地面圈與玩家視角終局cue接線。結束回合透過commit receipt讓draw可收束。規則、UI20原畫／主畫面及棋盤frame未變。

browser工作台tools/animation-21可播放七技能、正常速度／時間滑桿／降低動態、375／402與聲音預設關閉。它是獨立Canvas路徑示意，並非SwiftUI或Domain執行。正常播放／取消／端點與路徑分離等結果保存在artifacts/animation-21；Swift八項新測試、原生UI及IntegratedAudioAudit已寫，NOT RUN。Windows／WSL沒有Swift compiler，也沒有Xcode／iOS SDK；基線與修改後原生build均未驗證，不能沿用歷史250或1106當本輪結果。

報告docs/v11/ANIMATION_21.md；接續Mac編譯／Swift／原生UI與整合音訊，再看同局面聲畫錄影調整。沒有Git commit／push／merge、安裝或TestFlight授權／發布；爐石整體品質仍未驗收。

## 2026-10-13 AV22：Owner 要求持續逼近爐石品質

沿用UI20與AV21候選，保留前輪来源后新增原創8格局部特效，依成功receipt蓄力／接觸取樣；連鎖新增第二次蓄力，奉獻新增抬手釋放；非受影響棋子短暫退後至88%且完整恢復，危險與選取仍在特效上方。Domain規則、角色原圖／clean plate、UI20源與音訊排程不改。

tools/animation-22以來源分層polygon與before／after pose keyframes重建比較，修正AV21整圖轉動工具限制；新增24个32／48／64px樣本、密集標本與對等細節放大。這些是Canvas候選，不是原生或合法Domain執行。原生已新增三項回歸但NOT RUN；Windows無Swift／Xcode，原生編譯／聲畫／FPS／輸入恢復未驗。候選材質與兩個出力拍点改善，但爐石整体品質尚未達成。

完整prompt／原圖hash／來源快照／失敗與最終檢查在artifacts/animation-22；報告ANIMATION_22.md。下一關Mac原生同局面375／402密集聲畫與工程回歸；沒有Git或TestFlight發布。

## 2026-10-13 先推送，再做 AV23 節奏

Owner明確授權「先push然後再優化」。UI19／UI20／AV21／AV22候選已推送codex/v11-game-interface，remote核對354acb22ad77d8e9bdb2b3d5d400fc3e4084e893。HTTP408兩次後精簡重複影音，完整未發布歷史仍保存在本機refs/codex-safety/av22-unpublished-full-20261013；其他工作樹未改，沒有hook bypass／主線合併／TestFlight。此段更新前面歷史記錄中的「未push」狀態。

接續AV23分開visual／input／audio窗口：一般成功動作演出結束後恢復操作，普通下一手可讓已落定技能配音收尾；新技能／魔物戰利／終局替換舊聲音，復原／背景／中斷等完整停止。音樂duck仍涵蓋配音，不隨輸入提前恢復。保留UI20／AV22原畫、WAV與規則。來源推導盜賊減少約0.579秒等待，非真機實測。

Browser27項與來源／資產不變核對通過；第一次matchMedia事件等待及WAV四捨五入的harness失敗保留。三項Swift窗口測試及六項實際store／音訊audit新增但NOT RUN，Windows無Swift／Xcode。報告docs/v11/ANIMATION_23.md；完成來源檢查後同分支提交與推送，下一關Mac原生編譯／串行UI音訊／四職密集聲畫，尚不能宣稱爐石品質或裝置延遲改善已驗。

## 2026-10-13 AV24：90%品質目標仍未完成

Owner要求分析距離爐石品質，未達則繼續優化，至少90%以上才可停止；另明確要求本輪push並更新剩餘plan。最新候選基線371718e已推送；source仍004ed4c。AV24完成兩次局部調整，但沒有可靠證據宣稱90%，品質目標保持開放。不能用browser測試數／像素差異／未看完整的競品GIF自行升級品質结論。

- [x] AV23已推送371718e；配音／輸入窗口分離、普通下一手保留配音、音樂duck涵蓋音訊。
- [x] AV24四職接觸beat：180ms局部輪廓、連鎖0.26／0.36兩段交換、奉獻供體原點；不改Domain。
- [x] 第一輪增量不足後再調整手繪材質大小／透明度，原生ground／foreground分層保住人物；前版／iteration-1與最終證據保留。
- [x] 連鎖兩段接觸沿用原WAV但獨立player alias，避免第一個起播被覆蓋；原時長／AV23輸入窗口保留。
- [x] 最終browser41項motion＋32項contact／Canvas／WAV檢查，來源／資產／Domain不變和Xcode檔案接線核對；這不是原生或品質百分比。
- [x] Mac原生驗證腳本與三項Swift contact測試／一項實際audio排程audit已準備；腳本只做過Bash語法檢查。
- [ ] Mac跑完整Swift測試；Debug／Beta原生編譯，修正本輪或先前UI20／AV21／AV22／AV23未經編譯的整合問題。使用review-animation24-native.sh並核對來源SHA。
- [ ] 串行Native UI／IntegratedAudioAudit，確定新測試真的執行且未skip；覆蓋復原、靜音、背景／中斷、終局與快速下一手。
- [ ] 同局面375／402、普通／密集、七技能正常速度及降低動態的原生影片；檢查分層接縫、接觸點、前後層與陣營辨識。
- [ ] 實際聽四職同音量A/B，核對兩段接觸／配音／BGM duck和疊音；必要時修音效或原創來源，不把排程成功當聽感品質。
- [ ] 真機觸控恢復、FPS／frame time、VoiceOver／Dynamic Type／iPad与完整對局舒適度。
- [ ] 依原生聲畫比較再迭代人物表演、次要動作與材質份量；用代表性爐石片段和獨立真人比較判斷整體接近程度。90%仍未驗收，不關閉本項。

本輪驗證後推送同一codex/v11-game-interface候選分支；不合併main或發布TestFlight。報告ANIMATION_24.md與artifacts/animation-24；目前可完成本機候選與browser比較，缺Mac／iPhone聲畫評估能力的項目明確保留，不能冒稱整體完成。

## ASSETS-PASS-1（2026-10-19，Beta/DEBUG候選）

Owner授權從PR #30建立art/assets-pass-1，僅改善肖像、七加一技能圖示、原創可重現音效；一包一commit，推分支開PR，不合併/不TestFlight。Release原素材、棋盤骨架/P02、規則/Bot/存檔/手勢/識別碼不變。

- A已交付四張1254來源及512/256，三設定建置成功；UI首輪61/62，runner終止的一項重啟模擬器後1/1補跑通過；不是乾淨首輪全過。詳細視覺結論：docs/art/ASSETS_PASS_1.md。
- B已完成七加一圖示與ArtV2入口、三設定建置、原生操作區前後比較；完整UI62/62通過，0失敗/跳過。
- C已製作25個版本音效並獨立量測：最長1.18s、最大true peak−4.7dBFS、組內0LU（0.1精度）、無削波；三設定及原生成功/失敗事件已驗；完整UI抓到無效預覽選取音，已用合法目標集合修正，聚焦回歸1/1通過，最終完整UI與新增負向audit進行中。
- 實機、真人評分、效能、正式發布權利接受未驗；未重畫棋盤身體。完整證據在artifacts/assets-pass-1及assets/candidates/assets-pass-1。
