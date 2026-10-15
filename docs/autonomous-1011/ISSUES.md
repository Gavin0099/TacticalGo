# 疑慮與修復紀錄

- 所有疑慮先留在此檔，自主窗口內不向Owner提問；停止條件只限制受影響Slice，其他工作繼續。第55回合策略價值未判定沿用HOLD，不把探針當停滯修復。BOSS／3D／真人與演技選擇於截止後集中交付。

- CONTENT探針：兩口氣不能直接推論下回合會被提。原始盜賊草案產生兩個對手不能合法填入的內部空點；已保留失敗測試，改為真實的「多用回合省Mana／施法省AP」取捨，不把安全兩氣說成必死。

- iPad 旋轉驗證：初次標籤的點擊區不足 44pt，已改為 label 內部設定。後续 accessibility frame 在旋轉轉場中短暫縮為約36pt，測試改在原生旋轉完成後檢查；保留前三次失敗。第04次行為通過但截圖仍拍到過渡中的黑邊／裁切，因此追加只等待旋轉穩定的第05次，視覺結果仍需檢查。
- BOT-P2：最初 oracle 正向控制使用開放棋盤，完整敵方回合加逐一勝利見證耗盡6000預算，正確退回Pass。改用獨立封閉棋串的全部完整合法敵方回合，驗證成功分支；此測試注入Pass，不證明真正baseline曾無必要等待。
- C#/Swift fresh parity 初次因本機SDK8不支援net9而失敗。改用臨時隔離SDK9、核對官方SHA512，不改target或全域SDK；重跑結果另記。

- 原生回歸早期挑到要求語音開啟的舊案例。本輪審查語音關閉，保留失敗，不為過測試開語音；另測四組實際黑白施法者／目標的無語音案例。
- 一次Xcode建置同時占用共享build.db而失敗；之後原生建置依序執行。iPad helper缺return的編譯失敗及修後結果均保留。
- 舊背景換手案例查找1014已隱藏的重複playMessage；改查實際常駐人類回合HUD且沒有過期Bot文字，再重新通過，不增加假的產品控制項。
- 續攻probe曾讀Core內部history.count而不能編譯；改以完整合法來源與GameState獨立重播一致性驗證，沒有擴Core公開API。遠端召喚C1草案不合法，改先合法落B1連接，再召喚C1。
- 早期六場對局metadata誤稱外部100回合截斷；實際是既有Core maxPlies結算Drawn。保留原檔，另附更正；最新Release04重新跑六场并使用正確scope。
- 新的直接壓力／英雄行動篩選讓安靜準備fixture不再進入續攻，舊tiny-budget案例因此未觸發預算耗盡而失敗。改用獨立已知有效的完整反制fixture測預算不足，保留04失敗與05四項通過；不因篩選宣稱安靜計畫無價值。
- 檢查到提示可在immutable controller發布前被更新而後覆蓋；現在busy期間停用／守衛提示，跨提交、實際反擊与重啟提示保存回歸通過。從選關恢復敵方回合也傳入現有Reduced Motion值，不假設false。
- 第一份scope稽核誤把baseline的source人類標籤當檔案路徑，得到282個假輸入差異；02原結果保留，03改用明確1014來源根目錄，實際輸入檔全相同，Core／音訊／mask沒有改動。
- Debug Simulator Info沒有版本欄位，錄影改用實際執行檔SHA与完整源碼清單識別，沒有捏造build1014。未簽名Release最後以實際1014交付bundle/version族建置1015，第一份通用建置只保留編譯證據；沒有安裝設備或覆蓋現行版。
- 整理驗證index時，初稿把targets-native-03誤列最新通過；該包實際是build.db鎖定、0 tests。四組無語音案例先前通過在shared-regression-01的個別測試內，該整包仍有另一個語音案例失敗。保留index初次assert失敗；針對現行來源順序執行單一四組案例為04，取得独立新結果，不以整包失敗中的7項偷稱全部PASS。
- canonical memory writer從既有外部framework模組執行兩次，沒有直接改memory Markdown。第二次guard可執行且B0 blocker=0／completion_claim_allowed=true；同時仍提示repo-local writer／guard path缺失、missing_canonical_memory=2、test_evidence_provenance_not_found=7。保留原始輸出，不把零blocker說成全部既有記憶或治理已完整正規化；治理安裝與更新不在本輪五Slice範圍。
