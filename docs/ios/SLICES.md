> 2026-10-10 Owner 最新回饋：三職細線／光圈 VFX「有點弱」，視覺不通過。依據 Vortex 有限多段粒子及 Pow 分層研究，製作更清楚的蓄能／方向傳遞／局部撞擊強化候選；不增加音樂、語音、規則或第二技能。唯一法師演出時間表調整，但總長仍950/760ms。研究及驗證：artifacts/ios/vfx-three-classes-01/research/DECISION.md；Native/Owner Gate 分開回報。

# Swift／iOS 開發切片

## 2026-10-10 — 三職 VFX 開工授權（取代先等全部本體核准的啟動限制）

Owner 明確要求「開始做三個職業的特效」：在既有 Cozy-02、B-v02 與已完成本體上依序執行 VFX-W1 築壘、VFX-M1 原版一格魔法之手、VFX-R1 換位。只接成功 before/action/outcome 收據，預覽輕量、捕獲依正式 payload、共用既有演出時鐘；取消／復原／重開／背景／Bot／Reduced Motion 回歸。三職完成後交正常速度完整棋盤、7×7／9×9 稀疏密集、黑白及條件提子原生影片供 Owner 看，不自動延伸第二技能。

此授權只開啟特效工作，不代表戰士／三職本體、整體美術或英雄語音已正式驗收。英文英雄語音維持 HOLD／關閉；不修改 Domain、Bot、AP/Mana、技能、人物原畫或投影，不新增配音。隔離分支 codex/vfx-three-classes-01 可必要 commit/push，不 merge、TestFlight 或發布。工程與真人觀感、模擬器與真機分別報告；完整候選證據見 artifacts/ios/vfx-three-classes-01/REPORT.md。

以下日期相同的舊「本輪不開 VFX」條目為歷史決策，不覆蓋這次 Owner 新授權。

## 2026-10-10 — 原畫角色動畫與後續 VFX 決策

Owner 接受法師 M3 人物呈現方向，沿用底座環與外側陣營標記；不代表正式美術全部結案。已先建立 tacticalgo-cutout-animation Skill，沿用成功收據、原畫身份、分層握持與小尺寸原生驗收。

| 順序 | Slice | 範圍與 Gate | 現在狀態 |
| --- | --- | --- | --- |
| 1 | ANIM-W1 | 戰士登場、上身後收、舉盾、前推築壘、事件後兩兵同步落定、收勢；本體先可辨 | 本輪執行 |
| 1 | ANIM-R1 | 盜賊登場、下蹲、方向性閃身、英雄與敵兵沿交換路徑移動、落定收勢 | 本輪執行 |
| 2 | VFX-01 | 法師 M3 上增加短符文、杖尖蓄能、方向釋放、受術士兵衝擊及落定；小範圍不遮棋局 | 後續預定，本輪不執行 |
| 3 | VFX-02 | 戰士盾牌震波／兩兵登場效果、盜賊短換位殘影；統一三職強度 | 後續預定，本輪不執行 |
| 4 | 三職聲畫／觸覺整合 | 既有 SFX、支援裝置輕量震動及英文語音時間；語音待 VFX 動態驗收再決定 | 後續待排，不新增自動授權 |

本輪 W1／R1 完成即停止供 Owner 看原生正常速度錄影，不直接展開 VFX。既有 B-v02 身份、M3 底座、成功收據、Domain、AP/Mana、提子與 Bot 決策保持；只修改演出。英文英雄語音關閉，既有 SFX 可保留。隔離分支可必要 commit／push，不 merge、TestFlight 或正式發布。兩職交付黑白雙方、7×7／9×9 密集小尺寸、原畫／遮罩／補圖、取消／復原／重開／背景／Reduced Motion及來源與測試證據；完整棋盤先於近景。

## BOT-01 — 目前新增的單人對戰切片

2026-10-09 Owner 核准基本戰術電腦對手，三線並行；SW1／SW2已有可玩交付，V2新素材仍由Visual Agent提供。TacticalGoBot依賴原Core，完整己方1／2AP、有限對手反應、背景規劃、必要SwiftUI單人選項、Owner追加的逐步下棋／事件動作與晚到決策拒絕。原V1資訊布局／A0身份保留。

BOT-01工程／原生／實際合法對局證據见 artifacts/bot-01/REPORT.md；接口及重現见 BOT_01.md。BOT-02／03未開工，單人只7×7、你執黑；不實作第二技能、不改R2預設、不用機器對戰宣稱G5已通過。舊3D／舊SW2待實作條目是歷史，不能覆蓋最新A0可玩版與本輪。

