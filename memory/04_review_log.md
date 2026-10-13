# Review Log

## Entries

- Append review summaries and validation history here.

<!-- memory_record_projection:review-log:0fb5fcd7920a6537d581c7871a770e8287dc480aabb1239234822e8743ed9fc8 -->
### Canonical memory checkpoint — cli-20261012-025229

- Writer: `governance_tools.memory_record`
- Record identity: `0fb5fcd7920a6537d581c7871a770e8287dc480aabb1239234822e8743ed9fc8`
- Commit binding: `cdab133` (bound)
- Record: 完成既定1.1候選與來源/像素/Release/簽名安裝驗證、14有效原生姿勢圖及6實際原生無聲錄影/明示後製混音；保留MageD/MageB/WarB。發現啟动過早截圖為白圖，以及初始scene(false)取消誤清定格收據，將不可變reviewReceipt與正常可取消播放分開；從定格載入存局未解除reviewTime/reviewFixture會鎖住棋盤與保存，驗證成功後清除檢查旗標。兩項修復有新原生回歸，最終Expansion8/0；兩組無效圖和失敗測試/路徑驗證都保留。Xcode CgBI編譯PNG檔案SHA會變，透過ImageIO相同sRGB預乘RGBA核對可見像素並保留兩種檔案SHA。
- Validation boundary: artifacts/v11/feel-10/delivery-evidence-receipt.json
- Next action: 既定範圍工程完成不擴大功能；截止前不問Owner、不重复未變來源的測試/安裝。2026-10-12 11:37:48台北後依OWNER_REVIEW_12.md及delivery receipt回報一次，若裝置可用可嘗試一次既有授權的presentationlab啟動，再暫停tacticalgo-1-1 heartbeat。本機雙人、原Bot拒收擴充；真人美術/聲音/玩法/平衡/素材採用與真機AV錄影未驗收。不commit/push/merge/發布。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:8b864b59d3b4809eda98d28ba213c46add903ad1e7acffa5175176799eba4158 -->
### Canonical memory checkpoint — cli-20261012-083221

- Writer: `governance_tools.memory_record`
- Record identity: `8b864b59d3b4809eda98d28ba213c46add903ad1e7acffa5175176799eba4158`
- Commit binding: `cdab133` (bound)
- Record: Owner要求幫我安裝；現有presentationlab簽名驗證通過，配對iPhone16Pro安裝與devicectl啟動success，PID35718。前次Locked啟動保留為歷史，当前成功啟動不證明真機音畫品質或真人驗收。未改程式、未重建/重跑235與27測試、未動普通1.0，未commit/push/merge/發布。更新三份計畫與OWNER_REVIEW實際啟動狀態。
- Validation boundary: artifacts/v11/feel-10/device-install-owner-20261012-0031.json; artifacts/v11/feel-10/device-launch-owner-20261012-0031.json; codesign --verify --deep --strict exit0
- Next action: Owner可直接試玩TacticalGo聲畫；既定十小時窗口截止後统一回報實際交付及待驗收項目並暫停heartbeat，無需再重複安裝或啟動。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:b17821eddafa812c84dde84f5f00710fffdc4c6377186d35c931e65ded8befe2 -->
### Canonical memory checkpoint — cli-20261012-084709

- Writer: `governance_tools.memory_record`
- Record identity: `b17821eddafa812c84dde84f5f00710fffdc4c6377186d35c931e65ded8befe2`
- Commit binding: `cdab133` (bound)
- Record: 普通PlayableGameView Debug首頁新增openExpansion，fullScreenCover開V11Home並可返回；新端到端UI驗證普通root→擴充mage預覽确认Undo→回普通對戰。3UI/0、Simulator/Release/簽名build、codesign通過。用既有herobody更新手機皇冠戰略1.1/1101，install/launch成功PID35893。先備份Documents/Preferences，六份Documents更新後hash相同，54聲畫資源不變。手機整合不是Gitmain合併；保留1.0上架來源封存，不commit/push/發布，不宣稱完整設定行為/真人聲畫/平衡通過。
- Validation boundary: artifacts/v11/integrated-phone-13/DELIVERY.json; Integrated-entry.xcresult:3/0; build-check.json; device-install.json success; device-launch.json success; unchanged Documents6, voice/VFX assets54; earlier235 Swift not rerun
- Next action: Owner開皇冠戰略→1.1新玩法試玩，返回首頁可原規則；窗口截止後统一回報實際驗證與待驗收，暫停heartbeat，不重複安裝或啟動。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:25b40b6601064e1ac05bcb53fb10e2deeebe444dd371ebe8173c4a7d066962b2 -->
### Canonical memory checkpoint — cli-20261012-092258

