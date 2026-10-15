# P27-UI 第一輪：十小時工作仍在進行

Owner回報1108遊戲畫面與音效好很多，授權2026-10-13 15:54:08 UTC至2026-10-14 01:54:08 UTC（台北09:54）繼續聲畫優化。已更新既有heartbeat，不另建重複排程；截止後统一交付與暫停。

## 假設與觀察

1108技能牌在尚未召喚／已施法／資源不足時外觀仍接近可用牌，玩家需點進去才知道受限。此次增加鎖標記、插畫降飽和／透明度和較暗牌底，但保留名稱及費用的可讀性、可點選查看原因、選取外框與原有合法預覽。nil restriction僅表示可開始選目標，不等於有合法施法目標。英雄已離場改為不能重召的明確說明。

共享TacticalReadiness只讀已確認GameState，對全局前提給出說明，不執行行動、不推論提子或修改規則。選取、確認與目標合法性仍由Core完成。額外輸入／成功聲音、動態脈衝、引擎與職業規則未改，避免增加干擾。後續P28錄製正常速度同receipt演出，P29處理材質與混音；目前未宣稱動畫／音訊已進一步改善。

## 比較

兩輪同一testFixedPhoneBoardAcrossFourClassesModesPreviewHelpHandoffAndUndo，在同一402pt Simulator、相同合法ExpansionPractice局面／操作序列／結果。1108基準artifacts/v11/polish-27/baseline/native-402/D2007128-BC98-493D-9DA6-A2700E1AAB2E.png；新候選beta-attachments/0F2223D6-B31F-4519-B055-9CF381DA4BED.png。觀察召喚牌能與可選普通／第二技能區分，而棋盘、綠點與操作框沒有縮小；這是agent視覺比較，不是獨立reviewer或Owner驗收。

主／小手機原生畫面已檢視，包括施法後三張受限牌與375pt固定200pt操作區。缺英雄、已召喚、quota受限仍可點開原因；VO accessibilityValue同步傳達原因，未做真正VoiceOver操作验收。

## 工程與接續

完整Swift282/0，Beta3/0＋375pt小Debug2/0、0skip；四職44pt控制、固定棋盤矩形≤0.5pt，普通技能預覽／取消／Undo／續玩綠點保留。五個新readiness測試檢查資源與目標合法性分離、英雄缺席／已離場、quota及Undo、終局／AP、從合法開局討伐的隔回合解鎖。首輪付費討伐fixture已走到解鎖回合而錯誤期待鎖定，改為0AP討伐保留當回合窗口，focused5及完整282重跑PASS；swift-first失敗日誌保留。沒有更改規則去配合測試。

260份SOURCE_PIN與原生Debug參考App已保存；1108簽名包和258份基準來源完整保留。實際49audio審核是UX26來源相同的歷史結果，本輪聲音播放生命週期／音檔不變，沒有冒稱重跑。iPhone保持Owner接受的1108，最佳驗證候選在窗口末才Wi-Fi更新；當前P27沒有真機交付、TestFlight或Git發布。PROGRESS.json明確記錄窗口仍ACTIVE，下一步P28先保存相同規則演出基線再改動畫。
