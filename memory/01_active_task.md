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

- Cozy-02/ANIM-01/AUDIO-01 engineering candidate installed separately on iPhone and iPad; phone physical gesture automation and human art/hearing remain HOLD/BLOCK; no commit/push/merge, BGM HOLD. <!-- memory_record_projection:active-task-summary:43596922f2a2dc9c0b72d42df61dac93cb332ec399b1cbfc83c8805173fd5ba9 -->

- GAME-FEEL-10H-v2 on codex/game-feel-voice-01; S0 committed, S1 voice engineering PASS; continue S2/S3/S6/S7, no merge/TestFlight/release. <!-- memory_record_projection:active-task-summary:8fe4c6325d5229659deae83aa0825a4924cf1bce44a946cbbedfe8ec3c9b3c57 -->

- GAME-FEEL-10H-v2 engineering candidate delivered in isolated codex/game-feel-voice-01. S0-S6 PASS with current V3 native simulation; S7 commit/push/report in progress. True iPhone0.8.0(802) installed separate Hero Voice app; foreground/hearing Pending due Locked. No new gameplay/Domain/Bot/second skill; formalBGM HOLD. Stop adding work after S7; Owner acceptance Pending. <!-- memory_record_projection:active-task-summary:eb7ed6ec58355e6ecd4caf3611b0413098d41ca05d73deb78b6bd547dd25ae0a -->

- GAME-FEEL-10H-v2 S0-S7 engineering delivery complete; sourcec9f86c6 pushed isolated codex/game-feel-voice-01, maincdab133 unchanged. Final evidence commit to follow. Owner product/art/voice and physical V3 foreground Pending; iPhone Hero Voice802 installed, Locked launch; iPad simulated only. Current seeded Piper TTS no Apple generated clips in pushed history. FormalBGM HOLD; no merge/release/new work. <!-- memory_record_projection:active-task-summary:a1bb7527a87cb8b184eb6c4b6c2204606907729f9360f30b5572051b14549498 -->

- Hero Voice V3 product performance FAIL after Owner listening: rigid reading, lacks warrior firmness/mage playfulness. Preserve engineering delivery branch c5cde5d and wiring. New local review/brief only; no regenerated audio, code changes, paid service or push. Next actual two-line performance Gate before full recasting; formal BGM/art and physical V3 hearing Pending. <!-- memory_record_projection:active-task-summary:5c925fcf8460b524933975dcd26044d47334c209a8a02ff39adc0a15b868fe16 -->

- VO-PERF-01 two-line dry pilot ready on local codex/hero-voice-performance-01; warriorA/B mageA2/B3, independent words4/4 and PCM4/4, seven generated takes with3 prior held experiments retained. Owner audition preference/acting acceptance Pending. No App/Domain/Bot or BGM change; no push/merge/release in this slice. Original VoiceV3 performance FAIL remains until replacement accepted. <!-- memory_record_projection:active-task-summary:1691a57f3dc78f21574036872386ce3d48bdb78d8358a1ce12aff550b6013847 -->

- ANIM-M1/M2法師本體候選工程已交付，本地未提交；演技/美術與真機動態Pending。iPad903已裝但Locked，手機unavailable。VO新素材未整合、BGM HOLD；Domain/Bot不變。 <!-- memory_record_projection:active-task-summary:0017307175297158e5a53f22fa10f249a29b9b586d2d4a5c1c864d317070ec6d -->

- ANIM-M1/M2法師本體候選工程交付，本地未提交；演技/美術/真機動態Pending。162項結果與97/97 audit、正常速度錄影有可追溯receipt；iPad903已裝但Locked，手機unavailable，Domain/Bot不變。 <!-- memory_record_projection:active-task-summary:95fc212d4527f41ad3c0c34b7935f15b480e745e04fec73341642f8bb584b9de -->

- ANIM-M3 isolated codex/anim-mage-m3 candidate: engineering evidence PASS; Owner visual/acting and physical dynamic gates Pending. Necessary commits/push authorized; merge/release prohibited. <!-- memory_record_projection:active-task-summary:00b75600385cb7804cbcb7d4d8d6d7b0d28767110fadfa83da7c47802f6eb947 -->

- ANIM-W1／ANIM-R1 本體候選開發；完成後停下 Owner 動作驗收；VFX-01→VFX-02→聲音／觸覺／英文語音屬後續 <!-- memory_record_projection:active-task-summary:b4ffe21f5c781f8034d7f78fd253b8029ca005aaa2bcb60de5ae572c2f719c21 -->

