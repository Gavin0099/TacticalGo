> **現行規格已改為 A0（2026-10-09）**：原始 A Token＋B 卡、2.5D 棋盤；3D 身份流程暫停。最新 V1 資訊層級／390與320布局見 [V1_A0_UI_SPEC.md](V1_A0_UI_SPEC.md)。下方真正3D候選與驗證是保留的歷史研究，不是目前產品主線或已通過品質驗收。

# V1 棋盤與真正 3D 模型候選規格

2026-10-09 · 候選，尚未 Owner 視覺核准。參考《皇室戰爭》的手機競技場可讀性與立體底座語言；TacticalGo 用自己的棋盤、角色與操作模型。

參考來源：[Supercell 官方遊戲頁](https://supercell.com/en/games/clashroyale/)、[官方 Gameplay First Look](https://www.youtube.com/watch?v=_hNxfiXmeAE)。SwiftUI 嵌入 SpriteKit 使用 Apple 的 [SpriteView](https://developer.apple.com/documentation/spritekit/spriteview)。它們是視覺／技術參考，不是下載使用的遊戲素材。

## 2026-10-09 Owner 最新方向：真正卡通 3D 建模

Owner 明確要求「要真的像皇室戰爭那種建模」，取代只將既有全身插畫縮小的視覺解法。Swift App 預設使用 RealityKit 原生 3D 候選；SwiftUI／SpriteKit 保留作操作與畫面比較。此變更只涉及 iOS presentation，不修改規則、資源或技能。

- 技術：[Apple RealityKit ARView](https://developer.apple.com/documentation/realitykit/arview)，使用 nonAR 模式，不啟動相機 AR session；SwiftUI 封裝 native view。
- 三職由 `MiniatureModels` 產生真正網格：圓潤體塊、倒角裝備、自製旋轉曲面帽子／衣袍、閉合兜帽／面罩、折線披風、連續袖子、厚盾與金屬刃、立體臉部。actual streams 匯出為可編輯 Blender / USDZ；棋盤與近距離模型檢視共用 bundled v03 蒙皮候選。3D 人物卡從同樣模型原生渲染。
- 方向為大頭、短肢、厚實道具、鮮明色塊，參考 [Supercell 官方](https://supercell.com/en/games/clashroyale/) 的卡通模型體積；保留 TacticalGo 自己的三職。這是可檢查的程序建模候選，不能宣稱已達皇室戰爭完成度。
- 材質：布料／皮革 roughness 0.72，金屬 roughness 0.48；暖色主光、冷色補光、主光投影。棋盤為有厚度的草地、石緣、角落樹叢、旗幟與邊緣草叢 meshes；棋子有立體陣營底座。裝飾不覆蓋規則交叉點。
- 座標：規則 `(x,y)` 映射為 world `(x−(N−1)/2, 0.035, y−(N−1)/2)`，每個交叉點距離 1。模型腳底在原點；英雄縮放 0.62，底座頂面高 0.115。
- 相機：PerspectiveCamera，棋盤 FOV 38°，基礎距離 `(N+1.25) × max(1,1/aspect) × 1.55`，高度係數 0.88／前向係數 0.48，yaw 0 或 0.30 rad。`ArenaCamera` 再以實際棋盤八角落的透視投影需求增加距離，旋轉後維持 94% 安全範圍。試玩畫面提供 1.6× 放大與全盤切換；選點後放大以該點為 focus，放大裁邊是刻意的區域檢視，不改規則坐標。
- 點選用原生 `ARView.project` 投影真正 3D 交叉點，選最近交點且距離需小於當地最小列距的 0.55 倍。棋子頭部、武器、場外點不作命中範圍。舊版 `BoardProjection` 僅服務兩個 2D 比較渲染器。
- 模型檢視可切換戰士／法師／盜賊，拖曳或按鈕旋轉到背面；能確認輪廓、材質與背面幾何。
- 事件動畫操作實際骨架關節並恢復 rest transforms。v03 有 body／兩肩／head 四骨，Mage/Rogue 各192個肩袖頂點有最多兩骨混合，其餘多為 rigid weights。可編輯工程、native packages、六時間點頂點 round-trip 與五 phase 法杖 socket 已驗證；完整有機／臉部 rig、UV 與 artist production masters 仍待辦。
- 下一個 V1 Gate 仍為 Owner 對三種完整 iPhone 畫面的核准。真機效能、9×9 密集選點、輪廓／遮擋、資源預算仍待 SW2a 驗收。

以下 2D 比較規格保留，不能當作 3D 的投影公式。

## 2D 比較相機與 anchor

- iPhone 直向；固定斜俯視，棋盤不轉成菱形，X 向右、Y 向下。透視由梯形與遠近寬度表達，不冒稱真正 3D 相機。
- 尺寸 N 為 7 或 9，`row = y / (N−1)`；每列寬度 `0.74 + 0.12 × row`。
- 落點在棋盤 View 的正規化座標：`u = 0.5 + (x / (N−1)−0.5) × width`；`v = 0.18 + 0.65 × row`。
- 原點 anchor 是棋子的足底／底座中心；身體向上延伸。所有選取與 hit test 以落點為準，禁止用頭部中心決定格子。
- SpriteKit 僅在 presentation 邊界做 `sceneY = height − viewY`，不得把倒置座標傳回核心。
- 棋子半徑 `viewWidth / (N+1) × 0.31`；遠處縮小或正式 character 比例另在 V2 調整，不能遮住相鄰交叉點。

## 圖層

| 層 | SpriteKit z | 內容 |
|---|---:|---|
| 棋盤厚度 | −1 | 10 pt 下移的深色底座 |
| 地表／格線 | 0 | 草綠場地、金色邊框、清楚交叉線 |
| 合法落點 | 1 | 半透明白點 |
| 既有封印 | 2 | 紫色空點環；仍算氣 |
| 棋子 | `10 + y × 10` | 陰影→陣營底座→本體→種類符號；同列同 z，避免無必要覆蓋 |
| 危險／預期提子 | 190 | 紅環；主將危險標記整個相連棋串，不是每顆獨立 HP |
| 選取／技能候選 | 200 | 金環與半透明預覽；未確認不消耗 AP／Mana |
| HUD／卡片／操作 | SwiftUI | 置於棋盤外，確認按鈕固定在棋盤下面 |

## 素材配置

- 2026-10-09 Owner 要求先接入美術：英雄使用 `.agents/skills/tacticalgo-character-style/assets/{warrior,mage,rogue}-v01.png` 的既有全身候選；iOS 複製到 `miniature-{class}.imageset`，原始 bytes／SHA-256 不變。這是全身圖的縮小棋盤候選，不宣稱已完成專門重繪的正式 token。
- 士兵是黑／象牙棋石；主將為有皇冠與金圈的棋石。陣營用獨立藍／紅底座與圓點／三角標記；角色不換色。選取與危險覆蓋層和角色分開。
- 角色來源 canvas 為 1254×1254，候選足底 anchor（原圖 top-left 座標）：warrior `(0.54,0.93)`、mage `(0.54,0.94)`、rogue `(0.55,0.93)`。以肉眼定位供原型比較，尚非 production anchor 認證。
- 棋盤角色 canvas 邊長 `min(viewWidth/(N+1)×1.02, viewHeight×0.65/(N−1)×1.10)`，按垂直列距限制高度；兩渲染器使用同一尺寸及 anchor，腳底落在交叉點。美術本體不參與 hit test，選點仍由 `BoardProjection` 決定。
- 全身候選與人物卡是不同版本：棋盤 v01、人物卡 B-v02；目前接線保留各自版本，不宣稱兩者已達最新身份／配色完全一致。
- 人物卡復用 `assets/candidates/vis-feel-01/tokens/B-{warrior,mage,rogue}-v02.png`，原檔無改動。iOS 使用 `Assets.xcassets/{warrior,mage,rogue}.imageset/portrait.png`。
- 藍／紅與圓點／三角表示陣營，皇冠／全身角色／普通棋石表示主將／英雄／士兵；不只靠顏色區分。
- 角色卡和棋盤 token 分開配置；正式 token 應透明背景、底座中心 anchor、輪廓優先，另交 32／48／64 px review。本輪不生成新的角色圖或動畫表；只複用既有全身圖與卡片。
- 候選角色的來源與權利狀態沿用 `assets/candidates/vis-feel-01/provenance.json`、`sources/asset-provenance.json`；本輪復用不等於商業發佈權利核准。

## iPhone 驗收

畫面切換：一般→技能預覽→危險，各有 7×7／9×9；渲染切換不會重開局或修改狀態，切換示例／尺寸會重載示例。

- 一般：看得清輪到誰、剩餘行動、能量、主將、英雄、士兵；點選與取消不扣資源。
- 技能預覽：辨識施放範圍、金色目標、可能提子與確認按鈕；確認後事件與盤面一致。
- 危險：主將棋串 1 氣有數字＋紅環；封印空點仍是氣；不能把提示誤讀成獨立 HP。
- 9×9 的交叉點小於 44 pt 時，不能據「中心 tap 自動測試通過」宣稱手指操作已通過；必須在 SW2a-02 評估放大／定位。原型另有 native「格點清單」供 VoiceOver／密集選點，但不能替代主要棋盤操作驗收。
- 小螢幕與大字級若無法同屏，需調整佈局；ScrollView 是候選的保底，不是同屏 Gate 通過證據。
- 真機的遮擋、連續操作、效能、VoiceOver 與 Dynamic Type 待 SW2a；模擬器截圖不替代真機。

## 本輪接線驗證

證據放在 `artifacts/ios/art-integration/`：來源 SHA／透明度、32／48／64 px 灰階與輪廓 review、原生 7×7／9×9 模擬器畫面與互動測試。角色排序為逐列由後至前；提示在最上層。

iPhone SE 的 9×9 會將角色縮得更小，臉與裝備細節不足；目前可以看全身候選搭配陣營底座，但辨識速度與手指操作仍需 SW2a 放大／定位和真機驗收。不把本輪素材載入成功當作正式 V1 視覺核准。

## 3D 動作候選契約

- 規則即時提交，動畫讀取 accepted receipt；非法操作不播、預覽不扣資源、復原清除 receipt。TacticalGoMotion 是純 Swift presentation target，Core 不依賴它。
- 落子 0.30 s、英雄召喚 0.46 s，接地後回彈；提子在主動作落地後 0.28 s 退場。主將被提完再播放 0.58 s 彩紙，勝負由核心決定。
- 築壘先蓄力 0.18 s，兩士兵同步落下，0.39 s 接地对应盾擊最大角度，0.48 s 回穩。
- 封印 0.60 s：杖頭起始、投射、到达才顯示結果環；blocked player 回合結束的 sealExpired 以 0.22 s 縮環退場。
- 換位預備 0.10 s、移動 0.32 s；兩枚實體走相反且最大側距 0.36 world 的弧線、小跳高 0.12，地面交叉點仍由規則決定。
- Reduced Motion 立即顯示最终盤面，不播放 transient nodes；跳過／切頁／復原恢复關節與實體可見性。慢動作改變速度但保持當前 phase。
- 近距離「造型動作」是 art pose study，使用同一四骨蒙皮 package，不送規則 action；不能据此宣稱完整有機骨架或完整遊戲流程已完成。

## 2026-10-09 04:35 手機試玩構圖

預設隱藏 renderer／示例／素材驗收工具列，將這些控制收在「對戰設定 → 驗收設定」；試玩畫面保留資源、棋盤、人物卡、氣、技能與確認／換手。兩個模擬器各保存一般／技能預覽／危險 × 7×7／9×9 六張 native screenshots，全部人工看過；375pt SE 的主要控制同屏可見，9×9 全盤角色仍小。

放大後中心點對應與非法落子／復原已在 17／SE 自動操作通過；SE 最初一次在選單收起動畫中檢查 hitability 失敗，原始診斷保留，settled-screen predicate retry 通過。沒有因此宣稱真機手指／VoiceOver／大字級 Gate。證據 artifacts/ios/phone-layout-v01/VALIDATION.md。

## 2026-10-09 09:50 — Owner 要求回到原角色身份

Owner 追加「至少要有這樣的程度」並提供 Plants on Fire 手機畫面，隨後明確要求「按照之前設計的圖片來建模」。身份依據固定為 character-style 三職 v01 全身圖與 VIS-FEEL-01 的 B-v02 卡片：戰士栗髮／無頭盔／奶油衣／青綠披風／左盾右劍；法師年輕紫髮／紫帽奶油邊／右手晶杖；盜賊銅髮／靛藍開臉兜帽／苔綠背心／赭圍巾／右短刀。所有六張已逐一看圖，v01 SHA 已核對。皇室戰爭與 Plants on Fire 是完成品質、體積光影與手機可讀性的標準，不能據此換角色。

v09 與 v10 騎士雕塑均不算視覺通過；新河流城堡場景僅保留為獨立構圖研究。官方 KayKit Adventurers 2.0 FREE 實際下載、CC0 許可已讀，僅可作拓撲／骨架／動畫做法與合法施工基底，不可原樣換入新人物或宣稱全原創。原設計 v01 與 B-v02 仍 candidate，並未擅自升格 exact-file production approval。

切片：ID-M1 戰士原設計的臉／髮／衣／左右裝備重建及正側背對照 → ID-M2 法師與盜賊一致性 → ID-A1 相容骨架動作與原生載入／還原 → ID-V1 iPhone 三種完整畫面。先看模型是否像原图，再做整合。第一輪戰士 source 渲染仍有浮眼、硬髮、姿態偏差，保留失敗圖並修正，不替換 main bundle、不宣稱品質 Gate。期限 11:09:54 不變，無 commit/push/發布，模擬器不替代真機。


## 2026-10-09 11:06 — 原圖身份候選與原生動作證據（品質尚未通過）

ID-M1／M2 已有三職原圖身份候選：栗髮左盾右劍戰士、紫髮紫帽晶杖法師、銅髮開臉靛帽苔綠衣盜賊。最新 source 為 ios-identity-motion-v05，各有可編輯 .blend、23骨、43幀自編造型動作與 strict USDZ；KayKit CC0 僅施工基底，不替代身份，不宣稱全原創。iOS 模型檢視可 opt-in 原圖候選與原全身縮圖對照；主棋盤仍 v09/11骨，23骨 gameplay adapter 未做。首 source 烘焙／staff零權重選取／native後腦透眼失敗均保留，五個實際 mesh 的法師 staff 修正 pass/fail regression 通過；最新補閉合頭與內袖後，原生眼睛透後腦消除，但袖口縫、握持、背髮帽殼與平板披風仍存在。

v05 build-for-testing與12 USD流程步驟exit0；SE/iOS18 focused UI 1/1 PASS。17六正背截圖與六動作的十二對齊影格全部人工看過，max clock誤差 .0166秒，6 controller完成18 joint samples，31,301,946-byte native movie。Warrior importer片段1.2s而source1.4s未定位原因；兩資源是global/subtree重複入口，非兩套獨立動畫。最新17 UI／SE正面像素補驗正在收尾，另以 final evidence 結果為準。Core本輪未改，模擬器不等於真機，不宣稱品質Gate。ID-V1三種完整局面、7/9新模型比例及規則技能／落子／提子／勝負完整整合尚未完成。證據 artifacts/ios/identity-model-v01/REVIEW.md、VALIDATION.md。

11:09:54期限維持；到期停止新切片，整理既有結果及Owner待決，不commit/push/發布，不將候選升格完成。

11:08 收尾補驗：最新17／SE focused UI各1/1 PASS，SE3職正面也人工看過；9張静止＋12動作影格。final-input-consistency.json 核對源工程／USD／包／bundle／installed17及原圖bytes一致。美術與完整場景仍未通過，見 identity-model-v01/REVIEW.md、VALIDATION.md。
