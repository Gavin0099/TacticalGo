# 下一個 Gate：iOS A0 試玩與操作驗收

## 當前 Gate：BOT-01 玩家試玩（2026-10-09）

Owner 已試玩並核准基本 Swift 電腦對戰，早期「沒有可玩介面／Bot 暫停」表為歷史。此輪試玩入口：iOS 選角 → 電腦對戰 → 選雙方職業 → 開始；玩家黑方先手1AP，電腦白方正常2AP。只支援7×7單人，本機雙人7／9保留。

固定戰術與原生證據見 artifacts/bot-01/REPORT.md；請觀察能否理解電腦攻守、召喚／技能是否有意義、密集盤面是否拖沓，以及是否想再玩一局。弱電腦胜率／自動合法終局不代替G5／職業平衡。BOT-02職業深化、BOT-03難度效能尚未授權，本輪不擴展。

iPad 仍待 Owner 連接；安裝、真機效能、Owner試玩與模擬器驗證分開報告。

## 当前程式交付 — IOS-V2-ASSET-01

Owner授权iOS Agent继续程式；SW1／SW2已有实际可玩与Golden證據，跳过重做，直接整理V2接線。静態V1不再扩展。原生整包metadata／图片／anchor接線與fail fallback完成，規格docs/ios/V2_ASSET_CONTRACT.md，當片驗證artifacts/ios/v2-asset-interface-v01/REPORT.md。接入新素材仍需Owner確認具體版本；接線通過不代表V1品質或新美術通過。後續依已提交事件接A1–A5，第二技能不實作；iPad未連接保持待辦。

## 最新交付檢查：V1 A0 資訊層級與尺寸

V1静态稿先核對目前行動方、AP／Mana、原始人物卡、普通技能成本、合法預覽／确认取消与主將最後一氣；390與320同看，並补7／9盤面。另一Agent的正式棋盤美術后續接入，当前SVG板面是布局占位。UI既有可玩版与SW1不重跑，第二技能／R2候選独立。证据 `artifacts/ios/v1-a0-ui/VALIDATION.md`；规格 `docs/ios/V1_A0_UI_SPEC.md`。Owner未視覺核准以前不把静态稿叫成原生整合或真機驗收；iPad安裝等Owner連接。

## 最新試玩後檢查：R2 規則候選

Owner 已完成一輪 iOS 對戰並指出密集盤面技能失效；這是玩法回饋，不代表 G5 樂趣與平衡通過。已核准固定局面 A／B／C／D 比較，原版手機與 UI 不變。R2 初輪結果支持戰士繼續真人審查，法師異色交換保留安全遠程破陣／盜賊空間風險。有限比較不替代整局反制測試；下一次 Owner 規則判斷以前，不改正式預設。證據與可讀棋形見 `artifacts/r2/REPORT.md`、`docs/r2/POSITIONS.md`。

## 最新 Gate：iOS A0 可玩候選（2026-10-09）

Owner 已玩過 Windows，要求先做 iOS；不再等待 Windows G0 才進行移植。下一個檢查點為 iPhone 上的選角、新對戰、召喚／三職技能／提子、完整復原、7×7／9×9 觸控與勝負操作。技術測試與安裝不替代 Owner 的操作驗收；G5 遊戲性仍獨立。舊 3D Identity Gate 不通過，A0 原畫保留。見 `artifacts/ios/playable-a0-v01/REPORT.md`；以下為舊 Gate 歷史。

2026-10-09：V1／SW1 已開工，下一個技術 Gate 為 iPhone 正確點選與渲染比較，詳見 `docs/ios/SLICES.md`。Swift 原型可在模擬器檢查三畫面與 7×7／9×9；正式視覺與真機仍未核准。下方玩家策略 Gate 保留為 SW2b 之後的真人驗證；舊 Windows UI 先行順序已被本次決策取代。

# 保留的玩家驗證：職業會不會改變棋盤策略？

> 狀態：Draft（2026-10-08）。這是進入完整 UI 之前的 Gate；自動化測試全過**不能**取代它。

## 要回答的問題

玩家會不會「因為選了不同職業，而採用不同的棋盤策略」？
如果戰士、法師、盜賊在同一個局面的最佳操作幾乎沒有差別，就先修改能力，而不是增加技能（PLAN §6 Stop 條件 1）。

## 已有 / 還沒有

