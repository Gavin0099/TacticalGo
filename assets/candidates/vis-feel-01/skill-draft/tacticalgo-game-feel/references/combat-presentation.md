# Combat presentation comparison

先選一個已確認的技能 receipt：before、action、成功 outcome、目前 committed after 必須對應。預覽、非法操作或過期 receipt 不得播放成功聲音。演出不推論提子與勝負；只讀 outcome 的事件，完成也不再寫 Domain。

A/B 固定相同原畫、棋形、輸入和正式結果。記錄基線 commit 及是否真正上線；舊候選不能稱作現行正式版本。新版用一個時間表同步蓄勢、出手、移動、落定、提子及收勢，以單調時鐘驅動視覺與聲音。角色動作先在無特效版本可辨識，再加入不遮住相鄰交叉點、陣營與危險提示的效果；不要用大量光效補足動作。

若 Owner 指「手機原版」，先查實際安裝的 bundle／build，再對其簽署來源 manifest、原畫、棋盤、動畫 revision、音檔 hash 和完整時間表。main、舊候選或最近 commit 都不能自行替代手機基準。取得基準後保持它可重播，改良版另設選項。Owner 已退回的聲畫保留為診斷，不再當新版本預設或推薦。

SFX、語音、BGM 分層，音量與取消獨立。短技能主要由 SFX 表達結果；語音先作可關閉候選，避免每次施法重複台詞。若語音超出演出，duck 時長按實際聲音生命週期處理。既有素材可以沿用，但必須記錄真實來源；程序音調、授權音訊取樣、錄音及模型語音不可互相冒稱。

音訊保存未加工來源、孤立音層、衍生 cue、混音預覽、處理脚本、hash、授權或模型及聲音來源。記錄 sample rate、聲道、峰值、RMS、DC 與邊界樣本。數值無 clipping 只證明檔案條件，不能替代真人聽感。生成台詞和原畫仍以 Owner 接受度另行驗收。

取消、新 receipt、切版本、復原、重設、靜音、音訊中斷與背景均使旧世代排程失效，停止已排程及已開始的音效。不能只取消延遲 Task 而留下硬體排程。保留播放器到 owner 的生命週期結束，避免 AVFoundation 已排隊 finished callback 與提前釋放衝突。系統或手動 Reduced Motion 立即顯示正式盤面、角色靜止；保留聲音時間表及靜音控制。

驗證同局面雙方、敵我士兵、最後 AP、提子／無提子、非法與過期 receipt；在 native app 於出手前中斷並等待全聲音窗口，證明沒有延遲聲音且復原正常。32/48/64 與真實棋盤 pitch 檢查法杖、握持、鄰子與陣營。驗證 Debug 與 Release 的候選隔離；有改動才重跑相關項目。

交付原始 native 錄影；後混音影片另外命名，標明音訊不是裝置現場擷取。Simulator、實機操作、實機錄影及 Owner 聽感是不同證據，不互相替代。磁碟不足時只在授權範圍內清除可重建 cache，保留失敗紀錄與原始素材。

方法參考：[Blizzard VFX](https://news.blizzard.com/en-us/article/22552047/developer-insights-the-art-behind-the-science)、[Blizzard sound team](https://news.blizzard.com/en-us/article/23964694/inside-battle-net-meet-the-sound-team-behind-hearthstones-harmonic-design)。借用表達原則，不複製角色、台詞、音效或美術。

Owner 退回 PRESENT-03 的教訓：細線、小亮點、微調姿勢與幾乎不可聞的新增音層，不能當作已改變演出。先寫出玩家能描述的物理動作（例如手掌抓穩、施力、棋子受力、落定、鬆手），再為它選材質與聲音節點。特效需要清楚、簡單的物件輪廓；不能因怕遮盤而縮小至無法辨識。實際正常速度錄影必須證明主要物件露出、動作因果可讀，静態大圖與工程測試不能替代。若物件藏在棋子後只剩光尾，先改接觸位置和深度，再考慮更多粒子。提供原版 A、無聲與音層素材以隔離評估；美術／動作／聽感各自維持 Owner 品質 gate。