- ANIM-W1/R1及cutout-animation Skill工程交付；Rogue動作正面，Warrior改善但氣勢未過；停供Owner驗收，VFX-01/02未開。 <!-- memory_record_projection:active-task-summary:652b4c427dbf0faa155783a4faabe41ba3bfa6e8e31246f854a67bbbe3099329 -->

- ANIM-W1戰士續修候選在codex/anim-warrior-body-02；Owner氣勢待看片，三職均明確確認前不VFX，英文英雄語音HOLD／關閉。170 Swift、137 Golden、4 Simulator、108狀態檢查；iPad Wi-Fi build1005安裝／OS接受啟動，UI認證取消、iPhone unavailable，實機操作未通過。 <!-- memory_record_projection:active-task-summary:e05970b4bed5c671db0c3c3c1285f7deda4e084dc8fd7d03b96ee2c5493c5bba -->

- ANIM-W1 Body02 candidate: Owner acting confirmation pending; all3 bodies before VFX; English hero voice HOLD/off. Evidence artifacts/ios/anim-warrior-body-02/REPORT.md. <!-- memory_record_projection:active-task-summary:782a3c02a32ee7bfb0e4b48bc12822f523ca3deab847d0f4d6f7654e30791eb6 -->

- 三職 VFX finite-bursts-03 強化候選完成；177 Swift／137 Golden／4 Simulator UI／iPhone2 通過；Owner 美術 Pending。iPad 重測連線成功但鎖定拒啟動，等待解鎖；語音與BGM關閉，無 merge 或發布。 <!-- memory_record_projection:active-task-summary:d0795c170c8367fa184ffa9551d74201854fe8ee6aa37d24adb67aa29871cd82 -->

- 自主開發窗口持續：CONTENT03 Core 初步通過，原生驗證進行；BOTP2/ANIM01R 未完成；BOSS00/3D00 文件待審。 <!-- memory_record_projection:active-task-summary:2f6a805ddb6db2a8d325c66f5ddf7826ac5f3c6321710b528d805931cb17b908 -->

- 十小時窗口候選整理／即將凍結：三关與法師原生候選可重播；AI改善HOLD；Boss與3D只有文件。截止才回報待決策，不追加Slice，不安裝、提交或發布。完整證據 artifacts/autonomous-1011/REPORT.md、GATES.md、validation-index.json。 <!-- memory_record_projection:active-task-summary:854ed123c1a90085784b1897ff5d149478cb3e06adf681d9131e9233bec1b505 -->

- 五項Slice候選已凍結；CONTENT-03三關與ANIM-01R完成工程候選，BOT-P2有限策略研究改善HOLD，BOSS-00/3D-00僅規格。Owner新增手機安裝授權已完成iPhone1015簽名更新與正常啟動，原22記錄和6聲音設定保持。仍待台北11:08十小時結束統一交付；未commit/push/merge/TestFlight/發布，未安裝iPad，未真人／美術驗收。 <!-- memory_record_projection:active-task-summary:51199d32cd6fa5a7360b3fb3fbe1fa196a65f069fb6e89591190fbb83f70587e -->

- 五Slice候選已完成；Owner追加手機固定viewport修正1016工程通過及簽名ready，最後安裝仍1015，1016待WiFi恢復；AI改善HOLD，未提交合併發布。 <!-- memory_record_projection:active-task-summary:d2900546303c003deb380581c39b2099f5ebf1fdf309e7f38695e0ab6278640e -->

- 自主窗口已結束並停止新增Slice；五Slice候選／文件及1016手機UI修正ready，AI改善HOLD。iPhone仍1015，1016待連線恢復後完成已授權安裝；沒有commit/push/merge/發布。 <!-- memory_record_projection:active-task-summary:971a5379fd2f1bd650948dbd32a6cc0346b790a2dbed4ab884028281ef12ecb1 -->

- 十小時窗口結束，五項合約部分完成且工程缺口已明列；1016手機同屏版建置與回歸通過、等待iPhone在線安裝。未commit/push/merge/發布。 <!-- memory_record_projection:active-task-summary:69374fc33e212ce7438b90471d3ce491fad2c9bff88eaf1bf335143e8ce879c2 -->

- 窗口後既有合約工程候選及手機同屏修正已整理；簽名1017已安裝iPhone，23資料檔及6聲音偏好保持，正常啟動因Locked待解鎖；Bot限定正例成本/Owner、三關真人、法師演技/真機Gate仍Pending，未合併發布。 <!-- memory_record_projection:active-task-summary:a182f3a1fa3dfa061b64cfa3fceadcab8485562915a4792a815bf7c1c3fe18fd -->

