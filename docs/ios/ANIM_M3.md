# ANIM-M3｜小尺寸法師動作與陣營標記

Owner授權：沿用M1/M2，先修底座／遮擋，再強化法師姿勢，取得同局面、同尺寸、正常速度的M2/M3原生對照。可在隔離分支提交與push，不merge、TestFlight或發布。三個人類Gate（人物完整、動作明顯、戰術清楚）仍需Owner實際判斷。

基線先按原final-source-manifest確認全數SHA相同，保存M2實作與交付於4e15078（後續記憶提交另列）。不覆寫原畫、補圖或M2影片；不改Domain、技能、AP/Mana、Bot、BoardProjection或命中。只調presentation。

已觀察：390pt實際pitch46.56，舊canvas0.70pitch=32.59pt，原畫painted寬僅約27.75pt；64px獨立近景不能代表棋盤尺寸。黑白字牌及職業徽章壓住左手／右披風。舊蓄勢杖超出canvas，出手杖靠臉，不直接放大肩角。

實作契約：英雄薄環及前外緣實心／空心形狀提示，不在人物前畫字牌；法師canvas0.92pitch、ground source448，保留完整下方手袖。小於32pt pitch省略職業徽章，帽杖輪廓＋選取資訊說明職業。主將仍皇冠、士兵不變。

姿勢先以source512座標躯幹X約+34/-38、旋轉+4/-5度，以及手杖共享x偏移試作，肩肘總角限制，披風／帽延遲約80–100ms。原950／760ms時間表保留；先無VO／無粒子對照，再驗證少量指向受術士兵的演出。不補新臉或新角色圖。

驗證：重新跑Swift Package、Golden（明確標fresh/cached C#）、native owner cancellation／資源audit、390及SE320 dense／Reduced Motion、兩次AP／Bot playback、iPad等比與命中、Release。32/48/64各黑白／原姿／蓄勢／出手 native ImageRenderer，實際像素大小不放大當正常尺寸。錄影包含召喚、無提子、有正式提子、previewcancel／undo／320dense，M2/M3同fixture比較。真機按實際在線狀態執行，不以Simulator冒充。

交付與Gate結果：artifacts/ios/anim-mage-m3/REPORT.md（完成後填）；來源及未提交物保留。禁止將程式通過或silhouette數值自動當成人類演技PASS。
