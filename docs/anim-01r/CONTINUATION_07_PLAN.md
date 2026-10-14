# ANIM-01R｜補充工程驗證計畫

本輪僅補測試與證據，不改 production 動畫、規則、聲音偏好或手機1016排版；不提交、上傳、安裝或發布。原始合約與既有編號證據保持。

- AM1-04：既有 `Anim01Fixture.state(capture:true)` 的對方主將在(3,2)只有(4,2)一氣；己兵從(4,3)推至(4,2)必須產生真實提主將與勝利。黑／白、正常／Reduced Motion共4案例。檢查預覽尚未獲勝、2→1AP、勝者、undo；保留真實GameStore收據、順序、影片與原生截圖。
- AM1-07：SE375、iPhone390、iPad mini三台iOS18 Simulator，各測7／9路×黑／白施法者×正常／Reduced Motion×直向／裝置轉橫16案例。7路用既有無提子fixture，9路用既有denseState，不改Domain製造特例。每列檢查棋盤／控制項在viewport中、獨立投影選點、預覽／取消、确认、2→1AP、回穩解鎖、undo，附完整截圖與實際尺寸資料。
- 手機產品設定只支援直向，所以手機轉橫的16列是直向穩定性；支援的render為手機直向16列＋iPad直橫16列，不能稱為48種直橫畫面。未取得手機橫向產品授權，不用測試override偽造支援。
- XCTest方法数、内部案例数、截圖数与收据数分开報告。原生截图和幾何只提供Owner讀圖材料，不自動通過身份、字牌辨識、演技與目標可信Gate。
- 既有語音保持關閉，不增配音或改音樂。Simulator原生無聲錄影不能證明系統收音、人耳聽感、聲畫同步或真機觸控／效能。

風險：新增測試可能暴露未支持方向或裝置佈局；若有production缺陷，先保留失敗與報告，再由root決定修正範圍。測試本身回退只刪除本輪新增mage方法，舊影片／素材／測試不變。原生build與test按序執行避免build.db競爭。

## 補測中實際揭露的問題

`win-10` 的4個終態／復原案例及完整收據檢查通過，但原生無聲錄影揭露勝利banner、結束標題及終局訊息早於士兵落定／提主將。因此**不把原生終態PASS寫成AM1-04完整PASS**。原始影片15.0s及16.0s影格、逐格檢視表和visual-finding.json保留。Root另行負責最小presentation修正；本agent不修改production renderer/GameStore/Core。

後續同fixture錄影使用既有 `--vfx-record-marker`：小8pt標記依真實AP由cyan變magenta，只用來定位已編碼影片中的提交，不改棋局／時計。正常播放的單次accessibility snapshot若看到「行動演出中」，同snapshot不得有終局banner/文字；若XCTest已等待至完成，明列未觀察中段，以原生影片補證，不用固定sleep捏造穩定測試。Reduced Motion允許立即完整終態。