- Writer: `governance_tools.memory_record`
- Record identity: `25b40b6601064e1ac05bcb53fb10e2deeebe444dd371ebe8173c4a7d066962b2`
- Commit binding: `cdab133` (bound)
- Record: 完全接入PlayableGameView選角/行動/棋盤/存局續玩，GameStore路由唯一當前session；原Bot仍三職原規則。新castOffering1AP2Mana只犧牲兩格內己兵，舊Sanctuary保留重播，新增失敗/Ko/Undo/舊紀錄相容性測試。239Swift/0，原生六項階段PASS，正跑九項final。修AX識別污染與直接棋盤選點預覽訊息；修正Mute thumb試法及Priest測試Ko開局，不繞過Ko。Simulator/Release/已簽名herobody1102 build PASS，手機unavailable，備份失敗而未安裝。未commit/push/main合併或發布，未動1.0agent來源。
- Validation boundary: artifacts/v11/integration-14/swift-final.log:239/0; native-ready-summary.json:6/0; Native-delivery.xcresult RUNNING; device-delivery-build.log/release-delivery-build.log/simulator-delivery.log PASS; devices-ready.json unavailable; first failed xcresults retained
- Next action: 待Native-delivery完成後核對結果/原生畫面/素材/簽名；用scripts/install-unified-integration14.sh在手機可用時備份再更新1102，不等待Owner、不假稱已安裝；完成後保留候選，窗口截止統一回報並暫停heartbeat。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:e0a0ee604fc0741694a265d1ca0c2d84d608d7c73b7bdf62b6218059ab339a22 -->
### Canonical memory checkpoint — cli-20261012-093310

- Writer: `governance_tools.memory_record`
- Record identity: `e0a0ee604fc0741694a265d1ca0c2d84d608d7c73b7bdf62b6218059ab339a22`
- Commit binding: `cdab133` (bound)
- Record: 14版原界面整合驗證完成；GameStore路由唯一目前session，選角四職與原行動列/棋盤/存局續玩接上ExpansionPresentation，原三職Bot保留，背景音樂及施法ducking/復原狀態接回。castOffering1AP2Mana移除兩格內己方兵無補子；舊castSanctuary重播仍補援，相容性/Ko/扣費/非法/Undo均有獨立測試。239Swift/0；Native-delivery9/0，階段6不累加；54資源byte同、魔物ImageIO像素同，七圖已目視。Simulator/Release/签名herobody1102/codesignPASS，手機unavailable安裝未嘗試。保留AX識別污染、選點缺預覽訊息、测试thumb未切換、Ko開局不合法及并行xcresult摘要競爭等失败；實際修复/新验证另存。未碰1.0agent工作樹封存，未commit/push/main合併或發布。
- Validation boundary: artifacts/v11/integration-14/DELIVERY.json:software_verified_phone_pending; swift-final.log239/0; Native-delivery.xcresult and native-delivery-summary.json9/0; build logs/codesign/delivery-verification.log; install-20261012T012446Z/devices.json unavailable; unified-lobby.png +6 native screenshots; source/audio/art pins preserved
- Next action: 手機可用時bash scripts/install-unified-integration14.sh先備份再更新，然後python3 scripts/verify-unified-integration14.py刷新實際安裝結果並寫milestone；已成功則不重複。離線/鎖定保存签名結果，不等Owner。OWNER_REVIEW_14.md為最新同流程與新奉獻說明，12版影片為歷史。截止台北11:37:48統一回報工程實際交付及真人待驗收/本機雙人/真機AV缺口，暫停heartbeat。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:498d05845f5a9b9998c3020975851d7e043b9462b1bf2e7fa8d1d96e41e5fedf -->
### Canonical memory checkpoint — cli-20261012-095313

