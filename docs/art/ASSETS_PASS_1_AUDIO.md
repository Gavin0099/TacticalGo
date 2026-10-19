# Assets pass 1 — 音效、事件與誠實邊界

選擇用 ffmpeg 量測波形、頻譜和 EBU R128，沒有進行真人或代理主觀試聽。這符合先聽「或」量測的檢查路徑，但量測不等於音色好聽。未把任何一個項目稱作「聽不出差別」：未聽驗並不等於沒有差別。

## 原音效缺點及設計修正

| 事件/原檔 | 基線問題與依據 | 本輪做法與判定 |
|---|---|---|
| 放置 place | 0.24s短衰減；與capture平均響度接近，但材質尾音短 | 原創125Hz木/石共振、短材質噪聲、19/43/79ms早反射，0.48s；改善（包絡/材質層次設計），聽感未檢查 |
| 提子 capture | 單一短噪聲與接觸帶重疊，無長收束 | 多段不等頻率碎裂、三次小碎片尾音，0.70s；改善（與place波形不同），聽感未檢查 |
| 選取 selection | −27LUFS遠低於其他短事件，但作輕提示合理 | 保留−27LUFS，小泛音與柔短尾；持平，音色差異未聽驗 |
| 確認 confirm | 整合版沒有獨立確認音，成功行動只播放施法/落定 | 新增0.32s短雙音，成功confirm後才播放；新增事件，聽感未檢查 |
| 召喚 summon | 有原檔，但整合版placeSoldier/summonHero共用place路由 | 0.98s上升和音及短早反射；Beta/DEBUG將召喚接到既有summon鍵；改善（事件區隔），聽感未檢查 |
| 戰士 warrior/w7-* | brace/land約−25LUFS，strike約−18.8；同職分段差6.8LU | 低頻木/鋼共振、非整倍泛音與厚接觸；同組校準−23LUFS；改善（響度一致性），重量感未聽驗 |
| 法師 mage/p5-* | 舊施法/接觸多集中低中頻；mage與warrior主鍵平均響度接近 | 青晶高泛音、聚氣與推動分段、接觸短晶響；同組−23LUFS；改善（頻譜/包絡區隔），亮度聽感未檢查 |
| 盜賊 rogue/p8-rogue-* | land比coil/dash低約2.7LU，動作頻段重疊 | 快速布擦、短斬風、皮革落定，0.42–0.48s；同組−23LUFS；改善（響度），速度聽感未檢查 |
| 牧師 p8-priest-* | bless到land約3.9LU；落定過弱 | 書頁/柔鐘/慢起音共振，0.70–0.95s；同組−23LUFS；改善（響度/起音），柔和聽感未檢查 |
| 提走主將 commander-capture | 普通提子共用capture，終局另加勝負音，無專用材質 | 新1.08s低頻破裂加收束，依已確認receipt捕獲kind為commander才選用；新增事件，聽感未檢查 |
| 勝/敗/和 victory/defeat/draw | 舊勝2.15s、敗1.55s超過短音效上限；和1.20s；三者約差2.5LU | 上行大和聲/下行小和聲/中性往返，1.10–1.18s、同組−22LUFS；改善（規格與區隔），音樂收束聽感未檢查 |
| danger | 舊約−11.2LUFS，比selection高約16LU | 兩拍低警示校準−23LUFS；警示效果未檢查，需真人確認不過弱 |
| B音樂層/終局樂句/tabletop-loop | 本輪沒有建立「太乾」或循環爆音的聽感證據 | 位元保持相同，首尾PCM跳變另量測；持平，沒有宣稱聽過循環 |
| 其他舊Presentation/怪物SFX | 為完整盤點一併量測，未改來源或接線 | 持平（位元相同），詳細各檔在量測表；不宣稱已改善 |

「早反射」是三個短延遲原始波形相加，沒有第三方混響、取樣或模型。固定種子、每鍵音型和產生腳本完整保留。所有短音效先做soft saturation再整體增益校準，不靠削波變響。

## 證據與使用方式

