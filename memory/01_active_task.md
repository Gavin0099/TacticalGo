# Active Task

## Current Status

- Adopted governance baseline (2026-10-08, `adopt_governance.py`, copy-based = audit-only class).
- Tech route chosen: iOS native Swift/SwiftUI (`docs/TECH_DECISION.md`).
- Rules Draft v0.2 (Owner decisions 2026-10-08, see `docs/DECISIONS.md`): first-turn 1 AP default (2 AP baseline kept), no hero resummon, hero summoned next to any friendly piece.
- C# reference engine + 3 skills; 75 tests pass incl. 23 hand-authored golden fixtures in `tests/golden` (shared with the future Swift package).
- S0 AP probe in `docs/S0_AP_GATE.md` (heuristic bots only, not a balance sign-off).
- UI-1 delivered (commit cdf2bf9): Windows WinForms board `src/TacticalGo.Play` over the C# engine (see `docs/ui/UI1_README.md`); isolated `TacticalGo.Windows.sln`. Awaiting Owner hands-on check before UI-2.
- Next gate: `docs/NEXT_GATE.md` — do classes change board strategy? Order: UI-1 -> UI-2 (three classes) -> PLAY-1 (fixed positions) -> PLAY-2 (human playtest); bots paused.

## Next Steps

- Owner tries UI-1 and reports feel/clarity problems; then decide UI-2 details (hero summon, skill select with legal targets, reasons and expected effect shown after selection, not hover).
- Before any push of the public repo: resolve `governance/MEMORY_PROTOCOL.md` (framework working tree has an uncommitted edit that was copied) and add Apache-2.0 attribution for copied framework files.
- Owner reviews the remaining pending items in `docs/RULES_DRAFT.md` section 8 one by one.
- Swift Package + manual-trigger macOS workflow only once Package.swift exists; it must pass `tests/golden`.

- 1.1 魔物戰場在獨立 codex/v11-monster-battlefield 工作樹完成 MOB-01/02 核心與 Debug 試玩入口；163 項 Swift 測試、62 組 Golden 與 12 組合法重播通過。iOS 操作驗證進行中；真人取捨、MOB-03 戰利技能待驗證。沒有新增提交／推送／發布，不改 1.0 工作樹。 <!-- memory_record_projection:active-task-summary:1564fe1040217796a5134cd59c81eaba92d489806bb8284209cd8b0195924efe -->

- MOB-01/02 原型工程驗證通過：163 Swift 測試、62 組 Golden、12 組合法重播、3 項 iOS 操作與 Debug/Release 編譯。真人比較待辦；MOB-03 黏彈/暗影狼未實作。獨立工作樹，沒有新提交/推送/發布。 <!-- memory_record_projection:active-task-summary:78ed780d9281844e33366eaf29a0e148cd5010ff2e79fcaef8c7213eb6d4ecd0 -->

- MOB-03a 黏彈與 MOB-03b 單怪暗影狼/影步工程驗證通過：176 Swift tests、62 Golden、16 合法重播、5 iOS 操作與 Debug/Release 編譯。Owner 現在沒空測，真人取捨不作工程阻擋；雙怪、Bot、正式存局/素材待後續。隔離工作樹，沒有新提交/推送/發布。 <!-- memory_record_projection:active-task-summary:eb9cfebb9937bb58cdbef4a3f7532226805fba710d7c4523266c445951e0dc09 -->

- MOB-04 雙怪／多份戰利能力工程完成；真人試玩依 Owner 留到下次，仍在獨立 1.1 工作樹，無新提交／推送／發布。 <!-- memory_record_projection:active-task-summary:8d88cd3d044ee12445cd6e6905aa537fb2b7fa797b22424575cac669690b4dd8 -->

- Monster Art v01：史萊姆／暗影狼依角色風格 skill 生成並接入 1.1 Debug 原型；透明／小尺寸 QA、兩項 UI 操作及 Debug／Release 隔離通過，候選及真人辨識待下次。 <!-- memory_record_projection:active-task-summary:e78a82382999c7c2d53625a3c8b1cad3dc89d273ba5ac26a6c4f811fff49c01a -->