| 項目 | 狀態 |
|---|---|
| 規則引擎、三招技能、跨語言黃金測資 | 有（`dotnet test`：75 項） |
| 啟發式機器人探針 | 有，但**不會用技能策略**（築壘不會築防線、封印只靠評分）→ 不能拿來調數值。**暫停**，等真人玩過再決定要不要做技能型機器人 |
| 可讓真人玩的介面 | **沒有**。2026-10-08 決定順序：UI 草圖 → Windows 可操作棋盤（WinForms，呼叫 C# 引擎）→ 真人試玩 → 改職業技能 → 機器人 → 正式美術。UI-0 草圖見 `docs/ui/UI0_layout.html` |
| 代表性戰術局面 | **沒有**。需要 3–4 個固定中盤局面（見下），由 Owner 審 |
| 試玩紀錄表 | **沒有**。每局記：選的職業與理由、關鍵決策、是否想換職業重玩、看不懂的規則 |

## 建議的固定局面主題（棋盤待設計）

1. **主將只剩 2 氣**：對手還有 2 AP。誰能活？戰士築壘補氣？法師封住對手要填的氣？盜賊換位反殺？
2. **雙方中盤互有打吃**：先手 1 AP 的補償是否讓局面有來回，而不是一邊倒。
3. **英雄是否冒險前出**：召喚位置現在要鄰接己方棋子，英雄部署的位置本身是否構成決策。
4. **看似穩固的棋形**：盜賊換位能破陣嗎？對手能否預防？（檢驗職業之間要有反制，而不是強弱排序）

## 通過 / 停止判準（由 Owner 依實際行為判定，不是機器人數字）

- 通過傾向：同一局面出現兩種以上合理且職業相關的解法；玩家能說出為何選這職業；輸了想換職業再戰。
- Stop/Pivot：最佳解與職業無關；職業排序（兩個支配、一個墊底）；大量時間花在記例外規則；玩家看懂了卻不想再試。

## 這個 Gate 之前**不做**

卷軸、神器、紅龍完整系統、大量美術、13×13、正式 SwiftUI 介面。


## 2026-10-09 — 現行可玩 iOS 與 Owner 追加範圍（取代前述 G0 Pending／SwiftUI 未開始的歷史狀態）

Owner 已實際玩過 Windows 與 iPhone 單人版本，確認電腦逐步落子可辨認。Swift Core／SwiftUI 本機雙人與三職第一技能、7×7 Bot、V2 接線均已有工程交付；G5 完整真人／平衡驗收仍未通過。A0 原卡＋Token 維持，不重啟 3D、美術或第二技能。

本輪最小追加：選角可選黑／白和簡單／標準，預設簡單。簡單保留己方完整回合、直接勝負與主將救援，減少候選並略過對手完整回合搜尋；不保證人類獲勝，也未測勝率梯度。選白時電腦黑方自動首回合 1 AP；复原保留電腦開局。局中改難度作廢舊決策，保留已提交 AP／Mana／技能旗標，僅重新規劃剩餘回合。

Owner 另授權將 Audio Agent 的音樂／音效整合進此候選並安裝 iPad。只接入原程序合成 BGM＋11 SFX、AVAudioPlayer、成功事件時間表與持久化聲音設定；不覆蓋 Bot、Domain、A0 素材或引入完整 CombatBoard 視覺改版。undo／restart／離場／背景／難度切換取消舊 cue。無聲的正常 endTurn 保留已成功技能的落定音；勝負聲在單人模式依玩家方別選 victory／defeat。iPad 目前使用 iPhone 相容呈現，非平板原生布局验收。

目前獨立 worktree codex/bot-01，不 commit/push/merge 或正式發布。來源、測試、失敗／修復與雙裝置安装以 artifacts/bot-01/REPORT.md 為準。BOT-02、完整 BOT-03 與 R2 未開始。


## 2026-10-09 — 原生 iPad 排版與雙裝置 Wi-Fi 更新

Owner 回報 iPad 排版不適合，指定 Wi-Fi 更新並追加 iPhone 安裝。本輪僅修改 PlayableGameView、app/test 裝置設定與原生 UI 測試；原生支援 iPhone/iPad，平板四方向、手機直向。iPad 直向置中放大棋盤與按鈕，橫向棋盤左／雙方資源與操作右；選角橫向分欄。旋轉保留局面與行動預覽，既有 Domain、Bot、音訊與 A0 素材 SHA 未變。

原生 mini6/iOS18 三項測試、SE/iOS18 三項回歸通過，7/9 點擊、白方電腦開局、旋轉預覽確認／復原、選角與聲音設定有實際截圖。初版容器識別覆蓋子項、旋轉測試過早讀取與 app 局部截圖方向問題均保留紀錄並修正；最終全螢幕截圖按 EXIF 轉正，沒有更動畫面內容。歷史 68 Package/38 Golden 未重跑，本輪規則無改。

