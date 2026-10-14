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

- UX26完成Wi-Fi手機候選1.1/1108：合法落點與技能步驟限制恢復，新局預設沿棋群築壘+調度己兵，Bot/保存Undo一致、舊局不改。Swift277/Beta6/小Debug3/實際音訊49均PASS，已裝啟動且7存局5偏好保留；本機修改未新commit/push/TestFlight，真人品質待Owner新局驗收，heartbeat暫停。 <!-- memory_record_projection:active-task-summary:5ec9e6c1b4b4147aa2dab1353c177d1ed640cc14fab70c47e998c4dfb19b6b98 -->

- 新十小時聲畫窗口ACTIVE至2026-10-14 01:54:08 UTC/台北09:54；Owner1108畫面音效相對接受。P27技能牌限制提示完成：282Swift/Beta3/小Debug2 PASS，基準258/候選260來源與原生圖保存，手機仍1108。接續P28先錄同receipt動作基線再改四職，P29混音；截止後交付並暫停heartbeat。不改規則/AI策略/另一1.0，不Git/TestFlight發布，不提問/不冒稱爐石品質。 <!-- memory_record_projection:active-task-summary:0ea2f5d15502204835f1df64eb3ef02bf53cc4f4c7f46ca4c81691dc0174801c -->

- 十小時聲畫窗口ACTIVE至UTC2026-10-14 01:54:08/台北09:54；P27 UI已驗，P28A七招原生基線與戰士投影可讀性A/B完成，8Motion/2Debug PASS0skip。手機仍1108；接續P28B先讀Mage/Rogue/Priest既有基線再具體改動，P29混音，最终Beta/完整測試/簽名Wi-Fi末段交付待。保留dirty與兩錄影失敗，不重錄未變素材、不改規則/AI策略、不Git/TestFlight發布、不提問/不自稱爐石品質。 <!-- memory_record_projection:active-task-summary:b0f522c33e75cc79d817c64388da933155181bb991a3ce730d3241f050da88a7 -->

- 十小時聲畫窗口ACTIVE至UTC2026-10-14 01:54:08/台北09:54：P27 UI/P28A戰士/P28B連鎖候選已驗，Motion72及三類Native分批PASS0skip，A/B與精確定格保存。接續P28C先檢查討伐/戰利顯示與演出，尤其pending hunt錯套技能quota/Mana/noAP提示；P29混音及最終Beta/全套/簽名Wi-Fi待。保留dirty與所有失敗，手機仍1108，不改規則/AI策略，不Git/TestFlight，不提問/不自稱爐石品質。 <!-- memory_record_projection:active-task-summary:3b541ef49159f1d30a9a96cefc3b3338b71842a0f922990e762ac938660ec98f -->

- 十小時窗口ACTIVE至UTC2026-10-14 01:54:08/台北09:54；P27/P28A/P28B保留，P28C討伐提示完成：actual hunt與Core合法性，Content5/主Native2/小1 PASS0skip，263來源/前候選同局面圖及初輪失敗保存。下一步P28D先錄魔物討伐/戰利原生基線後再具體迭代，P29混音；全套/Beta/最終簽名Wi-Fi待收斂。手機仍1108，不提前安裝，不改規則/AI，不Git/TestFlight，不提問，不自稱爐石品質。 <!-- memory_record_projection:active-task-summary:5f77e6e03cadac961d7a57e6d1cc556df99fcab3fb43e2b1465dc5285238a0bd -->

- 十小時窗口ACTIVE至UTC2026-10-14 01:54:08/台北09:54；P27/P28A/B/C保留。P28D兩怪討伐接觸＋event授權戰利圖示/文字已驗：Content3/Motion76/Native2＋caption後1 PASS0skip，四基線/兩最後候選/精確定格/268來源保存。黏彈/影步動作、Core/Bot及音檔不變。接續P29-A现有assets/candidates/feel-10/audio材質stems與已接受英文B配音/BGM同响度混音，必要native49審核；最終全套/Beta/簽名Wi-Fi待，手機仍1108。不提問、不Git/TestFlight、不自稱爐石品質。 <!-- memory_record_projection:active-task-summary:a020021d7e0a9c4fc9b4ba14d4c43be85489ab1f31124460acfe5c126512ef43 -->

