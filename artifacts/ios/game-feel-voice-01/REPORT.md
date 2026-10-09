# GAME-FEEL-10H-v2｜工程候選交付

結果：S0–S7 完成可檢查的 SwiftUI 聲畫候選；Owner 產品／美術／聽感驗收 Pending。
原因：沿用 Cozy-02、成功 Domain 收據、既有 MotionPlan 與畫面持有的 CombatAudio；沒有另寫棋規、改技能或重做人臉。
下一步：試玩隔離候選與六句英文語音，決定接受或修改；不 merge、TestFlight 或發布。

## 候選與工作界線

分支 `codex/game-feel-voice-01`，基線 `cdab133` 加本輪保存的既有 Cozy 接線。UI 繁體中文；B2-B 士兵、既有 B-v02 英雄與固定 Cozy-02 語意色。原 Desktop checkout、Visual worktree／凍結來源包不修改。完成即停止新增功能；10 小時為最多約略工作窗口，不用等待裝置耗滿窗口。

| Slice | 工程結果 | 證據／產品邊界 |
|---|---|---|
| S0 | PASS | 17542ec 保存此前原生 Cozy 候選；原始盤點 S0-baseline.json |
| S1 | PASS | 630c40b：6 句可替換離線英文 TTS、Voice/BGM/SFX 分離、一句不排隊、取消／背景／中斷／普通第二 AP；最後素材 V3 |
| S2 | PASS | 3 職真實召喚、約 460ms 淡入／抬升／落定／局部雙圈；動畫後可繼續下棋，語音無需先播完 |
| S3 | PASS | 魔法之手 80ms 準備→220ms 推動→100ms 落定，僅真實 piecesCaptured/gameWon 接提子／勝負；預覽不移動、不扣費、不播成功台詞 |
| S4 | PASS | 戰士局部盾牌與兩兵同步落定；盜賊雙向換位與短 lift，保留雙方棋子身份與正式提子 |
| S5 | PASS | 普通兵短落下、被提縮退／淡出、主將局部退場環及真正胜負；不再瞬間換盤 |
| S6 | PASS（可用工程環境） | Package／Golden／原生模擬器／Release；實體前景及人耳 Pending |
| S7 | PASS（推送以 DELIVERY.json 為準） | 原生操作影片、明示後製音軌、6 句試聽、來源與 SHA、隔離提交及 push；無 merge／發布 |

所有演出由 before/action/outcome/after 的成功收據建立。動畫結束不再 apply、不扣第二次 AP/Mana、不重新判勝。最後 AP 改變當前玩家時，語音仍依 before.current 選職業。預覽保留原位和空目的地。取消、復原、重開、離場、背景和音訊中斷清除過期呈現；Reduced Motion 直接呈現正確終態並保留必要聲音。

普通第二 AP 可保留尚未播完的已確認台詞；新的英雄台詞停止舊台詞、不堆疊。真正 Bot 決策不修改，只在真人動畫完成後排程既有電腦回應，避免真人與電腦演出重疊。

## 驗證

- Swift Package **156 tests / 0 failures**：S6-package-all.log。含獨立成功／失敗／資源／雙方／最後 AP／正式與候選規則隔離，以及 presentation timing。
- Golden **38 fixtures / 99 steps PASS**：S6-golden.log。此為既有 C#／Swift 等價重播，不能证明全部棋規或遊戲樂趣。
- iPhone 390 pt Simulator **22 tests / 0 failures**：S6-native-phone-final.log。V2 Piper 素材、同一聲畫接線；包含雙方召喚／技能、取消／非法／快速確認／復原、7/9 密集、Bot 逐手及重開／離場、存局／復原／候選副本、聲音設定。
- SE 320 pt Simulator **2 / 0**：S6-native-se-final.log，9×9／密集／Reduced 等比投影；V2 素材。
- iPad V3 final Simulator **4 / 0**：S6-native-ipad-v3-final.log。portrait/landscape/rotation、9×9 選點、操作／取消復原及真正畫面持有音訊 owner **64 項 PASS**，目前六句 V3 音檔。
- V3 六句原生實際操作錄影 **1 / 0**：media/S7-demo-native.log；普通落子／主將提子／復原錄影 **1 / 0**：media/ordinary/S7-demo-native.log。
- V3 phone focused **2 / 0**（Voice64／設定持久化）：S6-native-phone-v3-focused.log，實際 audit JSON 為 S6-v3-hero-voice-audit.json；不以歷史 V2 結果冒充最後素材。
- 成功收據原生 frame audit **24 項 PASS**：S4-S5-game-feel-frame-audit.json，含召喚 start/end／重複確認、築壘同時兩兵、換位半程及身份、普通提子／主將胜負、Reduced 與 actual SFX。
- iOS Release build／signed device Debug **PASS**：S6-release-v3-final-build.log、S6-device-v3-final-build.log。
- 原生 UIKit/SwiftUI 操作、資源與 before/after 可於 media/game-feel-receipts.json、demo-edit-audit.json 核對。示範局來自正式 GameSetup／Core，非偽造動畫盤面。