- TacticalGo 1.1 怪物圖樣 v02 視覺預覽完成，現有 App 保留 v01。 <!-- memory_record_projection:active-task-summary:4d311becdfb4530ed003dd2aef8ec3ce57998296d95fc0077247e8658f5c7aee -->

- v02 怪物圖樣已接入獨立 Debug 魔物戰場，雙怪畫面與操作驗證待 Mac 解鎖。 <!-- memory_record_projection:active-task-summary:63a9631da09cb2961d125028f7cd0ec55b5b5eeab166e85446089b313568f14c -->

- PRESENT-01 法師動畫／聲音獨立候選已實作，native 驗證進行中 <!-- memory_record_projection:active-task-summary:9389b4c9c4bfc1621461eb2e64bb732b316d0aa09c9b7e1a0a91d536ce14e3c7 -->

- PRESENT-01 法師聲畫 A/B 候選已完成工程驗證，獨立 iPhone 安裝；Owner 真人聽感／實機錄影待驗收。 <!-- memory_record_projection:active-task-summary:7a3f540b4281e9f0fd0a6e92206f376f72425c22c7e5183d3e6dd9e062be9f44 -->

- PRESENT-01 被 Owner 明確退回：比之前難看、聲音差。先確認之前指一般對局或 A，再製作修正版。 <!-- memory_record_projection:active-task-summary:3e84aa60eb9017095752f905ac6febd01cb762dffa59c026581e1a6a777a6d5c -->

- PRESENT-02 phone1.0 baseline confirmed and restored from signed1023 sources in isolated Debug Lab; new presentation/audio quality pending. <!-- memory_record_projection:active-task-summary:fcd8dc045fa8ae3abf450a05e6ef511cbe32677e3e337dba1e06301db24405b8 -->

- PRESENT-03 Mage C improved on verified phone1023 baseline; separate phone presentationlab installed and launched, Owner art/listening pending. <!-- memory_record_projection:active-task-summary:fe47a08db4c0e8b69126d995ffa920b56a3d794b6b2b6552f6b5b543d3b777ab -->

- PRESENT-03 Owner rejected; PRESENT-04 isolated literal magic-hand candidate being validated; no art/audio acceptance or release claim. <!-- memory_record_projection:active-task-summary:4f382c1d5ef2dab70eaf4e2196f9756315d32941b138e4257fef2a470763387f -->

- Owner accepts PRESENT-04 animation; audio remains rejected as weak. Keep animation and research/iterate sound only. <!-- memory_record_projection:active-task-summary:88c2fef30194e50e5f439c23f19b8390dac16e6afd7c57e21fd0a6382b08c3fd -->

- Owner accepts PRESENT-04 animation; AUDIO-05 sound-only candidate uses layered thrust/body/tail and equal-level comparison. Listening acceptance pending. <!-- memory_record_projection:active-task-summary:79247c4590d11ff8cf54d3004d28824eb3728e4206b47382248a648bb60663f1 -->

- Owner accepts D animation and prioritizes English casting voice. VOICE-06 two new Move aside! takes installed and launched in separate phone presentationlab; native checks underway, listening acceptance pending. <!-- memory_record_projection:active-task-summary:fd9c3ec6569ca1cf9bae5dcb933b19fe25ff1b22bccb9a9266b3f0dc5463201b -->

- English mage casting VOICE-06: Owner relatively prefers B; B default installed and launched in separate phone Lab. D animation retained unchanged. Native8/0, Debug/Release/device and saved source delivery integrity verified; listening acceptance pending. <!-- memory_record_projection:active-task-summary:ec03e8597bbca5bed377aae90d5815a441f8e156ba6dcf7df2b08a20c16bf7e5 -->

- Warrior Bastion B voice and tangible shield projection candidate installed/launched; mage D/B preserved; Owner effect review pending. <!-- memory_record_projection:active-task-summary:ea66c1790c5732c510219c1c532bcbd7ceeeebbaea1321b3b8240e3439c9523e -->

- TacticalGo 1.1 ten-hour autonomous window 2026-10-12 01:37:48–11:37:48 Taipei; active candidate work only codex/v11-monster-battlefield. No Owner questions before deadline, no commit/push/merge/release. <!-- memory_record_projection:active-task-summary:93fe5e6e7816dd489f223c4391cf618db57a5525b371fa415c4f59f0bdc153d6 -->

