# TacticalGo 建模與動畫 — 約 10 小時執行窗口

Owner 於台北 2026-10-09 凌晨 01:09 要求持續做下去，疑慮在 10 小時後確認；隨後提供目標截圖並明確將建模與動畫列為優先。窗口自 01:09:54 至 11:09:54（UTC 2026-10-08 17:09:54 至 2026-10-09 03:09:54）。當前 active goal + 半小時 thread heartbeat 維持跟進；不把已排程當作完成實作證據。

可逆的造型／技術選擇自行決定，待 Owner 選擇的問題寫下，窗口內不提問。不 commit/push/發布；不以尚未測試的真機或流程宣告 Accepted。

## 目標參考

精確附件副本：`assets/candidates/ios-3d-v01/owner-target-reference.png`；hash 見 provenance.json。取用的是俯視透視、鮮明草地、厚實可辨認單位、地面陰影、清楚蓄力／位移／命中回饋。參考圖不作遊戲素材輸入；保留 TacticalGo 交叉點與包圍規則，不新增塔防／河流玩法。

## 執行片與完成條件

| 優先 | Slice | 交付與驗收 | 狀態 |
|---|---|---|---|
| 1 | M1 真 3D 基礎 | 三職 actual meshes、材質／光照、正背面可檢查，共用棋盤和模型檢視 | 程序初版與單一視圖修正已驗證，三職正背面可看；持續品質精修 |
| 2 | M2 模型精修 | 獨立臉部／帽髮／體塊／厚盾刀杖、背面服裝、近俯視辨識 | 已加入倒角厚盾／菱形刃、圓靴及手臂／頭部 transform hierarchy；正在原生畫面 review，仍非 final |
| 3 | A1 基礎事件動畫 | 落子落地、召喚、提子退場、回合／勝負回饋；可跳過、Reduced Motion | 首版已接事件、跳過／Reduced Motion 並通過原生邏輯回歸；正在影片驗證 |
| 4 | A2 戰士 | 蓄力→盾擊／築壘雙落子→回穩，沿核心事件，不新增傷害 | 候選已實作，正在逐段原生 QA；Owner／完整對戰 Gate 待辦 |
| 5 | A3 法師 | 杖頭蓄光→投射→封印目標脈衝／到期消失，沿核心事件 | 候選已實作，正在逐段原生 QA；Owner／完整對戰 Gate 待辦 |
| 6 | A4 盜賊 | 預備→交換路徑／殘影→到位，清楚兩枚棋子交換 | 候選已實作，正在逐段原生 QA；Owner／完整對戰 Gate 待辦 |
| 7 | A5 勝負与整合 | 主將被提、勝利畫面與完整雙人對戰回放；動畫不改規則／不得卡流程 | 候選已實作，正在逐段原生 QA；Owner／完整對戰 Gate 待辦 |
| 8 | V1 原生三畫面 | 一般／技能預覽／危險，7×7／9×9，動畫 clips 和 screenshots | 部分候選已有；最新畫面待整合 |

## 邊界与待確認事項

- 程序模型目前是粗模且共用臉部，需精修到參考的體量／職業個性；不能先宣稱 Owner 已核准。
- UI testing idle 不證明 Metal 影格已更新。截圖曾發現切換停留／空白，已改單一 native view 共用並有正背面原生證據；後續動畫仍須影片／影格 QA。
- 模型與 B-v02 半身人物卡未統一；優先模型／動畫，卡片統一後排。
- 9×9 手指精準操作、實體 iPhone效能、VoiceOver／大字級仍是技術 Gate，不假造真機通過。
- 美術師精修、UV／蒙皮、骨架、USDZ production master 若本輪未交付，須明確記錄；transform-based 動畫不能稱成品骨架動畫。
- 參考畫面火球/投射只借鏡視覺節奏；技能行為仍是築壘、封印、換位，不新增 rocket damage。

## 驗證紀錄

- 3D 首版與舊 2D 回歸在 iPhone 17 共 4 UI tests 0 failures；iPhone SE 初版共 4 UI tests 0 failures。
- 這些 tests 支持操作邏輯，但 gallery 截圖曾與所選職業不符，視覺仍待修復證據。沒有以此宣稱 M1 完成。

## 01:38 進度

