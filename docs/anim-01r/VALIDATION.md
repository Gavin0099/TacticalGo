# ANIM-01R｜驗證紀錄

本頁原輪證據保持，續作的具體計數／終局修正／source snapshot另見 [補充工程結果07](CONTINUATION_07_RESULTS.md)。補充完成32支援render＋16手機轉橫穩定列、4真實獲勝案例；不因此關閉手機橫向、真機或Owner品質Gate。

## 本輪實際證據

- Motion R1三個測試涵蓋共享時鐘的出手維持、連續且有界的姿勢、Reduced Motion与登場收勢；包含在最新完整Swift206项零失敗結果。
- `mage-audit-and-handover-02`：重新編譯後原生法師audit與背景換手兩項通過。真正持有的GameStore／CombatAudio執行97項檢查，包含黑白、Full／Compact、有無提子、取消、非法、重複確認、undo／restart／leave／background／interruption、中斷三時間點、Reduced Motion与第二次不扣費。
- 新audit的16個影格讀取MageTiming cue，不再把舊0.54秒稱作本版0.60秒落定。影格是原生ImageRenderer，不是動畫錄影或真機截图。
- `mage-se-dense-01`：SE375pt viewport內320pt局部九路壓力情境、白方法師、正常與Reduced Motion兩次操作；黑白來源／目標另外有390原生四組測試通過。
- 四組黑白來源／目標最後獨立重跑為 `mage-r1-targets-native-04`：一項XCTest內執行四個組合，零失敗。02／03是建置失败，不算通過或四項獨立測試；早期shared-regression中相同案例的通過也不重複累加。
- 原始全畫面正常速度影片：`media/reference-with-source-03/native-full.mp4`、`candidate-with-source-03/native-full.mp4`。同fixture與共享時鐘，含登場、無提子、有提子、預覽取消、復原、背景；Simulator原生畫面，**沒有音軌**，未後製配音。三份真正GameStore成功收據與時計逐欄一致，只切Mage revision；源碼／素材與Simulator執行檔SHA隨影片保留，來源在錄製前後相同。見 `media/same-receipt-comparison-03.json`。較早影片仍保留，不重複稱為新結果。
- 最新iPad原生直橫向預覽、確認一格推動、落定／解鎖、復原錄影在 `media/ipad-native-with-source-03/`；原生測試一項通過，源碼前後、實際Simulator執行檔SHA與一份成功收據隨片保留。旋轉未扣AP，確認2→1AP，undo回2AP。這是iOS18 Simulator，不是實體平板。較早 `ipad-native-rotation-02/` 原片也保留。
- 另外 `native-ipad-nine-sound-01` 通過九路棋盤的相鄰選點、取消／復原及音量設定控制項檢查。此案例不是九路法師演技或人耳音效验收，不合併兩種證據。
- `candidate-with-source-03/filmstrip/` 的完整PNG由原片指定影片時間擷取；接觸表只等比縮放排列。時間標籤是影片時間，不冒充與收據cue逐幀同步。原片沒有裁切或調色。
- 32／48／64pt原生1px/pt樣本在 `native-audit-02/mage-m3-review/`。M2／M3／R1與黑白陣營分列；不是512放大圖代替小尺寸驗收。

## 保留的失敗紀錄

早期合併測試選中了要求語音啟用的舊voice-review案例；本輪語音關閉，所以它失敗。沒有為了測試開語音，改用獨立的無語音黑白來源／目標測試。一次原生建置因共享build.db同時操作失敗，後續建置順序執行；不算產品行為失敗或成功。舊背景換手案例依賴1014已隱藏的重複playMessage，更新為實際常駐人類回合HUD與無舊Bot文字，再重新驗證通過。

完整舊結果、修後新命令與xcresult均保留，不將失敗藏掉或重複累計。

## Gate與限制

原圖、clean plate、mask、原畫身份與所有聲音檔位元沒有替換。工程只能確認真正分層、成功收據、事件/資源一致及生命周期；不能由97項或照片宣稱表演有個性、揮杖更有氣勢、音效同步或真機效能。

原畫固定3/4視角，肢體為同一portrait平面；方向性效果依action目標而非固定棋格，不代表任意目標方向的完整轉身成立。R3遠距調度保留原fallback，没有假套一格推動。

真機、Owner角色身份／小尺寸辨識／重量感／節奏 Gate Pending。保留M3參考回退；没有合併、發布或新語音。
