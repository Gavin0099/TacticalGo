# ANIM-W1 / ANIM-R1 — 原畫角色本體候選

結果：可玩 SwiftUI 戰士／盜賊本體候選、可重用 Skill、完整棋盤原生錄影與 Slice 順序已保存。工程驗證與 Owner 動作／美術驗收分開。
原因：採既有 B-v02 原畫切層，獨立身體／頭部／持握／盾牌／布料；原有成功收據控制動作與結算，不用特效替代角色動作。
下一步：完成隔離提交／push後停止，請 Owner 先觀看 W1／R1；VFX-01、VFX-02及語音／觸覺不在本輪。

## 範圍與位置

工作分支 `codex/anim-warrior-rogue-01`，基線 M3 `c13f23e`，沿用其黑白薄底座／外側形狀提示。主 Desktop checkout 未修改；不 merge、TestFlight 或正式發布。M3 呈現方向已接受，正式美術及Owner 已回饋盜賊動作不錯，戰士原版只有還好；盜賊凍結，戰士只做下擊／落兵同拍修正，最新 Owner 回饋「動作比較好一點，但還是沒氣勢」；動作改善已收到正面回饋，技能氣勢及整體美術仍未通過，未擅自開VFX。

Skill 保存於 `.agents/skills/tacticalgo-cutout-animation/`，相同版本安裝 `/Users/pc49-58/.codex/skills/tacticalgo-cutout-animation/`；quick_validate兩份均 `Skill is valid!`。可用 `$tacticalgo-cutout-animation` 呼叫。原畫身份、遮罩、成功事件時序、取消與小尺寸證據流程可重用；不是建立新角色、3D 或配音的授權。

`docs/ios/SLICES.md`及`docs/PLAN.md`、canonical memory已記錄：**W1/R1本體 → 停下供 Owner 看 → VFX-01法師 → VFX-02戰士／盜賊 → 三職 SFX／輕量觸覺／英文語音時間整合**。不因前一輪工程通過自動開下一輪。

## 可以直接觀看

- `media-warrior-impact/warrior-w1-full-board.mp4`：最新戰士修正；登場、黑方築壘、正式提子／勝利、白方、320pt/9×9密集與Reduced Motion。
- `media/rogue-r1-full-board.mp4`：Owner 已正面回饋的盜賊版本；登場、黑方換位、正式提子／勝利、白方、密集與Reduced Motion。
- `media/warrior-rogue-small-dense-reduced.mp4`：同上小尺寸段落，正常速度。
- `media/warrior-preview-cancel-undo.mp4`、`rogue-preview-cancel-undo.mp4`：實際選取／取消／確認／復原錄製序列。
- `media/warrior-rogue-native-closeup.mp4`：原生造型檢查頁，僅輔助接縫檢查；沒有宣稱對局結算。
- `hero-body-review/`：32／48／64 **grid pitch** 的1px/pt雙陣營姿勢表及512px原生近景。不是把512px圖當正常棋盤辨識證據。
- `hero-body-checkpoints/`：實際 CozyBoard 成功收據 renderer 的原姿、蓄勢、出手、途中、落定及密集正交鄰兵；靜態固定時間點，不取代正常速度影片。

影片是實際 Simulator／SwiftUI／XCTest 點擊輸入，**靜音、無後製音軌、無角色合成／變速**。字幕加於完整原生 viewport外。12個成功收據保留before/after/AP/Mana/事件、clock、SHA及剪輯區间，見`media/edit-audit.json`。Recorder clock是剪輯依據，不是校準真機音訊延遲；Simulator原片為可變幀率，轉30fps不證明實際60fps或真機流暢。

設備：iOS18.0 iPhone390pt Simulator（176A7ED7…）與SE Simulator（97B346CB…；實際窗口375pt，另測320pt內容容器）、iPad18.0 Simulator（9838EAA7…）。390內容板面382×429.75pt／pitch46.56；320內容板面312×351pt／pitch28.52，英雄canvas0.88pitch。格線、ground anchor、提示及hit投影未改。

舊版 `media/` 保留、不覆寫；戰士最新 `media-warrior-impact/` 重錄同樣12個合法收據。`warrior-before-after-native.mp4` 為同一黑方無提子7×7局面、同viewport、正常速度左右比較；兩段均原生，無新角色或變速。

## 本體與時序

| 動作 | 戰士 | 盜賊 |
|---|---|---|
| 登場 | 底座／短距離角色落定，盾與持劍手回穩，640ms | 短距離落定、壓身與持刀手、580ms |
| 蓄勢 | 上身後收、整盾抬升 | 下蹲、重心偏移、持刀群組後收 |
| 出手 | 320ms開始前送，最後90ms下擊；580ms最低盾姿與兩兵340–580ms落定同拍，80ms回震 | 200ms出手，220–420ms兩棋反向交換 |
| 提子 | 真正capture事件才640ms起退場 | 真正capture事件才480ms起退場 |
| 本體收勢 | 900ms回原姿，布料延遲80ms | 720ms回原姿，布料延遲80ms |

姿勢位移以512px原畫座標描述：戰士盾Y−72抬升→−22前送→+38下擊、盾X+12避臉、上身X+22→−32、盾角−20→+10度；盜賊下蹲34px、上身−5→+7度、持握−12→+10度。不是整張Token轉動；底座不隨角色層旋轉。身體、頭、持握手＋武器、盾與布料的可編輯遮罩／支點在`HeroBodyView.swift`；數值和source mask SHA在`assets/candidates/anim-warrior-rogue-01/rig-and-timing.json`。

盜賊交換中點兩棋原先重疊，現採垂直於交換方向的短路徑偏移：英雄−0.16pitch、敵兵+0.08pitch，sin曲線，端點歸零。橫向換位偏Y、縱向偏X，終點仍是既有交叉點。未改合法目標、交換規則或命中。

