# v11 現行定位優先

2026-10-13 Owner 指定 `codex/v11-monster-battlefield`；檢查時最新 HEAD 為 `004ed4c`。每輪重查 remote，不把日期快照當永久最新。下面舊 main / AV-STYLE 記錄僅供歷史比較。

- 正常 solo / 雙人：PlayableGameView → GameStore.expansion → ExpansionLabStore → ExpansionBoard。四職、第二技能、魔物／戰利走同一路；舊 1.0 存局仍有 legacy 路徑。
- 原畫：P02 棋盤、三職棋子；P08 牧師；選角使用 asset catalog 三職 portrait 和 P08 牧師。逐用途讀來源，不憑相近檔名交換。
- GameInterface.swift 是本輪共用 UI 元件；色彩、材料、技能卡、資源寶石、按鈕狀態都從此處修改。PhoneMatchLayout 的 200pt 操作區不隨技能、方向、戰利、勝負改高。
- 動畫／音效現行入口為 ExpansionPresentation、ExpansionSpellEffects 與 ExpansionLabStore.schedule。不要從舊 CombatFeedbackPlan 推論 v11 實際聲畫。
- AV21來源候選已分開Offering與Sanctuary、以玩家視角選擇終局cue，讓endTurn走同一receipt；原生執行尚未驗證。`ExpansionFeedback.swift` 的tokenFrame／CaptureDissolveFrame／RogueSwapArc／RogueChainPath由ExpansionBoard和SpellEffects消費，非Domain動作。
- 正常與進階技能共用現有落定拍點；連鎖先交換第一兵，再交換第二兵，拖尾使用相同路徑取樣。奉獻只在原點向上消散；傳遞／落定／提子只來自receipt列出的點，無關單位保持rest。
- tools/animation-21為可播放Canvas比較，時間常數來自Swift、標本座標另行描述；它不執行Domain，也不等同原生分層rig／投影／音訊。看清楚這些差異後才能使用其中證據。Swift測試與整合音訊audit在Windows未執行。
- AV22的game-spell-atlas-v22是原創透明8格局部材質，SpellAccentFrame控制蓄力／接觸尾韻。只在成功receipt的施法者／受影響點使用，不把光環解讀為buff或新增落子。未受影響棋子最多淡化12%，降低動態與收束恢復1；危險／選取不能跟著淡化。
- tools/animation-22改用來源polygon與pose表的Canvas分層合成；兩側都用同一層合成，避免把工具改善算成native進步。密集標本／細節放大是比較用，未執行Domain。32／48／64樣本之外仍要原生正常速度影片；不可宣稱Canvas與SwiftUI等價。
- Interface 19 的 browser 位於 tools/game-interface-preview；它是排版／互動 fixture，不是 SwiftUI renderer 或遊戲規則引擎。Windows 上 build、原生 UI、效能、VoiceOver、真機聲畫皆另驗。

## 歷史定位（非當前 runtime）

### 舊主線研究

研究基線：TacticalGo `cdab133cd469dd185fd8ca3f47fea2e217cfb139`，2026-10-13 實讀。以下是定位線索，不是未來版本永久事實。先確認檔案存在及 runtime 呼叫路徑，再修改。

| 範圍 | 檔案／用途 |
|---|---|
| 可玩主畫面 | `ios/TacticalGo/PlayableGameView.swift`：選角、玩家資訊、操作及棋盤接線 |
| A0 棋盤 | `ios/TacticalGo/BoardViews.swift`：`SwiftBoard`、`BotBoardFrame`；不是所有同檔 renderer 都在正常對局啟用 |
| 呈現收據 | `ios/TacticalGo/BoardPlayback.swift`、`ios/TacticalGo/GameStore.swift`：before／action／outcome、暫態、非同步與取消 |
| 聲音排程 | `swift/TacticalGoCore/Sources/TacticalGoMotion/CombatFeedbackPlan.swift`：成功事件到 cue |
| 音樂混合 | `swift/TacticalGoCore/Sources/TacticalGoMotion/BattleMusicMix.swift` |
| 原生播放 | `ios/TacticalGo/CombatAudio.swift`、`IntegratedAudioAudit.swift` |
| 原圖／Token | `ios/TacticalGo/Assets.xcassets/`、`docs/ios/visual-pack-original-a0.json` |
| 聲音成品／來源記錄 | `ios/TacticalGo/Audio/manifest.json`、`b-manifest.json` 與 WAV |