- TacticalGoMotion 是獨立 presentation target，事件／時序與模型渲染分離；7 個實際規則局面覆蓋落子、召喚、提子、築壘、封印、換位、勝負。
- 純 Swift 現有 Core 7 項與 Motion 5 項合計 12 tests PASS。首版 iPhone 17 5 UI tests / 0 failures，驗證動作示範實際 AP/Mana、跳過與 Reduced Motion，以及玩家棋局不被 review 改寫。
- M2 geometry 與 rigid-part hierarchy 已建置。動畫採真正 mesh transform 与局部效果，非影片貼片，仍不是蒙皮骨架成品。正在錄製原生 tour 與最新 iPhone SE 回歸。
- Native gallery 修正保留单一 ARView；不能再為 modelClass 建新 `.id(hero)` 視圖或與棋盤同时建立第二个 ARView。

## 01:45 小螢幕回歸缺口

- iPhone SE 動作頁首輪 FAIL：播放按鈕超出 VStack viewport，改 compact layout + ScrollView 保底；不是測試放寬或宣稱同屏 Gate 已過。
- 同一 run 的 3D 選點 test 在 iOS18 XCTest AX 快照出現 objc_msgSend / NSDictionary EXC_BAD_ACCESS，堆疊在注入的 XCTest snapshot request，沒有 app Swift 畫面 stack。查明影響前不當作偶發 PASS。隔離 Metal 私有子視圖的 accessibility 曝露並使用 SwiftUI arena + 明確格點清單，正在 focused regression。
- 3D 相機提高到更接近目標的俯視角；test 的右側交叉點改用公開相機規格手算的比例，以適應兩種 viewport，避免固定大手機像素坐標。
- 第一段 native tour 原始影片已完整涵蓋七種動作，保留原始編碼；顯示完整勝負結果，仍需逐段中間影格精查。

## 02:02 逐幀檢查與新修正

- iPhone SE 修正版完整 5 UI tests / 0 failures，保留第一個 FAIL 與 EXC_BAD_ACCESS 原始診斷。此結果支持修正後操作，不能證明實體 VoiceOver 或所有 OS 不會崩潰。
- 逐張 QA 發現首次进入模型頁仍殘留棋盤；增加 mounted-host lease 防止 outgoing SwiftUI representable 晚到更新／dismantle 改寫共用 ARView。focused regression PASS，首入戰士截图人工確認為真實模型，見 lease-attachments。
- 三職 refine：圓髮束、眼睛高光、厚盾鉚釘、背面披風／刀鞘、金屬 roughness 0.48、傾斜帽與真正多面水晶。這仍是程序候選，非美術師蒙皮 master。
- 八種 real-action review 包含封印到期；iPhone 17 focused UI test PASS，結果 AP／Mana 来自 GameEngine，review 不修改玩家對戰。
- 七種 tour 的原始片已逐段抽檢蓄力／雙落子／封印投射／換位／退場，swap 舊弧線仍偏近因此修正；latest native video 待重錄。
- 共用 ARView 的速度切換改为保持當前 phase，跳過／切場景恢復所有實體和關節。新增近距離造型動作，正在原生驗證。

## 02:31 模型資源與動作交付片

- 原生預設 sphere/rounded box 使三職每隻約32–39萬 triangles；實際 export 才看出密度，已改固定面數網格，大臉與體塊保留較細解析度。現在戰士25544／法師20904／盜賊22784；不能轉述成真機性能改善。
- USD/USDC/USDZ 候選從實際 runtime mesh streams 匯出，保留局部關節層級。三職 static native reload bounds error 0、mesh counts相同；三職 rigid-pose包各識別2個約1.4秒動畫。Code native poses、export samples 共用 MiniaturePose。
- 獨立 native resource preview 已看戰士／法師；QuickLook CLI 沒產生圖並已停止自己的程序，未計入 PASS。validation原始coding diagnostics保留。
- 新 SE interruption regression PASS 並人工確認跳過築壘兩士兵都顯示、切回主棋局與模型頁正確。
- 本轮繼續模型品質，下一片加入可編輯建模工程／服裝及關節接合；工具取官方 Blender5.2.2 LTS arm64，在 /tmp/TacticalGoModelTools 自用，不改使用者全域 Applications。下載／hash／執行尚待確認。

### 02:54 — 可編輯骨架工程通過，造型 v02 修飾中
三職 .blend / USDZ 已有四骨與可編輯 pose；iPhone17 simulator 可原生播放。Blender 六時間点全頂點比對及原生 raw-rest 範圍通過，focused UI test 回到對戰 AP2 通過。單骨 rigid weights 是明確候選限制；不宣稱柔性皮膚／UV／真機或 Owner Gate。證據 artifacts/ios/blender-rigs-v01/VALIDATION.md。初次 AABB 比較失敗保留，修正為同樣的 actual vertex range 後 <1e-6m。

