# ANIM-01R｜精修候選與回退

新增 MageArtRevision.r1；公共純 Motion API 默認仍 m3，原生對局選 r1。Debug `--mage-m3-reference` 用同 fixture／時計返回 M3；M2 歷史選項保留。不是正式素材採納。

- 蓄勢前半先收手，再帶動軀幹，握點與原圖保持。
- 揮杖峰值 torso−5°/x−44 sourcepx、held x−30、shoulder18°/elbow5°。直到實際 moveStart 保持清楚出手輪廓；M3 在這段已提早收回。
- 到位回穩：torso−3°/x−24、held x−17、shoulder12°/elbow5°。身體與手先穩定，帽延遲70ms、披風90ms，同原時計完成。
- 登場短距 −14 sourcepx 落定，持杖手於82%穩定，帽與披風最後收回；不是整張按鈕彈跳。

沒有新增 PNG、mask、補圖、粒子、語音或 BGM。其他兩職動作、身份、薄底座、棋盤投影與命中不變。

同局面正常速度影片：`artifacts/anim-01r/media/reference-with-source-03/native-full.mp4` 與 `candidate-with-source-03/native-full.mp4`，含召喚、無提子、有提子、預覽取消、復原、背景。是原始全畫面 Simulator 錄影，無聲軌，沒有重建角色幀或後製配音；兩個版本同三份Core收據、同時計，附源碼與實際執行檔SHA。若另交選段／停格，另記處理，不取代原檔。

回退只選 M3 revision，不改正式對局或聲音偏好。本輪新回歸結果另記，不能沿用歷史97/97算新 PASS。真機、人耳與 Owner 演技 Gate 仍 Pending。