- Writer: `governance_tools.memory_record`
- Record identity: `498d05845f5a9b9998c3020975851d7e043b9462b1bf2e7fa8d1d96e41e5fedf`
- Commit binding: `cdab133` (bound)
- Record: Owner授權1.1 TestFlight。Beta15原選角/棋盤完整功能已簽名herobody1.1/1103 archive/IPA，54聲畫及兩魔物核對、2+1 Beta UI通過；核心239套件來源未變。上傳實際exit70 Failed to Use Accounts，Xcode無登入，未上傳/未處理/未入Owner群組。簽名包及續傳腳本/源固定保存，1.0工作樹送審未動。
- Validation boundary: artifacts/v11/testflight-15/DELIVERY.json；Beta-native2/0與Beta-advanced1/0；archive-distribution/export-distribution/codesign/assetsPASS；upload.log exit70 Failed to Use Accounts；來源與14版239收據比較一致。
- Next action: Owner在Xcode Apple Accounts登入完成後，執行upload-testflight15.sh續傳；上傳成功後查既有App6821588889內部群組與Apple處理，不重複已通過測試或宣稱已可下載。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:724db7b497609fc5b0e3bde880671385bc28914b4f3b1d88adb98a61796158b3 -->
### Canonical memory checkpoint — cli-20261012-102911

- Writer: `governance_tools.memory_record`
- Record identity: `724db7b497609fc5b0e3bde880671385bc28914b4f3b1d88adb98a61796158b3`
- Commit binding: `cdab133` (bound)
- Record: Owner回覆登入後確認ASC網頁成功，但Xcode帳戶仍空；1103續傳exit70 Failed to Use Accounts保留。已開Xcode登入sheet。ASC無內部群組，建立手動分發Owner 1.1，只加入現有Owner帳號持有人一名；UI確認1人0build沒有可用版本，未加入1025/外部人員或啟用自動分發。簽名包與來源未改。
- Validation boundary: artifacts/v11/testflight-15/upload-20261012T022448Z/upload.log exit70；ASC_GROUP.json與owner-group-created.png；xcode-signin-open.png；verification.log保留3Beta UI/239來源未變與簽名素材PASS。
- Next action: Owner完成Xcode登入後用upload-testflight15.sh續傳，查Apple處理與1103加入Owner 1.1群組；勿重建/重跑來源未變驗證，勿宣稱可下载。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:22add944a06eb57274c3628ce0f20588d527e7e666087810c4574e37933c0f28 -->
### Canonical memory checkpoint — cli-20261012-104042

- Writer: `governance_tools.memory_record`
- Record identity: `22add944a06eb57274c3628ce0f20588d527e7e666087810c4574e37933c0f28`
- Commit binding: `cdab133` (bound)
- Record: Xcode登入後1.1/1103上傳exit0成功，Apple處理完成；Owner 1.1內部群組1人1build正在測試，Owner已邀請，1103繁中試玩說明已保存。DELIVERY三项uploaded/processing/group均true。修正上傳成功字串解析並執行失敗/本機export/成功三fixture，沒有再次上傳。工程來源/驗證未變，未動1.0送審或Git發布。
- Validation boundary: artifacts/v11/testflight-15/DELIVERY.json；upload-20261012T023102Z/upload.log與exit-code0；ASC_BUILD.json/ASC_GROUP.json/testflight1103-ready.png/owner-invited.png；verification.log簽名54素材2魔物3BetaUI與239來源未變PASS。
- Next action: Owner透過Apple邀請信開TestFlight接受並安裝皇冠戰略1.1/1103，從本機雙人/玩法練習驗收；不宣稱手機安裝/真人品質已通過。不重複已完成交付或擴展功能，11:37:48台北後原定整理與暫停heartbeat。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:126b6523a744841d8addc37ccf27a9e45ebadd64eb8cb1dd48ef425d3a97c197 -->
### Canonical memory checkpoint — cli-20261012-110950

- Writer: `governance_tools.memory_record`
- Record identity: `126b6523a744841d8addc37ccf27a9e45ebadd64eb8cb1dd48ef425d3a97c197`
- Commit binding: `cdab133` (bound)
- Record: Owner回饋9x9手機太小；16版focused原画视窗與精簡控制區保留81格/法師方向/說明與復原，7x7/iPad原框不變。Visual8、main serial4、small1均通過，七張圖已看；1104簽名匯出/54聲畫2魔物固定驗證PASS，上傳中，未宣稱可下載。此前測試fixture錯誤與主runner重疊排除保留。Core規則來源未變，未動1.0送審/Git發布。
- Validation boundary: artifacts/v11/phone-board-16/DELIVERY.json/verification.log/visual-tests8/0/main-serial4/0/small-repaired1/0；source/archive/signature/assetsPASS；TEST_RUN_NOTES.md排除先前失敗/重疊結果。
- Next action: 等待1104上傳，查Apple處理並加到既有Owner1.1；保留1103比較、不重複成功上傳。Owner實機驗收9x9是否足夠大；截止後不新增實作。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:5f821450e1d852039a1de653768a04aa5ebf616c729e6a7bffc5812086a6e489 -->
### Canonical memory checkpoint — cli-20261012-112249

