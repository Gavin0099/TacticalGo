> 2026-10-10 Owner 最新回饋：三職細線／光圈 VFX「有點弱」，視覺不通過。依據 Vortex 有限多段粒子及 Pow 分層研究，製作更清楚的蓄能／方向傳遞／局部撞擊強化候選；不增加音樂、語音、規則或第二技能。唯一法師演出時間表調整，但總長仍950/760ms。研究及驗證：artifacts/ios/vfx-three-classes-01/research/DECISION.md；Native/Owner Gate 分開回報。

# 三職技能VFX整合候選
Owner最新授權開始戰士／法師／盜賊VFX，取代先前「本體三者確認前不開VFX」的製作限制；本體／正式美術／語音Pending不自動通過。語音關閉。

L1：presentation-only，純Swift成功事件描述＋原生SwiftUI向量VFX，無新外部素材／規則／Bot評分／資源／UI流程／角色身份改動。沿用60ffa99及現有共享body／SFX時間表，不按建議時間硬改。

1. 戰士：暖金蓄勢、盾擊短地面震波、兩落點同步標記／落定碎光。
2. 法師：實際杖尖蓄能／底座短符文、定向能量、受術來源／目的地／落定衝擊。
3. 盜賊：靛紫目標高亮、雙向短殘影路徑、各自落點；身份與兩條現有移動軌跡可追蹤。

成功receipt才有VFXPlan。預覽輕量提示；取消／Undo／重開／背景／Bot換手清除過期receipt；Reduced即時正確結果＋短靜態方向／落點提示，不大震波或粒子。

驗證：三職黑白7／9、無／有真正提子、密集相鄰盤面、錯誤目標／預覽／取消／復原／重複確認／2AP／背景／Reduced／Bot同receipt；Swift／Golden／native UI／Release。三套完整棋盤正常速度原生Simulator錄影；實機另外明列，不將渲染圖／測試當人類美術通過。

隔離codex/vfx-three-classes-01必要commit/push沿用授權，完成後停供Owner看片；不merge／TestFlight／發布／第二技能／配音／新建模。
