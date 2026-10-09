# AUDIO-01：原創程序合成候選

本輪提供可循環對戰音樂與 11 個短音效，供「魔法之手」完整聲畫示範使用。音訊只回應已確認的 Domain 結果；音訊模組不判定移動、提子、勝負或資源。其他職業音效先提供候選，不代表已驗收其技能演出。

## 音樂

`ios/TacticalGo/Audio/tabletop-loop.wav` 為 90 BPM、D 大調、4/4、8 小節，長 21.333333 秒。原創和聲與旋律以柔和撥弦、木質敲擊和低音量泛音墊底構成溫暖奇幻桌遊感。所有樂器皆為合成波形，不是實錄木琴、弦樂或任何外部取樣。

每拍恰好 29,400 個 sample frames，整段共 940,800 frames。延音與立體聲反射循環寫回第 1 小節，保留跨段自然尾音；首尾最大振幅差為 44 / 32767。這是訊號連續性驗證，聽感仍需 Owner 在手機與耳機上驗收。

## 素材規格

所有檔案均為 44.1 kHz、16-bit、雙聲道 PCM WAV。音樂峰值 -9.37 dBFS、RMS -22.90 dBFS；短音效保留至少 5.68 dB 單檔峰值餘裕。這是每個檔案的測量，不是多音混合後的響度或硬體音量保證。

| key / 檔名 | 秒 | 聲音身份與用途 |
| --- | ---: | --- |
| selection | 0.11 | 很輕的木質小音；只作預覽／選取回饋 |
| place | 0.24 | 木質低音加短落地衝擊；成功落子或移動落定 |
| capture | 0.48 | 下降的晶亮音與散去的氣流；已成功提子 |
| summon | 0.72 | 上行柔和鈴音，收尾有落地音；已成功召喚 |
| mage | 0.62 | 三個上行水晶泛音與短升音；魔法之手施法 |
| warrior | 0.45 | 厚實低頻衝擊與金屬泛音；築壘候選 |
| rogue | 0.35 | 左右短風切與淡晶音；換位候選 |
| danger | 0.55 | 兩個短木質提醒；進入主將一氣狀態時一次 |
| victory | 2.15 | 上行和聲與高音收尾；獲勝音樂提示 |
| defeat | 1.55 | 柔和下降撥弦；戰敗提示候選 |
| draw | 1.20 | 穩定開放和聲；和局提示 |

選取音效峰值額外降低至 -17.72 dBFS。預設 `musicVolume = 0.30`、`sfxVolume = 0.65`；實際 iPhone 音量、重疊 cue、耳機聽感需實機驗收後調整。

## 魔法之手接線

由 GameStore 持有唯一成功演出排程。以完整動畫為例：成功確認 0.00 秒播放 `mage`；士兵落定約 0.56 秒播放 `place`；若 Domain 回傳提子，約 0.62 秒播放一次 `capture`；若同一成功結果已終局，約 0.96 秒播放 `victory`。時序可依動畫調整，結果不能由動畫推斷。

- 預覽只播放 `selection`，不播放施法、落地、提子或勝負音。
- 非法操作不播放成功 cue。危險 cue 由進入一氣狀態的事件觸發，不隨每次畫面更新重播。
- 復原、重開、快速新行動、離開對局與背景切換，先取消 GameStore 的延遲 cue 排程，再呼叫 `cancelEffects()`。
- 降低動態模式以固定輪廓與淡出取代滑動、光點及縮放；使用同一份成功結果，保留同一音效時間表。

## 播放器介面與生命週期

`CombatAudio` 是 `@MainActor @Observable`，有可綁定與持久化的 `muted: Bool`、`sfxVolume: Double`、`musicVolume: Double`（範圍 0...1）。非有限音量值會收斂為 0。

```swift
audio.setMatchActive(true)       // 對局進入，包括終局短演出期間
audio.setSceneActive(true)       // 前景 active 才允許聲音
audio.play("selection")         // 立即播放；此模組不建立延遲排程
audio.play("mage")
audio.cancelEffects()            // 立即中止所有正在播放的 SFX
audio.setMatchActive(false)      // 離開：中止 SFX 並將 BGM 回到開頭
```

`setSceneActive(false)` 立即中止 SFX、暫停音樂、釋放音訊工作階段；前景重新啟用時恢復音樂，不恢復過期音效。靜音時中止 SFX 並暫停 BGM。選取音效有 80 ms 防連點間隔，SFX 同時播放上限為 8。同一 cue 重播會從頭重啟；已建立的播放器按 key 保留到 Audio owner 結束，最多 11 個，不依 `isPlaying == false` 立即釋放。錄影曾捕捉到播放完成回呼的原生崩潰，故保留完成物件，並以實際 AVAudioPlayer 壓力／取消／重播 harness 回歸。未知 key 與不允許播放的狀態會直接忽略。

採用 `AVAudioSession.Category.ambient`，尊重 iPhone 靜音開關並可和使用者其他音訊共存。系統音訊中斷會停掉 SFX，並呼叫 `onInterruption`；GameStore 應將此 callback 接至自身演出取消入口，避免中斷結束後播放先前延遲 cue。中斷結束只有系統允許恢復或重新進入前景才重啟音樂。

資源優先從 Bundle 的 `Audio` 目錄讀取，也支援 Xcode 扁平化資源路徑。解碼或工作階段啟動失敗會保留 `lastError`，不影響 Domain 行動結果。

## 來源與權利記錄

唯一生成來源為 `scripts/generate-combat-audio.py`，使用 Python 3 標準函式庫的 additive／subtractive synthesis；音高、和聲、旋律與節奏直接定義於程式，雜訊使用固定種子 101...104。沒有下載音效、取樣錄音、外部音樂旋律、第三方素材或生成服務。

`ios/TacticalGo/Audio/manifest.json` 保存 generator 的 SHA-256、每個 WAV 的 SHA-256、合成方法、固定種子、格式、長度、峰值、RMS 與循環資料。外部取樣授權標記為不適用；正式發布的權利與聽感核可狀態仍是 **prototype only / pending Owner review**。這份來源記錄不替代 Owner 的正式權利確認，也不代表這批音訊已可發布。

## 驗證與限制

```sh
python3 scripts/generate-combat-audio.py
python3 scripts/generate-combat-audio.py --check
xcrun swiftc -typecheck -swift-version 6 -target arm64-apple-ios17.0-simulator \
  -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" ios/TacticalGo/CombatAudio.swift
```

`--check` 在不寫檔的模式重新合成並比對全部 WAV 和 manifest。另從編碼後的 WAV 解讀標頭與 PCM，驗證取樣率、雙聲道、16-bit、frame count、非靜音、單檔峰值餘裕、DC offset、首尾無點擊的端點條件。PCM 驗證不證明音樂好聽、手機實際播放、系統中斷行為或混音聽感；這些由整合測試與 Owner 手機驗收補足。