## 已觀察到的落差

1. 基線 `PlayableGameView` 約 495 行只在 Bot 行動期間把 motion 傳給 A0 棋盤。真人成功操作是否獲得同等回饋，是下一輪可直接驗證的問題。
2. `BotBoardFrame` 使用移動 0.42 s、提子淡出從 0.45 s 開始；`CombatFeedbackPlan` 的法師落定音在 0.56 s、提子音在 0.62 s。這說明時間分散在兩處，尚未錄影量測真實聲畫差值；不能直接冒稱真機缺陷。
3. `MotionPlan.swift` 是另一條呈現邏輯。不能只因它缺某個 cue 就判定目前主畫面有 bug。必須從實際入口追到 renderer／音訊排程。
4. `docs/ios/AUDIO_01_SPEC.md` 指向的 `scripts/generate-combat-audio.py` 不在這個 checkout；B manifest 指向另一台 Mac 的工作目錄。WAV 在庫不等於來源可重建。先恢復來源或為新候選建立可版本化的原創生成流程。
5. 現有 512px B 卡是實際可用衍生檔。不能依歷史 provenance 記載就宣稱 1254px master 已取得；以檔案存在、尺寸和 hash 核對。

## 適合先做的垂直切片

先做一個完整主畫面的材質／層次候選，再用同一局面比較「真人與電腦的魔法之手 → 落定 → 提子 → 回到可操作」。包含取消、非法輸入、復原、背景返回、降低動態與靜音。固定 fixture 的來歷和原版／候選模式需明示。

若實際任務是戰士或盜賊，就以該技能為主；魔法之手是已有測資與接線可用的起點，不是永久優先順序。不必為此恢復曾被否決的 3D 頭雕流程。

## 驗證環境

### AV-STYLE-01 本地候選（2026-10-13）

這是 `codex/av-style-skill` 的未發布候選；不能把它當成已在 main／裝置啟用。

- `TabletopTheme.swift` 統一桌面、胡桃木面板、人物底座與按鈕。`tabletop-backdrop.imageset` 是本輪原創生成材質；來源見 `artifacts/av-style-01/PROVENANCE.json`。
- `CombatPresentationTiming.swift` 共用視覺落定與音效時間；`CombatBoardFrame` 為純 receipt 投影。以 `docs/ios/AV_STYLE_01_TIMING.md` 的新規格核對，不能沿用上方研究基線時間。
- `assets/candidates/av-style-01/index.html` 是固定 CombatDemo 的 browser 演出與材質工作台。它沒有完整規則引擎，也不是 SwiftUI 的等價 renderer；主線樣式由程式重建，不是原生 screenshot。
- `scripts/check-av-preview.cjs` 檢查 browser 選取／取消／重播、終態、靜音預設、降低動態和手機橫向溢出。`scripts/audit-combat-audio.py` 量測現有 PCM、條件排程與保守疊音上限，不代替聽感驗收。
- 手機縮短重複說明後，390×844 候選可在同一 viewport 看到棋盤及確認鍵；320×568 仍需捲動。9×9 的座標與 token 太小仍是待改項，不能因沒有橫向 overflow 就宣告可用性通過。

迭代記錄及未通過項目在 `artifacts/av-style-01/REPORT.md`。後續先取得原生 build／畫面與實際試聽，不以增加 mockup 版本取代這些缺口。

已存在的命令入口：

```sh
swift test --package-path swift/TacticalGoCore
python scripts/verify-ios-parity.py
```

先檢查腳本參數、所需 SDK／reference revision 與可用工具，再選必要驗證。iOS renderer／AVAudioPlayer 必須使用可用的 Mac／Xcode 及目標裝置；Windows 的瀏覽器候選不能替代原生效能、播放延遲或手機觸控驗收。

改變演出或生命週期時保護非法操作、取消、Undo、晚到結果及密集事件序列；expected outcome 來自既有規則、Golden 或獨立 fixture，不從本次實作輸出回填。僅建立 skill／研究文件時，不為了測試數量重跑無關遊戲測試。
