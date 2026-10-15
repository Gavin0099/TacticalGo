# 三職 VFX 強化：研究與採用決定

Owner 2026-10-10 看過細線／光圈候選後判定「有點弱」。舊版保留作對照，不宣稱美術通過。

|來源|實際檢查|對 TacticalGo 的用途|採用界線|
|---|---|---|---|
|[Vortex](https://github.com/twostraws/Vortex)|commit c9efc55beaf0837a8806f06615085365a3257b6d；Fireworks.swift 的 onUpdate 拖尾、onDeath 爆發、emissionLimit／damping／color ramp；Magic.swift 的壽命／縮小；MIT|蓄能、能量傳遞、命中必須有不同節奏；有限拖尾與短爆發|參考原理；沒有安裝、複製其粒子引擎或使用其圖檔；原始來源與 LICENSE 存在 research/|
|[Pow](https://github.com/EmergeTools/Pow)|commit 1b4b1dda28c50b95f0872927ee2226fe8b58950e；ParticleLayer.swift、SprayEffect.swift；LICENSE 隨來源保存|粒子放在棋盤層，不能被 Token 的局部 clipping 切掉|沿用現有棋盤兩個 Canvas 兄弟層；沒有安裝 Pow，也不採用其 UI 彈跳冒充英雄動作|
|[Apple SKEmitterNode](https://developer.apple.com/documentation/spritekit/skemitternode)|官方粒子數量、壽命及模擬控制介面|有限發射、逐生命期變色／消散與中止的原則|本輪保留 SwiftUI Canvas；沒有為三個短特效引入 SpriteKit 場景或第二套時鐘|
|既有 tacticalgo-cutout-animation Skill|原畫身份／小棋盤可讀性／成功收據／取消與中断合約|保護人物、陣營及規則；本體與 VFX 分開驗收|這不是 VFX 美術品質保證；不因套用 Skill 就宣稱特效有氣勢|

## 舊版為何弱

實際 native 棋盤 checkpoint 的主要效果是細光圈、方向箭頭、低透明光柱。它們接近戰術提示，缺少聚集→釋放→撞擊的強度變化；前景人物遮罩還裁掉部分方向線。法師 release→moveStart 只有20ms，在60Hz顯示器約一幀，原先不能靠加入漂亮 projectile 便得到可见飛行。

## 強化候選，尚待 Owner 判斷

- 地面：斷開旋轉弧、向中心聚集的光點；顏色外緣與小面積亮芯，避免木板上只看到淡線。
- 戰士：兩個落點同步竪向召喚光、同步落地；盾接觸與落點有限放射碎光／阻尼震波。不是追加兵、不是移動格點。
- 法師：真實杖尖發光與環繞光點→短能量彈／亮芯拖尾→同一兵的推動軌跡→目的地爆發。放大臉部不參與效果。
- 盜賊：兩條與既有交換路徑一致的分離速度帶→起終點短爆發。既有獨立角色動作保留；本輪不生成新人臉或假身份影像。
- 單次粒子樣本上限28、最多約0.72個pitch的局部位移；有限生命期，到期／receipt移除便沒有獨立timer殘留。
- Reduced Motion 保留240ms靜態來源／目的地提示，不播放完整爆發。

### 新的唯一時間表（秒）

法師 full：anticipation .18 → release .26 → moveStart .38 → arrival .60 → capture .70 → recover/unlock .95。
compact：.12 → .20 → .30 → .48 → .57 → .76。
只調演出，沒有新增等待或延長原總長；角色、士兵、VFX、SFX共同讀 MageTempo。成功 AP/Mana／提子／勝負仍只由 Domain 結算一次。戰士及盜賊原時間表不變。

## 非宣稱

研究不證明有氣勢；編譯、粒子數與單元測試不替代 Owner 看正常速度影片的判斷。Simulator 不是實體 iPhone。此前實體 iPad 稽核有一次尾項失敗，第二次抓取仍為同一舊檔，不作新重現；新稽核加入runID與時間以辨別新結果。語音未通過，保持關閉。未 merge／TestFlight／發布。
