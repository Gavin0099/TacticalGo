# 魔物圖樣 v02 視覺預覽

這版保留新史萊姆的彎曲頂部、薄荷色與笑臉，移除外側水滴並减少細碎高光；暗影狼直接使用 Owner 提供的新版原檔。

- `qa/board-preview.png`：9×9 明暗棋盤示意，怪物原生 32 px，格距 38 px，外加中立底圈；非 App 截圖或合法對局證據。
- `qa/scale-review.png`：原始史萊姆／簡化史萊姆／新版暗影狼，32／48／64 px 明暗、灰階與剪影。
- `slime-token-v02.png`：單次內建 image_gen 編修的 1254×1254 RGBA 候選。
- `shadow-wolf-preview-v02.png`：Owner 新版暗影狼原檔的完整位元組副本，未重畫。
- `sources/`：兩張 Owner 原圖完整保存；`prompts/slime-simplified.txt` 保存完整編修提示。
- `manifest.json`：來源、完整檔案與 RGBA hash、權利／批准／可用性各自記錄。

目視：新版史萊姆縮小後輪廓較整潔，彎曲頂部仍清楚；狼的尖耳可辨識，但 32 px 細毛色與臉部細節合併。提示要求兩塊高光，實際留下三塊主要高光；本次保留作比較。所有來源與輸出有透明 alpha 且未截邊。沒有真人辨識測試，沒有修改現有 App 圖樣或遊戲規則。

重建 QA：用有 sharp 的 Node 執行 `review.cjs` 再執行 `board-preview.cjs`。原始圖樣保持不變。正式採用與商業權利接受尚未記錄。

## 後續測試版接線（2026-10-11）

Owner 另行授權載入測試版：本目錄兩張候選已被獨立 Debug MonsterLab 引用，正式 Release 排除。原始預覽 manifest／報告描述建立時狀態；後續接線證據見 artifacts/v11/monster-art-v02-integration/。雙怪畫面與操作檢查待 Mac 解鎖，尚未正式批准或發布。