## IOS-V2-ASSET-01 — 当前Swift／SwiftUI接線Slice

2026-10-09 Owner正式双軌：本Agent負責程式与實機；另一Visual Agent負責美術／动画素材，不继续静態比较稿。SW1及SW2已有工程交付（原生7／9、選角、三職、雙人、勝負、復原），下方早期SW2待實作条目为历史原型狀態，不能覆蓋IOS-PLAY-A0-01。Windows／LinuxSwift執行及Owner新美術／完整無障礙驗收仍未據此通過。

本片交付TacticalGoVisuals素材規格validator、原生GameVisualAssets整包載入／fallback、SwiftBoard可選板面陰影／黑白單位／Token、人物卡接線。现有V1資訊基準保留，正常畫面仍A0原圖；Debug重用原圖fixture驗證真接線，不生成美術／动画或改Core。共用規格V2_ASSET_CONTRACT.md，程式／測試／实际原生截图见artifacts/ios/v2-asset-interface-v01/REPORT.md。接線候選完成不等於V2新美術／Owner／真機Gate通過。

## V1-A0-UI-01 — 目前授權的資訊／尺寸設計交付

2026-10-09：Owner支持UI擴展，先交付三完整狀態390／320對照，不將第二技能／動畫綁入。一般、法師推動預覽、主將1氣危險皆由原預設Core產生；7／9共12張HTML/SVG靜態稿，未整合原生App。另一Agent在做棋盤／Token美術，板面僅是布局占位。规格 `V1_A0_UI_SPEC.md`，證據 `artifacts/ios/v1-a0-ui/VALIDATION.md`。後續V2為原生素材与資訊層級整合；第二技能只Draft，不新增假按钮。iPad已授權安裝、待連接。


## 最新 Slice：IOS-PLAY-A0-01（2026-10-09）

Owner 已玩過 Windows，要求先做 iOS。交付範圍：原始 B-v02 選角／資訊、A Token 木質 2.5D 棋盤、7×7／9×9 本機雙人、三職技能、目標預覽確認取消、完整復原、勝負與玩法練習。Swift Magic Hand 規則以 Windows gameplay 分支 54deef97 為基準，原 main 封印測資保留比較。驗證與真機狀態見 `artifacts/ios/playable-a0-v01/REPORT.md`。不重啟任何 3D 或拆層動畫工作。下方舊 Slice 屬歷史，不改其驗收為通過。

2026-10-09 · Owner 核准 V1＋SW1 並行；正式產品主線為 iOS，Windows 保留規則與玩法驗證。此表取代舊文件的 Windows 動畫先行、等規則 Accepted 才開始移植的執行順序。規則仍為 Draft，移植不代表平衡核准。

## 邊界與驗證計畫

本輪是核心領域移植（L2）。規格來源為 `docs/RULES_DRAFT.md`、Owner 決策與手寫 `tests/golden/*.json`。C# 是參考實作；Golden 證明與既定案例一致，C#／Swift transcript 比較證明兩份實作一致，兩者都不能替代玩家規則驗收。

- Domain：`swift/TacticalGoCore`，純 Swift 值型別，不依賴 Apple UI、檔案、網路或時間。`GameState + GameAction → ActionOutcome(state, events, reason)`；拒絕時完整狀態與歷史不變，事件為空。
- Application：iOS `GameStore` 在 main actor 持有 session、選點與預覽；只有確認或換手才 commit；undo 恢復完整快照。
- Presentation：SwiftUI 處理玩家介面；SwiftUI／SpriteKit 比較候選共用 `BoardProjection` 與引擎狀態。棋盤負責座標映射與畫面，事件決定結果。
- Test adapter：共用 JSON runner、C# exporter、transcript comparator。有成功、失敗、邊界與多步序列；比較事件順序及 payload、資源、英雄旗標、封印、盤面、勝負。不可把 exporter 輸出改成 Golden 預期。

## 切片與 Gate

「已實作」只描述程式交付；「待驗收」保留 Owner 的視覺、操作與玩法決定權。