逐檔before/after響度、峰值、時長、判定和波形：[comparison.md](../../artifacts/assets-pass-1/audio/comparison.md)。每個changed cue的上下波形位於 `audio/comparisons/`，上下同縱軸、同時間軸，取每對較長時長作橫軸範圍，刻度以秒標示。獨立ffmpeg測量結果：[limits-summary.json](../../artifacts/assets-pass-1/audio/limits-summary.json)。

生成：`python3 scripts/build-assets-pass-1-audio.py`（標準庫加ffmpeg）；量測及報圖需Pillow/numpy，執行 `scripts/audit-assets-pass-1-audio.py before`、`after` 與 `scripts/report-assets-pass-1-audio.py`。原始輸入仍在原路徑，候選全部在 `ios/TacticalGo/Audio/V30/`，manifest延用schema1/key/file/sha256/frame/duration/rate/channel/bits/peak/rms/boundary/loop結構，另加響度分組與音型。

僅在ArtV2.enabled且Beta/DEBUG時優先載入Audio/V30，同鍵名回退原路徑；`--art-v1`仍載入原音效。CombatAudio僅更換URL解析，11個既有effect鍵、播放/快取/音量/靜音/背景/中斷/音樂路由保持既有流程。新增confirm/commander-capture由PresentationSamples載入，不新增CombatAudio快取鍵。原檔一律不覆寫，Release建置移除Audio/V30；英文語音、3D資源的Release排除維持。

沒有新增模型或取樣服務、沒有下載素材，rights.third_party_inputs為空。既有英文語音及授權狀態不改，不列入本輪新音效來源；正式發布的權利及聽感接受仍待Owner。沒有量測多事件和語音疊加後的真實總線LUFS或實機揚聲器；保留既有各事件stage gain，檔案同組≤2LU不等於實際疊加場景同響度。

## 缺檔回退與失敗 fixture

初版新增selection/summon播放器只在版本目錄存在時成功；缺少候選檔時，PresentationSamples以PresentationLab作預設來源，但這兩個既有WAV其實位於Audio。修正共享解析器：候選→指定舊目錄→Audio→舊flat-root，保留鍵名。以臨時Bundle實際放入原selection/summon WAV、刻意不建立V30或PresentationLab，驗證回退URL與AVAudioPlayer可讀時長；完全不存在的cue必須回傳nil。這是實際檔案pass/fail fixture，不是mock播放計數。

最終程式原生稽核：v30為64/64、`--art-v1`為55/55；另有音量22/22與節奏54/54的原生結果，完整UI測試再涵蓋其最終程式。初版60/52結果及一輪為補此回退而人工中止的C測試不計入最終乾淨UI通過數；原始log保留。

短勝/敗音縮至上限內，終局等待仍使用既有ExpansionPlaybackWindow，會跟隨新音效尾長；未宣稱終局等待毫秒數與舊版完全相同。非終局技能視覺時長及操作識別碼未改，成功/失敗盤面與undo由原生audit比較。終局B音樂六秒樂句保留。

既有debug的cues/lastSoundKeys統計範圍仍是已確認行動的排程時間線；新增的即時selection/confirm不併入該舊計數。這兩個事件改以實際AVAudioPlayer是否播放、音量歸零/背景取消及失敗確認狀態不變作驗證，不用舊cue總數冒充已檢查新事件。


## 非法預覽選取音回歸

完整UI曾在testIllegalPreviewSilentCancellationMuteReducedAndBackground失敗：非法四點預覽後的audit顯示players=1，原斷言要求保持players=0。原因是新增selection在檢查結果以前無條件排程。修正只讓既有legalTargets集合中的點播放輕選取音；沒有更改合法性判定、規則、Bot或原測試斷言。原生64項同時驗證合法選取有聲與非法選取無聲；聚焦UI回歸1/1通過，結果C-selection-regression-summary.json。含此失敗而中止的C-UI-final-tests.log保留；最終完整輪次另記C-UI-complete-tests.log，不將前輪當作全過。

最終完整UI **66/66 passed，0 failed，0 skipped**，含原要求62及4項原生音訊/音量/節奏/滑桿UI。完整結果C-test-summary.json；UI執行後取出的原生結果在native-audio/ui-final。Debug（C-Debug-complete.log）、Release與Beta指定1118配置（C-Release-complete.log/C-Beta-complete.log）皆成功。
