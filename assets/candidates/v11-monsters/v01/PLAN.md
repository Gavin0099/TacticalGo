# 魔物圖樣 v01

Owner 要求怪物圖樣依 tacticalgo-character-style skill 繪製。本批僅史萊姆、暗影狼兩張簡化棋盤 token；使用 imagegen built-in，固定已檢視且 SHA-256 相符的 warrior STYLE 參考。遵循 VIS-FEEL-01 的棋盤辨識優先，沒有新增英雄、人物卡或動畫。

史萊姆：圓潤黏液整體剪影、薄荷／青綠、友善大眼。暗影狼：尖耳／狼吻、大頭短胸、靛藍與淺色吻部；不使用恐怖／發光粒子。暖棕輪廓、簡化大色塊、柔和手繪 2.5D、左上光源，真正透明背景、無地面／陰影／烘焙底座。

保存完整 prompt、原始 PNG、reference/file/decoded RGBA SHA-256、尺寸及生成工具未知 metadata；32/48/64 px、淺／深底、灰階／剪影檢視。只在隔離 1.1 Debug Lab 顯示候選，不修改核心規則、既有正式英雄素材或 1.0 上架工作。

approval=pending_exact_file_acceptance；availability candidate=true, production=false, animation=false；rights=pending；qa 依實際結果記錄。真人辨識留待下次；不要求 Owner 現在試玩，不提前宣稱正式素材核准。

## 整合與驗證合約

- 原圖從候選目錄直接作為兩個 Debug bundle PNG resources，不覆蓋既有英雄，也不進正式 Asset Catalog；Release 用 EXCLUDED_SOURCE_FILE_NAMES 排除這兩檔並檢查实际 build app 的缺席。
- Lab 使用同一格點／點擊／預覽資料，將「史／狼」字牌替換成透明圖；淺色底圈及中立輪廓由 UI 外加，無烘焙陣營。保留完整原有 accessibility 名称。
- 檢查原圖透明邊界、RGBA hash、實際 32/48/64px；Debug／Release build 與兩項既有雙怪 UI 操作，截圖涵蓋雙怪在場、一隻移除及能力預覽。Core hash 與上一片證據一致，這次不重跑未修改的規則測試。
- 生成工具沒有回傳 model 或版本，記 unknown；所有 artwork 原樣保存。候選／approval／rights／qa 狀態分別記錄。

初輪操作通過但圖片空白，截圖驗收攔下；改為 UIImage 明確載入 PNG 及固定格點 frame，補實際資源解碼檢查、缺失提示並重跑。原始美術不變，沒有追加生成。
