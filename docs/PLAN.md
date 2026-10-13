# Tactical Go｜職業導向戰術原型 PLAN

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
