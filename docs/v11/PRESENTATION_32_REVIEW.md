# 版本核對與第一個 UI 修正

結果：已將八項切片與1109成果對照，保留原候選並完成首個提示修正；新Simulator候選1110尚未手機交付或上傳。
原因：1106的平面面板已在後續UI20改善，應接續最新來源。獨立審查找到合法預覽後上方仍要求選點的矛盾，修正只改這一段狀態文字。
下一步：下一批先比较全盤合法點／資源框的視覺層級，並取得選角至勝負的完整含聲手機片段；基線真機Gate尚未完成，不將此小修當全部品質切片完成。

## 同條件比較

前後都是402pt、相同法師練習、相同第7回合、同資源及兩點合法預覽。頂部從「點選目標・預覽後確認」變為「合法預覽・等待確認」；底部仍是「目標已選好，按確認施放」。

[1109前圖](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/polish-30/main-attachments/4363095C-1314-41E2-ACBF-49890E9B746F.png) · [1110候選圖](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/presentation-32/main-attachments/5A608C17-3E65-4452-AFCB-9DAAA4485826.png) · [375pt候選](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/presentation-32/small-attachments/EA4DC4FD-C3AB-4A8A-A934-D52F18CA0C2D.png)

獨立只讀reviewer判斷此張402pt圖的指令階段已一致，未見可見截斷或布局退步，但頂部與技能座仍稍有重複；沒有外推全部狀態、動作或聲音品質。主agent另檢視375pt圖，新文字可見，原棋盤、技能牌與控制保留。

## 驗證與範圍

正式TacticalGoBeta、TACTICALGO_V11無DEBUG build-for-testing成功。主402兩方法、小375一方法：三次執行、兩種方法，0fail/0skip。法師回歸涵蓋未選、非法敵兵不消耗、取消、第一點選取、合法預覽不消耗、確認、Undo及保存續玩，同時核合法提示與固定棋盤；7×7 solo測試保留電腦回合/Undo流程。不是新全套300Swift，也未重測未變音訊。

相對凍結1109只改PlayableGameView狀態欄與ExpansionLabTests六個回歸assertion；SOURCE_DIFF.patch與CANDIDATE_SOURCE_PIN保存。表頭／資源／狀態／200操作區尺寸、字級、規則、Bot、Motion、WAV、角色圖片未變。新版本號1110只供Simulator區分，無新簽名包/手機/上傳；原1109development及distribution已簽包保留。

1106八圖從舊完成xcresult重新匯出，兩張已親自檢視，並非八張全部重新審查，也非真機。首次圖片讀取用了錯UUID，改以manifest實際檔名讀取；首文件寫入因編碼失敗未產生修改，改用apply_patch保存。兩者不是App失敗或測試PASS。

未完成：含聲真機片段、手機FPS/觸控/音畫物理同步、耳機實聽、真人長局疲勞、全八Slice品質驗收。PRES-00目前只有版本/來源/歷史靜態核對，不冒稱完整通過。沒有重新製作角色、轉3D、Git發布或重啟十小時排程。