- 1017已安裝iPhone，Owner確認畫面正常；23資料檔與6聲音偏好在更新後保持。既有五Slice候選及同屏修正封存；Bot成本/真人、三關取捨、法師演技與語音仍分開Pending，無新程式、合併或發布。 <!-- memory_record_projection:active-task-summary:4cc7c8cc1adf31ca8aa9c35c271993f1e0d70255ace7eecb3646a2113ffa3528 -->

- 1017已實際由Owner試玩並回饋操作順手；本次整理十一小時實際改動，未再改程式。手機同屏/三關候選/法師R1已交付，AI有限研究成本及後期停滯、紅龍/3D文件後續實作與語音仍各自待決，未合併發布。 <!-- memory_record_projection:active-task-summary:60264a987e2b4c99a3d95d49af0212c8462b6603bf48f5cd8b2cc2b2fcd1dc22 -->

- 1017稳定保留，Owner实机操作顺手；已准备PLAYTEST03三关反馈表与BOSS01效果对照，待逐关真人回馈/龙息封点推兵清兵选择。此轮仅文件，无Boss运行、新代码/音档/3D/合并发布。 <!-- memory_record_projection:active-task-summary:884f8a9e38afa631b47117975eb6c31845f0c8defb8b3ef329c22b59b8229072 -->

- 1018 已修正三關入口誤開六關、補對局入口與兩章切換，六關沿用現行棋盤／英雄；两機安裝完成且保存資料／聲音偏好，iPhone正常啟動，iPad Locked待解鎖。三關趣味仍待 Owner，不merge發布；紅龍清除效果已選、結算僅候選文件。 <!-- memory_record_projection:active-task-summary:7c671fcf4f8bcfaf9468a450ad47de5f16ffed801256b50f9ab40d76453e5bdf -->

- RELEASE-01：首版內容凍結與本機上架盤點完成；1018保留為驗收基線，首頁挑戰仍待最小修正。隱私清單、政策／支援、素材權利、正式簽名配置、三關／陌生玩家／雙機完整流程待確認；不新增玩法，不送審或發布。 <!-- memory_record_projection:active-task-summary:3955b7dd73b744dcd6eae282a2e0ac5f5f2c16dbd9228355de3ef2bb1863e2bf -->

- RELEASE-01 本機收尾盤點完成；已固定1018來源與首版範圍，未開始R1 UI修正。正式簽名、隱私／支援、素材權利、三關與新人／雙機完整試玩待確認；不擴玩法、不合併送審發布。 <!-- memory_record_projection:active-task-summary:0d4b98aedb016dbdaf156b7cdd514fb6aec13a7090eb85364425f8cf0b683983 -->

- RELEASE-01 R1候選1019：首頁直達教學與兩章挑戰、包內隱私清單；iPhone已更新但Locked，iPad連線逾時，真人／權利／發布仍待。 <!-- memory_record_projection:active-task-summary:83bb58f29a8e42171c60996865851303947012eb7afc6e1dbc3b75d7ddc4b5bd -->

- Owner 已採用新版技能為新局預設；1020 移除規則選擇與 selectedRules，保留舊存局規則。iPad Wi-Fi 連線已恢復，27檔及聲音偏好已備份；正在完成原生回歸與同 bundle 更新，未合併或發布。 <!-- memory_record_projection:active-task-summary:5cedbe0895daaa08544e9908dfc3b18d93fd6c4565e10baec188493ef355c16c -->

- 1020 adopts connected-group Bastion and friendly redeployment for new matches; rule selector removed. iPad Wi-Fi installed, 27 saved files and 6 sound preferences preserved; App process observed but foreground launch remains Locked. No merge or release. <!-- memory_record_projection:active-task-summary:1153148b666a3a37670c8b9099ac9cb2bd5e7291c662921e7890d922daea4423 -->

- UI結算1021候選已建置；首輪4PASS/1helperFAIL已修，最終UI因Mac鎖定中斷，仍待解鎖補測；未安裝合併發布。 <!-- memory_record_projection:active-task-summary:02f17f99b3b2b2f3aac26b7410b1b5300c1cf137c5e3308c77ad518f2a05dbc6 -->

- 1021結算候選已Wi-Fi更新iPhone/iPad；最終原生回歸及資料保留PASS，兩台正常啟動因Locked待Owner解鎖。未提交合併發布。 <!-- memory_record_projection:active-task-summary:a483517e4122ec796bba0fe36887044b7b86f4e1bb13941895e78d8390f37543 -->

- 1023雙機Wi-Fi更新，iPhone啟動，iPadLocked待解；選取固定與字級回歸通過，Owner實機／首版NT60買斷驗收Pending，未merge或發布。 <!-- memory_record_projection:active-task-summary:045d9257c9aed135b3b5f0d3b4e6d0f8636d4985c4c999424fa71688426c24a4 -->

