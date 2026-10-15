# TacticalGo 1.1 十小時候選開發

Owner 授權：2026-10-12「現在有10小時的空檔，先把1.1的目標做好，有問題等10小時後再說」。
窗口：2026-10-12 01:37:48–11:37:48 Asia/Taipei。此聊天 heartbeat 每30分鐘接續，截止後彙整一次並暫停；若已完成不追加範圍。

只修改 codex/v11-monster-battlefield 工作樹；保留1.0與其他 agent 工作。允許本機可逆實作、測試、獨立 presentationlab 候選安裝；不 commit/push/merge/發布。遇問題先修復，不能解決則保存明確限制並做獨立項目，截止前不詢問 Owner。

## 目標與順序

| Slice | 可檢查交付 | 現況 |
| --- | --- | --- |
| EXPANSION-08 | 牧師＋三職第二技能：明確原子結算合約、有效/失敗棋形、資源/Ko/Undo/舊規則回歸 | 工程235/0：原子結算、勝負、自殺/Ko/Undo與魔物共用技能；真人平衡待驗收 |
| PLAY-09 | 統一1.1入口、一般擴充對戰與魔物對戰、各技能操作與預覽 | 統一入口、四職／第二技能／魔物與預覽已接入；最終擴充原生8/0 |
| FEEL-10 | 接上已接受法師D／英文B、戰士B；盜賊、牧師、魔物各有動作和分層聲音 | 原法師D/戰士B接入，盜賊/牧師原畫分層、英文A/B及魔物材質聲完成候選；14張有效原生動作圖與6段正常速度原生畫面/後製混音完成 |
| CONTENT-11 | 從合法開局可達的技能比較、精通挑戰與反制例子，存局/重播邊界 | 四職合法開局試用、牧師兩真眼救援與法師反制、獨立候選存局/重播已通過；本機雙人，原Bot拒收擴充 |
| DELIVERY-12 | 7/9、黑/白、取消/復原/背景/減少動態、Release隔離、簽名真機候選、完整影片與證據 | 27項不同原生測試通過；Debug/Release/簽名真機build、來源/編譯像素及候選安裝通過。手機鎖定，未完成真機啟動與聲畫錄影；Owner品質待驗收 |

## 已接受基線

法師 P04 D 動作及 VOICE06 B「Move aside!」、戰士 W07 B「Hold the line!」。原角色身份、美術與素材權利记录保存；不得悄悄换掉。怪物v02仍需新的原生UI验证。测试通过不表示玩法、美术或演技通过真人验收。

## 初始盘点

魔物占位/讨伐0与1 AP/史莱姆黏弹/暗影狼影步/双怪库存均已有 Core。现行 MonsterLab 本机双人，无正式存局或 Bot；声画展示只有法师/战士，尚未接入完整1.1对战。第二技能与牧师尚未实作。

## 决策记录

2026-10-12：新增玩法全部由 RuleConfig 明确启用，不改变原规则默认值。第一轮不改变 Mana 上限6、每回合回复1、2 AP；第二技能候选成本4与5可比较，与普通技能/魔物技能共享每回合一次。牧师避免只有移除一子而延后失利，先做「奉献救援」：牺牲近处己兵，在己方主将或牧师身旁形成援兵；不增加总兵数，保留拆线风险。详见 EXPANSION_08_CONTRACT.md。

## 待 Owner 验收（窗口结束后）

所有新增技能的乐趣与平衡；牧师救援是否形成实用的新职业；第二技能4/5 Mana取舍；讨伐0/1 AP；声音演技与图像小尺寸质量。不预先标为通过。

## 2026-10-12 02:49 候選交付里程碑

既定範圍的本機候選實作與工程驗證完成，停止新增功能，不為用滿十小時擴大範圍。Swift235/0；27項不同原生UI測試（擴充8、魔物7、法師8、戰士4）通過，其中擴充8是兩項定格/載入修復後的新一輪。來源pins、raw/dry聲音、CC0與模型文件、所有資源与Release隔離已核對，最終receipt見 artifacts/v11/feel-10/delivery-evidence-receipt.json。試玩入口與影片見 OWNER_REVIEW_12.md。

原生截圖驗證曾發現啟動白圖及scene取消誤清定格收據。兩組無效圖片留存並排除，已分開固定檢查資料與正常播放排程；14張新圖均實際呈現不同姿勢。載入合法存局後解除定格與恢復可保存操作的回歸也通過。正常操作、Undo/背景/中斷仍取消播放。

候選已簽名並更新安裝至獨立 com.tacticalgo.prototype.presentationlab，普通手機1.0不改。最新已記錄的啟動因鎖定被系統拒絕，因此不宣稱真機啟動/錄音完成。無Owner操作或真人演技/美術/樂趣/平衡/素材最終採用證据。原Bot仍拒絕擴充；候選目前本機雙人。

截止前 heartbeat 保持安靜：只核對有無新輸入/外部狀態變化，不重跑未變來源的測試、不新開功能、不重複安裝。2026-10-12 11:37:48台北後統一回報剩餘項目；若裝置可用，可嘗試一次已授權的候選啟動，再依實際結果說明，然後暫停 heartbeat。未提交／推送／合併／發布。

## 2026-10-12 02:27 工程里程碑

Swift完整235/0；首輪原生20/0（擴充5、魔物7、法師8），戰士4項本輪待補跑。聲音raw/dry A/B、來源CC0/Apache文件、seed/固定14檔模型SHA與獨立ASR4句保留。美術改為牧師v02頭部43%以改善小尺寸，v01留存；兩版本都未有Owner exact-file驗收。工程檢查非趣味/演技/權利通過。evidence_refs: artifacts/v11/expansion-08/core-evidence-receipt.json。

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
