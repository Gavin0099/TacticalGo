# 3D-00｜雕塑到 iOS 的風險與測量計畫

只規格，未執行任何雕塑、retopo、UV、rig、貼圖烘焙或USDZ匯出。

| 階段 | 風險 | 未來要取得的證據 |
|---|---|---|
| 人工Stylized Sculpt | 單角度投影能對齊但其他面/表情不像；程序髮塊葉片化 | Owner身份表、多視角未知處核准；原角度/側面分別評閱 |
| Retopo/表情 | 拓撲與面部deformation合理不等於角色氣質正確 | 中性/自信微笑的目標，眼瞼與眉嘴非對稱不丟失 |
| UV/手繪 | 几何修正后貼圖光影重烘焙；細線在小尺寸消失 | 大卡与64px輪廓/線條/金屬布料差別，相同光源比較 |
| Rig/裝備 | 持劍/盾握點、布料交疊、縮放與坐標差異 | 小範圍表情/裝備pose後再全身；不先加大量骨架 |
| Blender→USD | 不是每個shader節點都能完整交換；toon/Eevee表現可能需另建 | 固定版本、導出選項與材質manifest；原DCC與目標runtime同鏡頭比較 |
| iOS renderer | 輪廓、陰影、透明排序、色彩/曝光差異；金屬高光可能過強 | 真機選角/棋盤、黑白底座、密集局幀時間與記憶體、Reduced Motion |

本輪查閱的官方參考：Blender 4.2 LTS 手冊說明USD材質近似轉為Preview Surface；因此不能保證自訂toon完整保留。[Blender USD](https://docs.blender.org/manual/en/4.2/files/import_export/usd.html) 使用固定版本資料作風險依據，不宣稱本機exporter已測。

Blender Studio 的角色開發資料將頭部探索、表情、retopology、UV與pose分開呈現，適合作為審查順序參考。[Rain Character Development](https://studio.blender.org/training/stylized-character-workflow/chapter/5d3583da84e830f1f7fee8e1/) 沒有下載模型、教材或素材，不以課程角色權利推論TacticalGo權利。

Apple CustomMaterial頁本輪只取得需JavaScript提示，未成功讀到詳細API；因此不宣稱其toon能力或具體版本支援已驗證。部署版本保持專案現有設定。Runtime可使用何種NPR需未來實驗，不在這輪新增shader框架。