- Writer: `governance_tools.memory_record`
- Record identity: `5f821450e1d852039a1de653768a04aa5ebf616c729e6a7bffc5812086a6e489`
- Commit binding: `cdab133` (bound)
- Record: 手機9x9放大版1104上傳exit0、Apple處理完成並入既有Owner1.1一人群組，1103/1104均正在測試；1104說明已保存。Visual8/main serial4/small1與簽名54素材兩魔物源固定PASS。ASC顯示Owner已装1103於16Pro/iOS27，1104真机安装/真人大小验收未核。未動1.0送審/Git發布，先前失敗排除並保留。
- Validation boundary: phone-board-16/DELIVERY.json；upload-20261012T030816Z exit0；ASC_BUILD/GROUP與testflight1104-ready.png；Visual8/0、Main-serial4/0、Small-repaired1/0；SCREEN_METRICS/main36.67pt/small28x28.5pt；verification/signature/assets/sourcePASS。
- Next action: Owner在TestFlight更新1104比較手機9x9與觸控；1103保留。候選交付完成，不擴scope/重跑/重複成功上傳；截止後整理並暫停heartbeat，真人驗收獨立。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:01e3ea4920174223e2b35bcf238f115c216ed900ae9b1c9c678604fc3045ef58 -->
### Canonical memory checkpoint — cli-20261012-115622

- Writer: `governance_tools.memory_record`
- Record identity: `01e3ea4920174223e2b35bcf238f115c216ed900ae9b1c9c678604fc3045ef58`
- Commit binding: `cdab133` (bound)
- Record: Owner新回饋solo舊規則/舊棋盤，已接共用1.1四職技能英文聲畫並移除大廳版別切換，加入Bot魔物/第二技能評估與solo存局控制metadata；戰士新增蓄勢快速下擊60ms停留。十小時heartbeat已暫停，新授權修正進行中。
- Validation boundary: artifacts/v11/solo-17/swift-delivery.log:250/0；階段Beta-main4/0，finalBeta正在跑；Debug共用ios/Build DB lock失敗保留，串行重跑待完成。
- Next action: 完成最終Beta6和Debug安全2，簽名1105、核對來源素材、TestFlight內部Owner更新；勿宣稱真人已驗收。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:e1e674302f70b96e10bfdeb043b2d53f70e22571667ac14f982e53e912b81695 -->
### Canonical memory checkpoint — cli-20261012-121219

- Writer: `governance_tools.memory_record`
- Record identity: `e1e674302f70b96e10bfdeb043b2d53f70e22571667ac14f982e53e912b81695`
- Commit binding: `cdab133` (bound)
- Record: 17完整solo1.1整合與戰士重量候選1105已簽名並實際TestFlight上傳exit0，Apple處理/Owner群組分發仍待核對。
- Validation boundary: Swift完整250/0；Beta-final6/0；Debug-final2/0且0skip；簽名/源固定/54素材與1104+IPA一致/2魔物像素PASS；actualupload20261012T040821Z exit0；正常速度原生Simulator戰士前後receipt完全相同，無實機AV/真人品質claim。
- Next action: 網頁核對1105處理完成，加既有Owner1.1并保存試玩說明；不重傳成功包或修改1.0送審/Git。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:4318a3d829d93052da4c5c8fbbf0f5a1f11af5ee17ea49b88706f709026c70c9 -->
### Canonical memory checkpoint — cli-20261012-122052

- Writer: `governance_tools.memory_record`
- Record identity: `4318a3d829d93052da4c5c8fbbf0f5a1f11af5ee17ea49b88706f709026c70c9`
- Commit binding: `cdab133` (bound)
- Record: 1105已TestFlight上傳、Apple處理完成並加入既有Owner1.1內部群組；1人/1103、1104、1105三build正在測試。solo1.1與戰士重量可逆候選交付完成，沒有Git/main/AppReview動作。
- Validation boundary: Swift250/0、Beta-final6/0、Debug-final2/0零skip；最終源固定/分發签名/54素材對1104+archive+IPA一致/2魔物像素PASS；upload exit0、ASC_BUILD處理true及ASC_GROUP1105可測true；兩原生Simulator正常速度無聲動畫receipt相同，不宣稱1105真機或真人通過。
- Next action: Owner更新TestFlight1105新開電腦對戰，驗收AI、技能取捨、畫面與戰士重量；不要自行重傳/擴scope。舊heartbeat已暫停。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:7a7e032d6630b69a611f4f82bc34e62ece6f1215231cd2fe37bb58adbf30e75a -->
### Canonical memory checkpoint — cli-20261012-132558