- 十小時窗口ACTIVE至UTC2026-10-14 01:54:08/台北09:54；P27/P28A-D保留。P29A stage mix已驗：命中/英B/WAV/時間不變，Motion78、Native49audio檢查、52實際volume全PASS；30對離線同LUFS試聽/272源/两renderer失敗保存，代理未聽感驗收。接續P29B實際1.1聲音sheet只mute/voice toggle/reduced/BGM，補獨立音效/配音音量與持續性，預設不變，零音量/動態調整/尾音/BGM原生測試。舊CombatSoundSettings的SFX滑桿不屬1.1，不誤報失效。最終全套/Beta/簽名Wi-Fi待，手機1108，不提問、不Git/TestFlight、不自稱爐石品質。 <!-- memory_record_projection:active-task-summary:dcd99b5e96a740f936c8c4eb1b3044f88649518f7a14672066d822133d6a31d8 -->

- 十小時窗口ACTIVE至UTC2026-10-14 01:54:08/台北09:54；P27/P28A-D/P29A保留。P29B獨立SFX/英voice音量與保存、可見title/百分比同行已驗：22實際volume＋49原audio全PASS，主4/小1 native0skip，SOURCE_PIN272未變，首observer遞迴crash修正保留。DEBUG review不寫OwnerPreferences；預設80/85保留P29A，不混用legacy65。接續P30整體原生、完整Swift/Beta/簽名，窗口末Wi-Fi備份更新最佳同App；手機仍1108，不提問、不Git/TestFlight、不自稱爐石品質。 <!-- memory_record_projection:active-task-summary:3cb4d4454a85972570eccffc03f9bcb3cc03e47dc829c8cd5cd492c684ea5e01 -->

- 十小時窗口ACTIVE至UTC2026-10-14 01:54:08/台北09:54；P27/P28/P29候選保留，P30已準備signed herobody1.1/1109：Swift300、正式Beta主11/小2/最終設定1 PASS0skip，54素材/2怪像素/來源274/簽名裝置PASS，PHONE本輪未更新。READY/COMPARE/OWNER_REVIEW30/installer5fixtures保存；錯runner與PNG路徑失敗保留。接續無變只讀不重跑；UTC01:34:08–01:54:08才fresh Documents/Preferences備份後python3 scripts/install-polish30-wifi.py Wi-Fi更新同App，查RESULT不重複成功安裝；鎖定離線保存包不等Owner。截止後一次回報PAUSED，不提問、不Git/TestFlight、不自稱爐石品質或真人通過。 <!-- memory_record_projection:active-task-summary:2a73d22e1cfef340f8214f291b2360a56c71bad7f29ee085bf725818137d765f -->

- Owner新授權直接TestFlight：P31進行同來源1.1/1109/herobody App Store distribution archive/export/upload，處理後只加既有Owner1.1群組；來源274未變、300Swift/Beta14次11方法沿用。本窗口仍至UTC01:54:08，手機1108尚未更新；新授權僅取代TestFlight禁止，不Git/公開發布/1.0改動，不冒稱上傳或真人品質。若heartbeat同時觸發只讀進度不重複runner。 <!-- memory_record_projection:active-task-summary:0696ade10b8b4d92ee355377f9f246a24375715b0d4be6306d6322cad69a9721 -->

- P31 Owner授權TestFlight交付：1109 distribution archive/export及274源/54素材/2怪像素/privacy/身份PASS，上傳兩次exit70 Failed to Use Accounts（第二次allowProvisioningUpdates同因），尚未TestFlight。Xcode現帳戶無P358EB3X9H ASC上傳權限，已開登入sheet請Owner驗證原帳戶；登入後續傳既有archive再核Apple處理和Owner群組。手機仍1108、窗口至UTC01:54:08，其餘不Git/公開發布/1.0/規則限制有效；heartbeat只讀等新登入回覆不重複失敗upload，未證真人品質。 <!-- memory_record_projection:active-task-summary:3114f7db077882cec73c4cc83ba2a1efcacea90bb299bce75b5424a7079a81da -->

