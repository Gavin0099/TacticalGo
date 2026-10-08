# 方法來源

2026-10-08 唯讀檢查 OpenAI `openai/plugins`，固定來源 commit `0722921d5542fc593105c27bd52630babd8b8c2a`。以下只摘要相關方法，沒有複製整份指令或安裝依賴。

- [game-ui-frontend](https://github.com/openai/plugins/blob/0722921d5542fc593105c27bd52630babd8b8c2a/plugins/game-studio/skills/game-ui-frontend/SKILL.md)：保護棋盤和關鍵資訊、收起次要資訊，少量有意義的狀態動態並尊重減少動態。來源 Browser／3D 假設不作 TacticalGo 引擎要求。
- [game-playtest](https://github.com/openai/plugins/blob/0722921d5542fc593105c27bd52630babd8b8c2a/plugins/game-studio/skills/game-playtest/SKILL.md)：操作主要動詞、截取代表狀態，分別檢查介面與渲染，記錄可重現問題。這不代替真人與實機證據。
- [sprite-pipeline](https://github.com/openai/plugins/blob/0722921d5542fc593105c27bd52630babd8b8c2a/plugins/game-studio/skills/sprite-pipeline/SKILL.md)：固定 seed、比例、定位與透明背景，檢查實際遊戲尺寸。未來影格流程延後，本輪以現有 PNG 和幾何標記呈現回饋。

現有 `tacticalgo-character-style` 負責人物風格。本 Skill 處理現有素材的棋盤呈現；來源、可用性與權利狀態由素材 provenance 決定。

Owner 指定的風格參考是 [Supercell 官方《皇室戰爭》](https://supercell.com/en/games/clashroyale/) 與 [Media Center](https://supercell.com/en/media-center/)。本輪提取形體、主道具與投影方向，動畫時間為 TacticalGo 設計提案，沒有宣稱使用官方規格或逐幀量測。
