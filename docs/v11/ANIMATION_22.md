# AV22 角色出力與特效材質

2026-10-13。Owner指出AV21與爐石仍有差距，要求繼續優化。這輪完成新的原創局部特效、連鎖第二次出力、奉獻釋放姿勢、短暫焦點層次與更貼近來源的分層比較工具。仍是未經原生編譯／播放驗證的候選，不能宣稱已達爐石水準。

來源分支重新fetch後仍為 `origin/codex/v11-monster-battlefield` 的004ed4c，在既有 `codex/v11-game-interface` 上迭代，沒有覆蓋其他工作樹或發布。AV21修改前的六個來源快照及hash保存在 `artifacts/animation-22/baseline`；前輪工具與證據保留。

## 本輪實作

- 原創4×2透明圖集 `game-spell-atlas-v22`：石塵接觸、青色魔法環、薄荷刀光、金色光葉、杖尖光、地面壓力環、速度絲帶、空座光環。按確認receipt的release／arrival／duration取樣，特效集中於施法者和受影響點；中心／周圍格線與角色仍可辨識。
- `SpellAccentFrame` 提供有限的蓄力與220ms接觸尾韻，接觸前impact為0，時間無效／結束／降低動態皆quiet。每職拆成独立SwiftUI視圖，避免把所有材料與計算塞進一個大型view expression。減少動態不新增粒子或新光暈。
- 連鎖換位在第一組交換後增加第二次蓄力與出手；奉獻在0.42秒有抬手、抬書釋放。原本普通換位／Sanctuary的預設姿勢保留。戰士與法師既有分層姿勢和四職落定拍點保留。
- 未受影響棋子在施法中最多降低12%不透明度，落定後180ms內恢復；施法者、來源／目的地、奉獻點與提子維持本身呈現。危險與選取仍位於特效之上，不增加鏡頭震動或規則效果。
- 新圖集1774×887，等分格邊為443.5px，以render等格取樣。水平與三條垂直邊界附近alpha最大值皆1，格內最高252至255；沒有可見跨格串色。生成原始bytes未改，完整prompt／來源／hash保存在provenance.json。

設計方法參考[爐石官方VFX文章](https://hearthstone.blizzard.com/en-us/news/22552047)中「大而直接的施法關係、職業形狀與材料、粒子支持主動作」。這是文章方法與本案設計推論，未量測競品GIF，未匯入競品素材，也沒有品質百分比分數。

## 比較工具與觀察

開 `http://127.0.0.1:8771/tools/animation-22/`，兩側皆用同一組原畫、來源裁切區域、原生keyframe表和當前七技能拍點；左側AV21來源姿勢，右側AV22姿勢及材料。source polygons與before／after keyframes由 `build-animation22.py` 擷取，Canvas重新合成頭、手、武器、書、衣服、身體，杖尖連線使用相同pivot變換。

這修正了AV21工具只旋轉整張人物的比較限制，**不能把這部分工具改善全算成原生角色改善**。原生先前已使用分層rig；本輪真正新增的角色動作為連鎖第二次出力及奉獻釋放，戰士／法師新增的是局部材質光與接觸回饋。

提供24個四職32／48／64px前後姿態樣本、正常／密集標本、對等演出細節放大、七技能正常速度連播、聲音預設關閉、取消／復原與降低動態。細節放大只是比較攝影，不是新增原生鏡頭。密集標本是可視性樣本，不是Domain合法棋局或實際玩家對局。

本輪自我視覺比較：第二次刀手蓄力可辨，奉獻留在原點的光葉和空座更有材料身份；小尺寸與密集場景下新增材質仍偏細，沒有達到爐石事件份量／人物表演／聲畫完整性的驗收。靜態圖只支持輪廓／材質，不能證明正常速度重量或舒適度。沒有獨立真人盲測。

瀏覽器重新排了前後層：地面和速度絲帶在棋子下，杖尖和奉獻光葉在前，修掉材質藏在人物後的工具差異；英雄底座也依原生0.03pitch中心／0.74pitch寬修正，避免工具造成浮空印象。Canvas仍不是SwiftUI等價renderer：投影、抗鋸齒、depth、實際字體和GPU路徑各異，這是候選比較。

## 驗證

`node scripts/review-animation22.cjs` 最終結果見 `artifacts/animation-22/browser-checks.json`：包含375／402七技能普通与密集布局、取消清排程、背景式停止、降低動態、七技能正常播放及連播、手機頁面無水平溢出；24個姿態樣本檢查與第二次蓄力方向。端點、路徑分離、非法時間和奉獻尾韻仍沿用本工具不變量。這些執行的是browser，不是Swift。

第一次本輪harness因新增第二個details讓未限定的locator匹配多個元素而失敗，已限定第一個details再重跑；失敗錄影保留failed-locator-browser.webm。前輪27項結果不與最終41項相加。初期診斷也曾使用未加引號的數字CSS selector而停止，修正為nth後重新取得圖，未計入通過結果。

`SpellAccentTests.swift` 三項新增Swift回歸：接觸峰值与收束／非法時間／降低動態、新姿勢與rest邊界、只淡化非目標且完全恢復。**NOT RUN**。Windows與WSL沒有Swift compiler，沒有Xcode／iOS SDK；基線／修改後native build、原生UI、真機聲畫、FPS與輸入恢復時間皆未驗。UI20來源、角色與clean plates byte、Core／Content／Bot／Records未變以verify-animation22.py核對；source export、資產、skill和git diff --check另存checks及validation.log。

本輪沒有更改音訊排程／音樂；原生presentationHold等待既有配音尾韻的空檔仍待原生測量，不能用browser單一視覺時長當總延遲。聲音選項僅播放既有SFX，沒有實際聽感結論。

下一個必要关卡：Mac跑完整Swift套件、Debug／Beta與UI／IntegratedAudioAudit，再以相同375／402密集棋局錄製四職七技能聲畫。確認人物腳底／裝備接縫、特效遮擋、接觸聲、結算與可操作恢復後，才繼續收斂力度与節奏。沒有commit／push／merge、版本號變更、安裝或TestFlight發布。
