# P29-A：英文B保留，次要音層降低

窗口ACTIVE至台北2026-10-14 09:54:08；手機仍1108，不提前安裝／發布。Owner既有Mage D／Mage English B／Warrior English B、原畫與規則保留。

## 實際改動與候選假設

現有聲音已包含真實布料／金屬／木質／濕黏與作者加工的奇幻狼素材，不重新合成更大聲的音調。本輪只改ExpansionCueMix的施放角色gain：有語音時英雄蓄勢.20、移動.26、命中.30，無語音時.42／.58／.65；怪物.48／.58／.65。命中、戰士同時金屬與木質兩層、連鎖第一接觸為最後.60、capture／terminal／語音.85均保持1108參考。

假設是較弱的次要蓄勢聲能让主接觸集中；尚未實際聽感驗收，不把信號比改善或源相同當作更好聽的證明。英文台詞、timbre、素材檔案、pitch／time、動畫與排程時間、輸入解鎖、BGM source／duck、Core／AI均不改。

新增DEBUG正常confirm的cue排程記錄與AVAudioPlayer實際volume getter，capture script從合法開局輪流啟動，不寫Owner偏好。完整15個基線與15個候選实际App施放包含四職普通／第二招、兩怪討伐／戰利與四個語音關閉分支；52個cue的play(atTime)接受計數、Float player volume與計画gain相符。這是實際API執行／音量，不是實際輸出錄音。

## 可聽比較／數值限制

artifacts/v11/polish-29a/LISTEN.md連到30對3秒試聽：十個代表聲音分支各含無BGM、normal一層、danger三層。來源是实际native schedule和同一WAV，離線mono44.1k float疊加，再用整段線性gain匹配LUFS、轉PCM16；原聲源與runtime語音gain不變。背景固定phase8s、music .30，英雄duck沿既有.12秒降到-5dB、hold到audioEnd、.75秒恢復。這是固定normal／danger參考，並非真實Core配樂轉場重建。

ab-converged/MANIFEST記錄所有原始／匹配檔案、來源SHA、原生52gain對照、量測與匹配迭代。30對最終LUFS差最大0.03，true peak最高-3.0dBTP；60個原始float混音樣本超出滿刻度為0，最高樣本峰值-1.69dBFS。這些無提子／終局fixture不能證明所有合法疊音或真機輸出都不削波。

沒有配樂的四個voiced案例，活躍speech樣本對SFX能量比候選約增加0.39–1.23dB；這不是語音辨識率、演技自然度、手機重量感或疲勞度的測量。整段LUFS匹配也會改試聽中整體語音音量，不能冒稱每個試聽的語音絕對振幅完全相同；runtime乾聲與.85仍不改。代理沒有實際聽這些檔案，Owner後續聽感／實機AV同步／喇叭驗收保持開放。

## 工程與失敗

完整Motion78/0，包括两個新profile測試：命中維持已接受native參考／次要音層低於主接觸、gain有界。NativeAudio的1個UI runner PASS0skip，JSON中的49個真实AVAudioPlayer／music檢查全部通過：載入、取消不復播、原位背景／中斷／回復、配樂同步與duck、新版Mage B／Undo、連鎖兩獨立contact、.70解鎖後語音尾音及普通下一手、終局路由／取消等。52gain斷言另由實際native排程／獨立合約參考表執行，不把它稱為52個UI test。

離線首次renderer因ffmpeg在loudnorm JSON後附muxer文字而解析失敗；用raw_decode讀完整JSON物件，沒有改量測數。第二次直接用估計線性gain時，短片在PCM／loudness gate轉換後實際差0.18LU超出門檻，驗證阻擋完成。改成每次量測實際輸出、只向下衰減最多四輪直到≤0.10LU並保持峰值頭空間；最終最大0.03LU。ab與ab-fixed不完整檔／日志保留，只ab-converged為可比較交付。兩次離線失敗不是runtime遊戲或音檔來源失敗。

SOURCE_PIN272含runtime／原素材／tests／project／錄影、排程及混音script，BASELINE_ASSETS、來源查核與canonical記錄保存。未報本輪完整Swift／Beta／真機建置或已達爐石品質。

## 來源核對與下一輪

现有素材來源archive SHA逐項吻合；runtime WAV與1108全部同雜湊。2026-10-13重讀作者頁：[Kenney RPG Audio](https://kenney.nl/assets/rpg-audio)、[Impact Sounds](https://kenney.nl/assets/impact-sounds)、[rubberduck slime](https://opengameart.org/content/40-cc0-water-splash-slime-sfx)、[CaveboyTup wolf](https://opengameart.org/content/wolf-monster-sound)均標CC0。狼作者說明由CC0馬噴氣加工，不冒稱真狼錄音。沒有新下載／採購／新配音，現有模型／聲源來源記錄保留，未作全作品最終發行權利驗收。

检查實際聲音sheet發現1.1 IntegratedExpansionSoundSettings只有mute、英文voice on/off、Reduced Motion和BGM volume；SFX slider屬舊CombatSoundSettings，不能把未提供的1.1滑桿說成「已顯示但失效」。下一轮P29B補獨立音效／配音音量控制與偏好持續性，預設聲音不變，驗證零音量、連續調整、正在施法與語音尾音取消／不復播、Mute／BGM獨立，保持固定棋盤与既有Store生命週期。不得為此改費用／規則／Bot或提前手機更新。