M2 下一版 assets/candidates/ios-3d-v02：原生閉合兜帽／面罩、折線披風、 fitted 胸甲與握把手指；正在收集新 mesh 與渲染 QA。v01 檔及 evidence 保留，不覆蓋舊版候選。繼續建模／動畫優先，疑慮留到 11:09 截止。

### 03:21 — v02 三職骨架模型已打包進 iOS
閉合兜帽／面罩、連續袖子、折線披風、 fitted 胸甲、整体髮型與握把指節已由 Swift actual mesh 匯出，三職 .blend / USDZ 可編輯。原生近距離與棋盤均使用 ios/TacticalGo/Models，與 v02 export binary 完全相同。ModelLibrary 先完整預載；外層 pose wrapper 保留 package bind space，骨架 reset 與跳過／離開保持匹配。iOS17 路徑使用 async publisher，相容部署編譯通過；iOS17 runtime 未跑。

iPhone17 與 iPhoneSE 各 full UI 7/7 PASS，11 Python validators PASS，八個新 shell actual topology PASS，三職六时间点 vertex round-trip <1e-6m、native actual-rest bounds <1e-6m。證據 artifacts/ios/model-polish-v02/VALIDATION.md。單骨 rigid weights／真機／Owner Gate 仍 pending，不把测试 PASS 當成正式美術 accepted。

正錄新版 native model / skill tour。M3 接續布料關節、陰影畫面及 iPhone 棋盤構圖；Core、Windows規則及已知玩法疑慮驗收仍分開。没有 commit/push/release。

### 04:00 — M3 partial sleeve skin 已原生驗證

三職 bundled USDZ 更新 v03，Mage/Rogue 各192個衣袖 mixed vertices，最多兩骨影響；actual weights、六時間點 deformation、native rest bounds、五 phase 杖頭 socket 通過。三職人物卡使用同模型 native 透明肖像。focused iPhone17 2/2、Python14 PASS，55秒八動作影片與約35度抬手 stress 已人工抽看。這是候選肩袖蒙皮，不是完整角色 production rig；工程 / Owner / 真機 Gate 保持區分。

繼續棋盤場景建模與手機構圖，疑慮留到11:09。M3 evidence: artifacts/ios/model-skin-v03/VALIDATION.md。

### 04:05 — 原創棋盤場景與旋轉構圖

草地、低石緣、角落樹叢、隊伍旗幟、邊緣草叢均是 native meshes；7×7/9×9工程可編輯 .blend/USDZ，native source triangle counts匯入相同。角落投影計算避免yaw裁邊；17的點選+八動作 focused2/2、SE模型/點選focused1/1 PASS。SE9×9角色仍小，不宣稱手指 Gate。下一片 native 法術光暈/粒子尾跡；窗口11:09前繼續，無提問／提交／發布。

### 04:35 — 手機試玩畫面與放大

預設界面保留資源、3D棋盤、模型肖像、氣、技能／确认／換手；驗收工具進設定選單。17 focused2/2 PASS；SE首次和局PASS、zoom落子／非法／復原正確，但選單收起動畫未結束的hitability檢查FAIL。原始診斷／影片保留，改為等待同按鈕恢復可點擊，focused1/1 PASS。兩尺寸各六張真實畫面已全部人工看過；9×9放大1.6倍保持坐標，但panning／真機手指仍pending。evidence artifacts/ios/phone-layout-v01/VALIDATION.md。

投射FX已加白芯、cyan光暈、18個沿實際拋物線回溯的mesh尾跡與落點脈衝；native錄影看見尾跡，ParticleEmitterComponent的獨立貢獻未單獨隔離，不以此宣稱粒子完整驗收。正在小螢幕Skip/Reduced回歸與v03三職原生近距離錄影；接著補actual main win／draw流程，繼續建模動作至11:09。

### 04:37 — FX、和局／勝負与 v04 下一片

封印尾跡與落點脈衝已人工看 native video；SE八動作方法1/1、Skip/離場1/1 PASS，Swift15 PASS。main commander-capture 的 preview/confirm/end/undo/new-match 原生17 test1/1 PASS，SE執行中；不是完整競技對戰。證據 artifacts/ios/effects-v01/VALIDATION.md。

45秒v03三職近距離tour已錄；抽幀看見 Mage披風穿過腰帶。v04以新版本保存，先修cloth clearance/後背袋位置，再做UV與柔和材質細節，原v03工程保留。機械四骨/有限肩袖skin並非完整有機rig；後續操作、真機、Owner仍pending。仍至11:09不提問/提交/發布。

