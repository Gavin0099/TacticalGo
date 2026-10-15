# iPhone 9×9 放大版：1.1（1104）

結果：手機9×9採用較大的棋盤視窗與精簡行動區，整張原畫保持比例，裁去外圍留白；所有81格、邊角點選、確認/取消/復原與法師方向選擇均保留。1104已成功上傳、Apple處理完成並加入既有Owner 1.1群組，狀態「正在測試」，可從TestFlight更新。

原因：1103把1024×1152直式棋盤塞進偏矮區域，又留出完整木框與重複技能說明，壓縮了真正可下棋的範圍。新布局將較長说明移到資訊按鈕的視窗，預覽結果及行動按鈕仍留在原對戰畫面。7×7與iPad維持原來的幾何框架。

下一步：Owner在TestFlight將皇冠戰略更新至1.1（1104），比較手機9×9是否足夠大；1103保留。真人覺得是否足夠大仍需實機試玩，不以工程PASS代替。

## 同局面比較

以下都是原生Simulator截圖。兩張法師圖都是同一合法開局、同一雙重牽引確認結果；只有畫面布局/視窗不同。

1103：

![1103法師雙重牽引](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/testflight-15/advanced-attachments/ED12ECF0-E2A0-4A46-9A3F-3BABA895A941.png)

1104：

![1104放大棋盤](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/phone-board-16/serial-attachments/1D311784-537C-4C45-9FC7-3B0E437E75E4.png)

小尺寸375pt iPhone的同一放大布局（此張為放兵預覽，非上方技能局面）：

![小尺寸iPhone](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/phone-board-16/small-attachments/3A201FD9-A3ED-4E71-A002-E9311D60379E.png)

## 驗證

視覺套件8/0（6既有＋2新增）；獨立公式檢查九行九列中心、完整觸控格/直立角色邊界、原畫比例與7×7原框不變。同一視窗focused pitch至少比原fit多19%。原生主手機serial4/0＋小手機1/0；不是五個不同測試。涵蓋四角、81格、預覽不扣資源、說明視窗保留選取、法師單推/方向/Undo、三職第二技能、魔物/戰利/續玩，以及原7×7牧師奉獻。402pt手機格點觸控框約36.67pt；375pt/短螢幕為28×28.5pt，沒有將小手機說成44pt達標。

七張當前原生圖已觀看，主手機三職與小手機的確認/取消/結束回合均完整，未發現邊緣角色裁切。簽名archive、匯出、profile/get-task-allow=false、SOURCE_PIN、54份聲畫byte與兩魔物像素核對通過。改動套件來源只有Visuals/Anim01Geometry；Core/Content/Bot/Motion/Records未變，239/0保留為14版完整Swift歷史結果，不稱全部當前重跑或累加為241。

失敗證據保留：首個角落fixture預設advanced，修正測試為先選放兵；方向按鈕原始識別是push-Right，修正測試誤用小寫；一次主手機兩runner重疊產生非正常退出，兩組排除，改由Main-serial乾淨串行結果交付。法師方向列在精簡區實作中補齊；沒有變更技能規則。詳見TEST_RUN_NOTES.md。

證據：artifacts/v11/phone-board-16/DELIVERY.json、verification.log、visual-tests.log、Main-serial.xcresult、Small-repaired.xcresult、archive.log/export.log。上傳/處理/群組分別以實際结果更新，不以本機匯出冒充TestFlight。

未動1.0agent checkout/封存/送審，未commit/push/main merge/公開發布，沒有新增角色/技能/音檔。本版只改善Owner提出的手機9×9呈現與操作空間。


## TestFlight交付

upload-20261012T030816Z上傳exit0，Apple完成處理；build ID 93af286d-5699-4d1f-add8-b51915d16764。Owner 1.1仍一位Owner，兩個build1103/1104都正在測試，手動分發，不新增其他人、不讓1103過期。1104繁中試玩內容已保存。ASC另顯示Owner先前已安裝1103/iPhone16Pro/iOS27；1104實際手機安裝與真人可讀性接受仍未核對。

![1104與1103都正在測試](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/phone-board-16/testflight1104-ready.png)

最終DELIVERY.json的uploaded/appleProcessingVerified/ownerGroupAvailabilityVerified皆true。測試只使用原生Simulator（主26.5、小18.0），不是宣稱iOS27真機驗證。SOURCE_PIN未變，不重建、重跑或重複成功上傳。