- 窗口仍至UTC2026-10-14 01:54:08，1109候選全部保存；01:42:43窗口末Wi-Fi檢查源/簽名通過，iPhone unavailable/tunnel unavailable無localNetwork，installer連線階段exit1 installAttempted=false，apps probe exit1 CoreDevice1011無手機改動，最後已核手機1108。P31新授權TestFlight distribution完成但兩exit70 Failed to Use Accounts，等Owner原Xcode帳戶登入後續傳。無狀態變化不重試/不提問/不新增實作；截止後一次報實際完成/未交付/比較素材/真人待驗並PAUSED。其餘不Git/公開發布/1.0/規則限制有效。 <!-- memory_record_projection:active-task-summary:887fc23fdc7c99e95e6be5e20c6ea1381c4fd70afb088e75cef8813bdb034287 -->

- 十小時聲畫窗口已於UTC2026-10-14 01:54:08截止，02:02:42核對完成，heartbeat工具確認PAUSED；停止新增實作。1109源274/兩種簽名包/COMPARE21檔保存，Swift300及Beta14次11方法0fail0skip；手機Wi-Fi unavailable、未嘗試安裝，最後已核1108。P31 Owner已授權TestFlight，distribution包核對完成但兩exit70 Failed to Use Accounts未上傳，等原Xcode帳戶登入後只續傳既有archive再核Apple處理及Owner群組，不重開窗口。無Git/公開發佈/1.0改動，不自稱真人或爐石品質，OWNER_REVIEW30與WINDOW_RESULT記錄實際完成/未完成。 <!-- memory_record_projection:active-task-summary:3049b4f8d807da66e9a24037525ca377c90cc97778fd667055645728505dbd3a -->

- P32依新八Slice方向核對1106/1108/1109並保存1109源274/原兩簽名包；恢復1106八張Simulator圖，非真機。首UI修正只让本機頂部狀態符合選取/拒絕/合法預覽/演出，消除完成選點仍要求選点；1110 Simulator正式Beta主2/小1（兩種方法）0fail0skip，主375/402圖及獨立只讀審查PASS此圖階段一致，SOURCE_DIFF/候選pin保存。規則/字級/frame/角色/Motion/WAV不變。PRES00含聲真機和完整選角至勝負/品質Gate尚缺，下一批按PRESENTATION_32_PLAN，不倒退1106。1110未簽名/手機/TestFlight；原1109帳戶驗證後仍可續傳已授權archive，不重建未變原包。heartbeat仍PAUSED、無新十小時/Git/公開發布/其他checkout改動，不稱爐石品質。 <!-- memory_record_projection:active-task-summary:cff8dc46c4689ca02d80345b8da7af633bb88999139d9b33bfa8b0d8e5bcf0ec -->

- P33 Owner完成Xcode登入，最新1110含P32提示修正已App Store archive/export/274源/54素材/2怪像素/privacy/身份核對PASS；UTC05:53:24實際Starting upload，帳戶步驟通過但進程仍在跑，不能稱已上傳。原1109保存。接續只讀此upload結果，不重開，成功後核Apple處理/既有Owner1.1群組可測，不加人/新群組/1.0審查。P30 Swift300/14次與P32主2小1是分開既有證據；無新規則/素材/字級/Git/手機安裝，heartbeat保持PAUSED，真人品質仍未驗。 <!-- memory_record_projection:active-task-summary:2217d7101542ea49bd2900027c20ae629714ffa922cf8ea798a29c250405063c -->

