# Review Log

## Entries

- Append review summaries and validation history here.

<!-- memory_record_projection:review-log:b4ffe21f5c781f8034d7f78fd253b8029ca005aaa2bcb60de5ae572c2f719c21 -->
### Canonical memory checkpoint — cli-20261010-165147

- Writer: `governance_tools.memory_record`
- Record identity: `b4ffe21f5c781f8034d7f78fd253b8029ca005aaa2bcb60de5ae572c2f719c21`
- Commit binding: `c13f23e` (bound)
- Record: Owner 核准先製作可重用 tacticalgo-cutout-animation Skill，已建立並通過 skill-creator validator、安裝至個人 skills。記錄固定順序：ANIM-W1 戰士與 ANIM-R1 盜賊先完成原画獨立圖層及成功事件原生播放，交完整棋盤正常速度錄影後停下；後續 VFX-01 法師，再 VFX-02 戰士／盜賊，最後統一 SFX／輕量觸覺／英文語音時點。M3 人物呈現方向已接受，不等於整體美術结案；本輪語音關閉、無大型 VFX，不動規則／Bot／資源／投影。允許隔離 commit／push，未授權 merge／TestFlight／發布。
- Validation boundary: Skill quick_validate: Skill is valid!；W1／R1尚在開發，工程／視覺／真機驗收 NOT CLAIMED；docs/ios/SLICES.md及docs/PLAN.md已記錄順序。
- Next action: 完成 W1／R1 原生候選、32／48／64及7×7／9×9雙陣營錄影與操作回歸後，停下供 Owner 觀看；不得直接啟動 VFX-01／02。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:652b4c427dbf0faa155783a4faabe41ba3bfa6e8e31246f854a67bbbe3099329 -->
### Canonical memory checkpoint — cli-20261010-172555

- Writer: `governance_tools.memory_record`
- Record identity: `652b4c427dbf0faa155783a4faabe41ba3bfa6e8e31246f854a67bbbe3099329`
- Commit binding: `0fa29dfa4817dafbebf146bcdcee47a4c60d88c4` (bound)
- Record: 完成 tacticalgo-cutout-animation repo Skill並安裝個人skills；交付原畫戰士／盜賊2.5D本體原生候選及成功收據共同時序。保存順序：ANIM-W1／ANIM-R1→停供Owner觀看→VFX-01法師→VFX-02戰士／盜賊→三職SFX／輕量觸覺／英文語音。Owner覺得盜賊動作不錯，戰士初版還好；只調戰士抬盾hold70ms、下擊90ms、與雙兵580ms落定同拍、回震80ms，盜賊保留。最新Owner回饋動作改善但氣勢不足；技能氣勢仍未通過，未開VFX或新增VO。iPhone／iPad獨立Heroes1003透過Wi-Fi安裝啟動，不覆寫原候選；隔離commit/push已授權，未merge/TestFlight/發布。
- Validation boundary: Fresh Swift169tests/0failure；38fixtures/99actions/137snapshots與cached C#一致，C#未重跑；最新Simulator108/108 checks、2項receipt/secondAP、320/9dense UI及12收據錄製通過；實體iPhone1003實際2tests/0failure、108/108 checks；iPad安装啟動成功但UI runner認證取消，不宣稱動態PASS。Release與兩份Skill驗證通過。靜音Simulator錄影不作真機聲畫、人耳、真人表演通過證據；接縫、最小25px、裁切風險見REPORT。早期device0-test退出被拒絕，修harness後實際重跑tests。
- Next action: 停在W1/R1工程候選，保留盜賊正面回饋及戰士改善／氣勢未過，供Owner觀看完整棋盤正常速度對照。VFX依既定獨立Slice後續安排，不自動開工，不merge/發布。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:e05970b4bed5c671db0c3c3c1285f7deda4e084dc8fd7d03b96ee2c5493c5bba -->
### Canonical memory checkpoint — cli-20261010-175051

