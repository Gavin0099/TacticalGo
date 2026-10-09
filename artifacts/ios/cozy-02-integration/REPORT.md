# TacticalGo Cozy-02／ANIM-01 原生整合候選

結果：Cozy-02、B2-B 士兵、原 B-v02 英雄與魔法之手聲畫已接入可玩的 SwiftUI 候選；iPhone／iPad 均已透過 Wi-Fi 安裝 0.7.0（702）。
原因：正式成功事件驅動推動、落定、條件提子與勝利；預覽不扣費，過期聲畫會取消，沒有修改 Core、Bot、技能效果或資源規則。
下一步：Owner 試玩畫面與聲音；手機真實點擊自動化、最新版 iPad 再次起播及揚聲器／耳機聽感仍需補驗，BGM 正式整合維持 HOLD。

## 可玩入口與隔離

開啟裝置上的 **TacticalGo Cozy-02**。這是獨立 bundle `com.tacticalgo.prototype.cozy02`，原 TacticalGo App、原存局不被替換。候選預設採用新棋盤及元件；選法師、召喚後可使用既有正式魔法之手。候選調度仍依原有入口與規則標示，不用一格推動動畫冒充遠距調度。

工作樹 `/Users/pc49-58/.codex/worktrees/cozy-02-integration/TacticalGo`，分支 `codex/cozy-02-integration`，基線 `cdab133cd469dd185fd8ca3f47fea2e217cfb139`。本輪沒有 commit、push、merge、PR 或發布；PR #5／#6 不在本候選內。本輪未升級候選技能、未安裝 Skill、未重做頭雕。

iPhone 已成功安裝並完成前景實際播放器 audit；最後嘗試重新開到普通入口時 Wi-Fi 連線中斷。iPad 最新版安裝成功，最後嘗試重新啟動時系統回報 Locked；此前本輪真機手勢測試及實际播放器 audit 已完成。不能把最後一次啟動拒絕隱藏為「目前已保持開啟」。

## 交付行為

- 固定 Cozy-02 暖紙卡片、鼠尾草背景、深色文字、金色確認、厚底陰影、選取勾號及座標描邊。陰影僅附於按鈕背景，避免文字重影。沒有再開配色比較。
- 棋盤緊接 HUD，8:9 等比 contain-fit；格線、ground anchor、技能提示、反向命中共用同一投影。手機不足高度可捲動，並保留大按鍵選點。iPad 直向棋盤舞台感強，但下方操作列需要捲動，不能宣稱全部控制同屏。
- B2-B 原始黑白士兵透明匯出；三職沿用 B-v02 原畫，肩胸裁切與底座 anchor 固定。另加盾／星／短刃職業徽記與黑／白標籤，不重畫臉。390／7、320／9 密集局面及 320 戰士局面有原生截圖；最終小尺寸辨識品質待 Owner。
- 成功魔法之手收據建立蓄力、推動、落定；只有 `piecesCaptured` 才追加提子，只有 `gameWon` 才勝負。非魔法之手的既有電腦落子、換位及提子可見動作仍保留。
- 預覽只用 selection 聲；非法行動不扣資源、不建成功收據、不播放成功聲。確認期間阻止重複提交；取消、復原、重開、離開、背景與音訊中斷停止舊任務。
- 同一個 `PlayableGameView.store.audio` 保留及預熱 11 個 AUDIO-01 播放器。成功立即 cue 在 SwiftUI 首次渲染前起播，其餘 cue 共用收據時間。停止的 Timeline 強制呈現完整結果，修正提子淡影留在最後一幀的問題。
- Reduced Motion 呈現靜態正式結果，SFX 照常。BGM／SFX 音量各自保存，SFX=0 可獨立關閉；候選 BGM 開關明示 HOLD 並停用，不播放 B 曲或舊迴圈，不以文件授權假設正式音樂核准。

## 驗證

| 證據 | 結果 | 能證明的範圍 |
| --- | --- | --- |
| [Swift Package](package-tests-final.log) | 151／0 | Core、既有模組及新增事件／投影／停止最後一幀回歸 |
| [共用 Golden](golden.log) | 38 組、99 步 PASS | Swift 重播狀態、錯誤與有序事件吻合既定測資；本輪未重跑 C# exporter |
| [最新 390 模擬器](native-390-delivery.log) | 5／0 | 原生點擊、預覽純度、成功提子／勝負、復原／背景、密集／Reduced、實際 audio owner 及電腦動作 |
| [SE 模擬器](native-se-r1.log) | 1／0 | SE 375 pt 螢幕上 320 pt 內容約束、9×9 密集及 Reduced；320 不是宣稱裝置物理寬度 |
| [iPad 原生操作](native-ipad.log) | 2／0 | 未約束全尺寸的真機點擊、推動／提子、捲動及復原；同画面持有的 audio owner audit |
| [iPhone 實際 audio owner](phone-runtime-r3.json) | 17／17 PASS | 同前景 App 的真正 AVAudioPlayer.play、資源、條件聲音與取消安全；不是手勢或人耳驗收 |
| [iPhone XCTest](native-phone-r2.log) | BLOCK：0／2 | Xcode CoreDevice worker 啟動失敗，未執行測試手勢；原因未確認，不能宣称手機觸控 PASS |
| [來源檢查](input-pins.json) | 41 pins PASS、三張角色卡逐位元相同 | 正確版本／角色身份素材，非美術品質驗收 |
| [既有音效檢查](audio-source-check.json) | 11 SHA 相符、PCM 0 clipping | 數值與來源一致，非實際揚聲器／耳機音量舒適度 |
| [裝置產物](device-product.json)、[簽章](codesign.log) | 0.7.0（702），strict verify PASS | 本機簽署的測試候選，非正式發布 |