曾遇到並修正的問題：iPad portrait width-only 棋盤擠掉操作區，改依可用高度與同一 8:9 投影排版；新增 Voice section 後設定 Form 需捲動；landscape 任意 width>550 測試改為 9×9 實際 spacing>44；語音 duck 恢復 audit 需等待已定義 750ms release。失敗 log 保留在本機，沒有刪除後宣稱一開始就全綠。另有錯誤 Golden product 名稱與影片奇數編碼寬度的工具失敗，修正後才取 final 成功結果。

## 真機與模擬器邊界

Mac macOS 26.6.2、Xcode 26.6（17F113）、SDK 26.5。真正 iPhone 16 Pro／iOS 27.0（24A437）已經 Wi-Fi 安裝 **0.8.0（802）**、獨立 bundle `com.tacticalgo.prototype.gamefeel`、名稱 **TacticalGo Hero Voice**；S6-phone-v3-install.log 保留成功結果。原 App／存局不覆寫。

安裝不等於前景驗證：初次 launch CoreDevice 4000 transport timeout；重試取得連線後 **Locked／CoreDevice 10002** 拒絕啟動。未取得此次 V3 真機播放／手勢／影片，人耳揚聲器及耳機聽感 **Pending**。iPad 新版未安裝（資訊連線逾時）；本輪 iPad 4 tests 是 Simulator。既有 Cozy 真機 audit 17／iPad 2 為歷史證據，不當成 V3 真機完成。

## 可看／可聽交付

- media/native-hero-game-feel-demo.mp4：**23.1 秒**、真正 iOS Simulator SwiftUI XCTest 手勢，依七個成功收據剪輯三職召喚／技能及條件提子／胜利。
- media/A-mage-summon.mp4、B-magic-hand.mp4、B-magic-hand-capture.mp4：兩個主要 Gate 的短片。
- media/ordinary/native-hero-game-feel-demo.mp4：真正普通落子／主將被提。
- media/warrior-two-lines.mp3、mage-two-lines.mp3、rogue-two-lines.mp3：目前 V3 六句離線 TTS 分職試聽；不是已核准演員表演。

**影片音軌是依實際 AVAudioPlayer 起播時間／音量／停止事件重建的後製聲軌，非裝置或 Simulator 系統收音。** 片內有固定英文標籤；正常候選 BGM 關閉／正式整合 HOLD。播放器起播及後製吻合不能代替人耳聽感或硬體端到端同步驗收。

原始 silent.mov、完整 .xcresult 與中間片留在本機證據目錄，不把大型衍生 Build／模型／Python runtime 推到 Git。錄影及剪輯腳本保留；capture-ready 回應作為時間零點，未宣稱硬體 audiovisual timing 精度。

## 來源與可替換性

六句原話、輸出 SHA／時長／處理方法、generator/runtime/model/config SHA 在 `ios/TacticalGo/Audio/Voice/manifest.json`；Source check 六檔 SHA 相符、PCM 無削波。同 pinned Piper 1.8.0／ONNXRuntime1.31.0 CPU macOS arm64，seed 在 session load 前設定：兩個獨立進程六檔 bit-identical，見 S1-repro-check.json。不是跨平台 bit identity 保證。

使用 LibriTTS high 模型訓練卡（from scratch）、OpenSLR SLR60 CC BY 4.0 與保留歸屬，匿名 speaker index 每職固定；不模仿現有遊戲英雄／演員、不使用付費 API／不外送角色原圖。Piper GPL 工具與模型僅開發端，App 沒有打包引擎或模型。來源主要文件、條款連結與保守 CC BY 4.0 歸屬在 Voice/CREDITS.md；完整商用權利與聲線品質仍需正式發布前確認。

早期 Apple System Voice 本地試驗因 macOS Tahoe SLA 2F 公開分享限制，在尚未 push 的 S1 提交中已替換；本分支推送歷史不含那六個 Apple 產物。既有 AUDIO-01 11 個程序音效原始 manifest／生成來源未改。角色與凍結 Cozy 來源身份、Domain、Bot 決策 diff 檢查見 DELIVERY.json。

## Owner 待驗收

三職聲線是否有角色個性、召喚與技能是否有存在感但不遮戰術資訊；真機揚聲器／耳機聽感及同步、iPhone/iPad 真機動態操作、美術整體一致性與正式素材權利。均 Pending。這次不宣稱玩法更好玩、真人驗收通過、正式 BGM 啟用或發布完成。
