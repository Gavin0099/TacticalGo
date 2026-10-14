# P28A：原生七招基線與戰士落定辨識

十小時窗口仍進行中，截止台北2026-10-14 09:54:08。P27介面保留；本輪先建立正常整合棋盤的DEBUG選取→預覽→確認錄影，從合法ExpansionPractice開局重播七招，沒有改用Lab畫面或偽造規則事件。

## 可指出的改進

基線接觸前後影格顯示：兩個大盾投影延續到落定後，覆蓋新士兵面孔，接觸焦點接近透明盾牌buff而非士兵落定。候選投影峰值由.72降至.50，抵達不再放大到1.12（改.96），.78秒完全消散（原延續至.98）；本體加重姿勢、.58秒落定與SFX、1.02秒可操作時長不變。地面接觸材料、原畫／盾徽／陣營底座不變。

已檢视主手機正常全盤影格與接觸／收勢局部：新士兵面孔在落定後较早可見，收勢時投影已消失；這是agent影格判讀，沒有把它宣稱為獨立reviewer、完整正常速度試聽或Owner演技接受。此輪改善的是戰士特效層級，不宣稱已全面改善四職骨架動作。

## 可比較素材

- artifacts/v11/polish-28/baseline：七招完整／截短Simulator原生無聲影片、實際Core結果與資源／聲音key紀錄，SOURCE_PIN。
- warrior-candidate：兩招候選同條件影片及接觸／收勢細節。
- warrior-basic-comparison-silent.mp4、warrior-advanced-comparison-silent.mp4：左為1108動作基線（P27 UI），右為P28A；相同尺寸／棋局／輸入／Domain結果／聲音排程。錄影裁切對齊僅以log／trace檔寫入時間近似，不宣稱50ms精度或真機聲畫同步。影片沒有音軌。
- SOURCE_PIN_P28A.json與PROGRESS.json固定本輪來源。兩次實際runtime快照只有WarriorPresentationPlan.swift不同；聲音原檔沒有改。

## 工程與失敗記錄

聚焦WarriorPresentation8/0，新增投影在恢復前消失、抵達不膨脹、地面impact保留的契約檢查。Debug原生安全2/0且0skip：背景取消錄影等待／回來不晚到施法，以及新版遠端築壘／資源／Undo／固定棋盤。七條基線及兩條候選實際成功Core結果、AP/Mana／時間線／聲音key全相同。282完整Swift是P27歷史結果，本輪不冒稱全套重跑；最终P30按新增來源補完整驗證。

錄影入口只在DEBUG，準備由Scene active啟動、一次性，等待／預覽兩段檢查同store／state／generation／取消。固定review配音條件只改該測試match，不改Owner持久偏好。原生build與Safety.xcresult都真實執行；Beta／Release不包含自動錄影入口，最终Beta重编译仍待。

首錄影準備在場景變化時退出，沒有成功trace，改task(id:scenePhase)並以一次性旗標避免背景回來重播。第二次Core已成功但Python monotonic與Simulator systemUptime原點不同，assert offset失敗；改同檔案系統寫入時間作近似對齊，明示非延遲量測。failed-baseline-first／failed-baseline-clock保留原錄影與來源，首／修正版build日志保留；兩次錯誤traceback在本聊天工具輸出，未冒称失敗錄影為有效基線。

下一步P28B先從已保存Mage／Rogue／Priest基線讀出具體差距，必要時加入有可辨性改善的動作候選與相同結果比較，再P29聲音材質／配音／BGM層次。iPhone仍Owner接受的1108，窗口末才交付最佳已驗候選。未Git／TestFlight發布、不改規則／費用／AI策略／其他工作樹；真機FPS、聲畫、真人品質及爐石水準未驗。