本輪新增測資含成功／失敗、空推不提、條件勝利、未扣費預覽、重複確認、完整 Core history 復原及非法操作，預期取自既有正式事件與 fixture／時間表。沒有在 UI 另寫提子、氣、資源或勝負規則。上述皆為本機證據，沒有聲稱 GitHub CI 通過。

保留初次 AX 查詢失敗、首 cue 延遲與 inactive audit 失敗、Xcode 手機啟動失敗及錄影 File exists／未支援 drawtext 的原始診斷；修正後成功結果以表列最後證據為準。錄影脚本現在須收到 Recording started 並成功結束才交付，避免舊影片與新時間紀錄混用。

## 畫面與聲畫

- [390／7 一般局面](delivery-cozy-390-7-before.png)、[技能預覽](delivery-cozy-390-7-preview.png)、[提子結果](delivery-cozy-390-7-captured.png)
- [320／9 密集局面](delivery-cozy-320-9-dense.png)、[Reduced 結果](delivery-cozy-320-9-reduced-captured.png)、[320 戰士辨識](cozy-320-warrior.png)
- [iPad 真機一般局面](ipad-cozy-native-device-before.png)、[真機提子](ipad-cozy-native-device-captured.png)、[真機復原](ipad-cozy-native-device-undo.png)
- [4.2 秒聲畫示範](media/Cozy-02-Magic-Hand-postmixed.mp4)：實際原生 SwiftUI 錄影＋事件紀錄對齊的 AUDIO-01 **後製音軌**。字幕已燒錄「NOT DEVICE AUDIO」；影片不是系統收音，不可當成真機同步或聽感驗收。
- [原生無聲錄影](media/native-silent.mov)、[後製來源／時序／數值](media/synchronization.json)、[重現錄影](media/record-native.py)、[重現後製](media/make-demo.py)

最新模擬器成功收據：mage 起播 +9.8ms，place +329.9ms，capture +415.2ms，victory +617.9ms；Timeline 評估落定 +330.3ms、提子 +415.7ms。iPhone 收據：+37.4／336.1／421.4／613.8ms。這些是實際 player request 與 Timeline evaluation，不是聲波到耳朵或螢幕合成時間。後製錄影起點以 record-ready 時鐘近似，不能宣稱 frame-accurate acoustics。

後製原始 PCM 峰值 −6.96 dBFS、0 clipping；AAC 解碼另保留數值檢查。沒有 BGM；因此沒有假造音樂退後／恢復的驗收證據。

## 來源、版本與權利

[Cozy source pins](../../../ios/TacticalGo/Cozy/source-pins.json)、[ANIM-01 manifest](../../../ios/TacticalGo/Anim01/anim01-manifest.json)、[AUDIO-01 manifest](../../../ios/TacticalGo/Audio/manifest.json) 保留版本、匯出 anchor、SHA-256 與来源。前兩連結相對工作樹路徑由本報告向上三層解析。

Cozy 配色／卡片來源為本機 `vis-3d-anim-01` 的 `assets/candidates/vis-ui-cozy-02`；ANIM-01 來源為 `anim-01-magic-hand` 工作樹。B2-B 原黑兵 SHA `04f41c4816b80b0605cccd43d872111e14acacd5bd05b2630090d667e544e276`，白兵 `198b7342f42a2c54debbd6230a48ba407a41733b9743003610e01053ada5ba38`；透明 padding 匯出另有 manifest SHA，不能混稱同檔。三張 B-v02 原圖不更換身份。

AUDIO-01 是既有原創 Python 標準庫合成、固定 noise seed、無外部 samples；生成來源腳本 SHA 已保存於 manifest。圖片與音效仍屬開發候選，正式發布權利及聽感未核准；不因可編輯、hash 正確或程序合成就宣稱商用已通過。

## 重現與待验收

[來源快照](Cozy-02-source-snapshot.zip) 是基線上的檔案覆蓋包；[diff](candidate.patch) 是審閱用，不要再套到已含快照的工作樹。排除 Build、.build、裝置資料與 xcresult。完整程式 SHA 見 [final-source-manifest.json](final-source-manifest.json)。

```sh
swift test --package-path swift/TacticalGoCore
swift run --package-path swift/TacticalGoCore tacticalgo-golden tests/ios-golden
xcodebuild build-for-testing -project ios/TacticalGo.xcodeproj -scheme TacticalGo -destination 'platform=iOS Simulator,id=<dedicated-device>'
# 原生 UI 個別用 test-without-building；同一 SYMROOT 不可平行建置。
```

裝置建置本輪透過 CLI 設 PRODUCT_BUNDLE_IDENTIFIER=com.tacticalgo.prototype.cozy02、INFOPLIST_KEY_CFBundleDisplayName='TacticalGo Cozy-02'、MARKETING_VERSION=0.7.0、CURRENT_PROJECT_VERSION=702；不覆盖原 App。

工程整合 PASS；手機手勢自動化 BLOCK，整體美術／小尺寸英雄辨識／耳機與揚聲器聽感 HOLD。下一步先由 Owner 實際比較舞台比例、320 密集可讀性、技能音量與同步；沒有新增玩法工作、沒有自動升級正式美術或 BGM、沒有合併或發布。

### 紀錄與檢查邊界

本輪 milestone 由既有外部 `governance_tools.memory_record` 寫入 daily／active 摘要，docs/PLAN.md 已同步；[guard 紀錄](memory-check.log) 顯示本輪無 blocking item。檢查仍警示本 repo 本地 canonical writer／guard 路徑缺失及既有 missing_canonical_memory，保留原輸出，不宣稱治理覆蓋完整或框架已更新。沒有把任務完成當成 session end，沒有 closeout、memory commit 或自動發布。
