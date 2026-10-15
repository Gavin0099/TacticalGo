# AV21 四職動畫候選

2026-10-13。Owner在UI20主畫面／icon候選完成後明確指示開始動畫，以爐石品質為目標。這輪恢復先前保存的AV21改動，增加七技能受力與路徑差異，完成原生程式接線及可播放browser比較。Swift編譯與原生播放仍未執行，不能稱已达到爐石品質或已修復真機上的所有問題。

## 來源與範圍

`codex/v11-game-interface`，當輪重新fetch並確認 `origin/codex/v11-monster-battlefield` 仍為 `004ed4cdc661bc20261a587e11d91e54dc649b9d`。先前隔離的 `artifacts/av21-pending/tracked.patch` 通過git apply --check後恢復；新Motion來源與測試從保存副本恢復。UI20資產與主畫面程式保留。

本次採用[爐石官方VFX文章](https://hearthstone.blizzard.com/en-us/news/22552047)所說的資訊清楚、職業形狀／材料身份與大事件獨立收束原則。重新讀了文章，未對文中GIF做時間量測；以下秒數是TacticalGo現行拍點，並非競品數值。沒有匯入第三方遊戲美術、音訊或新依賴。

## 已接線的原生候選

| 技能 | 具體改動 | 保留的落定拍點 |
|---|---|---|
| 築壘 | 雙兵落地壓縮、40ms壓實、140ms恢復，金色地面碎點 | 0.58秒 |
| 戰線重整 | 搬運時小幅抬起，落地壓實；撤掉與新增雙兵混用的盾影 | 0.58秒 |
| 魔法之手 | 手托住／推動時同步棋子壓縮，接觸後回彈；短星芒標出落點 | 0.68秒 |
| 雙重牽引 | 每個transfer各有連線、手掌與受力，保留棋子陣營 | 0.68秒 |
| 換位 | 兩方沿相反弧線移動，拖尾與路徑一致，落定小圈 | 0.36秒 |
| 連鎖換位 | 第一組交換先完成、第二兵先等待；再進行第二組，避免三兵同軸交錯 | 0.36秒 |
| 奉獻 | 原點棋子漸淡、向上金葉與空座提示；不飛到英雄後再落回原點 | 0.58秒 |

`ExpansionTokenFrame` 與 `CaptureDissolveFrame` 為純呈現取樣，僅作用在receipt列出的點。其他棋子維持rest；降低動態使用after盤面，不重建被提走單位。一般落子／召喚也有短落地回彈。提子在原點短暫縮小淡出，主將有较大的金色地面圈；危險、選取等資訊層仍在特效之上。

既有戰士、法師、盜賊、牧師的原畫分層姿勢保留。本輪沒有重畫人物、換音樂或更改Domain規則。呈現仍由通過驗證的成功receipt與before/after驅動；完成回呼不套用規則。

表中為視覺拍點，不是輸入解鎖的總時間；原生presentationHold仍會等待既有配音／SFX尾韻。讀取WAV確認B配音長度為法師1.040秒、戰士1.200秒、盜賊1.219秒、牧師0.880秒，並未實際聽音。下一輪原生錄影需核對收束到可操作的空檔，不能用browser短片推論原生節奏已合格。

終局新增按computer／winner映射的cue，勝／敗／和局透過GameStore既有CombatAudio收束BGM。一般結束回合也走同一commit receipt，讓回合上限和局能到達此路徑。背景、取消和續載已結束對局使用silent finish，不重播ending。這是來源接線，尚無原生實際聽音／生命週期通過結論。

## 可播放比較與迭代

`http://127.0.0.1:8771/tools/animation-21/` 提供七技能、375／402、選取／確認／取消／重播、進度滑桿、降低動態與聲音開關。聲音預設關閉，啟用後只播放既有三拍SFX，沒有搬入配音或BGM完整混音。`scripts/build-animation21.py` 從實際Swift來源擷取release／moveStart／arrival／captureStart／duration；固定標本由獨立座標描述，進階座標參考ExpansionPractice。

左側是前版路徑示意，右側是本輪候選，**兩側都不是iOS錄影**。browser使用Canvas與整張人物姿態近似，不等同原生分層rig、棋盤投影、遮擋和danger／結果畫面；沒有執行Domain或真正扣資源。錄影 `artifacts/animation-21/seven-skills-browser.webm` 為無聲瀏覽器演出，不能驗證手機FPS、播放延遲或native字體。

第一輪中圖：連鎖換位兩次交換比同時直線路徑可追蹤，奉獻原點淡出比返回光葉更符合空點結果。法師和戰士的細微壓縮需要看正常速度與原生影像，不用靜態中圖宣告重量感合格。鏡頭保留9×9標本原尺寸，角色仍小；需要原生錄影／32至64pt姿態樣本核對人物分層與辨識。

初次工作台因sheet使用單個querySelector作迭代而載入失敗；修為querySelectorAll後重新執行。失敗錄影保存 `failed-setup-browser.webm`。第一輪26之前的25項結果不與最終結果相加。第二輪增加七技能连续正常速度播放到最後奉獻的檢查。

## 驗證與界線

- `node scripts/review-animation21.cjs`：最終browser檢查見 `browser-checks.json`，涵蓋14個尺寸／技能情境、取消早於音訊拍點、背景式停止、降低動態、七技能正常播放、連續七技能及手機頁面無橫向溢出。另有端點、交換分離、非法時間rest、奉獻尾韻消失的不變量。這些只執行JavaScript候選，不證明Swift正確。
- `ExpansionFeedbackTests.swift`：八項新Swift測試，包含兩方勝負／本機視角、回合上限和局、非法／普通receipt、四職結束／降低動態rest、非目標點不變、奉獻消失、落地／托住、提子邊界、簡單交換分離及兩段連鎖。**NOT RUN**。
- `ExpansionLabTests` 增加電腦獲勝選擇敗北的路由assert；`IntegratedAudioAudit` 增加實際擴充winning receipt、SFX關閉仍收束BGM，以及背景後不復活／取消早於終局cue。**NOT RUN**。
- Windows與WSL Ubuntu都沒有Swift compiler；Windows沒有Xcode／iOS SDK。基線與修改後原生build均未驗證，因此來源整合仍有編譯／行為風險，不把歷史版本當可信build結果。

資產／UI20來源未變hash、Domain無變更、來源時間一致與git diff --check保存在本輪checks／validation.log。沒有commit／push／merge、版本號遞增、安裝或TestFlight上傳。

下一個原生關卡：Mac執行 `swift test --package-path swift/TacticalGoCore`，編譯Debug／Beta，串行執行整合音訊與UI回歸；同局面錄製四職7技能375／402正常速度与降低動態影片，確認雙手、兩段交換與犧牲空點可讀。由實際觀察再調節力度／拖尾／時序，不以測試數或自評百分比宣布市場品質。
