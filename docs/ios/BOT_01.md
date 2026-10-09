# BOT-01：基本單人電腦對戰

2026-10-09 Owner 授權；候選工程交付，玩家驗收待進行。工作在 `codex/bot-01`，沒有提交／合併／發布。現行Swift/iOS原本尚未提交，已以明確檔案清單與SHA凍結為Bot工作基線，不能聲稱獨立分支已從Git取得完整現行App。

## 試玩

在本worktree的Xcode開啟 `ios/TacticalGo.xcodeproj`，scheme TacticalGo。正常選角頁選「電腦對戰」，選雙方職業，按「開始電腦對戰」。可選玩家黑／白；黑方首回合1AP，正常回合2AP，選白時電腦先開局。單人限定7×7，本機雙人仍可7／9。UI沿用V1/A0，Visual新素材沒有納入。

電腦回合顯示思考中，禁止替電腦下棋；復原、重開、返回仍可操作。單人復原撤回電腦回覆與最後一個玩家行動，回到玩家決策點。App進背景取消規劃，回前景若仍是電腦回合則重新規劃；未新增持久化存局。

## 決策介面與邊界

`TacticalGoBot`只依賴純Swift `TacticalGoCore`，不依賴UI、網路或時鐘。API：

```swift
let plan = BotPlanner.planTurn(state, limits: .standard, cancelled: { Task.isCancelled })
// plan?.actions / reasons / score / stats
```

輸入不可變完整GameState，輸出完整己方回合（勝負或換手即停止）。終局／取消回傳nil。全部候選來自Core.legalActions，再由Core.apply驗證；棋串與氣由Core計算。Bot只評估，不另實作提子、自殺、superko、AP、Mana、召喚或技能規則。

標準預算：6000次Bot顯式apply、己方beam10、對手beam3、最多8個完整回合候選做反應比較。Core.legalActions內部亦執行合法性驗證，**不包含在6000計數內**，另外報legalEnumerations；因此這是顯式轉移上限，不能宣稱是總Core結算或嚴格牆鐘限制。排序使用固定action key，無隨機數。完整同輸入／預算可重現；不同硬體的時間不影響選擇。

直接獲勝優先，評估主將危險、棋群氣數、兵／英雄、召喚位置、資源與技能造成的棋形。搜尋己方兩AP組合；保留使敵主將剩1氣的第一步供第二步驗證，有限對手反應檢查直接與兩手反擊。搜尋剪枝仍可能漏招；任何戰術fixture通過都不能證明所有局面最佳。

資源不足的搜尋只回已經合法完成的計畫。未完成的對手反應不能冒充安全評分；沒有完整反應可比時保留合法fallback並明示未驗證。理由是除錯摘要，不是人類戰術解說或最優性證明。

## 回合執行與生命週期

GameStore在main actor持有session。Task.detached持有完整快照，規劃不阻塞UI。交付時驗證取消、generation、完整狀態相等、電腦陣營與當前回合；即使工作忽略取消而晚回合法計畫，也不得提交到新棋局。先Core驗證整份計畫合法、長度與回合邊界，再逐步提交session。fallback只合法結束回合，不轉換成隨機落子。

原生測試用DEBUG專用30秒、不合作的工作回傳（留足SE原生選單操作時間），證明undo／restart／exit後實際晚到结果作廢；不是僅斷言Task已取消。正常入口測試使用真正Bot和正式newGame，不用預置Bot回覆。

## 重現驗證

從本worktree根目錄：

```sh
swift test --package-path swift/TacticalGoCore
TACTICALGO_DOTNET=/tmp/tacticalgo-dotnet/dotnet python3 scripts/verify-ios-parity.py
swift run -c release --package-path swift/TacticalGoCore tacticalgo-bot /tmp/bot-match.json Warrior Mage
swift run -c release --package-path swift/TacticalGoCore tacticalgo-bot --replay /tmp/bot-match.json
swift run -c release --package-path swift/TacticalGoCore tacticalgo-bot --benchmark /tmp/bot-benchmark.json
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO \
  -only-testing:TacticalGoUITests/PlayableGameTests test
```

CLI職業名使用Core rawValue（以Runner輸出setup為準）。完整結果、固定局面、原生截圖、性能與安裝狀態見 `../../artifacts/bot-01/REPORT.md`。測資是手寫局面与Core observable結果，不以評分數字當預期。

## 尚未解決

密集盘面常認為合法落子劣於pass，造成長期跳過直至100回合和局；實際trace與診斷保留。這是有限搜尋／啟發式侷限，不能用「合法終局」證明會玩或好玩。初輪沒有難度選擇；後续 BOT-03a 已提供簡單／標準與黑白選擇。職業深入策略、強 AI、英雄重新部署與第二技能仍未提供。BOT-02／03待Owner驗收，R2仍opt-in候選、正式規則不改，G5真人策略驗收繼續獨立。


## Owner追加：電腦下棋必須看得見

2026-10-09 Owner試玩反馈「電腦要有下棋的動作，不然看不出來」。BOT-01增加最小A0演出接線，不新增素材或重做動畫框架。完整計畫先驗證，之後每一步先指示目標／座標／第N步，再commit并播放原圖落下／推動／換位／提子，兩步間保留停頓。預設每步準備0.9秒、落定0.9秒；減少動態保留靜態提示與順序。正式技能效果不改。

