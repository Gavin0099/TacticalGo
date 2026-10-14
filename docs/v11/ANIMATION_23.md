# AV23 操作恢復與配音尾韻

2026-10-13。Owner 指示先 push 再優化。UI19／UI20／AV21／AV22 已先上傳到 `codex/v11-game-interface`，remote 核對為 `354acb22ad77d8e9bdb2b3d5d400fc3e4084e893`。本輪在同一分支改善「演出已落定，但仍等待配音才可操作」的來源時序差距；沒有宣稱達到爐石品質。

## 行為

`ExpansionPlaybackWindow` 分開視覺結束、操作解除與音訊結束。一般成功動作在既有視覺演出結束後恢復操作；配音可以自然收尾，背景音樂仍依音訊時間壓低。終局保留原本結算／音訊等待。非法／溢出的時間回到零窗口，避免無限等待。

已落定技能的配音可延續到普通落子、召喚與非終局結束回合；新的英雄技能、魔物／戰利動作或終局會替換舊配音。復原、重開、離場、背景、音訊中斷與聲音設定變更仍完整停止。每段 Task 等待後核對 generation、active 與 interruption；演出回呼不修改 Domain。audit 新增 voices 欄位於最後，保留既有 UI 測試使用的 players／active 相鄰格式。

兩個 GameStore 入口把電腦等待用的 presentationHold 與壓低音樂用的 presentationAudioHold 分開，避免配音尚未結束就恢復音樂。音樂混合曲線、WAV、UI20 與 AV22 原畫／動畫素材、Domain／Content／Bot／Records 沒有變更。

| 職業 | AV22 操作等待 | AV23 操作等待 | 少等時間 |
|---|---:|---:|---:|
| 戰士（兩技能） | 1.280 s | 1.020 s | 0.260 s |
| 法師（兩技能） | 1.120 s | 1.080 s | 約 0.040 s |
| 盜賊（兩技能） | 1.279 s | 0.700 s | 約 0.579 s |
| 牧師奉獻 | 0.940 s | 0.940 s | 0 |

這是目前 B 配音與 SFX 的 WAV sample count 加來源排程、無提子／非終局標本；不是 iPhone 輸入延遲量測，也不是爐石的參數。A 配音、提子與終局依各自音檔動態計算。

## 比較與驗證

`tools/animation-23` 兩側皆顯示相同 AV22 畫面，只比較輸入窗口；正常播放可選既有 WAV，聲音預設關閉。下一手按鈕檢查瀏覽器配音保留，沒有執行 Domain 或改變棋盤。工具選擇標本會完整清除聲音；不能據此推論原生選取目標會截斷已提交的配音。

- `node scripts/review-animation23.cjs`：27 項 browser 檢查通過，包含375／402七技能、實際 HTMLAudioElement WAV 在落定後繼續、下一手保留、取消、新技能替換、背景式停止、降低動態與正常速度收束。沒有聽感判斷。第一次媒體設定 assertion 比 matchMedia 非同步事件早，已改為等待可觀察勾選狀態，失敗記錄保留，不與最終27項相加。
- `python scripts/build-animation23.py`：讀取現行 SFX 排程和 WAV headers，輸出七個時序標本。`verify-animation23.py` 核對來源、WAV、354acb2 前版快照與不變檔案。初次 verifier 把三位小數的配音時長當精確值而失敗，改用獨立檢視的29245／24000與24953／24000 sample counts；來源匯出本身未錯。
- `ExpansionPlaybackWindowTests` 三項 Swift 測試涵蓋普通長配音、終局、靜音、零時長、負值／NaN／Infinity／溢出；**NOT RUN**。
- `IntegratedAudioAudit` 六項新增檢查使用實際 ExpansionLabStore／AVAudioPlayer 與正常合法 ExpansionPractice，Domain 預期由 GameEngine 獨立 apply：音訊／操作窗口分離、配音尾韻解除鎖定、下一手保留、復原停止、背景停止、回來不復活；**NOT RUN**。

Windows 沒有 Swift compiler／Xcode／iOS SDK。基線和當前原生編譯、UI、聲畫、FPS與觸控皆未驗證；來源檢查或 browser 通過不能替代原生。不能沿用其他分支的歷史250項測試或 TestFlight 建置。

## 推送與接手

首次182檔完整候選 push 通過 hook 後遇 HTTP408；完整未發布歷史保存在本機 `refs/codex-safety/av22-unpublished-full-20261013`。精簡重複影音／暫存證據後，126檔候選354acb2通過 hook 並成功上傳。程式、資產、來源快照、生成／驗證腳本及精選圖片保留；其餘影音仍在本機。必要 inventory guard identity 設定來自同一repo既有設定，這不是治理框架更新。沒有繞過 hooks、丟棄其他工作樹或變更來源分支。

AV23 完成檢查後沿用同一候選分支提交／推送。沒有 main 合併、版本號遞增、安裝或 TestFlight 發布。另一台電腦應取得 `codex/v11-game-interface`，不要只 pull 原始 `codex/v11-monster-battlefield`。

Mac 下一關：完整 `swift test --package-path swift/TacticalGoCore`、TacticalGo／TacticalGoBeta 編譯與串行 UI 回歸；確認工程 audit 的 target 有定義 DEBUG，執行 `PlayableGameTests/testIntegratedNativeAudioCancellationAndReplay`。以同一375／402密集局面錄製四職聲畫，實測落定、輸入、配音、音樂與終局。先證明這輪沒有截音／早解鎖／殘留回呼，再依真機觀察調整人物表演與接觸力度。
