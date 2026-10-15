# 1.1 同一手機 App 試玩整合

Owner要求「直接合併進去讓我測試」。本輪把1.1入口接到普通選角首頁，並使用手機現有 com.tacticalgo.prototype.herobody／皇冠戰略 安裝更新；不再要求切換獨立聲畫 App。只在1.1工作樹實作，不修改另一个agent的1.0上架來源或既有封存。

合約：Debug普通首頁顯示「1.1 新玩法」，點入四職/第二技能/魔物/聲畫/挑戰/候選存局；返回關閉擴充畫面，保留普通選角。原規則入口與Bot仍使用原規則，新玩法明示本機雙人；Release仍不包含候選入口。新舊存局目錄維持分離，安裝為更新而非刪除App，先備份既有Documents/Preferences。沒有修改Core規則、台詞或美術。

驗證：無launch flag的普通首頁→1.1技能試用→實際確認/Undo→返回普通首頁→開始原對戰；原召喚預覽/取消/確認/Undo回歸；現有擴充首頁/魔物/聲畫連結回歸。重新建置Simulator、Release及已簽名herobody手機App；檢查bundle/名稱/候選資源、安裝和啟動實際結果。既有235 Swift和27項原生UI是上輪證據，不重复累計；本輪只報實際新增與重跑項目。

範圍：手機測試版整合；沒有Git main合併、推送、App Store/TestFlight或公開發布。若要將dirty候選正式整合到上架分支，仍需指定目標並逐項處理差異，本輪不宣稱完成該Git操作。

結果：3項原生UI/0失敗；Simulator build-for-testing、Release和簽名手機build通過，54份聲畫資源與已接受候選byte hash相同。已更新同一皇冠戰略App至1.1/1101，安裝與啟動success，PID35893。六份既有Documents在更新後內容hash全同；Preferences備份保存，不聲稱所有設定的runtime行為驗收。無Core或聲畫素材變更，未重跑235 Swift。證據 artifacts/v11/integrated-phone-13/DELIVERY.json、Integrated-entry.xcresult、device-install.json、device-launch.json；不是公開1.1或真機錄影/真人平衡驗收。