- P33最新1.1/1110已成功上傳TestFlight（UTC05:54:52 exit0 Upload succeeded），ASC可見處理中，帳戶權限阻擋解除；DELIVERY與processing截圖保存。接續核Apple處理後只加既有Owner1.1內部群組，不新群組/新測試者，成功1110不重傳、1109不傳。源274/簽名/54素材/2怪像素保持，P30/P32測試是分開既有證據；無新code/Git/1.0/規則/聲畫/手機安裝，heartbeat仍PAUSED，真人品質未驗。 <!-- memory_record_projection:active-task-summary:bba1c751262cd21475d36037b3f6217d8a0dbfbc613554487158efc762eea194 -->

- P33最新1.1/1110（含P32提示一致性及1109聲畫）已TestFlight成功上傳exit0、Apple準備內部測試並加入既有Owner1.1群組，實際正在測試/90天；DELIVERY和testflight1110-ready.png保存。舊1103/4/5/6保留、無新tester/群組/1.0審查；源274最後未變，簽名/54素材/2怪像素核對PASS，P30/P32既有測試不混算。Owner用TestFlight更新真人驗收，未證1110真機安裝/声畫/FPS/爐石品質。成功1110不重傳，1109舊封存保留；無新code/Git/公開發布/規則/音檔/人物修改，heartbeat仍PAUSED。 <!-- memory_record_projection:active-task-summary:a99ea651a75d605337511894d87c0fbb9184e68a6254a4c5bee9eec55d40d6d3 -->

- P34 1110真人回饋處理中：盜賊戰鬥第二招缺失未重現，選角只介紹普通招已確認，補兩招/費用；魔物同盤討伐Menu明示點選→確認非自動，wolf正鄰英雄/費用/隔回合loot不變。Owner魔物兩者/不確定，新局vs續局待答。牧師仍奉獻1AP2Mana移除己兵，兩眼/反制2項及Offering/Hunt8項PASS不等於一般局好用，不擅改規則。首卡UI type-check build65修helper後TEST BUILD SUCCEEDED；1111主7 Native正在跑，375後續，未上傳未手機。1110基準pin274/包保留，heartbeat仍PAUSED，不Git/公開發布/另checkout/規則/素材改動。 <!-- memory_record_projection:active-task-summary:43f3329bee31e765c8e2fa5f7c9f2a9ec57fa0fa86fa4609c3541b3014b984d6 -->

- P34候選1111：盜賊原有連鎖換位，僅選角缺第二招介紹已修；原用戶戰鬥缺招未重現，新局/續局待答。魔物新增同盤討伐Menu、人工確認與狼上下左右一格提示。首Native6PASS1FAIL為戰利42.67x13.33命中範圍，contentShape修後主3PASS，白話提示Hunt5與最後主2PASS；小375三項仍跑，未簽名未傳。牧師奉獻能兩眼但一般局價值未驗、未改強度。保留1110TF/原圖聲音/規則/Bot/保存與dirty，heartbeatPAUSED、不Git/公開發布。 <!-- memory_record_projection:active-task-summary:6a795248b592cf75ba7672c162695d598612c2dc975399c959a77606561c24cd -->

- P34 1111已簽名並上傳中：原生正式首頁無args新solo兩招可見，Owner確認新開局但缺招未重現，不能歸因舊存局。補選角兩招/費用與常駐討伐Menu、人工確認及狼上下左右一格原因，規則/AP/Mana/Bot/保存/聲画原圖不變。首Native6PASS1FAIL為戰利小命中，contentShape修後主3、最後主2、小375三項3PASS0skip；Content10種15次PASS，54資產/2怪像素/源274/privacy/distribution相同核對。牧師奉獻情境性/一般局價值仍待；375選角全卡文字圖未拍到、對戰牌圖已審。Apple處理/Owner群組待；保留1110，heartbeatPAUSED，不Git/公開發布。 <!-- memory_record_projection:active-task-summary:d8c2d954d9b49220d07ce88bced501bf9e0b9504ab8e1f3a291516437fe028b2 -->