共用成功adapter `HeroPerformance` 讀取piecePlaced／piecesSwapped，供BoardPlayback、CozyBoard、動作鎖定及畫面實際audio instance使用。兩兵在release前隱藏after-state目的地，避免提早出現；capture、勝負／和局及換手依共同時序。最後AP和局尾音duration已補齊；最新Package與Release包含此修正。Owner 戰士回饋後，新的戰士時序、影像、Simulator及iPhone實測另以warrior-impact命名，舊版時序證據不充作新版。既有可選小提示同樣讀receipt.plan，未新增符文、震波、殘影或新音檔。

## 原畫與補圖

臉、頭、原武器／手及整盾徽記皆用未改原圖像素。原姿直接顯示原圖。生成來源僅補移開後的衣料缺口，限制在原alpha輪廓；不用生成臉或主兜帽。頭層縮至真正頭／頸，不再搬動左肩甲；hole扣除採destinationOut聯集，不把重疊孔恢復成重複武器。補接線的original underlap再排除held／shield。

兩張true-alpha backing由內建image_gen依原圖編輯，原輸出未重繪或重採樣後覆寫來源。prompts、生成方法、身份及input/outputSHA在`assets/candidates/anim-warrior-rogue-01/`；modelVersion未知，不假填。來源權利／正式發布與美術核准維持candidate／Pending。

## 驗證

| 新證據 | 結果與界線 |
|---|---|
| skill-validation.log | Repo及安裝copy均有效 |
| package-warrior-impact.log | 169 tests，0 failure；新增W/R兩陣營7/9、失敗／成功、資源、同期雙兵、動作連續與最後AP和局尾音 |
| golden-replay.log／golden-compare.log | fresh Swift 38 fixtures／99 actions／137 snapshots 與cached C#完整錯誤／事件／資源一致；本輪C#未重跑，不據此宣稱規則本身正確 |
| hero-body-warrior-impact-audit.json／native-warrior-impact.log | 108/108；actual畫面GameStore／audio，共同時序、雙兵出手後才出現、兩向／垂直換位分路、取消／非法／重複确认、AP/Mana／Undo、背景／重開／離場／中斷、Reduced Motion、語音關閉 |
| native-corrected.log／native-final-se.log | 第二AP技能後普通落子、自动換手、復原；保留Mage M3第二AP回歸 |
| native-separated-small.log | SE 320容器／9×9密集、黑方正常／白方Reduced、等比與hit、確認／復原 |
| media-warrior-impact/native-record-test.log | 12個成功對局收據、預覽／取消／Undo／Home返回、雙職近景原生操作通過 |
| native-ipad-regression.log | 縱橫旋轉、投影／預覽留存、兩職黑白成功／取消／Undo、既有真Bot mage技能／落子／提主將回歸通過；未新增或調整Bot評分 |
| release-warrior-impact.log | 新源碼Release BUILD SUCCEEDED；Simulator不是實體裝置驗收 |

初次Package測試把GameStatus.won錯寫為帶Player關聯值，按現有Core的status＋winner契約修正。初次native build未把review檔加入repo的compact PBX語法，補檔案引用後通過。初次94項audit唯一失敗為harness載入新局未清掉上一非法戰士選取；重置selected後再fresh驗證102及最後108全通過。保留原失敗logs/JSON，不因此改Core規則。

目視QA先抓到盾原位大透明孔並補衣料backing、縮頭遮罩；第一次錄影操作通過但兩棋交換中點遮擋，改分路後重新完整錄製。舊native原片保留`media-initial-crossing-overlap/`，不充作修正版成果。

## Gate 與限制

工程候選可檢查，**W1/R1角色動作、身份、黑白小尺寸辨識、節奏及正式美術由Owner判斷，未自判PASS**。32pitch的英雄canvas約28px，最小板面pitch28.52時canvas約25px，職業徽章省略；不能靠64px表宣稱最小尺寸皆清楚。密集測資有實際正交鄰兵，但不宣稱所有最壞棋形／所有方向皆無遮擋。

近景仍有細金邊／刀邊殘留、頸／披風分層輪廓；戰士抬盾右緣接近512px檢查畫布，有裁切風險，原畫是頭胸像，不是完整全身骨架，沒有偽造敲地腿部姿態。單一原畫持握方向也不等於多方向手繪動畫。既有SFX可播放；無新增英文語音、VFX或觸覺；影片無音訊，不用起播記錄代替聲畫／人耳驗收。

物理裝置：獨立 TacticalGo Heroes 1.0.0(1003)，com.tacticalgo.prototype.herobody，透過Wi-Fi安裝並啟動iPhone16Pro/iOS27.0及iPad mini6/iPadOS26.6.1，未覆寫既有正式候選。iPhone最新1003兩项UI test實際執行，0失敗，actual GameStore/audio audit108/108；實體截圖及audit JSON另留。iPad只證明安裝／啟動，UI runner認證取消，未通過動態操作驗收。

首次device harness仍指向cached M3 runner，產生0 tests＋成功退出，已拒絕當成PASS。重新綁定實際簽名bundle後1002及最新1003各實際跑2 tests；保留初始紀錄。`device-delivery-summary.json`保存型號、系統及驗收界線。手機／平板真人觀看、聲畫及完整玩法仍Pending，交付影片仍為Simulator。

公開 Release transcript僅正規化行尾空白，沒有刪除診斷；原始bytes另存release-warrior-impact.raw.log，原SHA保存在transcript首行。原生真機log含裝置識別，保留本機；公開device summary及真機audit/image不帶識別。未以缺失或0-test run充作通過。