- 1023 UI 獲 Owner 接受；新商業方向免費體驗後付費或廣告，額度/價格/SDK未定，僅計畫完成。首版收尾未結案，未合併或發布。 <!-- memory_record_projection:active-task-summary:46fbf8154ba6a08abd32d2ebefb06f757b82873ff1cbf1e0d9a956a9285258aa -->

- 免費額度已定前3場完整對局；付費或廣告續玩取代付費下載，購買/廣告未實作，價格/SDK未定。1023UI已接受，首版收尾與發布仍未結案。 <!-- memory_record_projection:active-task-summary:a779e3a2e919cb82a55da92dc9025ce2a493b49da51e3c041f8d1cfc337f5fa8 -->

- 1024免費三场／StoreKit／真rewarded工程候選PASS（252來源、239Swift、38Golden；原生商業／棋盤回歸通過），Owner兩機保持1023；正式ASC/AdMob/公開政策與Sandbox/真機/權利/distribution尚缺，發布BLOCK；不擴玩法或自行merge。 <!-- memory_record_projection:active-task-summary:a6415123fab593dfd3fa6b3d2fc56610b524b3bf92c06dc6debe207ab58efac0 -->

- 1024帳戶草稿已建立；Apple Paid agreement/AdMob本人註冊待完成，正式IDs政策Sandbox簽名及發布Gate未完成，無上傳發布。 <!-- memory_record_projection:active-task-summary:539ce23d9dfc66e22a959f3c34d28fbaf59b322862773d39d6e598cb5f126cd1 -->

- AdMob已註冊、付款資料設定完成且重載後警示消失；帳戶審核/遊戲App與廣告單元/UMP、Apple商務及正式發行Gate仍未完成。 <!-- memory_record_projection:active-task-summary:624d9de551fb4d915e59d5f4bc7b8146d411940e5e51c600c21683572ac63b5f -->

- 已建立正式AdMob App及rewarded unit（1場對戰），僅發行配置草稿；Apple付費協議新、AdMob審核中、UMP／policy／profile等未完成，1024凍結包與1023真機不變。 <!-- memory_record_projection:active-task-summary:0618d02c64fc81f6116d66dfa6e1cd66c2e82fdc7fe9ec7f3aeb3c41b7d48cf1 -->

- App Store 1.0 store copy, categories, age questionnaire and free download saved. Game source and frozen 1024 preserved. Support/privacy/app-ads privately deployed; public access, IAP price/regions and Owner tax/bank pending. No upload, review submission or release. <!-- memory_record_projection:active-task-summary:9747637bac47b4116c32551fbc4c83a50651d981303659b34f254da0d98f355e -->

- Release prep: Taiwan tax complete, US forms missing, bank processing; distribution profile installed; limited phone and iPad tests pass; public site and IAP decisions pending; no archive/upload/review. <!-- memory_record_projection:active-task-summary:6a33d7ddce717a94a57a8ed83132ebef9be4dcae840626caafa5b182d9cd7023 -->

- 三份Apple稅務已完成；付費協議與銀行正在處理，網站公開與商品價格地區待Owner回覆，尚未封存或送審。 <!-- memory_record_projection:active-task-summary:5e1ba1748433429ae54c0bdc8b8e8123c95b8cb1c95fa08f2964243d873f9d1e -->

- 上架準備：Apple商務有效、台灣免費下載及NT60解鎖、公開政策、UMP與IAP審核圖已備妥；1.0/1025 Release Simulator配置與啟動PASS。隱私法律确认/審核電話/最早英雄圖源及Mac解鎖待Owner，未archive/upload/submit。 <!-- memory_record_projection:active-task-summary:c29f58119319ce8e22fc46f168c8fdf4896f8bad35778225a2a8b62e4bf1a490 -->

- 1.0/1025正式archive與IPA、五張商店截圖及Owner隱私/電話已完成；上傳卡Xcode帳戶，原圖權利/Sandbox/最終真機待驗，未送審發布。 <!-- memory_record_projection:active-task-summary:a282d3ecaffe1073f0a3c96047b885807deed40d353b775b429a72e94ce2bfa8 -->

- 皇冠戰略1.0／1025與永久解鎖已同一submission送審，Apple等待審查；維持手動公開，正式交易／廣告／雙機RC待驗。 <!-- memory_record_projection:active-task-summary:6843982b6dc32f686228c1d1279d8bf2b065c6bd299b4b359dff945f3ce4e56e -->