### 05:08 — v04 UV／披風修正已原生整合

三職 .blend／USDZ 新版修正披風穿腰帶與背袋；1024原創UV色彩+局部AO保留材質金屬／粗糙度。初次漏色和第二次sRGB偏色版本保留，修正pixel transfer後UV有限取樣0缺口；19 Python tests PASS。三職native actual-rest bounds、五phase杖頭socket、built bundle SHA與原檔相同。iPhone17／SE各full10/10 PASS；SE Documents review仍v03，最新v04 imported focused回歸接續。native前背面已人工看過，仍有少量shadow specks；Owner／真機／完整有機rig未宣稱。evidence artifacts/ios/model-surfaces-v04/VALIDATION.md。

下一片串接兩段從標準newGame開始、沿核心接受動作的連續對戰（戰士／法師、盜賊／戰士），檢查三職技能、封印到期、双方勝負和Skip/undo銜接。只是配合走法的presentation QA，不等於策略平衡／真人完整對戰。繼續至11:09，不提問／提交／發布。

### 05:15 — 從開局到兩方勝負的連續動畫已驗證

戰士／法師16步9回合、盜賊／戰士11步6回合均從newGame沿actualGameSession結果播放，原生兩段影片／完整trace保留。兩尺寸各focused1/1 UI PASS，覆蓋Skip、undo、Reduced、reset、返回原棋局；Swift17 PASS。SE最新v04 imported model另focused1/1 PASS，修正先前拼錯method selector未執行之缺口，原命令／logs保留。證據 artifacts/ios/full-match-v01/VALIDATION.md。

配合走法只支持presentation QA，真人完整對戰與Owner／真機Gate不升格。接續實際腿部關節／腳底定位、boot輪廓與職業造型精修，另存新版本；11:09截止前繼續不提問、不提交發布。

### 05:40 — v05 十骨腿部／腳底定位完成候選驗證

三職thigh/calf/foot鏈與新靴底已bundle，Blender nested-parent evaluation首輪8.48mm偏差修正後六時點全頂點<4.8e-7m，原failure保留。Swift19／Python20 PASS、三職native10骨bounds與36foot samples＋3reset PASS；兩尺寸完整UI各11/11（imported Documents均v05）。同一native view的八動作×三phase×三種結束共72狀態還原PASS，三職技能27樣本確實變形後回穩。12張新版normal/skill/danger ×7/9 ×兩尺寸人工review通過；v04 SE SpringBoard失敗保留，新capture用unique readiness token與installed hash guards，不能把結構ready當pixel PASS。evidence artifacts/ios/leg-rig-v05/VALIDATION.md。

十骨rig仍是有限剛性腿與肩袖blend，表情個性、近距離shadow specks、9×9定位／真機／Owner風格Gate仍待。接續三職面部輪廓與原生光影精修，保持source／UV／pack／native對照；Core與C#規則不改。窗口11:09:54前不提問、不commit/push/發布。

### 06:07 — v06 三職個性與同模型卡片完成候選
三職閉合臉型／斜眉／戰士偏側髮型／法師白鬍髮已整合；同USDZ透明人物卡與32/48/64原生token review保留。native10骨／36腳+3reset／5杖頭socket／72實際中斷還原PASS，cleanSE full11、17 focused3 PASS，兩尺寸12張完整畫面人工查看正確。bias1/2.5/4未消除零星shadow specks，正式設定不改；原SE兩種啟動crash風險仍開啟，cleanSE八次啟動與fullUI成功不是根因修正。evidence artifacts/ios/face-light-v06/VALIDATION.md。接續普通棋子／主將原創模型與密集棋盤動畫，Core/C#不改，11:09:54前繼續、不提問提交發布。

### 06:36 — 士兵／主將與光暈資源候選完成
四款原創普通單位保持全部頂點／面數，runtime材質合併soldier30→8、commander38→9；獨立Blender＋native實際頂點與extents誤差<6.2e-8m。72中斷還原、两尺寸full11各PASS；八動作最新trace和12完整手機畫面人工review。透明光暈預載USD不再經Swift blending setter，原Unlit/PBR兩次assertion保留，不能稱框架根因修正。實體手指／效能、Owner美術與organic rig仍pending。evidence artifacts/ios/unit-compaction-v01/VALIDATION.md。接續v07披風固定肩部＋延後擺動蒙皮，source/curve27Python及20Swift候選testsPASS，原生／asset Gate接續；窗口11:09:54前繼續、不提問提交發布。

