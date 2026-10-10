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