- Writer: `governance_tools.memory_record`
- Record identity: `7a7e032d6630b69a611f4f82bc34e62ece6f1215231cd2fe37bb58adbf30e75a`
- Commit binding: `cdab133` (bound)
- Record: 18：Owner退回1105外層與棋盤跳動；根因phone9限定compact/盤高依角色技能戰利文字AI終局動態。viewport-only固定header/HUD/status/controls，phone7/9暖色桌遊與矩形行動，新7減圖外垂直留白。規則AI存局動畫54素材對1105未改；1106簽名archive/internal-only IPA，上傳進行中。
- Validation boundary: artifacts/v11/interface-18：Visual10/0；Beta-main5/0＋Debug-small3/0，0skip，8次執行7種方法，矩形比較≤0.5pt含375pt牧師/AI法師prepare+landing/terminal。archive/export與54素材/2怪像素來源簽名PASS；250全Swift為1105歷史證據。本輪失敗build-first保留修復。
- Next action: 實際成功後核對Apple處理與既有Owner1.1，只加1106保留1103/4/5，保存網站證據與DELIVERY；未證真機或真人style，不擴scope或重傳成功包。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:da9ea28c4e7a7766cbd9a583f6952341e53b2b121c10b2c3eec56308252e2d8e -->
### Canonical memory checkpoint — cli-20261012-133253

- Writer: `governance_tools.memory_record`
- Record identity: `da9ea28c4e7a7766cbd9a583f6952341e53b2b121c10b2c3eec56308252e2d8e`
- Commit binding: `cdab133` (bound)
- Record: 18完成：同一暖色桌遊UI、矩形控制與phone7/9 viewport-only固定槽。1106於13:26:39台北upload exit0，Apple處理完成581377ae-1551-4eda-9d3f-70404643ffe3；繁中說明保存，只加Owner1.1，1人4build正在測試，1103/4/5保留。SOURCE_PIN與最終DELIVERY三項true、54素材2怪簽名驗證；原根因動態分配/phone9限定已修。
- Validation boundary: artifacts/v11/interface-18/DELIVERY.json、ASC_BUILD.json、ASC_GROUP.json、testflight1106-ready.png；Visual10/0、Beta-main5/0、Debug-small3/0且0skip，8次執行7種方法，四職/技能/preview/cancel/AI準備落定/終局/Undo/loot/resume矩形≤0.5pt。Core/Bot/Motion/Records/Content源對1105不變，250全Swift是歷史結果；源固定/簽名54素材2怪PASS；失敗build-first保留。
- Next action: Owner從TestFlight更新1.1/1106，新開牧師對法師7x7並試9x9，驗收新外觀/觸控與棋盤穩定。工程完成停止擴scope/重傳，無1106真機安裝或真人接受證據；1.0及Git發布未動，heartbeat保持暫停。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:3117f94ef273e311e3170c135471c94985c8cd21f784819a8ef655cfe8aa01af -->
### Canonical memory checkpoint — cli-20261013-123228

- Writer: `governance_tools.memory_record`
- Record identity: `3117f94ef273e311e3170c135471c94985c8cd21f784819a8ef655cfe8aa01af`
- Commit binding: `e25b2d8fcd7e6ea3122c6957a1198a587b290bb5` (bound)
- Record: Owner先推上去授權commit/push；1106完整來源e25b2d8已推至origin/codex/v11-monster-battlefield，git ls-remote一致。517檔含code/tests/素材/來源權利/docs/精簡證據，9.6GB本機建置封存/簽名/帳戶裝置日志排除，保留本機。main仍cdab133，沒有PR/main merge/App Review或公開發布，另一1.0 checkout未改。
- Validation boundary: artifacts/v11/git-review/VALIDATION.json與clean-source-swift.log：待提交index乾淨匯出Swift252/0、unsigned Simulator Beta1106 build成功、54素材byte一致和兩怪存在；interface18源pin未變，既有Beta5/Debug3不重跑。staged code/docs/scripts/memory whitespace PASS，簡式私鑰/token/簽名檔掃描無命中；third-party raw CRLF留原bytes。
- Next action: Git推送請求完成，保持1106 TestFlight與paused heartbeat；Owner可檢視分支/試玩，新slice另依Owner指示，不擴scope或自行main merge。真人外觀/聲畫/玩法與真機1106接受仍待。
- PLAN reconciliation: `updated`