- TacticalGo1.1本機候選交付：四職/三職第二技能/魔物/英文聲畫/可達挑戰/存局已整合，235 Swift與27不同原生UI通過；獨立手機已安裝，鎖定造成啟動與真機錄音未驗證。保持候選，11:37:48台北後統一回報並暫停heartbeat。 <!-- memory_record_projection:active-task-summary:0fb5fcd7920a6537d581c7871a770e8287dc480aabb1239234822e8743ed9fc8 -->

- TacticalGo1.1候選依Owner要求於08:31台北重新安裝並成功啟動獨立iPhone App；235 Swift/27不同原生UI既有證據保留，真人聲畫/美術/玩法驗收與真機錄影仍未完成。維持候選，11:37:48後統一回報並暫停heartbeat，不重複安裝。 <!-- memory_record_projection:active-task-summary:8b864b59d3b4809eda98d28ba213c46add903ad1e7acffa5175176799eba4158 -->

- Owner要求同App整合，皇冠戰略herobody已更新1.1/1101並成功啟動，普通首頁新增1.1與返回入口。3項UI/Debug+Release+簽名PASS，六份既有Documents未變；235/27僅前輪證據，未改1.0上架工作樹或Git main，真人驗收仍待。截止後回報並暫停heartbeat，無需重複安裝。 <!-- memory_record_projection:active-task-summary:b17821eddafa812c84dde84f5f00710fffdc4c6377186d35c931e65ded8befe2 -->

- 14版進行中：Owner明確要同一選角/對戰，已撤銷另頁入口；四職/第二技能/魔物/聲畫直接接原UI，新奉獻只移除己兵不補子。239Swift/0與階段6UI/0，最後Native-delivery9UI正跑；1102已簽名但手機離線未安裝，勿沿用13版已完成結論。 <!-- memory_record_projection:active-task-summary:25b40b6601064e1ac05bcb53fb10e2deeebe444dd371ebe8173c4a7d066962b2 -->

- 14版軟體候選完成：四職/第二技能/魔物/聲畫/保存Undo直接整合原選角與棋盤，另頁撤銷；新奉獻僅犧牲己兵，舊補援重播保留。239Swift/9finalUI通過，herobody1102已簽名；iPhone離線未安裝。下一步可用時用install-unified-integration14.sh備份更新，11:37:48後回報並暫停heartbeat，勿重跑未變測試或宣稱真人通過。 <!-- memory_record_projection:active-task-summary:e0a0ee604fc0741694a265d1ca0c2d84d608d7c73b7bdf62b6218059ab339a22 -->

- 15版TestFlight包1.1/1103已簽名匯出，完整整合玩法與54聲畫、2+1 Beta UI通過，239套件來源未變。實際上傳Failed to Use Accounts，未在TestFlight；等Owner於Xcode登入後用upload-testflight15.sh續傳並核對處理/內部群組。未動1.0送審或Git發布。 <!-- memory_record_projection:active-task-summary:498d05845f5a9b9998c3020975851d7e043b9462b1bf2e7fa8d1d96e41e5fedf -->

- 1103 TestFlight尚未上傳：Owner登入的是ASC網頁，Xcode帳戶仍空，續傳exit70。已開Xcode登入sheet；Owner 1.1手動內部群組已建，只有Owner1名、0build。等Xcode完成後續傳並加1103，工程包/來源不變，不重建測試或動1.0送審。 <!-- memory_record_projection:active-task-summary:724db7b497609fc5b0e3bde880671385bc28914b4f3b1d88adb98a61796158b3 -->

- 1.1/1103已上傳TestFlight、Apple處理完成；Owner 1.1群組只Owner1人/1103一build正在測試，Owner已邀請。自測上傳請求完成，待Owner從邀請信接受安裝/真人驗收；未動1.0送審/Git發布，不重複成功交付或擴scope，截止後整理並暫停heartbeat。 <!-- memory_record_projection:active-task-summary:22add944a06eb57274c3628ce0f20588d527e7e666087810c4574e37933c0f28 -->