- Writer: `governance_tools.memory_record`
- Record identity: `e05970b4bed5c671db0c3c3c1285f7deda4e084dc8fd7d03b96ee2c5493c5bba`
- Commit binding: `06afb1cbad53de85b1421a7beef1570beaa711ac` (bound)
- Record: Owner要求繼續修戰士並確認語音尚未通過。保留Mage/Rogue，本輪修完整盾邊、握劍手/護腕/护手遮罩、單次70ms蓄勢停拍和連續下擊，双兵480ms同拍落定與回震，登場加穩重落定。無Domain/Bot/AP/Mana/投影/角色身份/新語音/VFX變更。工程候選不等Owner表演核准。
- Validation boundary: 170 Swift tests PASS; fresh Swift38 fixtures/99actions/137snapshots equal cached C#; C#not rerun, equivalence not rules correctness. 4 nonzero Simulator UI tests PASS,108 actual GameStore checks PASS.6 receipted silent normal-speed videos; unchanged originalSHA.ARM64 Release+signeddevicebuild PASS. iPad1005Wi-Fi install/OS launch success, UI runner auth canceled, in-app audit not retrieved; iPhone unavailable/install failed. Human acting/art/voice gates PENDING. Focused verifier PASS, no rules/Bot/projection diff.
- Next action: 先看artifacts/ios/anim-warrior-body-02/REPORT.md與完整正常速度靜音原生Simulator影片、同局面舊新版對照；等待Owner戰士及三職本體確認才VFX。英文語音情緒、人耳聽感與實機同步仍HOLD，不重做語音。設備恢復後補實機操作；不merge/TestFlight/發布。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:782a3c02a32ee7bfb0e4b48bc12822f523ca3deab847d0f4d6f7654e30791eb6 -->
### Canonical memory checkpoint — cli-20261010-175143

- Writer: `governance_tools.memory_record`
- Record identity: `782a3c02a32ee7bfb0e4b48bc12822f523ca3deab847d0f4d6f7654e30791eb6`
- Commit binding: `06afb1cbad53de85b1421a7beef1570beaa711ac` (bound)
- Record: Evidence citation correction for Body02: previous canonical record omitted an artifacts path in test_evidence. This record binds the complete verification receipt; no new runtime, art, audio or acceptance decision.
- Validation boundary: PASS: artifacts/ios/anim-warrior-body-02/test-evidence-receipt.json runs scripts/verify-warrior-body02-delivery.py; full counts, source hashes and physical/human limits in artifacts/ios/anim-warrior-body-02/delivery-verification.json and REPORT.md. This verifier is evidence consistency, not a fresh execution of all tests or an acting judgment.
- Next action: Owner reviews silent normal-speed warrior clips; wait for explicit all-three body approval before VFX. Voice remains HOLD. Physical input remains unverified.
- PLAN reconciliation: `not_applicable`

<!-- memory_record_projection:review-log:d0795c170c8367fa184ffa9551d74201854fe8ee6aa37d24adb67aa29871cd82 -->
### Canonical memory checkpoint — cli-20261010-183943

- Writer: `governance_tools.memory_record`
- Record identity: `d0795c170c8367fa184ffa9551d74201854fe8ee6aa37d24adb67aa29871cd82`
- Commit binding: `c9d42e7` (bound)
- Record: Owner 否決細線光圈候選偏弱；查閱固定版本 Vortex 有限拖尾／爆發與 Pow 棋盤圖層原始碼，自行實作 receipt 時間有限蓄能／方向帶／落點衝擊，未導入第三方引擎。法師出手到推動增加可見傳遞，總950/760ms不變。錄影VFR與host時鐘偏移造成初版剪輯缺段；新剪輯依實際編碼AP色碼對齊，僅重複靜止幀轉30fps，18段正常速度原生影片與SHA留證。iPad最新重測取得tunnel，但Locked拒啟動，尚無新測試。
- Validation boundary: artifacts/ios/vfx-three-classes-01/evidence-receipt.json；delivery-verification.json；177 Swift tests，137 fresh Swift/cached C# snapshots；156 GameStore/Core checks，57 native checkpoints；4非零Simulator UI tests；iPhone2實際UI通過；iPad-retest-launch.log Locked且0新test。等價不證明規則正確，工程不證明氣勢或聽感；人物／Domain／Bot／投影未改。
- Next action: 等待Owner看完整棋盤正常速度三職特效與解鎖iPad後重測。Owner美術／產品Pending；不得merge、TestFlight、發布、加入第二技能或新語音；語音仍未通過，BGM HOLD。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:045d9257c9aed135b3b5f0d3b4e6d0f8636d4985c4c999424fa71688426c24a4 -->
### Canonical memory checkpoint — tacticalgo-board-focus-1023-paid-plan

