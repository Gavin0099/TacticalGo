# 1.1（1103）TestFlight 可測試

結果：完整整合版1.1（1103）已成功上傳、Apple處理完成，加入Owner 1.1內部群組，狀態為「正在測試」。Owner帳號顯示「已邀請」，群組只有Owner一人與1103一個build。

原因：Owner完成Xcode登入後，續傳exit0，Apple回傳Upload succeeded並進入處理。原先瀏覽器登入不等於Xcode上傳帳戶，兩次帳戶錯誤保留，未重複成功上傳。

下一步：在iPhone開啟Apple的TestFlight邀請信，使用View in TestFlight接受並安裝「皇冠戰略」1.1（1103）；若已接受則在TestFlight更新。請先從本機雙人/玩法練習試玩。這是TestFlight已分發，不是手機已實際安裝或真人驗收通過。

![TestFlight 1103正在測試](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/testflight-15/testflight1103-ready.png)

## 測試內容

沿用原選角/棋盤的四職、三職第二技能、兩種魔物與戰利、牧師奉獻（只犧牲己兵）、英文語音和動畫、保存/續玩/復原。法師D/英文B與戰士英文B維持原檔。新玩法目前本機雙人；Bot仍原三職規則。本輪只打包給 Owner 測試，沒有新增玩法或替代真人美術/配音/平衡驗收。

專用 Beta 組態使用 `TACTICALGO_V11`，App以Release最佳化編譯，含54份既有Presentation素材及兩隻魔物；沒有開啟DEBUG根頁路由或啟動測試注入。TestFlight internal-only 匯出，不能被本封存用於公開App Store或外部群組。原Release組態和另一agent的1.0上架來源/封存/送審版本未改。

## 驗證

- 最終簽名archive、IPA匯出、deep/strict codesign、1.1/1103/bundle/icon、get-task-allow=false與本機設定/動畫計時隱私manifest通過。
- Beta原生2項（牧師預覽/取消/奉獻/Undo；魔物/戰利/續玩/Undo）＋1項（三職第二技能）均通過，完全由原首頁及玩法練習操作，不靠DEBUG測試入口；五张原生截圖已實際觀看。
- Core/Content/Bot/Motion/Records的Swift来源與14版239/0收據逐檔一致，沿用既有結果、不重複測試或累加。
- 54份聲畫byte與原素材一致；兩隻魔物封存像素與來源一致。AppIcon/Privacy manifest由已上傳1025來源只讀複製，未動1.0checkout。源檔/組態固定於SOURCE_PIN.json，變動會擋下續傳，避免過期包和新程式混用。
- 第一次Beta封存發現Lab共用音訊read-only計數仍在DEBUG下，修正後封存通過。第一次原生selector誤拼，實際只跑兩項；第三項另跑並各自記錄，不冒充同輪三項。所有失敗/階段封存保留。

完整證據 `artifacts/v11/testflight-15/DELIVERY.json`、`verification.log`、`archive-distribution.log`、`export-distribution.log`、`upload.log`、`Beta-native.xcresult`與`Beta-advanced.xcresult`。

![Xcode尚未登入Apple帳戶](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/testflight-15/xcode-account-required.png)

沒有commit/push/Git main merge、1.0送審修改、公開發行或任意測試者邀請。上傳成功、Apple處理完成、Owner群組可測試三項均已獨立核對；手機安裝/真人品質驗收仍需Owner操作。


## 10:28 登入界線與Owner群組

Owner回覆登入後，已確認瀏覽器ASC登入成功；但Xcode Apple Accounts仍無帳戶，續傳實際exit70 Failed to Use Accounts（upload-20261012T022448Z保留）。已開Xcode Sign in to your Apple Account視窗，請Owner完成這個視窗而非重登網頁。無密碼/驗證碼寫入聊天、記錄或腳本。

ASC尚無內部群組，已按Owner自測目的建立手動分發「Owner 1.1」，group ID d4c66485-705a-45b7-8e5f-9aaf5bbefe54，僅加入既有帳號持有人一名。建立時明確關閉無法事後變更的自動分發，沒有外部測試者或公開連結，也沒有加入1.0/1025。UI確認1名/0個build，狀態為沒有可用的建置版本。這不是1103上傳/可下載證據；待Xcode完成登入續傳並處理後只把1103加入此群組。證據ASC_GROUP.json、owner-group-created.png、xcode-signin-open.png。工程/素材/規則未變，無重建/重跑通過测试。

![Xcode登入視窗](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/testflight-15/xcode-signin-open.png)

![Owner群組目前尚無建置版本](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/testflight-15/owner-group-created.png)


## 10:39 交付核對

成功上傳upload-20261012T023102Z/exit-code.txt為0，upload.log含Upload succeeded、Uploaded TacticalGoBeta與EXPORT SUCCEEDED。腳本最初只找UPLOAD SUCCEEDED字串，漏辨小寫成功訊息；已修正並執行三個獨立fixture（真實帳戶失敗→false、本機export→false、真實upload→true），未再次上傳。沒有把本機export當成上傳。

ASC build ID 8549d8db-ff8a-4692-9a3d-35c862638766 已處理，版本1.1/1103/內部、正在測試、Owner 1.1群組1名；已保存此build繁中試玩說明。Owner測試資格顯示已邀請（2026-10-12）。群組Builds表確認只有1103，沒有加入1025/外部使用者，也沒有動1.0送審。最終DELIVERY.json的uploaded、appleProcessingVerified、ownerGroupAvailabilityVerified均為true；actual phone install/human quality acceptance仍false。完成此上傳請求，不擴展新實作。
