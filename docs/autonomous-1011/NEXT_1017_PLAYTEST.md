# 1017 後｜遊戲性驗收優先

日期：2026-10-11。初次規劃只核對交付、整理真人驗收與下一階段方向；後續 1018 入口／呈現缺陷修正另記於下方。未新增動畫、音檔、AI 搜尋或 3D 製作。

| 工作 | 本次處理與接續 |
|---|---|
| 穩定1017 | Source v1 ZIP SHA及現行Core／候選程式pins核對相同；iPhone實際操作顺手已記錄，保持隔離候選 |
| PLAYTEST-03 | Owner 回覆尚未試三關，隨後指出入口無法選入；1018 局部修正先處理真實入口與共用棋盤，逐關趣味仍待真人回饋 |
| BOSS-01 | Owner 已選「直接清除線上棋子，另定提子與勝負規則」；候選結算另記，先處理挑戰入口，不產生 Boss runtime |
| VOICE-01 | 沿用六句表演Brief；先驗戰士Hold the line!與法師Off you go!乾聲，聲音表演品質FAIL未解除；沒有新增朗讀版本或改現有聲音設定 |
| BOT-P3 | 仍是後期僵局根因分析方向；BOT-P2保留研究、不升預設；5.52倍為單一固定正例Mac成本，六場和局不代表整體和局率 |
| 3D-01 | 尚需身份／多視角與工作基準定案；A0及2.5D續用，本輪未開新模型 |

依賴：三關實際回饋→判定先修內容或進首領；紅龍效果定義→完整結算合約→隔離最小原型。語音用可聽見的表演驗收，不把播放器功能或音量視為自然度通過。

來源與回復：`artifacts/autonomous-1011/delivery/TacticalGo-1017-post-window-source-v1.zip`，320檔、SHA256 `021676fda6e5ae99d0f2b5ddcdbab8373af1597c89e86ffad2ab0295abc3778e`，凍結在Owner回饋前；後續文件與 1018 來源另記，不改写原封存包。

真人評估表：`docs/content-03/OWNER_PLAYTEST.md`。Boss規則審查：`docs/boss-00/BOSS01_PREFLIGHT_1017.md`。語音既有要求：`docs/ios/HERO_VOICE_PERFORMANCE_REVIEW.md`。

2026-10-11 接續：1017 的實際對戰 `⋯` 沒有戰術挑戰入口；首頁的兩個獨立 presentation／campaign state 亦在原生測試重現首次選三關卻顯示六關。先前入口說明不正確，不能當成玩家已能試玩的證據。修正及新結果見 `artifacts/challenge-fix-1018/REPORT.md`；1017 封存包不覆寫。1018 新路由只暫停目前對局演出與電腦工作，關閉挑戰後按原局狀態恢復，不重新建立棋局。
