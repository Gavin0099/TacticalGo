# 魔物棋盤圖樣 v01

依 tacticalgo-character-style 與 imagegen skill，用已檢視並核對 SHA-256 的 warrior-v01 作 STYLE 參考，透過 built-in image_gen 生成兩張新的簡化棋盤圖樣。延续暖棕描邊、柔和手繪 2.5D、紙感與左上光源。

| 魔物 | 原始 PNG | 完整生成 prompt |
|---|---|---|
| 史萊姆 | [slime-token-v01.png](slime-token-v01.png) | [slime.txt](prompts/slime.txt) |
| 暗影狼 | [shadow-wolf-token-v01.png](shadow-wolf-token-v01.png) | [shadow-wolf.txt](prompts/shadow-wolf.txt) |

每張原圖 1254×1254、真正透明背景，原始 bytes 完整保留；沒有重繪、裁切或補白。形狀、光源與細節為新魔物身份，不複製戰士的人物或裝備。狼採頭部與短胸輪廓，史萊姆採整個黏液身形，都是為棋盤用途直接繪製。

[32／48／64 px 檢查圖](qa/scale-review.png) 含實際尺寸、淺／深底、灰階與剪影；[數值驗證](qa/validation.json) 與 [完整來源 manifest](manifest.json) 記錄參考／prompt／file／decoded RGBA hashes、實際尺寸、透明度與個別状态。生成 model 與工具版本未提供，記為 unknown。

觀察：圓潤史萊姆與尖耳狼在 32 px 仍有不同輪廓，但狼的毛髮／表情細節縮小後減少，深底外輪廓對比較弱。Debug 棋盤的淺色底圈及中立輪廓由 UI 外加，沒有烘焙進圖樣。此觀察不是玩家一秒辨識測試；真人檢查留到下次。

approval 為待精確檔案接受，rights 待確認；candidate=true、production=false、animation=false。只用於隔離 1.1 Debug 試玩；尚未作為正式上架美術或製作動畫。

重現 QA（只產生檢查衍生圖，不修改原圖）：

```sh
NODE_PATH=/Users/pc49-58/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules /Users/pc49-58/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node assets/candidates/v11-monsters/v01/review.cjs
```

本次整合與模擬器驗證見 artifacts/v11/monster-art-v01/REPORT.md。