| Slice | 可獨立檢查的交付 | 驗收／依賴 | 本輪狀態 |
|---|---|---|---|
| SW1-01 | Swift Package、落子、棋串／氣、提子、原子拒絕、superko、回合／勝負 | 手寫 Golden；核心無 UI import | 已實作 |
| SW1-02 | 召喚、築壘、封印、換位；結構化事件與錯誤碼 | 三職成功／失敗、到期、資源與事件對照 | 已實作 |
| SW1-03 | 同一批 Golden 在 C#／Swift 執行；完整逐步 transcript 比較 | 不只最終盤面；錯誤結果及事件 payload 等價 | 已實作 |
| SW1-04 | 7×7／9×9、復原包含歷史；CLI 與手動 CI | Swift 本機可編譯執行；Windows／Linux 分別跑同指令 | macOS 已驗證；Windows／Linux 尚未執行 |
| V1-01 | iPhone 比例的一般、技能預覽、危險三種完整候選 | 7×7／9×9；棋盤、卡片、資源、技能同屏可讀 | 原生候選與模擬器截圖已交付；待 Owner 核准 |
| V1-02 | 相機、anchor、圖層、素材配置規格 | 替換素材不改規則及 hit target | 規格已交付；三職全身候選已接棋盤，正式 token／視覺核准仍待驗收 |
| V1-03 | Owner 審三畫面與小螢幕可讀性 | **V1 視覺 Gate**：三畫面整體核准，單張素材不算通過 | 待驗收 |
| SW2a-01 | 同一 iPhone App 切換 SwiftUI／SpriteKit，接純 Swift 核心 | 點選→預覽→確認；非法理由、復原；同座標結果一致 | 已實作並有模擬器互動測試 |
| SW2a-02 | 小螢幕精準選點、9×9 放大／定位候選、VoiceOver／大字級 | 邊角不誤觸；密集棋盤仍能選目標；控制不遮盤 | 格點清單、原生1.6倍放大／拖曳／置中已實作，兩尺寸原生方向／資源／選點回歸通過；真機手指、大字級與完整無障礙待驗收 |
| SW2a-03 | 真機操作、效能、遮擋與生命週期比較 | **下一個技術 Gate**：真 iPhone 正確操作後選定渲染技術 | 待執行；Owner真3D方向後RealityKit為目前原型預設，真機Gate前不宣稱正式選型通過 |
| SW2b-01 | 開局雙方選戰士／法師／盜賊、重開對戰 | 職業、成本、召喚位置取自核心 | 待實作；原型新對戰暫固定戰士 vs 法師 |
| SW2b-02 | 三職完整技能流程、可用理由、可選範圍、提子結果預覽 | 築壘兩點取消／改選、封印到期、換位禁止主將／英雄 | 原型接線已有；逐職 UI 驗收仍待完成 |
| SW2b-03 | 教學 1 次→2 次行動、盜賊技能組合 | 沿用既有驗證局面；新手試玩可完成 | 待實作 |
| SW2b-04 | 本機雙人完整對戰／勝負／重開 | **玩法 Gate**：主線完整對戰＋真人策略驗證 | 原型可輪流；完整產品流程與真人驗收待完成 |
| V2 | 核准視覺整合、9×9 縮放定位、真機驗收 | V1、SW1、SW2a／SW2b 通過 | 待執行 |
| A1–A5 | 基礎動畫、三職技能、勝負回饋 | 原 `ANIMATION_DIRECTION.md` 範圍保留，執行平台改 iOS；逐職及完整對戰驗收 | Owner 最新截圖指示改為先實作模型與動畫；候選進度見 OVERNIGHT_WORK，逐職與真機 Gate 保留 |

執行順序：**V1 ∥ SW1 → SW2a → SW2b → V2 → A1–A5**。SW2a-01 的最小比較原型本輪已提前落地，讓 V1 用真正的 Swift 畫面呈現；不據此宣稱整個 SW2a 已通過。

2026-10-09 早期2D比較候選接線紀錄：三職既有全身候選導入兩渲染器；當時人物卡保留B-v02、士兵／主將採棋石。最新3D主線已改同模型卡片與原創士兵／主將mesh，見OVERNIGHT_WORK與unit-compaction-v01。保留底座、腳底 anchor、角色逐列分層與獨立提示。來源及原生畫面見 `artifacts/ios/art-integration/`，未新增角色生成或動畫。

## Owner 最新建模方向的切片

Owner 明確要求皇室戰爭式的真正卡通建模，V1 增加下面三片；原本 2D 插畫整合保留為比較候選。

