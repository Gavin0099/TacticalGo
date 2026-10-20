# TacticalGo｜五 Slice 驗收總表（Owner 版）

**文件版次**：2026-10-11。所有欄位預設 `NOT_RUN` 或 `PENDING`；不要因為交付了本工作包就改成 PASS。

## Gate Dashboard

| Slice | Baseline | 設計 | 工程 | Owner 真人／美術 | 採納／發布 |
|---|---|---|---|---|---|
| BOT-P2 | NOT_RUN | NOT_RUN | NOT_RUN | PENDING | NOT_AUTHORIZED |
| CONTENT-03 | NOT_RUN | NOT_RUN | NOT_RUN | PENDING | NOT_AUTHORIZED |
| BOSS-00 | NOT_RUN | NOT_RUN | **N/A（純設計）** | PENDING 規則決策 | NOT_AUTHORIZED |
| ANIM-01R | NOT_RUN | NOT_RUN | NOT_RUN | PENDING 影片/真機 | NOT_AUTHORIZED |
| 3D-00 | NOT_RUN | NOT_RUN | **N/A（純設計）** | PENDING 身份規格 | NOT_AUTHORIZED |

## BOT-P2 Owner Checklist

- [ ] 第 40 回合的合理防守不被錯誤「修正」成必敗落子。
- [ ] 第 55 回合或其他可信中後盤有實際更好的安全進度證據。
- [ ] Bot 的兩個 AP、技能與防守理由能從棋譜重播確認。
- [ ] 多局不再有無必要的長期停滯；若仍有，已解釋根因與限制。
- [ ] 新版沒有明顯卡頓、晚到結果污染或原版／R3 規則漂移。
- [ ] 完整試玩兩局以上；願意再戰且能描述對手計畫。

決議：`GO / REVISE / HOLD`，記錄對局來源／影片／日期：____________

## CONTENT-03 Owner Checklist

- [ ] 第一關需要考慮敵方下一回合，而不只是填最後一口氣。
- [ ] 第二關反制是合法的電腦／腳本行動，而不是作弊或強制失敗。
- [ ] 第三關有真實的 Mana／技能／兩 AP 取捨，至少有一個「不用技能更好」的合理局面。
- [ ] 三關都不看提示可理解目標；輸掉後知道哪個決策造成損失。
- [ ] 舊六關與舊存局未受影響，重試／復原／iPad 橫向都正確。
- [ ] 記錄是否願意用不同職業重玩，而不只問是否通關。

決議：`GO / REVISE / HOLD`，關卡編號／次數／理由：____________

## BOSS-00 Owner Checklist

- [ ] 明確選定是否佔點、龍息效果、預告／結算時點及方向規則。
- [ ] 主將死亡、雙方同時死亡、Ko／氣數／推棋碰撞均有規則。
- [ ] 不需要即時隨機運氣也能展示可誘導的戰術。
- [ ] 四個手算場景各有合法狀態、完整事件／回合 trace。
- [ ] 存檔／重播、模式隔離與 Bot 公平性已有設計。
- [ ] 另外核准 BOSS-01 才可開始遊戲實作。

決議：`SPEC_ACCEPTED / REVISE / HOLD`；未決問題：____________

## ANIM-01R Owner Checklist

- [ ] 來源是 B-v02 法師，不換臉或重畫成另一個角色。
- [ ] 影片能清楚看到抬手、揮杖、打擊、收勢，不只是圖片縮放。
- [ ] 推己兵／敵兵時動作、方向、棋子落定與事件一致。
- [ ] 音效類型（原生／後製）、Reduced Motion、復原與取消正確標註。
- [ ] iPhone 與 iPad 的法師、底座、黑白字牌、被推棋子不遮擋。
- [ ] 動畫表現、動作時長、身份辨識與手感有 Owner 影片／真機意見。

決議：`ACCEPT_CANDIDATE / REVISE / HOLD`，影片來源：____________

## 3D-00 Owner Checklist

- [ ] 戰士唯一身份參考與可見／推定／未定處明確，512/1254 來源無誤報。
- [ ] 同角色的髮型／眼神／衣著／披風／劍盾與盾徽不可變項確認。
- [ ] 前／3⁄4／側／背及 64／128px 讀圖規格合理。
- [ ] Blender 渲染與 iOS 實際渲染的材質／光影差異已納入計畫。
- [ ] A1 2.5D 與 B0 3D 的成本、風險、品質 Gate 有比較。
- [ ] 未製造新模型；即使接受規格，也不自動啟動 3D-01。

決議：`SPEC_ACCEPTED / REVISE / HOLD`，仍需素材／美術人力：____________

## 不應跳過的安全盤點

- [ ] 舊工作樹與現行 HEAD 已核對；任何 dirty tree 都沒有被無授權清理。
- [ ] PR #5/#6、SELL-01C 與舊 ANIM-01 沒有被錯誤合併、覆寫或丟失。
- [ ] 原版 Golden、R3 opt-in、正式存局、事件重播與 7×7／9×9 既有行為維持。
- [ ] 各 Slice 證據有 source SHA、實際命令、真機／模擬器區別。
- [ ] 五項均尚未取得「合併／正式預設／發布」的自動授權。

### Owner 決策紀錄（可複製）

```text
日期／時區：
Slice：
依據 commit / artifact / 影片：
設計結論：GO / REVISE / HOLD
工程結論：PASS / FAIL / NOT_RUN / N/A
真人／美術結論：ACCEPT / REVISE / PENDING
本次接受的驗證債務與負責人（沒有填無）：
正式採納狀態：NOT_AUTHORIZED / SEPARATELY_AUTHORIZED
下一個被授權的唯一工作：
禁止擴張的範圍：
```
