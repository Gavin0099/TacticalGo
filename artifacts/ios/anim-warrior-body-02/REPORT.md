結果：完成戰士-only本體續修候選，英文英雄語音維持未驗收／關閉；三職動作尚未全部由Owner確認，未開始VFX。
原因：上一版出手中途再次停頓、握劍手與盾邊留下碎片；本版改成單次蓄勢停拍、連續下擊及雙兵同拍落定，並補齊原畫裝備遮罩。
下一步：觀看正常速度完整棋盤與同局面舊新版對照，確認戰士動作；三職本體都經Owner確認後才進特效，語音仍需另外驗收。

本輪分支 `codex/anim-warrior-body-02`，基線 `eb7be20`。既有法師與盜賊姿勢／角色身份保持；沒有新人物、3D Mesh、台詞、技能特效或規則改動。隔離commit／push依Owner既有授權；未merge、TestFlight或發布。正式美術／角色表演Pending。

## 可以直接觀看

- [完整棋盤、正常速度、靜音六段](media/warrior-w1-full-board.mp4)：召喚、築壘無提子、黑方實際主將提子、白方實際主將提子、320pt容器／9×9密集局面、Reduced Motion。
- [舊新版同局面並排](media/warrior-before-after-native.mp4)：相同before／after／正式事件，皆1倍速；以各自成功收據前450ms對齊。只將片尾已結束的靜止畫面補長，不改動作速度。非逐幀動作捕捉。
- [預覽、取消、確認與復原](media/warrior-preview-cancel-undo.mp4)：真實Simulator／XCTest操作，未重建角色或後製配音。
- [32／48／64pt黑白角色姿勢](hero-body-review/warrior-black-white-48.png)：ImageRenderer真實SwiftUI圖層樣本，不能取代完整棋盤或實機。
- [完整棋盤落定檢查點](hero-body-checkpoints/warrior-settle.png)：已成功收據在實際arrival時刻的SwiftUI棋盤，與完整操作影片分開標示。

影片是Simulator原生畫面，靜音、無後製音軌；不是實體iPhone錄影。完整錄影raw MOV、xcresult及初版修補的失敗／中間建置仍保存在本機，選定影片與驗證摘要可在分支檢查。

## 修改與時間表

`HeroPerformance.swift`只調戰士：200ms收盾蓄勢、70ms停拍、340ms出手、350–480ms兩兵同步落定、540ms開始正式條件提子、550ms完成接觸回震、780ms回待機；有終局事件可延長收尾，不再apply。召喚210ms身體接觸／盾牌落定、300ms穩住、640ms回待機。

`HeroBodyView.swift`以原畫完整盾邊與徽記為剛性層；握劍手、銀色護腕及金色護手同一變換，避免獨立碎片。臉、頭髮、服裝與裝備原畫未替換；沿用已凍結clean plate，只取原畫alpha內的衣料遮擋補圖。本輪沒有生成或修改bitmap。來源與遮罩程式SHA見 `assets/candidates/anim-warrior-body-02/rig-and-timing.json`。

原B-warrior-v02 SHA-256：`50885855dc9faee8966558ea854f99d24bd0ffd0ed93c03bb6b87c8643d42298`。

## 驗證與可重現入口

- Swift Package：170項、0失敗。新增回歸檢查出手到落定期間盾牌持續下擊、接觸重心較低及落定後回震；不能當美術／氣勢判定。
- Golden：重新執行Swift的38組／99行動／137快照，與保存的C# transcript完全一致，包含盤面、資源、錯誤與有序事件。這輪沒有重新執行C#；等價不證明原規則設計正確。
- 原生Simulator：4個測試執行非0，全部通過：共享成功收據／取消／復原、第二AP與背景、SE的320pt容器／9×9黑白密集Normal／Reduced、六場景錄影。共享畫面GameStore的108項狀態檢查通過，包含不重複結算、資源與SFX共用時間表、英雄語音關閉、播放後解鎖與重開。
- ARM64 Simulator Release build通過；本機簽名device build通過。
- `python3 scripts/verify-warrior-body02-delivery.py`核對上述非0測試、收據、來源SHA、六影片SHA及相對基線無Domain／Bot／投影／MageBodyView改動。程式不能判定演出好看。
- 原生記錄：`HERO_BODY_MEDIA=artifacts/ios/anim-warrior-body-02/media HERO_BODY_RECORD_TEST=testWarriorBody02NativeRecordingWalkthrough python3 scripts/record-hero-body-native.py`；需先build-for-testing，保留既有raw，不覆寫。

實際390pt容器的7×7棋盤382×429.75pt，交叉點pitch約46.56pt，角色canvas約41pt。320pt容器棋盤312×351pt，9×9 pitch約28.52pt、角色canvas約25pt；SE實際裝置viewport375pt，320pt是明確受限測試容器，不能宣稱是實體SE320pt螢幕。32／48／64pt姿勢表標示的是格距，角色canvas為約0.88倍格距。

公開log只正規化行尾空白，完整原始log另留在本機raw-logs，前後SHA見log-provenance.json；公開摘要見`delivery-verification.json`。一次並行build因共用Build資料庫鎖失敗，改為序列device／Releasebuild後通過，未把失敗隱藏。最初候選和最後盾邊修補前的錄影在本機保留，交付media為最後程式版本。

## 真機與未通過項目

iPad mini6／iPadOS26.6.1經Wi-Fi安裝獨立`TacticalGo Heroes`候選build1005；OS接受啟動請求。原遊戲bundle及原局不覆寫。UI runner初始化遇到「已取消認證」，真機UI操作測試沒有執行成功；直接launch後的in-app audit檔也未成功取得，不能推論真機108項通過、可讀性或流暢性。iPhone16Pro／iOS27.0目前unavailable，安裝失敗，仍是先前版本。沒有實體iPhone操作錄影，真機與Owner表演驗收HOLD。

固定頭胸像限制仍在：這是2.5D上半身分層，不是完整戰士身體，盾牌實際碰地／目標朝向的不同透視姿勢未畫；較大的動作仍可能露出衣料接縫或裁切邊緣。512px近景只用於接縫檢查，正式判斷看正常棋盤。小尺寸動作差異不等於足夠氣勢。

語音：播放功能曾有工程證據，但情緒、角色表演、人耳聽感與實機聲畫同步尚未Owner核准；維持HOLD、本輪關閉、不新增台詞或調聲線。特效：尚未開始；只有三職本體均得到明確Owner確認後才開VFX-01／02。
