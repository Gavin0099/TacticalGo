# ANIM-M3｜法師小尺寸動作與英雄陣營標記

結果：工程候選可檢查，三個 Owner 視覺／演技 Gate 仍 Pending。人物前方黑白字牌及大徽章移出，法師改為完整較大的分層呈現，蓄勢、出手、收勢的重心差異加強。
原因：原畫沒有改身份；改動限於 presentation、檢查與交付。相同局面 M2/M3 的 before／after／事件逐項一致，不以動作再次結算。
下一步：看正常速度完整棋盤影片，判斷人物完整、動作明顯、戰術清楚；兩台真機已安裝，但因鎖定尚未完成動態驗證。不得 merge、TestFlight 或正式發布。

## 直接看畫面

- [M3 950ms：召喚、無提子、有正式提子](media/mage-m3-full.mp4)
- [M3 760ms 同三段](media/mage-m3-compact.mp4)
- [M2／M3 同局面、同 viewport、同速度依次比較](media/mage-m2-m3-same-board.mp4)
- [M2／M3 推動左右並排](media/mage-m2-m3-push-side-by-side.mp4)；單段完整棋盤另存 native-1.mp4／native-4.mp4。
- [原生預覽、取消、再確認、復原片段](media/mage-m3-preview-cancel-undo.mp4)
- [M3 局部方向特效、有正式提子](media/native-9.mp4)
- [320pt／9×9 密集白方施法](media/dense/dense-320-0.mp4)；[Reduced Motion](media/dense/dense-320-1.mp4)
- [32pt](native-size-review/markers-poses-32.png)、[48pt](native-size-review/markers-poses-48.png)、[64pt](native-size-review/markers-poses-64.png)：native ImageRenderer scale=1，各原姿／蓄勢／出手，黑白双方、M2/M3。不是 Domain 操作錄影。
- screens-390／screens-se／screens-ipad：XCTest 實際原生截圖；mage-body-checkpoints：固定收據時間的原生棋盤靜格。

以上影片為 **Simulator 實際 SwiftUI／XCTest 操作、正常速度、無聲軌，沒有合成角色幀或後製配音**。完整來源 native-ui-silent.mov 與 xcresult 留在本機，體積較大不列入 push。剪輯以收據 uptime 對 recorder readiness 定位，非硬體同步量測；文字字幕在 native viewport 外。並排僅輔助比較，不替代單段完整棋盤。來源時計、收據與剪輯細節在 media/edit-audit.json、capture-clock.json、game-feel-receipts.json。

## 基線與修改

分支 codex/anim-mage-m3。開始前核對 M2 final-source-manifest 全部 SHA，M1/M2 保存於 4e15078、記憶紀錄 449e906；舊原畫、clean plate、舊影片及原報告不覆寫。

本輪檔案：MagePerformance.swift／其測試、MageBodyView.swift、MagePoseReview.swift、CozyStyle.swift、CozyBoard.swift、PlayableGameView.swift、CozyAudit.swift、PlayableGameTests.swift；docs/ios/ANIM_M3.md、docs/PLAN.md 及錄影／剪輯／证據腳本。不改 Domain、技能、AP、Mana、Bot、GameStore、BoardPlayback 或 BoardProjection。

沒有新增素材拆層、補圖或生成角色。B-mage-v02、既有 hand/staff/head/cape 遮罩及 clean plate 沿用；可編輯 2D cutout，不是 3D。

### 標記與尺寸

- 黑方墨藍底座、白方奶白淡金底座；雙明暗邊框。
- 底座 0.74pitch × 0.36pitch，中心 y+0.03pitch。黑實心圓／白空心菱形在 x−0.20pitch、y+0.225pitch，尺寸 max(3.5pt,0.10pitch)，不畫人物前方文字塊。
- 職業符號在 x+0.23pitch、y+0.215pitch，容器 0.12pitch。pitch<32 時省略，職業仍由原畫、HUD、選取資訊說明。
- 法師 canvas 0.70→0.92pitch，ground source 420→448，去掉舊裁切；士兵及主將呈現不改。其他英雄僅共同标記重整，不新增動作。
- 390pt容器／7×7 fitted board382×429.75pt，pitch46.55625、canvas42.83175pt；320pt容器／9×9 fitted312×351pt，pitch28.51875、canvas26.23725pt。SE Simulator 原生 window375pt，**以 debug320pt容器做小尺寸壓力測試**，不是宣稱實體 SE 為320pt螢幕。
- 格點、提示與反向命中沿用同一等比投影；底座不位移。

### 動作與時鐘

source512座標：蓄勢 torsoX+34／torsoY+10／torso+4°／heldX−3／shoulder−9°／elbow−5°；出手 torsoX−38／torsoY−5／torso−5°／heldX−24／shoulder14°／elbow7°。手與法杖共用群組及握持轉換，不旋轉整個 Token；帽子70ms、披風90ms延後跟隨，最終全部原姿。

