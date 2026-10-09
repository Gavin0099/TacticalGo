# V2 素材接線介面 — IOS-V2-ASSET-01

Owner 2026-10-09 授權双軌：iOS Agent負責純Swift／SwiftUI、素材接線與事件播放；Visual Agent負責2.5D棋盤、士兵、角色素材品質與動畫演出。沿用V1資訊布局，不重新產生比較稿、不自行建模。此文件是共用交接規格，已送到「規劃 2.5D 美術與動畫」聊天；尚未取得新素材或確認另一Agent已接受／完成交付。

## 現況與本片交付

SW1純Swift核心、SW2本機雙人可玩版已存在；本片直接進V2接線準備。`TacticalGoVisuals`是獨立無Apple依賴的素材metadata validator，不修改Core API／規則。原生 `GameVisualAssets` 先整包解析圖片再選用；缺圖、尺寸錯誤或缺alpha時拒絕整包並保留原始A0。

`SwiftBoard`已接可選棋盤陰影／板面、黑白士兵／主將、三職Token；選角與人物資訊接同包B portrait。正常App仍明確選原始A0，候選資料夾或JSON的存在不會自動啟用新美術。預覽、取消、確認、復原和格點清單仍走原來的GameStore／Core。

## 圖片與命名

| 內容 | 建議交付畫布 | 資源命名範例 | 要求 |
|---|---|---|---|
| 全棋盤板面 | 1024×1152 PNG | `v2-board-surface-01` | 無棋子、格線、座標、狀態圈或UI；完整normalized畫布，透明外沿 |
| 全棋盤陰影／厚度 | 同板面 | `v2-board-shadow-01` | 可獨立替換；透明背景，與板面同位置 |
| 黑／白士兵 | 256×256 PNG | `v2-soldier-black-01`／`v2-soldier-white-01` | 不能只靠服装顏色辨識；不內建選取圈、危險或玩家字牌 |
| 黑／白主將 | 256×256 PNG | `v2-commander-black-01`／`v2-commander-white-01` | 不遮住原生黑白字牌 |
| A英雄Token | 512×512 PNG | `v2-token-warrior-01`等 | 保留原畫身份，透明、可報anchor；不直接使用B卡替代 |
| B人物卡 | 512×512或實際master尺寸 | `v2-portrait-warrior-01`等 | 不重染、換臉；原圖來源與Owner確認紀錄另附 |

以上是交接建議，不要求Visual Agent重做現有原圖；實際非正方形畫布可用metadata宣告，長寬各1…4096px。PNG可直接匯入對應Asset Catalog imageset，原生查找asset name，不讀外部URL／任意檔案路徑。黑白底座及英雄／主將字牌由程式保留；新單位圖避免把底座重複畫兩次。

## Anchor與圖層

畫布origin在左上，x/y均0…1。人物anchor是腳底／Token落在交叉點的基點，非頭部中心。寬度為 `widthInRadii × r`，高度保持圖片長寬比；offset分別 `(0.5-anchorX)×width` 與 `(0.5-anchorY)×height`。原A0 Token寬2.45r、anchor=(0.5,0.6632653061)，恰保留舊版-0.4r垂直偏移。

棋盤固定使用V1 `BoardProjection`，不由素材修改點選：rear-left=(0.13,0.18)、rear-right=(0.87,0.18)、front-left=(0.07,0.83)、front-right=(0.93,0.83)。7／9共享四個端點；y線性插值，row越前寬度越大。板面外邊框可參考rear=(0.09…0.91,0.10)、front=(0.01…0.99,0.92)。板面及陰影按照整個棋盤view bounds映射，視覺Agent須使用相同normalized畫布；不能把不匹配相機的盤面直接拉伸冒充對齊。

後→前：棋盤陰影／厚度 → 板面 → 原生格線／座標 → 合法位置／封印 → 單位陰影和黑白底座 → 單位圖 → 黑白字牌 → 選取／預覽／提子／危險。單位按row分層；狀態圈置頂。素材不攔截點選，交叉點命中只由Core的projection控制；9×9仍保留格點清單。

## Metadata與啟用

參考 `visual-pack-original-a0.json`（真實現有六張512px原圖）。schemaVersion=1，projection必須`v1-oblique`，heroes必須含warrior／mage／rogue，asset name限英數／短橫／底線。可省略棋盤／普通單位圖，對應層沿用現有程式畫面；所有被宣告的圖必須存在、尺寸一致且符合alpha要求，拒絕部分載入。

真正的素材接入分兩步：先驗證候選檔案、來源及anchor，再由Owner確認具體素材版本；iOS Agent才把該pack明確接入 `PlayableGameView` 的visuals。JSON本身沒有「自動核准」欄位，manifest valid不等於美術身份／發布權利核准。本片Debug `--visual-pack-fixture`重用現有原圖測接線，`--visual-pack-invalid-fixture`故意缺一張圖測整包拒絕，不作新美術預覽。

## 技能與動畫事件交接（本片不製作動畫）

播放來源是 `BoardPlayback`：id、before、action、outcome.state及**原序outcome.events**。只有成功commit產生receipt，preview不播施放；undo／newMatch／practice清空receipt。動畫永遠不扣費、移棋或判勝，動畫完成也不呼叫再次apply。

| 引擎事件／Action | 素材所需演出語意 | 結算來源 |
|---|---|---|
| piecePlaced／placeSoldier、summonHero | 落子／召喚，在事件at落地 | event owner／kind／at |
| castBastion及兩個piecePlaced | 戰士施放、兩點築壘 | action兩點與before的英雄位置 |
| piecePushed／castMagicHand | 法師方向推動 | event from／to／piece，支援雙方士兵 |
| piecesSwapped／castSwap | 盜賊與士兵換位 | event兩點、before兩顆棋 |
| piecesCaptured | 原位置退場，含主將／英雄 | event完整CapturedPiece payload |
| gameWon／gameDrawn | 勝利／和局 | event結果，不自行看畫面判定 |
| turnStarted／resourcesSpent | HUD更新／換手 | 已提交outcome.state |

既有MotionPlan是歷史3D研究排程，尚未提供Magic Hand cue；新A0動畫不能直接宣稱該plan已支援全部玩法。後續A1–A5接入時補適當typed cue或直接adapter，另片測試，這一片保留原始事件不丟失。Seal事件僅歷史相容，不能當現行法師技能。

動畫素材交付需另附clip名、總時長、anticipation／impact／settle時點、pivot、frame序列／atlas尺寸與透明背景；技能各用事件坐標定位，不烘焙固定D4到E4。尚未收到動畫素材，所以本片不臆定frame rate或建立新動畫框架。A1–A5要另驗證減少動態立即呈現最終狀態、取消舊播放、復原與重開不留下ghost。

## 驗收界線

本片驗證metadata pass/fail、非正方形anchor、整包載入拒絕，以及原生接線後的預覽／取消／換手／復原／完整對戰。新美術尚未整合，V1視覺Gate、iPhone最新畫面Owner驗收、iPad真機與原生布局未因此通過。第二技能與R2正式預設不修改。測試與實際截圖見 `artifacts/ios/v2-asset-interface-v01/REPORT.md`。