| Slice | 交付 | Gate／状态 |
|---|---|---|
| V1-3D-01 | 三職真實網格、PBR 材質、光照、棋盤／近距離共用、前後旋轉檢視 | 目前三職原創mesh／11骨工程可執行；Owner於09:13明確否決外觀，改先重做單一雕塑大形並審實際3D畫面，V1品質未通過 |
| A-IDLE-01 | 模型檢視 opt-in 三職 3.4秒骨架待機、103幀可編輯工程與獨立USDZ | 兩尺寸native pose／啟停與還原、實際錄影影格候選通過；遊戲預設與v08技能資源保持，Owner／真機待辦 |
| SW2a-3D-01 | RealityKit nonAR 棋盤、原生投影選點、7×7／9×9、預覽與復原 | 本輪已接線；模擬器操作證據見 `artifacts/ios/models-3d/`；真機 Gate 待辦 |
| V1-3D-02 | 精修三職面部／輪廓／裝備、角色卡統一、正式模型資源與效能預算 | 已交付三職v08可編輯.blend/USDZ、UV材質、11骨／肩袖／披風有限蒙皮及同模型卡片，普通單位v02已原生驗證，完整organic rig／Owner品質與真機待驗收 |

## 規則疑慮獨立驗收

保留 `docs/RULES_DRAFT.md` §8：先手補償、superko、主將起始位置、資源成本、回合上限、封印細節仍是 Draft／候選。另觀察戰士同回合三子是否過強、英雄是否值得召喚、英雄早死是否失去職業差異、最佳策略是否與職業無關。任何 Golden PASS 均不會將它們升級為 Accepted。

視覺草稿的「魔法之手」與現行核心「封印」不同；本輪遵循已有規則與 Golden，不把美術示意當作規則核准。

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

## ID-H1 — Warrior Identity Recovery（Owner 新授權，頭部限定）

先研究 reference-to-3d／validator 與 Blender Studio 公開頭雕流程；用同一B-v02的可見輪廓和五官配準做獨立頭部粗胚，原畫／3D／50%overlay／灰階輪廓與推定側面交付。最新head-v02、前版head-v01及失敗頭胸像都保留。可審查候選完成，身份Gate未通過；主要偏差是硬葉片髮塊、簡化眼耳頰、未知側背粗胚。鏡頭與深度為单圖推定，輪廓IoU不是身份證明。詳見 artifacts/ios/warrior-identity-head-v02/REVIEW.md 與VALIDATION.md。

本片停在Owner評估；不處理新裝備、髮絲細節、下半身、骨架、動畫、USD/LOD，也不修改Gameplay/Domain/G0–G4。未安裝第三方MCP，未commit/push/merge。已到期十小時排程仍停用。

ID-H1正式Owner審查（2026-10-09）：研究成果接受，Identity Gate不通過，正式模型不接受。停止此Mesh方法及所有後續素材，不再開修髮片。不建立新框架。下輪A/B只提出成本可行性比較，docs/ios/CHARACTER_PRODUCTION_ROUTES.md；推薦A0，但路線仍待Owner選擇，沒有啟動A或B。G0–G4保持原路線。

## 2026-10-09 Owner追加：BOT-03a 難度與執色

Owner實際試玩確認逐步落子「ok」，另回報尚未贏過，授權簡單／標準與選黑／白。只做最小難度與單人方別，不展開BOT-02、完整BOT-03效能／難度調平，不改Domain、AP、Mana或技能。UI預設簡單；API預設標準保持相容。簡單仍看己方完整回合與直接斬首／救援／召喚／技能，但候選束至多4、顯式apply至多1600，略過對手完整回合搜尋；這不保證玩家會贏，未驗實際勝率梯度。

你可執白、電腦執黑，黑方第一回合1AP自動開局，之後2AP；人機角色與回合提示由實際陣營推導。白方尚未行動前沒有可復原的人類決策，避免撤回電腦開局後卡住；之後復原保留電腦開局並回到上一人類決策。局中改難度保留已提交Core狀態／AP／每回合技能旗標，取消舊generation後重新規劃剩餘回合。真機與原生結果見artifacts/bot-01/REPORT.md最新區段，不升格G5或正式發布。


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


## 2026-10-09 — R3 候選完整對局（取代固定試驗限定）

