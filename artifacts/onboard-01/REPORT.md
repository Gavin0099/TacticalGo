# ONBOARD-01：TUT-0／TUT-1

結果：基礎教學工程候選已實作，真人理解與約五分鐘目標仍待驗證。
原因：使用既有 Swift Core 的真實操作、查詢與事件完成五個小目標，不修改規則。
下一步：Owner 試玩本輪基礎流程；觀察卡點後，再決定 TUT-2～4。

## 試玩入口與交付

大廳「新手教學 · 不需要懂圍棋」。可以隨時退出，重入繼續，或確認後重新開始。完成後返回自由對戰選角。教學與正式對局的 journal 分開保存；既有選角、電腦、原版／候選對局、存局及音訊不改規則。

流程及完整文案合約：`docs/onboarding/ONBOARD_01.md`。每關文字和固定棋形：`swift/TacticalGoCore/Sources/TacticalGoOnboarding/Fixtures/onboard-v1.json`。Session、預覽、進度驗證及獨立持久化：`Sources/TacticalGoOnboarding/Onboarding.swift`。iOS 入口與畫面：`ios/TacticalGo/OnboardingView.swift`。

| 小目標 | 真實操作／獨立預期 |
|---|---|
| 認識勝負 | 黑 D3 封住最後氣，提白主將 D2，Core 判黑方勝 |
| 第一次落子 | 原版開局黑 C6，首回合1 AP；落子後白2 AP，普通落子不扣能量 |
| 讓棋子呼吸 | 先點 C4／D4，看二子共享6氣；E4 連接後三子8氣，也接受合法替代連接 |
| 包圍敵兵 | 白 D3 一氣，黑 D4 提一兵，沒有主將勝負 |
| 拯救主將 | 黑 D5 主將一氣，D4 連接後共享3氣，警示解除 |

點棋顯示 Core 棋群及綠色氣點；落子前預覽實際提子事件與資源，不扣資源。預覽時文字明示「目前（預覽前）」氣數，將被新子佔用的氣點改用空心。主將危險提示依 Core 判斷。本輪教學使用靜態結果，沒有假動畫、假提子或新戰鬥演出。

SE 提供大按鍵選點，測試其點選按鈕至少44×44 pt；棋盤最近點命中與共享 BoardProjection 一致。這是小螢幕操作替代，不表示所有實際使用者已感到舒適。

## 驗證

- `package-delivery.log`：144 個 Swift Package 測試通過，其中13個新教學測試。包含失敗與越界不扣資源、不寫 journal、手算角落／邊界／非斜角群與氣、明確提子事件、預覽等於提交、首回合資源、復原／完成邊界、合法替代、重播及壞檔保留、正式存局 bytes 不變。
- `golden.log`、`golden/`：重新產生 C# 基準，38組／99步／137份完整快照等價，包括有序事件 payload 和非法結果。參考版本 `54deef97e0fb7157b0025a7282fc2c0a448d4fb9`。等價不證明原規則的平衡或正確性。
- 原生最終結果與簽署／安裝狀態列於 `validation.json`。SE、iPad 使用同三項測試：五步真實操作／預覽取消／共享氣／主將勝負／復原；journal 重啟／背景清暫態／大按鍵／取消重設與確認重設；退出正式局／取消退出／教學／返回原存局。
- `source-before-tests.json` 與 `final-source-manifest.json`：Golden 執行後修改三個 iOS 畫面／原生測試檔，以及教學 journal 觀察前置驗證與其負例測試。原有 Core、Bot、Records、內容與 Golden Fixture 均未變；教學修正後重新執行整包144項與原生流程。

可重現命令：

```sh
swift test --package-path swift/TacticalGoCore
TACTICALGO_DOTNET=/tmp/tacticalgo-dotnet/dotnet python3 scripts/verify-ios-parity.py artifacts/onboard-01/golden-repeat
xcodebuild -project ios/TacticalGo.xcodeproj -scheme TacticalGo -configuration Debug -destination 'platform=iOS Simulator,id=97B346CB-21D7-41DB-AE79-4B667C3B1566' CODE_SIGNING_ALLOWED=NO build-for-testing
```

原生精確 destination、篩選的三個測試及 xctestrun 命令保存於原生 log 開頭；選取同一設備的 Core 等價命令不需原生硬體。錄影、截圖為模擬器實際操作，不是 iPhone／iPad 真機操作或真人測時。

最終 SE、iPad 各3項／0失敗，證據 `phone-onboard.log`、`pad-onboard.log`。实际模擬器錄影 `se-onboard.mp4`（83.8秒）、`ipad-onboard.mp4`（81.4秒）包含測試啟動、操作與安全回歸，沒有系統收音。已檢視 `phone-capture-preview.png`、`pad-shared-liberties.png`：SE 確認文字完整，預覽前氣數標示明確；iPad 氣點與群疊層對齐。這不是零經驗玩家的完成時間。

Release 編譯與 frozen app 的 strict codesign 通過。iPad 經 localNetwork 安裝成功；自動啟動因 Locked 被拒絕，Owner 解鎖後可自行點 TacticalGo，再由大廳進入教學。手機目前 unavailable，本輪尚未更新。私人裝置收據保留本機，不提交。沒有真機教學操作或聽感验收紀錄。

`resource-integrity.json` 確認50個既有受版本控制的視覺／資源檔未變，19個音訊資源與前版 frozen bundle 一致。可安裝候選 SHA 及逐檔資訊保存於 `release-manifest.json`。

## 修正與保留的失敗證據

1. 首次新增測試編譯受 CapturedPiece 內部建構子限制：測試使用 `@testable import`，没有修改 Core API。
2. 開局能量曾錯誤預期3：按已建立的首回合加1合約改為4；不是修改正式規則迎合測試。
3. SE 確認文字被截斷：顯示縮為「確認」，無障礙仍為「確認落子」。
4. iPad 返回確認視窗未可靠呈現：穩定識別子仍找不到按鈕，錄影與 UI hierarchy 確認留在原盤面。改用置中 alert，補取消退出／確認退出測試。不是只略過失敗或調高等待。
5. 教學重設同樣使用置中確認，測試取消保持進度、確認回第一關、重啟仍第一關。背景清除尚未提交預覽，已提交 journal 保留。
6. 教學 journal 必須與 commit 的「先觀察棋群，再落子」合約一致；合法落子但缺觀察紀錄的壞進度會拒絕保存，原檔不被覆寫。追加負例後重新跑全包與原生。

失敗的 `unit-r1.log`、`unit-r2.log`、`pad-safety-r1.*`、`pad-final.*` 及後續通過結果均保留。早期0測試編譯不計驗收；重跑不重複累加測試數。

## PASS／HOLD 邊界

TUT-0 與 TUT-1 的工程結果以 `validation.json` 為準。完整 ONBOARD-01 產品 Gate 仍 HOLD：沒有5位零圍棋經驗玩家紀錄，沒有真機教學操作錄影，也沒有約五分鐘的理解證據。安裝成功不等於真機操作驗收。TUT-2 三職技能教學、TUT-3 對局內持續氣數／提示開關／規則查詢擴充、TUT-4 真機及真人測試未啟動；本輪不宣稱完成所有交付物。

R3 候選仍不是正式技能，沒有自動帶入教學；原版規則、既有音樂／音效和 HOLD B1 素材地位不變。Bot 標準後期停滯、R3 實際樂趣仍未解決／未驗收。本輪不新增平衡、大招、美術或建模。

成果留本地 `codex/onboard-01`，隔離提交列於 `delivery-commit.log`；没有 push、Draft PR、merge 或發布。真人驗收待 Owner，不以工程全綠替代。
