# VO-PERF-01｜兩句英文表演試聽

結果：戰士／法師各兩個離線乾聲候選已生成，未替換遊戲內語音。
原因：改用接受自然語言聲線／表演指示的 VoiceDesign，直接生成不同重音和節奏；沒有對舊朗讀加音高、混響或音效。
下一步：Owner 試聽 A／B；表演與聲線先通過，再進兩句原生接線，尚不擴充六句。

隔離分支 codex/hero-voice-performance-01，自 c5cde5d 工程候選延續。現版六句 Piper 的表演 FAIL 仍有效；本輪是新的聽感候選，不撤銷舊審查，也不宣稱真人表演品質已達標。沒有修改 Swift/Core/Domain/Bot/玩法／角色圖片／動畫或 BGM，也沒有安裝新 Skill。原 App 仍使用原素材與可獨立關閉的 Voice。

## 聽什麼

| 角色／台詞 | A | B | 新版時長 |
|---|---|---|---|
| 戰士 Hold the line! | 堅定指揮，HOLD 起勢、LINE 落穩 | 短促號召，充滿決心 | A 1.04 秒／B 0.80 秒 |
| 法師 Off you go! | 帶笑、輕巧送走 | 俏皮、像彈開魔法 | A2 1.119 秒／B 1.36 秒 |

以上是指導意圖，實際是否聽得出仍待 Owner；A／B 自由設計聲線亦須選定後檢查未來同職台詞的一致性。本輪沒做 voice cloning，更沒有演員／遊戲配音參考。

warrior-old-A-B.mp3 與 mage-old-A-B3.mp3 每段順序：**舊版 → 新版 A → 新版 B**，中間 0.8 秒靜音；只調整線性增益，約匹配到 −20 dBFS RMS，peak 限 −3 dBFS。這是音量近似一致的比較，不是正式 LUFS 聽感等響保證。

四個乾聲 MP3/WAV 也個別保留，沒有 BGM、音效、混響、變調或時間拉伸。原先法師 B 的獨立 ASR 讀出額外「Ha」，B2 讀出「Ah, you go!」；兩者先 HOLD 而非直接判定人耳必然聽錯。保存 first-listen 比較段，精簡成正向短表演指示、沿用成功 A2 的種子後重錄 B3，四個最後候選都辨識為指定台詞。沒有剪掉開頭冒充重錄。法師 A 檔案名為 mage-A2-dry：初次 A 達 160 token 上限，長 12.8 秒，排除而非硬剪成短句；精簡指示、固定新的種子後重產 A2。原始失敗音檔、first-pass manifest 和程式快照保留，只供研究，不列入可選試聽。

## 工程檢查與證據

selected-manifest.json 是目前四個試聽候選的來源／SHA／指示／處理紀錄；manifest.json 是第一次生成歷史（含被拒絕的 A），retry-mage-A/manifest.json 是 A2 的完整來源；retry-mage-B3/manifest.json 是最後 B3。先前 B／B2 只作歷史，不列入最後選擇。

- PCM-CHECK.json：4 個候選 SHA、24kHz mono PCM、0 clipped samples、0.8–1.36 秒，乾聲數值檢查通過。波形／粗略音高範圍僅為描述，不能證明角色身份或情緒成立。
- ASR-CHECK.json：4/4 指定字詞一致，Whisper tiny.en 在本機獨立辨識；不把預期台詞提供給辨識器做提示。辨識仍可能誤聽，不代替人耳可懂度或表演驗收。
- 新 WAV 不接入 App，因此本輪沒有重跑 Swift/Golden/UI。先前156tests/38fixtures只代表先前的規則與接線版本，不作本輪聲音品質證據。
- source/runtime-freeze.txt、source/generator-first-pass.py 與 scripts/generate-hero-voice-performance-pilot.py／review-hero-voice-performance-pilot.py 保留生成與檔案檢查方式。保留 seed，不宣稱另進程／跨平台 bit-identical。

## 來源

Qwen3-TTS-12Hz-1.7B-VoiceDesign 原模型與 MLX 4bit 轉換均宣告 Apache-2.0，model revision 5c390979e4b93af5f2932f90742ca99c7dd04687。mlx-audio0.5.8/MLX0.32.3 在 Apple Silicon 本機推理；HF_HUB_OFFLINE=1，只有先下載公開權重，沒有外送原畫／音訊或使用付費 API。模型/runtime 不放進 iOS 或 Git。官方的指示控制能力不等於本輪表演成功。[官方說明](https://github.com/QwenLM/Qwen3-TTS)／[MLX模型卡](https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit)。完整歸屬、保留條款與發布界線見 CREDITS.md。

## Gate

兩句表演：Owner Pending。原生接線／真機聽感：本輪尚未開始。六句完整聲線、正式配音／商用權利核准：未完成。正式 BGM：HOLD。未 merge／發布。下一步依 Owner 選擇再進原生試聽，不因模型換新、字詞辨識或 PCM 全綠自動採納。

來源程式快照與4個最後WAV SHA核對通過，7次生成中保留3個失敗／HOLD研究版本；不無限制繼續取樣。開發環境略過MLX Whisper宣告但此file/waveform路徑未用的Torch依賴；pip resolver警告原樣保留，不宣稱完整環境pip-check通過。生成器的泛型transformers config警告亦保留；能生成／辨識不等於人物表演驗收。
