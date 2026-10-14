# P28C：討伐不再沿用職業技能限制

窗口ACTIVE至台北2026-10-14 09:54:08。手機保持已接受1108，本輪候選沒有提前安裝或發布。P27／P28A／P28B成果與dirty工作保留。

## 問題與修正

正常對戰點魔物後pending已是討伐，標頭／訊息卻沿用上一張職業技能的限制。從合法開局召喚戰士，沿棋群築壘後還有1 AP、2 Mana、已施法；史萊姆四正鄰控制2：0，Core允許討伐。舊UI確認仍亮黃，標頭與訊息卻說本回合已施法。

候選以選中huntMonster的Core validate結果產生只讀TacticalHuntPreview；不用技能mode代替實際動作。標頭顯示同一已接受魔物原畫／討伐名稱，步驟顯示獎勵與下一己方回合解鎖，訊息保持「合法預覽」並列出配置AP、0 Mana與控制數。說明列出取得／使用的不同成本與quota；狼無正鄰英雄的拒絕明確說明只在場不夠。法師專屬調度錯誤翻譯限於actual castFriendlyRedeploy，不再誤翻討伐失敗。

職業技能牌仍依各自mode保持施法次數鎖記；選討伐不會把技能誤標可用。取消恢復技能限制，確認走既有Core原子結算，Undo完整恢復。無新規則／費用／AI策略／聲音或動作改動。

## 同局面比較

artifacts/v11/polish-28c/baseline保存P28B之前已建Debug App；NativeBaseline用本輪新測試runner指向這份舊App。這是前一候選與P28C比較，不冒稱重新建置1108。新標頭identifier在舊App不存在，baseline方法因此失敗；AX階層／無聲原生影片保留，影片末段抽出baseline-hunt-after-bastion.png，確認實際舊畫面矛盾。

NativeFixed的D1080CED-B8EC-4B46-9A72-66EC21796473.png與375pt NativeSmall的2858EFC7-ECF7-4AA8-A39F-CC26024914E7.png已檢視：相同控制／資源局面，候選標頭、零Mana與控制數可見，原技能鎖仍在；200pt dock、棋盤與角格矩形不變。大圖同尺寸402pt基線，375pt不把文字擠掉棋盤。說明sheet原生圖保留。這是代理畫面判讀，未由Owner或獨立真人驗收可讀性。

## 驗證／失敗保留

聚焦Content5/0：合法開局技能後付費討伐與Undo；合法0 AP免費窗口；零Mana／無英雄史萊姆；有英雄但非狼正鄰；不足控制、已移除目標與未啟用模式。預覽不改状態，費用與loot由實際Core outcome驗證。首輪Mana期待1錯誤，依開局回合補能規則修正為2，保留content-first，未改生產費用或補能來遷就fixture。

NativeFixed兩方法通過0skip；NativeSmall重跑新討伐方法通過0skip，共3次執行／2個不同方法。包含正常入口築壘後受限技能→合法討伐→說明→取消→確認→Undo，以及普通討伐／戰利使用／真正首頁續玩。首候選NativeCandidate有1pass／1fail：把訊息改成「合法討伐」破壞既有「合法預覽」回歸期待，修回共同預覽字樣後兩方法重新通過。所有失敗xcresult、錄影與source邊界保留。

SOURCE_PIN263涵蓋runtime、素材、Package／project與測試；PROGRESS保存進度。未報本輪完整Swift或Beta已重跑，原282及Motion72只是此前適用來源的證據；無真機FPS／AV同步／真人聲畫或爐石品質結論。

下一步P28D從合法開局保存史萊姆／暗影狼討伐與戰利的現行正常速度片段，檢視接觸／落定再提出有限改進。P29保留Mage D／英文B及Warrior英文B，做原始／CC0材質與配音／BGM層次比較；最终Beta、全套集成、簽名Wi-Fi交付仍留窗口收斂。
