# P29-A：保留聲音身份，建立施放層次

窗口沿用AUTONOMOUS_27_PLAN，到台北09:54才Owner驗收／手機更新。起點已接受1108音檔與配音；不生成新台詞、改pitch或time、不换素材／音樂，不改Domain、AI、動畫時間、取消生命週期。

先保存實際正常DEBUG成功receipt的聲音key、device-clock排程延遲與gain（包含實際AVAudioPlayer volume），不是只從Python重造排程。四職與兩怪／戰利，語音開／關的有意義分支，scene固定合法開局，沒有成功preview音；音樂源与现有duck／分層参数另記。每段同原始素材与时间，提供無BGM及固定normal／danger BGM的離線A/B，清楚區分離線重建和實際手機輸出。

候選假設：保留命中與已選英文B語音主音量，降低次要蓄勢與小幅降低移動層，使出手／命中能辨識。語音開時英雄蓄勢0.20、移動0.26、命中0.30（舊三者0.30）；關語音時0.42／0.58／0.65（舊三者0.65）。戰士同時金屬／木質命中两层均保留原gain，連鎖第一命中仍終擊的0.60；capture與terminal原gain不變。怪物蓄勢0.48／移動0.58／命中0.65（舊0.65）。不把降低次要聲音冒稱實測聽感更好。

先核對原始來源／manifest／SHA，若素材实际与紀錄不符則停該材質改動、保留Owner基線，其他可獨立工作继续。沿用Kenney／rubberduck／CaveboyTup既有素材，作者頁於2026-10-13重查CC0聲明，wolf是作者由CC0馬噴氣加工的奇幻狼，不能冒稱真狼錄音。既有模型／配音來源記錄保留，未取得全作品最終發行權利驗收不宣稱已取得。

離線以相同波形、voice與BGM phase比較；每對先量Integrated LUFS，對齊到兩者較低的響度，避免比較因較大聲偏向候選。記樣本峰值、true peak、疊音、speech/SFX能量；不以LUFS、波形或耳機以外的播放數據替代台詞自然度、重量、疲勞與手機喇叭驗收。mono短片量測方法与限制明記。

聚焦profile與獨立參考表測試，真正AVAudioPlayer／voice tail／下一手／mute／離場／背景／取消／BGM duck的既有49項原生審核重新執行，增加必要的實際gain斷言而非mock。Muted不播成功音、preview不排程、動作無voice也有主接觸、skill/SFX開關不能關掉BGM或遺留舊 cue。輸入解鎖仍由原時間窗，混音不能延長動畫或阻塞下一手。

來源頁：[Kenney RPG](https://kenney.nl/assets/rpg-audio)、[Kenney Impact](https://kenney.nl/assets/impact-sounds)、[rubberduck slime](https://opengameart.org/content/40-cc0-water-splash-slime-sfx)、[CaveboyTup wolf](https://opengameart.org/content/wolf-monster-sound)。這些只是已讀作者聲明及現用來源核對，不是新採購或全作品法律審查。