- Writer: `governance_tools.memory_record`
- Record identity: `045d9257c9aed135b3b5f0d3b4e6d0f8636d4985c4c999424fa71688426c24a4`
- Commit binding: `4986805` (bound)
- Record: 1022 board-focused UI installed bothdevices; Owner physical screenshots exposed preview layout movement.1023 fixed reserved summary and shared scalable action/direction row44pt minimum, default390/375 frame stability and preferred XX/XS tests. RealXXXL1.67pt failed test retained and corrected. Same237input snapshot onlyUI View/UITest changed vs1022; signed1023 bothdevices Wi-Fi updated,iPhone launched,30oldfiles+6audio fields preserved;iPad27files+6fields preserved, launchLocked. Paid1.0buyout targetNT60/noads/subscription/IAP/TestFlightfree beta saved in4local documents; no account/release operations or Gitcommit/push/merge.
- Validation boundary: artifacts/ui-board-focus-1023/VALIDATION.json final5UIpasses0fails; prior stages17passes1realfailure retained; GEOMETRY_COMPARE.json390+8.8% and375+40.5%vs1021, all actionstates stable. SOURCE_ARCHIVE.json239entries verified, install/SIGNED_BUILD.json237hash/code-sign/iOS17/profile checked; install/RESULTS.json realWiFi versions/launch/retention; paid-doc-validation-final.json4hashes11links. Package/Golden unchanged notrerun; no physical gameplay/listening acceptance claim.
- Next action: Owner試1023選取取消與確認；iPad正常啟動待解鎖。保持固定首版內容，補完整局、三進階關、新人、聲画、素材權利與發行資料；不擴功能，不上傳或發布。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:46fbf8154ba6a08abd32d2ebefb06f757b82873ff1cbf1e0d9a956a9285258aa -->
### Canonical memory checkpoint — tacticalgo-monetization-00-plan

- Writer: `governance_tools.memory_record`
- Record identity: `46fbf8154ba6a08abd32d2ebefb06f757b82873ff1cbf1e0d9a956a9285258aa`
- Commit binding: `4986805` (bound)
- Record: Owner 接受 1023 操作修正，改提免費體驗後付費或看廣告續玩，取代先前付費下載；同步 release-01、PLAN/NEXT_GATE，新增 FREEMIUM_PLAN，保留歷史與裝置證據。前三場、永久去廣告及 NT60 僅推薦候選；額度等待回覆。
- Validation boundary: 本輪唯讀查核主 App/Xcode/Package 無 StoreKit 或廣告；Apple 官方頁核對；VALIDATION.json 確認 237 shipping 檔 SHA 無變更、本機 Markdown 連結零失敗。NOT RUN: 沒有改程式，不重新建置、跑 Swift/Golden 或裝置操作。
- Next action: 確認免費額度與付費/廣告細節後，限定實作獨立試玩權限、StoreKit 購買恢復及獎勵廣告；仍需固定候選雙機完整局、素材權利、公開政策/支援與發行封存，未授權外部帳戶或發布。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:a779e3a2e919cb82a55da92dc9025ce2a493b49da51e3c041f8d1cfc337f5fa8 -->
### Canonical memory checkpoint — tacticalgo-monetization-00-quota-confirmed