Owner 已明確回覆「接入候選對局，保留原版與原局」。因此現在接入 opt-in 候選 GameAction／legalActions／Bot／GameSession／存局及 SwiftUI；原版仍為預設，並保留原局檔案與逐手收據。對戰選單「複製此局測候選技能」先完整驗證、使用新 ID 保存後才切換；新局也可選候選。戰士沿施放前棋群築壘，法師可選原推動或射程2內相連己兵調到原群外緣，共用1AP＋2能量／每回合一次。候選名稱清楚顯示，支援預覽、取消、確認、復原與終止重開續玩。未採納為正式預設；第二技能與 CONTENT-02 不在本輪。

驗證：全包131/0；原版Golden38組99步137snapshots一致；SE原生5/0、iPad原生4/0，含截图G5/G7提G6／法師調度／原局與副本分開保存及重開／電腦剩餘AP／平板旋轉。63來源測試前後SHA一致，Release／strict codesign通過。音樂B及既有音效保留。裝置最新狀態以 artifacts/r3-playable/validation.json 為準：iPad已Wi-Fi安裝，手機初次unavailable待恢復連線；不以舊音樂版代替本輪手機安裝。詳 artifacts/r3-playable/REPORT.md。這段授權與交付取代先前「尚未授權候選全對局」的現況，舊記錄保留為歷史階段。

技能合法仍可能造成己群一氣，Bot標準後期停滯未全面解決，等待Owner候選對局及聽感試玩。不新增Slice、美術、3D、第二技能、AI評分或關卡介面；未commit/push/merge/正式發布。


## 2026-10-09 ONBOARD-01 交付範圍

本輪只執行 TUT-0 與 TUT-1。Owner 要求的三職技能教學、對局內提示設定與真人測試仍分別屬 TUT-2、TUT-3、TUT-4，尚未完成。

新增大廳入口「新手教學 · 不需要懂圍棋」，五個小目標依序教主將勝負、交叉點落子、棋群共享氣、提子與主將救援。預覽、結算及氣數均來自既有 Core。教學固定盤面不宣稱是正式對抗中自然出現的棋形。

教學 journal 在獨立 Onboarding 目錄；取消、复原、背景、重新啟動不改正式存局。新增大按鍵選點，提供小螢幕操作替代；不以棋盤交叉點的可點擊範圍宣稱觸控已舒適。

原版／候選技能仍隔離，R3 真人驗收仍 Pending；標準電腦密集盤面停滯仍未全面解除。沒有新平衡、技能、B1 素材、3D 或音樂改動。

成果在本地 codex/onboard-01 隔離分支，沒有上傳、合併或發布。工程測試與模擬器操作不能證明零經驗玩家已在五分鐘內理解。

Specification: docs/onboarding/ONBOARD_01.md. Evidence: artifacts/onboard-01/REPORT.md and validation.json.

2026-10-10 ANIM-W1/R1 候選補充：已建立 tacticalgo-cutout-animation Skill 與原生候選；Owner 覺得盜賊動作不錯，戰士只有還好。盜賊版保持，戰士-only提高舉盾／下擊差異並讓盾牌最低點與雙兵落定同拍；新版戰士仍待 Owner 看片，不因此啟動 VFX-01／02。完整證據見 artifacts/ios/anim-warrior-rogue-01/REPORT.md。

Owner 後續觀看戰士修正版：「動作有比較好一點，但是還是沒什麼氣勢」。記為動作改善正面回饋、技能氣勢未通過；VFX候選仍依原順序獨立安排，本輪未直接展開。

2026-10-10 Owner最新Gate：繼續修ANIM-W1戰士本體；等戰士、法師、盜賊三者動作都經Owner確認通過，才開VFX。盜賊動作已有正面回饋，法師M3呈現方向已接受；不得自行換算成全部動作／美術通過。英雄英文語音聽感、情緒表演及真機聲畫驗收仍HOLD，本輪關閉、不新增台詞。Warrior-only迭代在codex/anim-warrior-body-02，不改Domain/Bot/資源/投影，不merge或發布。

ANIM-W1續修候選交付：codex/anim-warrior-body-02，單次蓄勢停拍／連續下擊／雙兵480ms同拍落定及原畫盾邊、完整握劍手遮罩；法師／盜賊本體保持。170 Swift、137 Golden快照、4原生Simulator測試與108狀態檢查通過；正常速度靜音完整棋盤與同局面對照見artifacts/ios/anim-warrior-body-02/REPORT.md。iPad Wi-Fi build1005安裝與OS啟動接受；真機UI認證取消、iPhone unavailable，實機驗收未通過。Owner氣勢／表演Pending；三職Owner確認前VFX未開始；英雄語音HOLD／關閉，情緒／人耳聽感／同步仍待核准。