- 16版手機9x9放大候選1104：focused視窗與精簡操作/完整說明，Visual8與main serial4/small1通過，簽名資源核對PASS；正在TestFlight上傳，處理後只加既有Owner群組並保留1103。規則/聲畫原檔不變，真人手機大小待驗收，截止後停止新增實作。 <!-- memory_record_projection:active-task-summary:126b6523a744841d8addc37ccf27a9e45ebadd64eb8cb1dd48ef425d3a97c197 -->

- 手機9x9放大版1104已TestFlight上傳/Apple處理/Owner群組可測試；Owner1人，1103保留兩版比較。Visual8/main serial4/small1/签名素材源PASS，只有視窗/控制區改動；Owner更新1104驗收大小，未證1104真機或真人通過。截止前不擴scope/重跑/重傳，截止後整理暫停heartbeat。 <!-- memory_record_projection:active-task-summary:5f821450e1d852039a1de653768a04aa5ebf616c729e6a7bffc5812086a6e489 -->

- 17新授權修正進行中：solo接同一1.1四職/第二技能/魔物/英文聲畫，預設新規則無版別切換；Bot合法搜尋與solo存局復原，戰士重量動作。250Swift/0、階段Beta4/0，最終Beta6/Debug安全2及1105TestFlight待完成。舊heartbeat已暫停，未動1.0送審/Git發布。 <!-- memory_record_projection:active-task-summary:01e3ea4920174223e2b35bcf238f115c216ed900ae9b1c9c678604fc3045ef58 -->

- 17軟體候選1105已上傳TestFlight：solo四職/三職第二技能/魔物/新版棋盤與英文聲畫，預設新技能無版別切換、正確存局復原；戰士重量動作。250Swift/Beta6/Debug2通過、签名54素材/2怪/源固定PASS，Apple處理與Owner群組可下載待核對。原heartbeat已暫停，未動1.0送審/Git發布，真人待驗收。 <!-- memory_record_projection:active-task-summary:e1e674302f70b96e10bfdeb043b2d53f70e22571667ac14f982e53e912b81695 -->

- 17完成：1105已TestFlight上傳/Apple處理/Owner1.1可測，1人/三build保留1103/1104。solo四職/三第二技能/魔物與新版棋盤英文聲畫，預設新技能移除版別切換，正確存局/復原/取消；戰士加強蓄勢、下擊停留及回彈。250Swift/Beta6/Debug2、签名54素材/2怪/源固定PASS；Owner更新1105新開電腦局驗收，未證1105真機或真人品質。heartbeat暫停，未動1.0送審/Git发布，停止擴scope/重傳。 <!-- memory_record_projection:active-task-summary:4318a3d829d93052da4c5c8fbbf0f5a1f11af5ee17ea49b88706f709026c70c9 -->

- 18候選1106上傳中：7/9同一暖色UI與固定棋盤，Visual10/Beta5/小Debug3通過、0skip，AI/終局/預覽/Undo幾何不跳動；Apple處理Owner分發待確認，真機與真人style待驗。規則素材未改，1.0與Git發布未動，heartbeat保持暫停。 <!-- memory_record_projection:active-task-summary:7a7e032d6630b69a611f4f82bc34e62ece6f1215231cd2fe37bb58adbf30e75a -->

- 18完成：1106 TestFlight已上傳/Apple處理/Owner1.1可測，1人4build保留1103/4/5；phone7/9暖色矩形UI與固定棋盤，Visual10/Beta5/小Debug3通過0skip、矩形≤0.5pt含牧師對電腦法師。Owner更新1106驗收，未證真機或真人外觀；規則素材不變、1.0與Git發布未動，heartbeat暫停，不擴scope/重傳。 <!-- memory_record_projection:active-task-summary:da9ea28c4e7a7766cbd9a583f6952341e53b2b121c10b2c3eec56308252e2d8e -->

- Owner授權Git推送完成：1.1/1106來源e25b2d8已推origin/codex/v11-monster-battlefield並核對；main未合併、另一1.0 checkout未動。乾淨source Swift252/0、unsigned Beta1106/54素材完整PASS，9.6GB封存簽名暫存留本機，TestFlight1106不重傳。真人品質待Owner，heartbeat保持暫停，停止擴scope。 <!-- memory_record_projection:active-task-summary:3117f94ef273e311e3170c135471c94985c8cd21f784819a8ef655cfe8aa01af -->
