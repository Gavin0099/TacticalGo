# P29B候選：音效、英文台詞各自可調

原1.1設定頁只有mute／voice toggle／Reduced Motion／BGM，沒有舊模式的SFX slider。新增實際音效與英文voice音量，分別保存。未用過的偏好80%／85%與已驗P29A排程完全相同：音效依原gain×值/0.80，語音依原gain×值/0.85，单player clamp≤1；原模式CombatAudio預設65%及其key不變。

`PresentationSamples`保留每個cue的原gain，live改變群組倍率而不重新play。零值停止當前／延遲該群組並刪除其gain記錄，提高不復播；語音toggle只停voice，保留視覺／音效。下一招沒有語音時使用P29A無語音材質層次。Undo／背景／mute原有取消保持，BGM／終局樂句bus不改。新設定沒有存局規則／費用／Bot改動。

聲音sheet原生截圖有空白大標題區與多餘百分比列。候選inline cream標題及44pt完成，數字移到slider右邊。402與375pt圖已實際檢視，滑桿／語音／Reduced Motion／BGM可達，小尺寸尾段說明可捲動。root棋盤在聲音sheet返回與重開後矩形完全相同。

## 驗證

- `artifacts/v11/polish-29b/NativeDelivery.xcresult`：主4種原生方法PASS、0fail／0skip：22個真player音量檢查、既有49個音訊檢查、UI保存／重開／固定棋盤、原整合mute／Reduced Motion／背景。49及22是API檢查，不能說成71個UI tests。
- `NativeSmall.xcresult`：375pt重跑UI保存／返回同一方法1次PASS、0fail／0skip；合計5次原生執行、4種方法。非完整Swift套件重跑，P30仍需收斂當前全套／Beta。
- `integrated-volume-audit.json`全部22 PASS：獨立suite，預設不主動寫key、stage比率、live Core／inputEnd保持、零值取消、提高／啟用不復播、下一招無語音mix、偏好重建、NaN／infinity與範圍、BGM獨立、Undo／背景及DEBUG review不寫OwnerPreferences。
- `SOURCE_PIN.json`272來源在build／主小native期間未變。`CHANGE_BOUNDARY.json`：相對P29A只5個iOS／測試檔不同，Domain／Bot5檔及52份source WAV對1108雜湊不變；不把這等同最終signed素材核對，P30另做。
- 原P29A30對同響度試聽仍為預設mix參考，無新音檔／身份／timing／BGM改動，不重錄未變來源。升高個人音量未驗所有可能同時疊音，單player≤1不等於混音全局無削波。

## 可核對比較

舊P29A正常法師練習同402pt `polish-29b/baseline/settings-402.png`由實際menu操作保存（設定頁原本與1108相同，未聲稱1108重新錄影）。候選`settings-402.png`與`settings-adjusted-402.png`是最後native runner截圖，主畫面來源相同；402預設圖名字來自測試attachment，實際已受前一輪XCTest近似slider拖曳，顯示81／87／37%，不是80／85／30精確reference。比較只主張UI布局和控制增加，不以這兩張作同gain聽感比較。`settings-375.png`為fresh新key實際80／85／30%。比較素材皆Simulator，非真機。

首輪`NativeFirst.xcresult`3方法中2失敗：新增Observable didSet無條件給自己賦值，造成遞迴stack崩潰；crash與當時5個檔留在`first-source`。改為只在值需要clamp時才賦值。第一次修正`NativeFixed.xcresult`3／0PASS（21新＋49舊檢查），後續加入DEBUG review隔離與compact sheet，再由最後4＋小1驗證；不把中間通過重複加總。未使用的中間build-final只建置紀錄，交付依據為build-delivery及NativeDelivery／Small。補充CUA在XCTest後沒有iOS AX子樹，未成功操作候選menu；不用此嘗試充當驗證，候選操作證據來自原生UI runner。

## 待驗收及接續

未由代理實際聽音，不宣稱更好聽、台詞更清楚、真機AV同步或爐石品質通過。手機仍1108；此次没有安装、Git提交推送、合併或TestFlight。P30收斂整體UI／四職／魔物／solo／雙人／375pt、全套／Beta與签名來源核對；只有窗口末fresh備份後Wi-Fi更新最佳已驗同App，鎖定／離線保存包，不向Owner提問。截止UTC2026-10-14 01:54:08／台北09:54後回報一次並暫停heartbeat。
