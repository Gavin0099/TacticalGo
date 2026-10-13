# 1.1 魔物戰場 slices（2026-10-11）

Owner 要求切出 slice 後往下做。候選模式獨立於 1.0 發布；本 worktree 基準 cdab133（本機 origin/main），不更改其他 agent 的 checkout、不提交／推送／發布。

核心改動屬 L2：neutral occupancy 影響氣、提子、自殺、superko、回合與復原。驗證順序為合約 → 手寫回歸與合法 replay → opt-in iOS 試玩 → 真人取捨；工程通過不能代表平衡或好玩。

| Slice | 交付 | 驗收 | 狀態 |
|---|---|---|---|
| MOB-01 | 一隻史萊姆、中立占位、中心／偏中心、無戰利技能；獨立 Debug 本機雙人入口 | 氣／連接／落子與位移禁止／一般提子保留怪物／superko／勝負／完整 undo；合法開局可到達案例 | 工程驗證通過；真人試玩待辦 |
| MOB-02 | 主動 0／1 AP 討伐，同一條件、可選擇放棄；最後 AP 後免費決策窗口 | 同起點重播、2:2 不可討伐、提子後重算、勝利優先、窗口不增加普通行動 | 工程驗證通過；真人試玩待辦 |
| MOB-03a | 接觸方向黏彈一次、0 Mana／1 AP、下一己方回合解鎖、共用一次技能限制 | 非法不消耗、完整復原、合法重播與敵方回應；真人價值待辦 | 工程驗證通過；真人價值待辦，不阻擋後續工程 |
| MOB-03b | 單隻暗影狼與影步 | 部署限制、路徑與結算、可達重播；真人反制價值待辦 | 單怪工程驗證通過；真人取捨待辦 |
| MOB-04 | 雙怪同場、多份能力持有／解鎖／選擇消耗、逐隻免費討伐 | 配置拒絕、雙占位、兩種取得順序、分開歸屬、技能互斥、ko／勝利優先與 undo／replay | 工程驗證通過；真人單怪／雙怪比較待辦 |

## 本輪合約

- 模式預設關閉；9×9、一隻史萊姆。中心 (4,4)／偏中心 (3,4)，座標為 0-based。怪物不可占邊界或主將初始點。
- 怪物由 Board 核心持有，無玩家陣營、不連接任何棋串、不算氣、不可落子／召喚／築壘／封印或移動棋子到它的位置。
- 怪物不因一般無氣提子而消失；只能討伐。移除後立即成為真空點，所有相鄰棋串的氣依核心重算。
- 討伐條件：四正鄰實際友軍占位 >=2 且多於敵方；主將／英雄／士兵各算一格，斜角不算。2:2 可僵持。
- 主動討伐 cost=0 或 1；不扣 Mana，不占英雄技能次數。本輪無戰利能力／獎勵。1 AP 版本允許築壘＋討伐，將其職業優勢列為真人觀察。
- 0 AP 版本用盡 AP 時，若仍可合法討伐，暫停自動換手，只能討伐或 EndTurn 略過。不能再落子／召喚／施法；若不能討伐仍照原規則自動換手。
- 討伐與盤面行動仍原子結算；先提對手、再檢查自己、superko，失敗完整不變。主將被提立即勝利，不開免費窗口。
- superko key 包含怪物占位；復原包含怪物、窗口、歷史、AP/Mana、召喚與技能旗標。
- 1.0 Records 不支援怪物配置；Lab 使用獨立 GameSession，不接正常存局、Bot 或正式動畫。不宣稱它們已支持魔物模式。

## 要回答的玩法問題

同局面比較：直接攻防主將／討伐打開通道／保留怪物阻擋對手。控制落子也有棋盤價值，不把全部落子 AP 歸為額外討伐成本。沒有技能時不搶怪，只能解釋為清除障礙收益不足，不能判定整個模式失敗。

真人觀察：是否有合理的搶／不搶、移除是否同時幫助對手、位置／先手／築壘優勢。手擺邊界 fixture 證明規則；合法 replay 證明案例可達；兩者均不能證明好玩。

## 工程里程碑

- 163 項 Swift 測試通過，包含 17 項魔物核心邊界與 2 項 Bot／Records 模式隔離；38 組 iOS Golden／99 steps 與 24 組 legacy Golden／65 steps 通過。
- 12 組比較重播：兩位置 × 兩成本 × 討伐／保留／最後 AP 後討伐分支；每步合法且重播後狀態一致。没有推論最優策略。
- Debug 試玩編譯通過；iPhone 17／iOS 26.5 三項操作驗證通過。檢視預覽與免費窗口截图，棋盤、回合與操作可辨識；長內容可捲動。
- Release 模擬器編譯通過；實驗入口與畫面由 DEBUG 條件排除，未做 Release UI 操作驗收。
- 決策：Board 持有中立占位，控制討伐沿用原子結算；免費討伐只延後換手，不增加普通行動。先用本機雙人與合法重播收集取捨。
- 尚未取得真人比較證據；下一片技能成本與平衡待驗證。

