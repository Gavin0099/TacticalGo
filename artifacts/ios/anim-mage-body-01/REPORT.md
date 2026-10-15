# ANIM-M1 / M2 — 法師本體原生候選

結果：可操作 SwiftUI 法師分層登場與原版一格魔法之手候選已完成，提供無語音／無粒子光圈的正常速度原生 Simulator 錄影。工程驗證通過，角色表演、美術與真機動態仍待驗收。
原因：原本只有單張英雄原畫與外部特效。本輪將原畫局部分層，讓頭身、持杖手臂／法杖及披風有不同動作，並把角色、士兵、提子、音效與鎖定放在同一份時間表。
下一步：Owner 先看完整棋盤的950／760ms比較，再以近景確認接縫與角色姿態；解鎖iPad後完成真機驗證。沒有擴充其他職業或新語音，未merge或發布。

## 可檢查交付

- [實際棋盤、兩節奏、六次成功行動](media/mage-body-board-demo.mp4)：每個節奏各有召喚、無提子推動、有正式主將提子／勝利事件的推動。
- [950ms完整節奏](media/mage-body-full.mp4)／[760ms緊湊節奏](media/mage-body-compact.mp4)。
- [近景分層造型檢查](media/mage-body-closeup.mp4)：畫面明示造型檢查，不結算棋局。原姿／蓄勢／出手與實際原生動作；只能輔助檢查，不能替代棋盤尺寸驗收。
- [預覽→取消→再確認→復原](media/mage-body-cancel-undo.mp4)。
- [320pt、9×9密集白方、Reduced Motion](media/mage-body-reduced-motion.mp4)：實際行動與復原，關閉動態後直接顯示成功結果。
- 原始完整操作錄影：[390pt無光效](media/native-ui-silent.mov)／[320pt正常與減少動態](media/safety/native-320-reduced-silent.mov)。未變速，無音軌、未後製配音。字幕另加在原生viewport外；剪輯資料見 `media/edit-audit.json`、`media/safety-edit-audit.json`。
- `mage-pose-review/`：native ImageRenderer 輸出32／48／64／128／512px关键姿勢；`mage-body-checkpoints/`是成功收據凍結檢視，不是live操作影片。
- 規格／啟動flag：[ANIM_MAGE_BODY_01.md](../../../docs/ios/ANIM_MAGE_BODY_01.md)。

## 本體與動作

既有B-mage-v02是唯一身份原圖。穩定待機直接顯示原图；动作使用原图臉、頭髮主體、帽子主體、軀幹、手及法杖像素遮罩。新增補圖只用於移開前景手杖後露出的服裝及少量帽子背景；不使用生成臉。帽緣／披風晚於軀幹回穩，底座固定在棋盤交叉點。肩部／肘部與手杖握點為可編輯SwiftUI座標，不是完整解剖骨架、逐幀角色動畫或3D Mesh。

召喚是短距離落定、軀幹沉身／定姿與持杖手穩定，法師不再走整個Token均勻縮放的通用路徑。施法則先收手／收身，再抬杖出手，士兵其後才開始移動，最後手杖／披風收勢。原圖面部表情固定，未新增表情幀。

| cue | 完整 | 緊湊 |
|---|---:|---:|
| 蓄勢完成 | 180ms | 120ms |
| 出手／施法SFX | 280ms | 200ms |
| 士兵開始移動 | 300ms | 220ms |
| 到位／落地SFX | 540ms | 420ms |
| 有正式提子資料時開始退場 | 660ms | 510ms |
| 收勢／操作鎖結束 | 950ms | 760ms |
| 登場結束 | 720ms | 600ms |

時序位於presentation-only `TacticalGoMotion/MagePerformance.swift`，由BoardPlayback成功收據鎖定。聲音紀錄只證明播放器排程，不代表人耳或實機聲畫同步。這輪提供靜音影片，以避免語音掩蓋動作；沒有更換VO素材或正式整合新BGM。

## 結算與中斷

GameStore仍只apply一次，before／action／outcome決定表演，不由動畫再次扣費、移子或判勝。預覽保留來源與空目的地、不扣費、不產生成功演出。非法確認及連點不提交額外行動。取消、復原、重開、離開、背景與音訊中斷會停止舊播放；有限收勢結束前不提早解鎖。Reduced Motion使用中性姿勢與已提交棋局，保留必要SFX。遠距候選調度不使用此一格推動表演。

## 驗證