### 07:25 — v07披風與手機整合完成候選驗證
Final三職11骨／固定肩部cape混合skin、戰士latefollow-through與Rogue側腰包通過native／Blender／UV／strictUSD資源檢查。實際clip24組與6次controller完成trace、對應12個抽幀人工review確認姿態／披風／回穩；猜測elapsed抽幀沒有動作不是clip故障，未改動畫資源binding。兩尺寸12張最新完整手機畫面人工review、17full11與SEfocused3 PASS，44ptzoom獨立row正確。原9overlay缺失診斷撤回，首parentAXidentifier覆蓋FAIL保留並修正。Owner／真機／性能／organic Gate仍pending。evidence artifacts/ios/cape-motion-v07/VALIDATION.md、zoom-controls-v02/VALIDATION.md。接續arena-v02細草地、chippedstones與lobedfoliage建模，source已實作待實際export/native驗證；截止11:09:54前繼續，不提問提交發布。


### 07:46 — 棋盤 v02 與可對齊動畫影格完成候選

細草地、三種閉合破角石緣與群簇樹冠已保留可編輯工程；格線世界頂點與前版一致，裝飾在可玩區外。兩種棋盤完整原生匯入頂點誤差 <4.8e-7m、兩尺寸 12 張完整畫面人工看過；SE focused 3/3、Release 編譯通過。八動作 trace 完成，另用 DEBUG 獨立畫面時碼解出 16 張中／後段原始影格，全部逐張看過，時間差最大 0.0147 秒。舊影片 wallTime 對齊不準及解碼首輪失敗都保留，不能拿舊標籤宣稱精確 phase。證據 arena-polish-v02/VALIDATION.md。

陰影 culling 比較未消除三職黑點，預設不改。原生未貼圖模型沒有對應孤立點，正在隔離同一 v07 rig 的貼圖連線；法師下巴金色穿插另查幾何。Owner／真機／完整 organic rig 仍待，截止 11:09:54 前繼續，不提問提交發布。


### 08:02 — v08 法師領飾與實際影格序號驗證

法師兩片金領飾移到胸口，原生 source 所有 25 局部 mesh 保持一致，只兩節點位置／名稱改動；靜止下巴與領飾垂直間隔 8.016 mm。可編輯 .blend／USDZ／同模型人物卡已整合，两尺寸 native 3 rigs／39 foot／21 cape／5 socket／72 interruption 各 PASS。SE 首 focused imported startup 在 Metal reflection/RealityKit skeletal import EXC_BAD_ACCESS，原 ips/xcresult保留；bastion PASS、匹配 v08 Documents 再驗 imported UI 1/1 PASS，不宣稱 crash 根因修復。

模型影片有不連續 PTS，seek 秒數抽幀實際晚約 .6 秒；先前圖片／錯誤審核保留。工具改 decoded frame index，再逐張核對 PNG 畫面時碼，12 張全部精確匹配、最大 .0166秒，全部人工看過姿態與披風；Mage collar 仍清楚。arena-v02 原 16 張也複驗 clock 全部匹配。證據 collar-polish-v08/VALIDATION.md。陰影／貼圖／UV／靜態／雙面對照均未確定黑點根因，維持原材質設定。下一片接既定 9×9 放大後拖移／定位，保持模型與動畫；11:09:54 前繼續，不提問提交發布。

### 08:32 — 原生放大拖曳／置中候選已驗證

7×7／9×9原生地面射線拖曳、44pt置中與新對戰清除鏡頭位移完成。初版僅外格線限制有大片空白；四角射線版本雖UI PASS卻水平拖曳造成z跳動，原證據保留。改四邊中點並保留初始reference後，兩尺寸各8個fresh pan ends獨立方向／資源／邊界audit PASS；17先前full13、final focused兩尺寸各3/3、38Python、Release PASS。18張前版方向圖與2張final選點/旋轉圖人工看過；不宣稱full14／真機手指／完整無障礙。證據 board-pan-v01/VALIDATION.md。

v08三職同build/model SHA的主光陰影元件on/off六張人工查看，投影確實消失但固定小黑點數8/12/13各不變，故不能稱shadow-map缺陷。首nil關閉未成功的diagnostic保留，DEBUG改直接移除元件；正式預設仍開啟陰影。接續三職骨架待機呼吸／服裝擺動候選，先模型檢視與可編輯動作工程，不改Core/規則；截止11:09:54前持續，不提問提交發布。


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