演出中的玩家輸入鎖定到最後落定，復原／重開／離開仍可中止；每一次await後重新核對generation/電腦方/完整state。第一步已提交後undo仍撤回到上一人類決策；背景最後落定時恢復玩家文案與完成計數，避免舊task再提交。只讀Bot Agent已review，實際原生與錄影以artifacts/bot-01/REPORT.md最新結果為準。

Debug `--bot-step-review`在每phase等候「下一演出階段」測試按鈕，供穩定讀取AP／截圖；不改Bot選擇或規則，Release不含此按鈕。`--bot-mage-motion-review`由手寫反色固定局面讓真Planner選推動＋落子斬首，僅驗演出，不冒稱正式開局對戰。

## 2026-10-09 Owner追加：BOT-03a 難度與執色

Owner實際試玩確認逐步落子「ok」，另回報尚未贏過，授權簡單／標準與選黑／白。只做最小難度與單人方別，不展開BOT-02、完整BOT-03效能／難度調平，不改Domain、AP、Mana或技能。UI預設簡單；API預設標準保持相容。簡單仍看己方完整回合與直接斬首／救援／召喚／技能，但候選束至多4、顯式apply至多1600，略過對手完整回合搜尋；這不保證玩家會贏，未驗實際勝率梯度。

你可執白、電腦執黑，黑方第一回合1AP自動開局，之後2AP；人機角色與回合提示由實際陣營推導。白方尚未行動前沒有可復原的人類決策，避免撤回電腦開局後卡住；之後復原保留電腦開局並回到上一人類決策。局中改難度保留已提交Core狀態／AP／每回合技能旗標，取消舊generation後重新規劃剩餘回合。真機與原生結果見artifacts/bot-01/REPORT.md最新區段，不升格G5或正式發布。


## 2026-10-09 — 現行可玩 iOS 與 Owner 追加範圍（取代前述 G0 Pending／SwiftUI 未開始的歷史狀態）

Owner 已實際玩過 Windows 與 iPhone 單人版本，確認電腦逐步落子可辨認。Swift Core／SwiftUI 本機雙人與三職第一技能、7×7 Bot、V2 接線均已有工程交付；G5 完整真人／平衡驗收仍未通過。A0 原卡＋Token 維持，不重啟 3D、美術或第二技能。

本輪最小追加：選角可選黑／白和簡單／標準，預設簡單。簡單保留己方完整回合、直接勝負與主將救援，減少候選並略過對手完整回合搜尋；不保證人類獲勝，也未測勝率梯度。選白時電腦黑方自動首回合 1 AP；复原保留電腦開局。局中改難度作廢舊決策，保留已提交 AP／Mana／技能旗標，僅重新規劃剩餘回合。

Owner 另授權將 Audio Agent 的音樂／音效整合進此候選並安裝 iPad。只接入原程序合成 BGM＋11 SFX、AVAudioPlayer、成功事件時間表與持久化聲音設定；不覆蓋 Bot、Domain、A0 素材或引入完整 CombatBoard 視覺改版。undo／restart／離場／背景／難度切換取消舊 cue。無聲的正常 endTurn 保留已成功技能的落定音；勝負聲在單人模式依玩家方別選 victory／defeat。iPad 目前使用 iPhone 相容呈現，非平板原生布局验收。

目前獨立 worktree codex/bot-01，不 commit/push/merge 或正式發布。來源、測試、失敗／修復與雙裝置安装以 artifacts/bot-01/REPORT.md 為準。BOT-02、完整 BOT-03 與 R2 未開始。


## 2026-10-09 — 不等待建模：存局、棋譜與技能試驗

Owner 授權將可玩功能先完成；SAVE-01 / REPLAY-01 已接入大廳與局中選單。正式局成功動作原子存本機版本化 journal，Domain 重播還原完整 GameSession／AP／Mana／Ko／undo；壞檔保留、失敗警告、電腦中途續玩只規劃剩餘 AP。唯讀棋譜逐手看事件與資源，可匯出 JSON，不改 live game。

BOT-03b 有限校準已交付候選：滿 Mana pass 評分及簡單近最佳選擇；兩局 100 回合模擬仍和局且長期 pass，因此不聲稱已解決密集盤面或人類難度梯度。R2 既有八個固定局面 A/B/C/D 新增 opt-in 原生試驗入口；正式新局原版規則不變，不做第二技能。A0 卡／Token、音訊與 Core 保持原 SHA；V2 新美術仍等待 Owner 確認素材，不重新建模。

本輪 79 Package、手機 9／平板 5 原生操作測試通過，38 Golden／99 steps／137 snapshots 等價，R2 32 probes；存局按 L2 完整性檢查。Release 已 Wi-Fi 更新 iPad，啟動因 Locked 拒絕；iPhone unavailable，本輪新版手機更新尚未完成。先前雙裝置安裝不能代表本輪手機已更新。工程候選完成不代表 G5、R2 正式採納或真機驗收。詳見 artifacts/ios/product-playability/REPORT.md、validation.json、final-source-manifest.json。仍於 codex/bot-01 未提交，不 commit/push/merge/發布；以上現況取代舊條目，不增加新 Slice。