## MOB-03 工程合約（Owner 現在沒空測，允許先推進）

- 保留無獎勵對照；Lab 可切換戰利能力，Core 預設不發獎勵。仍是一隻怪物，史萊姆／暗影狼二選一，不混入 1.0。
- 討伐成功才發能力，歸討伐玩家持有、每局單怪所以每方最多一份。下一個己方回合（目前 ply + 2）可用，不過期；使用後消耗。非法預覽／操作不消耗，undo 完整恢復。
- 共通 1 AP／0 Mana，與英雄技能共用每回合一次。不要求英雄才能持有能力；黏彈無英雄仍可用，影步需要己方在場英雄。
- 黏彈：選己方正鄰接觸棋子作支點（士兵／英雄／主將均可），再選相鄰普通士兵（敵我皆可），沿支點→士兵的方向推一格至空點。不可旋轉方向、推主將／英雄、交換占位、越界；封印沿既有位移規則處理。保持士兵陣營，正常提子／自殺／superko／勝負結算。
- 暗影狼：四鄰友軍至少 2 格且多於敵方，其中至少一格為己方英雄，才可討伐。這是未經平衡驗收的站位候選，不宣稱星級強度。
- 影步：己方英雄沿同一列或行移動 1–2 格，路徑及終點均為空點；不可穿越棋子／怪物、不可交換。正常結算，會改變原先連接的防線，也不保證之後安全。
- 驗證：獎勵隔回合解鎖、雙方持有隔離、技能互斥兩方向、零 Mana、無英雄、目標／方向／路徑／中立占位拒絕、提子／勝負／ko／自殺、事件順序、undo、從合法開局取得再使用，以及對手先占終點的合法反制。
- 工程 gate 可先過；真人好玩度、最佳成本、職業優勢與雙怪同場仍待辦。Bot／正式 Records 不接入魔物模式。

## MOB-03 驗證里程碑

- 全套 176 項 Swift 測試通過；新增 12 項能力測試與 1 項正式存局拒絕測試。既有 62 組 Golden／164 steps 仍通過。
- 16 組合法重播通過：兩魔物 × 兩位置 × 兩成本 × 使用／對手堵路。失敗能力保留 token、AP、Mana、盤面與歷史；成功使用可完整 undo／replay。
- 五項 iPhone 17 操作測試通過，包含原三項討伐流程與新增黏彈／影步預覽、消耗及復原；Debug／Release 模擬器編譯通過。
- 觀察：影步終點鄰近移動留下的空點，不能把「看似三面被圍」直接當自殺；規格與測試已依氣的定義核對。黏彈推敵兵可填掉別條己方棋串最後一氣，仍會被自殺規則拒絕。
- 詳細證據與未驗收範圍：artifacts/v11/mob-03/REPORT.md。下一候選為雙怪同場的盤面／獎勵持有設計；沒有預設成本或平衡結論。

## MOB-04 雙怪合約與驗證計畫

- 本片限 9×9、一隻史萊姆與一隻暗影狼；Lab 雙怪固定在 (2,4)/(6,4)。Core 接受一至兩隻、不同種類／不同位置、非邊界／非主將開局點，拒絕空配置、重複與第三隻。
- Board 持有所有中立占位；每點各自阻擋氣、連接與位移。討伐只移除指定點，控制與狼的英雄條件各自計算。diagram 的每個 M 都是核心狀態，剩餘占位參與 superko。
- 每位玩家可同時保有兩種能力，依取得順序列出；分別依取得 ply+2 解鎖。第二份不覆蓋第一份；使用依能力種類只消耗該份。無丟棄／換裝／合成／永久升級。同種魔物重複尚不支持，避免隱含的 token 選擇規則。
- 0 AP 決策窗口在任一魔物可合法討伐時保留；每次討伐後重算其餘選擇。可以連續討伐兩隻，或討伐一隻後略過換手；不能新增普通行動。所有怪物不可討伐時自動換手；主將勝利優先。
- 共通技能仍每回合一次；不能同回合連用黏彈、影步或英雄技能。非法目標、路徑、ko、未解鎖不消耗任何能力；完整 undo 恢復盤面、各份能力、解鎖時間、歷史與窗口。
- 驗證先寫手工期望：雙占位／單隻移除、配置拒絕、分開持有與解鎖、雙能力互斥／定向消耗、雙免費窗口／略過／ko、兩種取得順序的合法重播與 undo。再跑完整 Swift、既有 Golden、Debug/Release 編譯與雙怪 UI 操作。
- 真人試玩延至下次；不推論雙怪比單怪好玩、成本最優或職業平衡。仍不接 Bot、正式存局或 1.0 上架工作。


