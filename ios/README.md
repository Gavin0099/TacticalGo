# TacticalGo iOS A0 可玩候選

Owner 2026-10-09 已玩過 Windows，要求直接做 iOS。正常啟動為 SwiftUI 選角／新對戰；不載入或展示未通過 Identity Gate 的 3D 人物。

- 雙方獨立選戰士、法師、盜賊，7×7／9×9 本機輪流對戰。
- 原始 B-v02 PNG 用於選角與人物資訊；原始 A Token 用於木質 2.5D 棋盤。三張 B 卡與三張 A Token 保持來源檔位元一致。
- 士兵落子、鄰接任一友軍召喚英雄、戰士築壘、法師魔法之手（可推任一方士兵）、盜賊換位。
- 預覽呈現操作後盤面與將被提走的棋子；確認才扣 AP／能量。魔法之手先選士兵，再選方向。
- 取消、完整復原、提早結束回合、自動換手、主將氣數、勝利／100 回合和局、重開。
- 棋盤上方常駐「輪到黑方／白方＋職業」，資訊卡明示行動中／等待；預覽不換人，確認、自動換手、結束回合與復原才依實際狀態更新。
- 雙方統一稱黑方／白方，與士兵色一致；主將與英雄用黑白底座及黑／白字牌識別，雙方同職也不依賴角色圖的顏色。
- 小螢幕棋盤高度保留操作區；棋盤 HUD 採固定可讀字級避免系統超大字溢出，規則與格點清單維持可滾動的系統字級。
- 四個可操作練習：提子、築壘、魔法之手、換位。練習完成以實際規則狀態判斷；可復原重試。
- 棋盤右上格點清單提供可讀座標與棋子名稱，支援 VoiceOver／小尺寸精確選格；真機 VoiceOver 人工操作仍待檢查。

`TacticalGoCore` 是不依賴 SwiftUI／UIKit 的純 Swift Package。Magic Hand 的移植基準為 Windows `codex/gameplay-g1-g4` @ `54deef97e0fb7157b0025a7282fc2c0a448d4fb9`，不是本機 main 的舊版 Seal 引擎。沒有合併、更改 C# production Domain 或宣稱 Windows main 已同步。

## 開啟與驗證

在 Xcode 開啟 `ios/TacticalGo.xcodeproj`，scheme `TacticalGo`，選 iPhone Simulator 或已配對 iPhone。部署最低 iOS 17，直向 iPhone。

```sh
swift test --package-path swift/TacticalGoCore
# SDK 9 required; use installed dotnet or point to an existing isolated SDK.
TACTICALGO_DOTNET=/tmp/tacticalgo-dotnet/dotnet python3 scripts/verify-ios-parity.py
# Historical main Seal fixtures remain unchanged and use the explicit baseline:
swift run --package-path swift/TacticalGoCore tacticalgo-golden tests/golden /tmp/legacy-swift.json --legacy-seal
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO \
  -only-testing:TacticalGoUITests/PlayableGameTests test
```

基準 exporter 只在暫存目錄讀取指定 Git revision 的 C# source；先逐檔檢查 fixtures 與該 revision 相同，再比較完整状态、錯誤與有序事件 payload。測試預期來自既有手寫 Golden，不由 C# output 自動產生。等價測試不能證明原玩法設計正確或平衡。

本輪可检查交付、截圖、Xcode result bundles、真機安裝與驗證邊界見 `artifacts/ios/playable-a0-v01/REPORT.md`。

## 保留的研究入口

舊 RealityKit／SpriteKit／SwiftUI 比較及 3D 模型回放只在 Debug 加 `--review-controls` 時進入。相關幾何、模型、原畫與歷史驗證保留研究用途；本輪不新增 Mesh、骨架、全身、拆層 Sprite 或角色動畫。Release 不提供該入口。

新流程的 Debug 測試入口：`--practice <包圍與提子|戰士築壘|法師魔法之手|盜賊換位>`、`--play-nine`、`--play-win`、`--play-draw`。正常對戰從規則初始狀態開始；Debug 勝負位置不能替代完整對戰驗證。

已有 BOT-01 基本 7×7 電腦對手；已有簡單／標準、黑白執色、候選 BGM／音效與可見電腦逐步落子；尚未提供網路多人、背景存局／恢復與整套正式動畫。本輪是本機可玩候選；沒有 App Store／TestFlight 發布，也不將候選素材升格為正式發布素材。

## V2素材接線

素材規格見 `../docs/ios/V2_ASSET_CONTRACT.md`，原A0六張圖片metadata見 `../docs/ios/visual-pack-original-a0.json`。正常App仍選原圖；候選檔案不会自動載入或視為Owner核准。Debug `--visual-pack-fixture`只重用原圖，`--visual-pack-invalid-fixture`驗證整包拒絕與fallback。独立 `TacticalGoVisuals`不依賴Apple或規則核心，metadata pass/fail測試随Swift Package執行。

## BOT-01 單人試玩

選角頁選「電腦對戰」，選黑／白方、簡單／標準，以及你與電腦的職業，開始7×7對戰。電腦規劃在背景執行；思考時可復原、重開或返回。單人復原回到上一個人類決策，包含撤回電腦回覆。原本本機雙人7／9與四個練習保留。

程式在獨立 `codex/bot-01` worktree，不能在 main Xcode工程中假定已經存在。詳細API／CLI見 `../docs/ios/BOT_01.md`；測試、實際對局、真機安裝狀態與限制見 `../artifacts/bot-01/REPORT.md`。目前是有限搜尋候選，密集局面可能多次跳過回合，不宣稱已具備強AI或人類驗收。

Debug可用 `--play-bot` 直接開正式初始單人局，選單的「電腦決策紀錄」查看行動、理由与背景耗時；Release無調試入口。`--bot-delayed --bot-late-result`只供測試不合作的晚到結果，不代表正式思考速度。


## Owner追加：電腦下棋必須看得見

2026-10-09 Owner試玩反馈「電腦要有下棋的動作，不然看不出來」。BOT-01增加最小A0演出接線，不新增素材或重做動畫框架。完整計畫先驗證，之後每一步先指示目標／座標／第N步，再commit并播放原圖落下／推動／換位／提子，兩步間保留停頓。預設每步準備0.9秒、落定0.9秒；減少動態保留靜態提示與順序。正式技能效果不改。

演出中的玩家輸入鎖定到最後落定，復原／重開／離開仍可中止；每一次await後重新核對generation/電腦方/完整state。第一步已提交後undo仍撤回到上一人類決策；背景最後落定時恢復玩家文案與完成計數，避免舊task再提交。只讀Bot Agent已review，實際原生與錄影以artifacts/bot-01/REPORT.md最新結果為準。

Debug `--bot-step-review`在每phase等候「下一演出階段」測試按鈕，供穩定讀取AP／截圖；不改Bot選擇或規則，Release不含此按鈕。`--bot-mage-motion-review`由手寫反色固定局面讓真Planner選推動＋落子斬首，僅驗演出，不冒稱正式開局對戰。


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