Release strict codesign 通過，同一 binary 已透過 localNetwork 安裝到 iPad mini6 和 iPhone16Pro；兩者啟動因重新鎖定被拒絕，解鎖後可自行點開，未宣稱真機操作或聽感驗收通過。這取代前一里程碑的「iPad 相容模式／iPhone 尚未更新」現況。完整驗證 artifacts/ios/ipad-layout/REPORT.md、validation.json。未 commit/push/merge/發布，不展開 BOT-02、第二技能、美術或新 Slice。


## 2026-10-09 — 不等待建模：存局、棋譜與技能試驗

Owner 授權將可玩功能先完成；SAVE-01 / REPLAY-01 已接入大廳與局中選單。正式局成功動作原子存本機版本化 journal，Domain 重播還原完整 GameSession／AP／Mana／Ko／undo；壞檔保留、失敗警告、電腦中途續玩只規劃剩餘 AP。唯讀棋譜逐手看事件與資源，可匯出 JSON，不改 live game。

BOT-03b 有限校準已交付候選：滿 Mana pass 評分及簡單近最佳選擇；兩局 100 回合模擬仍和局且長期 pass，因此不聲稱已解決密集盤面或人類難度梯度。R2 既有八個固定局面 A/B/C/D 新增 opt-in 原生試驗入口；正式新局原版規則不變，不做第二技能。A0 卡／Token、音訊與 Core 保持原 SHA；V2 新美術仍等待 Owner 確認素材，不重新建模。

本輪 79 Package、手機 9／平板 5 原生操作測試通過，38 Golden／99 steps／137 snapshots 等價，R2 32 probes；存局按 L2 完整性檢查。Release 已 Wi-Fi 更新 iPad，啟動因 Locked 拒絕；iPhone unavailable，本輪新版手機更新尚未完成。先前雙裝置安裝不能代表本輪手機已更新。工程候選完成不代表 G5、R2 正式採納或真機驗收。詳見 artifacts/ios/product-playability/REPORT.md、validation.json、final-source-manifest.json。仍於 codex/bot-01 未提交，不 commit/push/merge/發布；以上現況取代舊條目，不增加新 Slice。


## 2026-10-09 AUDIO-02 B integration (Owner authorized)

B dynamic battle music is now connected in the frozen AUDIO-B candidate. Three synchronized 76.8s PCM layers, commander threat/stable relaxation, successful-skill -5dB duck, human-relative six-second endings, independent music/SFX controls and cancellation lifecycle are covered. A menu/tutorial remains a candidate. Previous App-integration HOLD is superseded by Owner request; quality/long listening/commercial release are not approved.

Frozen BuildSnapshot excludes in-progress BOT-P0/CONTENT-01 targets; 84 Package tests, SE 3/Pad 2 native tests, each 34 native player checks pass. Release/strict codesign pass; iPad localNetwork install succeeded, launch Locked; iPhone first install failed (CoreDevice1011, Xcode Offline/-27 browsing). Owner says phone is online; wireless development connection remains pending actual verification. See artifacts/ios/audio-b-integration/REPORT.md, validation.json and release-manifest.json. No commit/push/merge/publication.

Owner subsequently authorized BOT-P0 + CONTENT-01 in parallel gameplay work: diagnose legitimate versus avoidable pass, and six formal-newGame reachable 7x7 tactical challenges with Core goals/solutions/counterplay. These are separate from this music binary; CONTENT-02 selection/progress UI awaits gameplay review, no second skills or default R2 changes. Visual source work remains separate.


## 2026-10-09 — B 音樂雙裝置交付、單人內容與後期技能候選（最新現況）

B 對戰音樂已整合，frozen music binary 經 Wi-Fi 安裝到 iPad mini6 與 iPhone16Pro；手機 localNetwork／connected、安裝與啟動 success，取代先前 Offline 待更新記錄。iPad 已安裝、先前啟動 Locked，不宣稱真機聽感／G5。這個已安裝二進位不含下述後續源碼。

BOT-P0 已完成原因診斷與有限定位評分修正。簡單樣本13回合獲勝且0 pass；標準兩個100回合樣本仍和局且61／66 pass，因此整體後期停滯未解決。部分落子會讓主將剩一氣、下一手被吃，不能硬禁 pass。詳 artifacts/bot-p0/REPORT.md；不聲稱修正使所有英雄後期可用或已建立難度／勝率梯度。

