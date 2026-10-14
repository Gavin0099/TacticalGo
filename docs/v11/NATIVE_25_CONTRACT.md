# Native25 原生整理與Wi-Fi iPhone候選

Owner要求整理最新版修改並安裝iPhone，指定Wi-Fi。來源06c534c/codex/v11-game-interface，保留UI20/AV21–24方向、原圖/英文B與規則。先跑269Swift/Debug/Beta/真實audio audit，再驗實際正常Beta入口。

首Beta8發現：plain說明按鈕AX/hit只有圖示12×16；圖集的大圖即使clip仍讓點擊落到相鄰技能，mode-skill實際選到advanced；舊測試還期待已撤銷的class+skill合併標題，和使用Debug-only啟動flags。

合約：圖集與特效圖像只作裝飾、不收觸控；每張技能卡hit限制於可見裁切卡框。說明按鈕44×44pt可操作，dock200pt及棋盤固定不變。回歸直接斷言選中指定技能，不只按鈕存在；進階身份以選中卡及規則命名核對。Debug audit在Debug執行，Beta用實際一般入口。不改費用/效果/AI/存局/素材/音檔，不把初輪失敗當PASS。

只建置本機1.1/1107 development候選，更新既有herobody App，先備份Documents/Preferences；不刪App、不改另一1.0checkout、不發TestFlight。核對簽名/來源/素材/安装/啟動，安裝前後存局hash。真機觀感/配音/90%品質與FPS未由工程檢查證明。