| 段落 | Full | Compact |
|---|---:|---:|
| 蓄勢到位 | 180ms | 120ms |
| 出手 | 280ms | 200ms |
| 士兵開始移動 | 300ms | 220ms |
| 到位 | 540ms | 420ms |
| 有事件才提子 | 660ms | 510ms |
| 收勢／解鎖 | 950ms | 760ms |
| 召喚落定完整演出 | 720ms | 600ms |

沿用 M2 共用時計。先拍無光圈／粒子／英文語音，再另拍局部杖尖亮點及法師→受術士兵的短方向提示。原版一格推動；遠距調度不套此演出。BGM 整合維持 HOLD。

## 驗證

| 證據 | 本輪結果 |
|---|---|
| package-initial.log | 164 tests，0 failure |
| Golden fresh Swift | 38 fixtures／99 actions／137 snapshots 與既存 C# 基準一致；C# 本輪未重新執行 |
| mage-body-audit.json | 97/97；黑白施法者／目標、含與不含提子、非法目標／方向、不扣預覽資源、重複確認一次、取消／復原／重開／離場／背景清舊演出、Reduced Motion、語音關閉 |
| native-focused.log | Audit、真實 Bot 推動／落子／提主將通過；第二AP初次斷言失敗保留 |
| native-two-ap-corrected.log | 第二AP施法後落子、Core自動白方2AP、復原黑方1AP通過 |
| media/native-record-test.log | 10個真實成功收據，9個無特效＋1個方向效果；三種模式同fixture／same before-after-events |
| native-se.log、media/dense/native-record-test.log | 320/9 dense、白方施法、Reduced Motion、取消／復原通過 |
| native-ipad.log | 原生平板縱橫旋轉、命中、預覽保留、確認／復原、Bot開局通過 |
| release-build.log、device-build.log | Release與簽名候選 build通過；codesign strict通過 |
| iPhone／iPad install JSON | 獨立 Mage M3 1.0.0(1001)、com.tacticalgo.prototype.magem3 安裝成功；鎖定拒絕啟動，真機動態未完成 |

原圖 SHA6980751a325e51156e56f14b38171a435bd54f4ef7d509433e94d6e3b9061a33；clean plate SHA9a633d497e0ce5baaa1f726312d87b49507df65b1c997c84374fa2f612be294d，與 M2 一致。来源及權利仍依原 provenance，不升格發布素材。

保留失敗：第二AP測試原以0AP為期望，但現有 Core 已自動換手；根據既有契約改為白方2AP後 fresh PASS，未因此改規則。剪輯初次可選 tpad 的小數格式被 ffmpeg拒絕，移除額外停格後重新成功；最初 evidence harness 誤限定 BUILD 而不接受 TEST BUILD 字串，修正識別後重跑。全部不是被隱藏的 production fix。

## 已知限制與 Gate

| Gate | 本輪能支持的觀察 | 判定 |
|---|---|---|
| 人物完整 | 原生圖的臉、手、帽與披風沒有被新標記盖住；黑白形狀在底座外緣 | Owner Pending |
| 動作明顯 | 原姿／蓄勢／出手的本體與持杖群組位置不同，可直接看950／760ms原生片段 | Owner Pending，不能以像素差宣稱有表演感 |
| 戰術清楚 | 成功出手後才推動、正式事件才提子；預覽／取消／復原與最後棋形有證據 | Owner Pending，方向與密集遮擋仍需目視 |

32pt符號約3.5px且職業徽章省略；320/9實際pitch更小，不能宣稱一次就能辨識。固定原畫杖尖偏左上，受術者可能在右方，**不是多方向手繪揮杖**，靠方向提示與士兵反應補因果。密集fixture包含鄰兵，但完成後正交鄰點有空位；不能推論四面紧貼最壞盤面全部不遮擋。既有cutout近景接縫與肩袖伸縮仍待美術判斷，沒有宣稱完整骨架／逐幀動畫。

工程 evidence PASS；真人可讀性、角色魅力、真機動態與正式美術皆未宣稱通過。真機測試在等待解鎖約214秒後中止，保留 Locked、TEST EXECUTE INTERRUPTED 紀錄，沒有當成測試PASS。

記憶紀錄使用 canonical writer；memory_workflow --check --run-guard 無目前修改阻擋，completion_claim_allowed=true。既存 missing_canonical_memory=2、provenance_not_found=5 及本 worktree 缺少本地 writer/guard 路徑的警告保留；工具透過既有外部 framework 執行，不宣稱治理完整導入或更新。

可逆隔離候選完成必要提交與push後交Owner，禁止合併與發布。