CONTENT-01 純 Swift 六個原版規則教學關卡已交付63合法來源動作、30分支67步；預設說目標、提示分開、合法替代兩手解法可過，真實敵兵反制在提前讓出回合後发生。敵人沒有英雄職業，合作建局證明合法可達而非自然對抗發生；無自動敵手、手機選關、持久通關或趣味验收。即時 assessment 在後續 CONTENT-02 必須於完成邊界保存並停止輸入。詳 artifacts/content-01/REPORT.md。

Owner 回報自由對戰戰士沒鄰接空點、法師身旁全己兵，並明確選「戰士沿棋群築壘＋法師調度己兵到棋群外緣」固定候選。R3 L2驗證完成：戰士沿用施放前棋群邊界；法師選射程2內同一群己方普通兵調到原群空邊界，共用1AP＋2Mana／每回合一次。預設關閉、獨立候選API，不接標準GameAction／legalActions／Bot／原生／存局，不改自由對戰或第二技能。共有結算維持原子提子、自殺、Ko及事件。

人工密集探針戰士0→66、法師0→144；正式開局138手棋譜第31／42回合戰士0→6、法師0→12調度。不是Owner本局，也不代表技能有益；實際法師候選可使英雄只剩1氣，仍需站位取捨與玩法驗收。詳 docs/r3/PLAN.md、artifacts/r3/REPORT.md。全包113/0、原版C#／Swift38組99步137snapshots等價與原生編譯PASS；音樂版另有84 Package、手機3／平板2原生操作、各34播放器檢查。

仍在本地 codex/bot-01，無新提交／push／merge／正式發布。下一關為 Owner 審查技能候選與音樂聽感、內容玩法；尚未授權 CONTENT-02 或候選全對局整合。A0原畫與Token保留，Visual Agent素材獨立，不重啟3D。


## 2026-10-09 — R3 候選完整對局（取代固定試驗限定）

Owner 已明確回覆「接入候選對局，保留原版與原局」。因此現在接入 opt-in 候選 GameAction／legalActions／Bot／GameSession／存局及 SwiftUI；原版仍為預設，並保留原局檔案與逐手收據。對戰選單「複製此局測候選技能」先完整驗證、使用新 ID 保存後才切換；新局也可選候選。戰士沿施放前棋群築壘，法師可選原推動或射程2內相連己兵調到原群外緣，共用1AP＋2能量／每回合一次。候選名稱清楚顯示，支援預覽、取消、確認、復原與終止重開續玩。未採納為正式預設；第二技能與 CONTENT-02 不在本輪。

驗證：全包131/0；原版Golden38組99步137snapshots一致；SE原生5/0、iPad原生4/0，含截图G5/G7提G6／法師調度／原局與副本分開保存及重開／電腦剩餘AP／平板旋轉。63來源測試前後SHA一致，Release／strict codesign通過。音樂B及既有音效保留。裝置最新狀態以 artifacts/r3-playable/validation.json 為準：iPad已Wi-Fi安裝，手機初次unavailable待恢復連線；不以舊音樂版代替本輪手機安裝。詳 artifacts/r3-playable/REPORT.md。這段授權與交付取代先前「尚未授權候選全對局」的現況，舊記錄保留為歷史階段。

技能合法仍可能造成己群一氣，Bot標準後期停滯未全面解決，等待Owner候選對局及聽感試玩。不新增Slice、美術、3D、第二技能、AI評分或關卡介面；未commit/push/merge/正式發布。
# 2026-10-09 GAMEPLAY-R3：下一關收斂至技能樂趣與完整對局

Owner 要求先試現有 R3，不再增加功能、美術／3D、第二技能或新音樂演出。候選維持 opt-in，原版／原局保留；真人五項驗收目前0/5，工程通過不能替代。試玩表與新增證據見 artifacts/r3-p1/PLAYTEST.md、REPORT.md。

本輪同版本三局正式開局探針及305動作重播：標準原版61純Pass／100回合和局；標準候選65純Pass／100回合和局；簡單候選17回合提主將、0純Pass。兩局標準均未耗盡搜尋預算，停滯未修復。固定正式可達第42回合，兩難度都能選中法師調度；另有合法調度使主將一氣、對手可提將。第40回合Pass有真實兩手防守原因，第55回合仍呈保守評分；不能硬禁Pass或宣稱新技能解決停滯。

本地隔離分支 codex/gameplay-r3-p1，實作快照5a08cd82e2ed362b0c13fbba79525fec477d0f60；未push／PR／merge／發布。原131測試對應的程式來源逐檔未變，未因增加診斷重跑整包；iPad已安裝候選binary不變，手機更新仍待無線連線。P1驗收待Owner完整對局與三職取捨回饋，不能升格正式規則。
