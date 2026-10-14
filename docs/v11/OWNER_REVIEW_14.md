# 同一對戰流程：1.1／1102

結果：四職、三職第二技能、魔物/戰利、原畫演出和英文施法語音直接接入原選角與棋盤；13版的「1.1 新玩法」另頁入口已移除。軟體候選完成；手機目前離線，1102尚未安裝。

原因：Owner要求完全整合原流程，並指出牧師像魔法之手。牧師改為「奉獻」：1 AP＋2能量，移除兩格內的一顆己方普通士兵，創造氣或眼；不搬子、不補子。英雄與主將不能犧牲。舊救援紀錄仍保留原來補子的重播結果，新動作不重新解釋歷史。

下一步：手機可用時，先備份再更新同一「皇冠戰略」。現有可安裝檔已簽名：artifacts/v11/integration-14/DeviceProducts/Debug-iphoneos/TacticalGo.app；可用 scripts/install-unified-integration14.sh 接續。最新安裝檢查因unavailable未嘗試覆蓋；不能把先前1101成功安裝當成1102完成。

## 試玩

原首頁直接選戰士/法師/盜賊/牧師，開始本機對戰。原行動列包含普通技能與第二技能；點魔物可以預覽討伐，取得的黏彈/影步出現在同一行動區。保存、續玩、取消與復原沿用相同流程。魔物開啟時以9×9開局；第二技能4能量、討伐1 AP。新玩法仍是本機雙人，電腦對戰保留原三職規則。

「玩法練習」中可以直接載入三職第二技能與牧師奉獻，同樣在原棋盤操作。「牧師：奉獻救援挑戰」會重播合法開局到單眼困境，犧牲E4可形成兩眼；提示需要自己點開。敵方仍能透過移動/提子反制。奉獻遵守原本的重複盤面限制，不能任意拿回剛放的子，也不是每個位置都值得使用。

法師D/英文B與戰士英文B保持原素材；普通技能与第二技能都有成功事件演出。背景音樂保留，施法時降低音量，設定提供靜音、英文語音、減少動態及音樂音量。關閉語音仍可保留材質音效；背景/中斷/復原會停止未完成播放。

## 實際画面

以下是本輪原生Simulator截圖，不是手機錄影或重畫。

![原選角的四職](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/integration-14/unified-lobby.png)

![同一棋盤的法師第二技能](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/integration-14/native-attachments/D3F316DC-ED36-4613-A3CB-59D1870F6843.png)

![牧師奉獻後，己兵消失而沒有移到別處](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/integration-14/native-attachments/31A7EDD1-EF5C-4528-87C2-1E776A31E538.png)

## 驗證與限制

完整239 Swift/0；最終同一原生build的9項UI/0（四職召喚/奉獻、三職第二技能、魔物/戰利/續玩、音訊設定/背景取消、非法預覽、反制、舊定格存局載入、英文A/B與Foley、原召喚取消/確認/Undo）。階段6項及前輪235/27/3項不重複加總。

Simulator、Release、签名herobody1.1/1102 build與codesign通過。54份聲畫資源byte hash保持；兩份魔物PNG的原生解碼像素一致，Release均排除候選美術。原生六張操作截圖與四職首頁均已觀看，沒有發現截斷主要操作或陣營辨識；不替代真人美術、配音演技與玩法平衡驗收。手機11:37窗口後仍需按實際可用狀態回報，沒有真機聲畫錄影。本次未提交/推送/main合併或發布，另一agent的1.0上架來源/封存未改。

來源與證據：artifacts/v11/integration-14/DELIVERY.json、Native-delivery.xcresult、native-delivery-summary.json、swift-final.log、device-delivery-build.log、release-delivery-build.log、delivery-verification.log。第一次完整UI失敗与中斷、Ko不合法測試開局、空的並行xcresult摘要都保留，修正後新結果另存，沒有以失敗材料冒充通過。

先前OWNER_REVIEW_12.md六段影片屬於歷史Lab界面/後製混音；其中牧師為舊補援方案，不能當成目前奉獻技能的錄影。
