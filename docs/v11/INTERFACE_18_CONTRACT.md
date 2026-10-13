# 18 — 同一1.1介面與固定棋盤

Owner退回1105：外層仍舊UI，手機棋盤大小跳動仍存在；最新13:04 screenshot為7×7 solo，深色大灰按鈕，棋盤留白很大。L1：UI/Visuals幾何；不改規則、Bot、動畫/聲音素材、存局意義。

根因：1104 compact panel只限phone9；7仍legacy panel。match height依當前hero、loot、instruction、result、mode而變；VStack未固定HUD/描述/按鈕列高度，文字和額外技能列可重新分配棋盤空間。

合約：
- 1.1大廳及對戰採既有P02暖色桌遊palette，矩形小卡按鈕，所有phone7/9共用控制區。
- 手機layout只接受viewport宽高，固定header40/HUD48/status20/controls200、間距4与外緣4；棋盤尺寸與全局中心不受職業、落子/技能/預覽、解鎖戰利、AI準備/落定/交手、勝負、Undo改變。
- 長說明/挑戰提示走既有info sheet。勝負在固定status slot；技能/方向替換同高度行，不插入新行。無第二技能/戰利也保留同高slot。
- 7和9可不同pitch但同viewport槽；7使用只裁畫外垂直留白的安全框，9沿用裁框；所有格點/人物/命中仍共享投影与fit。
- viewport自身改變可重新fit；不禁止iPad窗口/旋轉重新排版。失敗/取消/減少動態仍共用既有已確認事件，不碰Core。

驗證：獨立投影公式檢查375/390/402/414、所有7/9角落hitcell与人物；原生跨四職、各技能/方向/preview/cancel/AI/Undo/終局/prompt/loot對同一arena与cellRect比較(≤0.5pt)，并實際操作角落/按鈕與查看前後native畫面。小手機必须底部控制可觸，不用截圖代替UI坐標斷言。新1106來源/簽名/素材核對後同TestFlight Owner交付；真人視覺验收另行。
