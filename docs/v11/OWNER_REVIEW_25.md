# 原生整理與Wi-Fi iPhone候選1107

結果：最新UI20/AV21–24來源已在Mac編譯與回歸，1107已透過Wi-Fi安裝並啟動；Owner提出提示與基本技能設定問題，接續UX26。
原因：Windows候選需原生整合，已修圖集跨卡誤點、說明觸控範圍與小螢幕聲音設定返回。
下一步：UX26恢復合法落點、增加操作步驟與限制說明，預設沿棋群築壘及調度己兵，交付1108。

## 此版包含

同一正常大廳/solo/雙人/魔物1.1玩法；UI20手繪操作框、技能圖示、能量寶石；四職原畫演出與AV24接觸材料，盜賊兩段命中聲，奉獻供體消散；AV23落定後恢復操作，已提交英文配音可自然收尾，音樂duck仍涵蓋配音。保留選定原圖/法師英文B/戰士英文B，不改规则/費用/AI/存局。

原生修正：圖集只作裝飾、不收觸控，卡片只在自身可見框接收點擊；技能說明44×44；聲音設定完成明確關閉父sheet、Done44pt。固定200pt操作區、棋盤尺寸與角落格點仍受回歸保護。戰利能力從可見戰利按鈕展開。

## 驗證與界線

新來源Swift269/0，Debug/Beta build與實際audio audit1/0。修正後7種Beta與3種小Debug方法通過（分批，非單一全passrun）：Beta-fixed6pass+lootfocused1pass；Debug-small2pass+soundfocused1pass，均0skip。首輪失敗、舊標題/assert與Debug-only flags錯用Beta均留存並明列TEST_RUN_NOTES，不把失敗batch冒稱全部通過。

完整269和audio1在UI修正前執行；套件與音訊源未改，保留來源相同的證據。簽名手機1107重新編譯最終UI；CLI覆寫build1107，Git專案Beta仍1106，這不是新的TestFlight上傳。iPad/VoiceOver/DynamicType/FPS、真機聲畫同步與90%品質目標仍未驗收。當前修改保留本工作樹，不自行push/main merge/另開玩法。

## 目前原生畫面

![法師UI20與技能卡](../../artifacts/v11/native-25/beta-attachments/1D76382D-8050-45E7-B302-F3F2C5EA1398.png)

手機Documents7份與Preferences5份已先備份於本機；安裝後全部既有Documents雜湊與偏好值不變。安裝、啟動及裝置App資訊確認1.1/1107，證據在artifacts/v11/native-25/wifi-install/RESULT.json。私人資料、簽名包與大份暫存只留本機。Owner未接受1107的操作引導與舊基本技能，不能把工程驗證當成真人驗收。
