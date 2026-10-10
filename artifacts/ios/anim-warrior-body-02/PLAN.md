# ANIM-W1 戰士本體續修

Owner授權：只修戰士，本體三職均Owner通過後才VFX；英雄語音HOLD。

問題：盾牌原位置殘留邊緣，發力途中停頓；完整棋盤上不足以表現力量。

本輪：補齊原畫盾rim及整組握劍手／護腕／金色護手遮罩，收盾蓄勢→70ms停頓→一次連續下擊→雙兵同拍落定→70ms回震→收勢；登場增加身體落定／手盾跟隨。保留法師及盜賊動作，不生成新人物／3D／台詞／VFX。

驗證：原圖SHA、實際32/48/64pitch及390/7、320/9密集Renderer與原生影片；共享成功receipt、預覽／非法／取消／Undo／2AP／背景／Reduced；Swift+Golden+native UI+Release。實機可用時安裝獨立candidate，不能以Simulator影片或測試替Owner判斷氣勢。

L1：可逆presentation改動，無Domain/Bot/存檔格式/命中改動；隔離commit/push授權延續，無merge/TestFlight/發布。