- P34 1111已TestFlight交付：upload exit0/Apple處理完/Owner1.1正在測試90天，未證手機已安裝。補三職兩招/費用展示、同盤討伐Menu/人工確認、狼上下左右一格原因；規則/AP/Mana/Bot/保存/聲畫原圖不變。Owner主畫面新局整張連鎖牌缺仍未重現，非舊局或鎖頭；需完整對戰圖和TF建置號。主最後2/小3、control主3通過，Content10種15次PASS，首Main6PASS1FAIL保留。交付後僅追加UI測試：白後手/標準/雙怪實BlackPriest WhiteRogue 1/0/0；首弱fixture雙盜賊不算牧師證據、補角色4失敗保留、捲入全卡修測試後PASS，非真人觸控故障證明。273其他source與原上傳pin相同、54資產/2怪像素/privacy簽名保持。375全卡圖已獨立審，牧師未改强度/一般局價值待。1110保留，heartbeatPAUSED，不Git/公開發布，未把三項全部修好。 <!-- memory_record_projection:active-task-summary:465ab26ee9b1c30c0eb822a87e36300cda636e55315f40459d0f9bdcf28bff3a -->

- P35進行中：Owner要八Slice續做至爐石80–90%品質目標後再TestFlight，非新十小時/Goal/自評分數；1111源274與dirty凍結，候選1112先私有，QUALITY_35_PLAN。手機unavailable已請同Wi-Fi解鎖；先完整合法開局至結算演出基線與確定每招語音重複缺口，再UI綠點/資訊層級、戰士接觸、全技能矩陣。保留MageD/英B Warrior英B與身份、原規則/AP/Mana/Bot/保存，不Git/公開發布/另checkout，不逐小片上傳，heartbeatPAUSED。真機含聲/FPS/50ms與3位真人Gate缺口分開；盜賊缺牌/牧師玩法仍開放。 <!-- memory_record_projection:active-task-summary:543a851400806b2d84796e4789a1209cac623bf4d3cce199faf2deed4a13bacc -->

- P35持續八Slice自主品質優化，1111仍是TF現版，1112本機候選未傳。完整7/9正常入口baseline與低頻英B第一native驗證已保存；目前UI合法提示降飽和、戰士出手align、快速交棒carry/每cue混音新native回歸進行中，11技能confirmed silent素材錄到，初Beta診斷錯/fixture召喚錯失敗保存。保留身份/MageD英B/Warrior英B/規則/AP/Mana/Bot/保存/dirty，不Git/另checkout/heartbeat恢復/小片上傳；真機聲畫/P95/3真人與80–90%結論未具備。盜賊缺牌/牧師一般局價值仍未假稱解決。 <!-- memory_record_projection:active-task-summary:2284e23b84c2384f056408115a12f784998d4ef7c9e7b018ca76b568ce1a8ab4 -->

- 1112品質候選工程收斂已簽名；Owner改先TestFlight，CLI帳戶失敗後Xcode Organizer同archive已到Uploading，待實際上傳／處理／群組核實。80–90%未主張、真機和人類缺口保留。 <!-- memory_record_projection:active-task-summary:e9899461c54604d950226d5663574e3d55dd5f5798de619ac7dcf7eb95911789 -->

- 1.1/1112聲畫候選已上傳Apple，XcodeGUI成功證據和實際IPA核對保存；ASC網頁需Owner登入，處理／Owner群組／可安裝仍未核實。不得重傳；80–90%和真機／人類品質未接受，heartbeatPAUSED，無Git／公開发布。 <!-- memory_record_projection:active-task-summary:18a5f127a3ee600ffcf04cc4286abcca15bb1fa4674cde477a8a5ed327edf807 -->

- 1.1/1112已上傳Apple及驗實際套件；Mac鎖定、ASC登入逾時，Owner手動登入後核Apple處理／Owner群組／可安裝。不得重傳或冒稱可安裝／80–90%，無源新增、heartbeatPAUSED。 <!-- memory_record_projection:active-task-summary:bbb7fd1b70e3fce6d1555b00609ecd69b5fecf81e9c760c9678dd7b45b9f28cc -->