## MOB-04 工程里程碑

- 全套 188 項 Swift 測試 0 失敗，新增 12 項雙怪邊界；兩套 Golden 62 fixtures／164 steps 通過。
- 雙怪 14 分支合法重播：兩成本×兩順序×兩能力 8 組、免費連續討伐／中途略過 4 組、雙方分開取得並使用 2 組。原單怪 12 + 16 分支仍通過。
- 七項 iPhone 17 操作 0 失敗，包含新兩項雙怪能力選擇／保留／技能互斥／undo 與免費窗口逐隻討伐／略過／復原。Debug／arm64 Release 模擬器編譯通過。
- 固定雙怪為 C5 史萊姆／G5 暗影狼；核心占位集合與玩家能力清單分開管理，沒有同種重複／第三隻。討伐與每份解鎖時間各自計算，正常模式仍預設關閉。
- 修正免費版合法比較開局：準備過程就出現討伐窗口，要明確略過才能交手。最初單點 API 遷移編譯失敗與重播 16 個失敗斷言均保留；不更改回合規則來配合 fixture。
- 工程證據：artifacts/v11/mob-04/REPORT.md。真人單怪／雙怪、0／1 AP 與主將攻防重心取捨延至下次；不是 1.1 發布完成。

## Monster Art v01 — Owner 要求依 skill 畫圖

本批為史萊姆／暗影狼兩張簡化透明棋盤圖，固定 warrior STYLE 參考，依 tacticalgo-character-style 與 imagegen skill。完整計畫／prompt／hash／32/48/64px QA 在 assets/candidates/v11-monsters/v01/；只替換 Debug Lab 字牌，Core 不變，Release 候選資源排除。圖樣仍待精確檔案接受、production=false、rights=pending；真人辨識留至下次，不改上架工作。

Monster Art v01 工程完成：兩張 1254×1254 原圖透明／邊界／hash 驗證、32/48/64px 檢視、兩項雙怪 UI 操作、最新 Debug／Release build 及候選資源排除通過。首輪操作通過但圖片空白，由截圖攔下；已明確載入 PNG 並固定格點 frame 後重新驗證。候選來源與證據見 assets/candidates/v11-monsters/v01/README.md 與 artifacts/v11/monster-art-v01/REPORT.md。

## 2026-10-11 怪物圖樣 v02 預覽里程碑

依 Owner 看效果要求，完成新版史萊姆簡化候選＋Owner 新狼原圖、32/48/64 px 對照與 9×9 明暗靜態棋盤示意。三檔透明／邊界／來源 hash 驗證通過；尺寸與示意已目視。現有 App 仍沿用 v01；本次沒有更換消費端資源或遊戲規則。來源與完整提示在 `assets/candidates/v11-monsters/v02-preview/`，證據 `artifacts/v11/monster-art-v02-preview/REPORT.json`。正式採用與真人辨識仍待後續決定／測試。

## 2026-10-11 v02 圖樣載入測試版

依 Owner「載入進去讓我測試」，已替換獨立 Debug MonsterLab 引用與 Release 排除檔名；兩檔實際 Debug 資源存在／Release 排除、來源 hash、Debug／Release build 通過。App 已啟動，新史萊姆單怪画面確認。兩個 UI tests／16 失敗斷言；雙怪畫面與操作尚未確認。CUA 回報 Mac 鎖定，已請 Owner 解鎖；原因尚未定案，不提前報驗證完成。證據 artifacts/v11/monster-art-v02-integration/REPORT.json 與 DIAGNOSIS.md。遊戲核心、1.0 checkout 與正式發布未修改。

## 2026-10-12 十小時擴充候選交付

最新狀態由 AUTONOMOUS_12_PLAN.md 管理。牧師、三職第二技能、魔物/能力共用規則、原畫動作與英文語音、可達試用/牧師挑戰、獨立候選存局已整合於1.1入口。新增魔物v02實际資源的原生七項流程和入口圖片載入已通過，不再沿用上段兩項失敗作當前狀態；早先證据仍保留。

235/0 Swift；27項不同原生UI（擴充8＋魔物7＋法師8＋戰士4）通過；14張有效定格图、6段正常速度原生畫面/後製混音保留。Debug/Release/簽名真機build及獨立手機候選安裝通過；手機鎖定，真機啟動/錄音未完成。正式1.0 Records/Bot仍拒絕候選，新增ExpansionMatchRecord專用逐步重播/核對，不改正式格式。真人平衡、美術、演技與素材採用待Owner回来後，不宣稱1.1發布完成。沒有提交、上傳、合併或發布。

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