- Writer: `governance_tools.memory_record`
- Record identity: `a779e3a2e919cb82a55da92dc9025ce2a493b49da51e3c041f8d1cfc337f5fa8`
- Commit binding: `4986805` (bound)
- Record: Owner 已選前 3 場完整對局作免費額度，同步 FREEMIUM_PLAN、release-01、PLAN/NEXT_GATE，前筆等待回覆為歷史。一次去廣告/價格/供應商仍是待定細節；沒有改 App。
- Validation boundary: VALIDATION.json：237 shipping 檔 SHA 無差異、本機連結零失敗；獨立文件查核無阻擋。NOT RUN: 本輪僅決策與文件，不建置或跑遊戲測試。
- Next action: 依前三場完整局設計防重扣 ledger，再補 StoreKit 購買恢复與獎勵廣告；先確認商品/SDK與離線/舊局語意，完成最終雙機及發行收尾後再判可送審。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:a6415123fab593dfd3fa6b3d2fc56610b524b3bf92c06dc6debe207ab58efac0 -->
### Canonical memory checkpoint — monetization-1024-20261011

- Writer: `governance_tools.memory_record`
- Record identity: `a6415123fab593dfd3fa6b3d2fc56610b524b3bf92c06dc6debe207ab58efac0`
- Commit binding: `4986805` (bound)
- Record: 1024商業接線候選完成：前三場正式保存終局免費、舊局續玩／教學挑戰免費、StoreKit2 verified永久購買／恢復／pending／退款、真Google獎勵廣告一局及場景過期防護。Release隔離未接受語音／Models／研究入口，BGM/SFX與偏好保留。依Owner只讀字樹花園沿用公開Email/Copyright；正式帳戶/IDs/policy仍缺，未commit/push/merge/安裝1024/送審/發布。
- Validation boundary: artifacts/monetization-02/SOURCE.json 252重建測試輸入，基線237中5改／15新，117protected SHA不變；239Swift(含27ledger)0fail，38Golden/99stepsPASS；390最終12、tablet2、SE2方法PASS；真Google test creative r1兩方法PASS及r2同成功方法加A1→白方2AP重驗PASS。unsignedReleasePASS，Voice/Models/.storekit排除／17WAV保留；工具24fixturePASS、actualpreflight8PASS/18expectedFAIL。NOT CLAIMED: Sandbox/實體/同意特殊路徑/正式帳戶/權利/發布。
- Next action: Owner登入已開啟ASC、建立本遊戲non-consumable與AdMob/UMP及專属公開政策；沿現有com.tacticalgo.prototype.herobody資料語意核對正式bundle/profile。先Sandbox/雙機/權利/產品，再distribution1.0 archive；發布仍BLOCK，不擴玩法。
- PLAN reconciliation: `updated`

<!-- memory_record_projection:review-log:539ce23d9dfc66e22a959f3c34d28fbaf59b322862773d39d6e598cb5f126cd1 -->
### Canonical memory checkpoint — release-accounts-1024-20261011

- Writer: `governance_tools.memory_record`
- Record identity: `539ce23d9dfc66e22a959f3c34d28fbaf59b322862773d39d6e598cb5f126cd1`
- Commit binding: `4986805` (bound)
- Record: Owner登入後已登記既有herobody bundle並建立皇冠戰略ASC App 6821588889/SKU CROWNTACTICS-IOS-01、non-consumable商品com.tacticalgo.crowntactics.unlock/IAP 6821589396，中文說明儲存；1.0版本草稿手動發布、不需遊戲登入已重開核對。Apple Paid agreement仍新、bank/tax未查；AdMob到註冊頁未接受條款或建立帳戶，交本人處理。未修改1024 runtime/凍結快照、未安裝、未提交推送合併或上傳送審發布。
- Validation boundary: UI建立成功及儲存後重開確認：artifacts/release-accounts-1024/OBSERVATIONS.json與6張截圖；LOCAL_VALIDATION.json證明252來源雜湊/ZIP不變；RELEASE_PREFLIGHT.json exit 1 expected incomplete。NOT RUN: 本次僅帳戶/UI文件，沒有新遊戲測試。
- Next action: Owner完成Apple商務契約及必要法律實體稅務银行資料、AdMob註冊；再核對真實廣告ID/UMP、公開policy/support、商品定價metadata、Sandbox及distribution封存。
- PLAN reconciliation: `updated`