| 證據 | 實際結果 | 邊界 |
|---|---|---|
| `package-all-verified.log` | Swift package162 tests／0 failures | 含6個新本體／時序／fixture測試；非演技驗收 |
| `golden-replay.log`、`golden-compare-cached-reference.log` | Swift重新跑38組99步，137 snapshots與既有C#紀錄一致 | C# exporter此次未成功重跑，SDK8無法target9；不是fresh雙端執行 |
| `native-focused-verified.log/.xcresult` | 390pt Simulator3／0 | 實際owner audit、密集白方／Reduced Motion、preview／capture／undo／background；最後遮罩小修在此run後 |
| `native-se.log/.xcresult` | 320pt SE Simulator2／0 | 最後遮罩版本；9×9密集白方及Reduced Motion實際操作 |
| `mage-body-audit.json` | 97／97 | 畫面實際持有GameStore／Audio，不另建假播放器；黑白、兩節奏、提子／無提子、資源、重複確認、中途撤銷／背景／重開等 |
| `media/native-record-test.log/.xcresult` | 1／0 | 最後遮罩版本；六次真实成功收據，previewcancel／undo／background，外加造型頁 |
| `media/safety/native-safety.log/.xcresult` | 重跑1／0 | 最後遮罩版本；320pt Reduced Motion實際录影，非新增唯一測試 |
| `native-build-render-final.log`、`release-render-final-build.log`、`device-render-final-build.log` | DEBUG／Release／簽名裝置建置通過 | Build不證明實機動態 |
| `codesign.log`、`git diff --check` | 通過 | 未merge／正式發布 |

Xcode26.6（17F113），macOS26.6.2。Simulator390／SE320為iOS18系列，不稱為實體iPhone。測試次數按run列示，不累加為唯一測試數。目標Domain、Bot、音檔目錄無本輪diff；既有候選規則未修改。

Golden基準54deef97e0fb7157b0025a7282fc2c0a448d4fb9，cached C# SHA256 `9e41aaa31cc612a16e68e6f2270edb4ad382bf4af94280796c9eff4d670965da`，fixtures逐檔與該基準相符，詳`golden-evidence.json`。Golden證明與既有紀錄一致，不能證明原規則本身正確。

## 實機與分支

iPad mini6經Wi-Fi安裝獨立`com.tacticalgo.prototype.magebody`，TacticalGo Mage Body0.9.0（903）；`ipad-install-render-final.json`outcome成功。iPad仍Locked，CoreDevice10002拒絕前景啟動；已提出解鎖需求，沒有本輪實機動態通過證據。iPhone16Pro目前unavailable。舊Cozy／Voice真機結果不能移作本輪本體動畫驗收。

本地隔離分支`codex/anim-mage-body-01`，base005fba4bc2634c743a711a5b41011057e507dc42，實作未commit／push／merge／發布。主checkout未修改。既有語音研究、其他build及驗證檔保留，不打包為新成果。

## 素材／未通過事項

原圖512×512，SHA256 `6980751a325e51156e56f14b38171a435bd54f4ef7d509433e94d6e3b9061a33`。built-in image_gen遮蔽補圖實際1254×1254，SHA256 `9a633d497e0ce5baaa1f726312d87b49507df65b1c997c84374fa2f612be294d`。完整prompt、透明／decoded RGBA檢查在`assets/candidates/anim-mage-body-01/provenance.json`、`asset-inspection.json`；來源權利與正式使用待核准，工具模型版本unknown。

已目視原生棋盤及近景：原姿與兩動作姿勢不同，手杖握持維持同一變換。但近景仍有少量服裝接縫／原遮蔽邊界細線，法杖在出手時會靠近臉部；這些仍需Owner判斷，不宣稱專業角色動畫完成。小尺寸黑白底座及職業標記保留；可看見不等於真人已證明辨識清楚。未量測真機frame pacing、音訊聲學延遲或玩家耐受950／760ms節奏。

歷史失敗保留：早期build型別／mask重疊修正、dense白方fixture含零氣單子（修正邊界空點後新增測試）、C#SDK不符、第一次影片xctestrun路徑不符、ffmpeg未提供drawtext（改用独立字幕overlay）。未把失敗run當通過，最終run分開標示。

**判定：原生候選工程PASS；本體演技／美術與真機動態HOLD，待Owner與解鎖設備。正式BGM、VO聽感與發布權利維持既有狀態。**

## 計畫與記錄

PLAN已記錄本輪里程碑，記憶使用外部已存在的canonical `governance_tools.memory_record`，沒有直接改寫記憶Markdown。`memory-check-final.log`的authority guard無阻擋、允許completion claim；仍列repo-local writer／guard缺失、2個missing-canonical及5個provenance警告，不宣稱整庫記憶完整或治理更新完成。第一筆中文標點引用導致artifact路徑未辨識，後續canonical記錄引用`evidence-ledger-receipt.json`補正；保留原警告以供稽核。該receipt只核對既有測試log／錄影／ledger，不冒稱fresh重跑162項測試。task交付不是session end，沒有執行關閉session。
