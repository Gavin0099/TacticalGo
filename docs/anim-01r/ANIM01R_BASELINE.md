# ANIM-01R｜實際動畫基線

基底是實際 1014 的 M3＋既有 VFX，不是遠端 main 或最早的单張動畫卡。歷史 `artifacts/ios/anim-mage-body-01` 與 `anim-mage-m3` 保留；舊 26.25 秒影片有後製聲，不當系統收音或本輪結果。

B-mage-v02 512 PNG SHA `6980751a325e51156e56f14b38171a435bd54f4ef7d509433e94d6e3b9061a33`；clean plate 1254 SHA `9a633d497e0ce5baaa1f726312d87b49507df65b1c997c84374fa2f612be294d`。原圖與補圖位元不改。

MageBodyView 已有 torso/head/cape/held 群組。持杖手與晶杖共用肩肘及握點轉換，不是整張 Token 旋轉。Source512 shoulder(205,370)、elbow(174,436)、torso(263,445)、staff-tip(64,180)、ground448；薄底座與外側陣營提示保留。

原畫是固定 3/4 方向，不具備 360 度轉身。成功 action/receipt 提供施法者與目標，方向 VFX 按實際 target 顯示；肢體仍在固定 portrait 平面，不能聲稱任意方向的解剖轉身已成立。不得鏡像偷換臉或握手。此項保留 Owner 視覺 Gate。

## 當前共享時間表

| cue | Full | Compact |
|---|---:|---:|
| 蓄勢到位 | 180ms | 120ms |
| 揮杖 | 260ms | 200ms |
| 士兵開始移動 | 380ms | 300ms |
| 到位 | 600ms | 480ms |
| 有事件才提子 | 700ms | 570ms |
| 收勢／解鎖 | 950ms | 760ms |
| 登場完成 | 720ms | 600ms |

數值來自現在的 MageTiming；歷史 M3 報告的舊時計不拿來宣稱同步。本輪不拉長時間、不改 SFX 或 BGM。R3 遠距調度不套原版一格推動，維持既有 fallback；Reduced Motion 直接呈現正確終態和必要聲音。