## 2026-10-12 13:26 18修正：同一暖色介面與固定棋盤（上傳中）

Owner退回1105舊外層與棋盤跳動，13:04新圖為7×7牧師對電腦法師。根因是phone9才用compact panel，boardHeight依職業/技能/戰利/文字/AI/勝負動態調整且HUD/控制列未固定。18新增viewport-only PhoneMatchLayout，固定header/HUD/status/controls槽，phone7/9共用矩形行動卡與暖色桌遊界面；長說明info sheet，勝負/AI/技能在槽內替換。7×7只裁圖外垂直留白、角落人物與hit共享投影。Core/Bot/Motion/Records/Content來源對1105逐檔未變，原畫/語音素材未改。

Visual10/0；Beta主5/0＋Debug小3/0，0skip，8次執行/7種方法。arena與兩角格點矩形在四職/技能/方向/preview/cancel/help/AI prepare+landing/終局/Undo/loot/resume比較≤0.5pt，含375pt牧師對電腦法師。首build缺focusedPhone屬性已修、失敗日志保留；串行xcodebuild。250完整套件是1105歷史結果不重報重跑。主/小原生圖已查看，無iPad/真機1106或真人style接受。

1106 archive/IPA已簽名匯出，上傳正在進行；接續實際成功後查Apple處理，只加既有Owner1.1群組並保留1103/4/5。最新OWNER_REVIEW18/interface18證據。未動另一1.0checkout/封存/送審或Git提交推送main合併，heartbeat保持已暫停。


## 2026-10-12 13:31 18完成：1106 TestFlight可更新

1106 upload exit0/Upload succeeded於13:26:39台北完成，Apple已處理build581377ae-1551-4eda-9d3f-70404643ffe3。已保存繁中試玩說明，只加到既有Owner1.1內部手動群組；1人/1103、1104、1105、1106四build正在測試。ASC見Owner已裝1105；不能由此宣稱1106真機安裝或真人style/尺寸接受。SOURCE_PIN未變、最終DELIVERY核對，網站實際截圖保存。

Visual10/Beta-main5/Debug-small3皆0失敗0skip，8次執行7種方法；<=0.5pt矩形回歸涵蓋Owner7×7牧師/電腦法師、準備落定、終局、四職/技能方向/預覽取消/Undo/loot/續玩。Core/Bot/Motion/Records/Content對1105來源不變，250完整Swift為歷史證據；54素材/兩怪原生像素/簽名archive+IPA與來源核對通過。主小原生圖已查看，iPad/真機1106仍待，首compile失敗保留並修復。

同一暖色桌遊介面與固定棋盤候選完成，Owner更新1106驗收；不再擴scope或重傳成功包。最新OWNER_REVIEW18、interface18 DELIVERY/ASC_BUILD/ASC_GROUP與testflight1106-ready.png。未動另一1.0checkout/封存/送審或Git commit/push/main合併，原heartbeat保持暫停。工程PASS不等於真人品質接受。


## 2026-10-13 Owner授權Git推送：1106來源已上傳

Owner「先推上去」明確授權commit/push候選分支，取代舊候選no-commit/no-push限制。1.1完整來源e25b2d8fcd7e6ea3122c6957a1198a587b290bb5已推至origin/codex/v11-monster-battlefield並以git ls-remote核對一致；main仍cdab133，未merge/PR/App Review/公開發布，不動另一1.0checkout。517檔含應用/套件/測試/必要原始及聲畫素材/設計/來源權利/精簡證據，排除本機9.6GB建置cache、簽名archive/IPA/provisioning/帳戶裝置日誌。

從待提交index匯出乾淨來源，全Swift252/0，unsigned Simulator Beta build成功1106，54PresentationLab bytes一致及兩怪存在。封裝收據git-review/VALIDATION.json；interface18 SOURCE_PIN無變，之前8次UI來源不變未重跑、真機與真人品質未宣稱。自有code/docs/scripts/memory whitespace通過；第三方license/HTML原bytes含CRLF尾空白保留，簡式私鑰/token/簽名檔掃描無命中非全面安全audit。舊TestFlight1106維持，不重傳App。完整歴史artifacts仍本機，乾淨clone不能憑此執行依賴本機封存的delivery scripts，GIT_DELIVERY.md明確標示。

Git推送請求完成；後續依Owner選擇試玩/新slice，不自行合併main或新增功能。原十小時heartbeat保持暫停。
