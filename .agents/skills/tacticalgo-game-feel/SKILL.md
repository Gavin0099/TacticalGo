---
name: tacticalgo-game-feel
description: Research, design, iterate, and review TacticalGo screen style, board UI, animation, VFX, sound effects, and music against Hearthstone presentation quality and D&D tabletop references. Use for coordinated audiovisual polish and before/after comparisons; character creation and gameplay rules are separate concerns.
metadata:
  version: "1.6"
---

# TacticalGo Game Feel

讓整體畫面、操作、動畫和聲音呈現一致的奇幻桌遊質感。Owner 在 2026-10-13 指定以《爐石戰記》為品質標竿，先研究 D&D 類遊戲、repo 與 skill，再建立可持續迭代的方法。目標涵蓋完整遊戲畫面，不只技能特效。

《爐石戰記》提供比較標竿；TacticalGo 現行角色、棋盤語義及最新 Owner 選擇決定作品身份。既有畫面是可比較的基線，可以改善材質、光影、面板和節奏，不能因沿用 A0 而把視覺永久凍結。品質目標不等於已達成的品質結論。

## 開始時確認

1. 找到實際工作的 TacticalGo checkout，記錄 branch／commit／dirty state。不要假定目前目錄就是最新 iOS 版本。讀當次 Owner 指示、`docs/PLAN.md` 最新相關段落、`docs/DECISIONS.md` 和 `docs/RULES_DRAFT.md`；遇原版／R3 差異，核對實際設定與測資。歷史待辦不覆蓋較新的 Owner 指示。
2. 區分本次要求的是研究、比較候選、正式程式整合，或已授權的連續迭代。按要求完成，不為例行可逆修正反覆詢問；研究／skill 建立不自行擴張成整套遊戲重做。
3. Owner 在 2026-10-13 已指定 `codex/v11-monster-battlefield`（曾口述 v11-moster），舊 main／AV-STYLE-01 不能再充當新版證據。先 fetch 核對本次最新指定分支；這不是永久固定 commit。
4. 先看實際遊戲畫面與現用素材，再作美術判斷。照片、概念圖、舊 HTML 與程式碼都不能替代當前 runtime 畫面；缺少時清楚標示，仍可完成來源研究和候選設計。
5. Owner 後續已認可 UI20 風格，先完成主畫面與 icon，再明確指示開始動畫及自主優化。沿用同一風格迭代四職演出；原生驗證缺口持續標示，不把UI20認可當成最終聲畫品質驗收。

## 依工作載入

- 操作區／全遊戲 UI：讀 [共用遊戲介面契約](references/game-ui.md)。Owner 已要求整體一致，不等他逐個指出仍像表單的區域。
- 全畫面／材質／人物卡／棋盤／文字：讀 [視覺與聲音風格](references/style.md)。這是共享風格基準。
- 研究競品、尋找 repo／skill、選比較片段：讀 [來源與借用範圍](references/sources.md)，再開需要的原始來源；不要每次重搜全部資料。
- 動畫／音訊接線：另讀 [實作定位與已知缺口](references/integration.md)，現場重查呼叫路徑。
- 自主迭代／品質驗收：讀 [比較與停止條件](references/iteration.md)。需要交付記錄時使用 [迭代記錄模板](assets/iteration-record.md)。

## 工作方式

**先建立一段可比較的完整體驗。** 固定同一棋局、鏡頭、尺寸與操作序列，先存目前基線，再提出明確改善假設。一般先做一個完整主畫面，以及一段「選取 → 預覽 → 確認 → 技能 → 落定／提子 → 回到可操作」演出；同時檢查四職業的共用介面，不必為比較重畫整套人物。

全畫面比較至少能回答：第一眼看哪裡、誰走、主將危險在哪、技能能選什麼、確認後發生什麼。裝飾的材質、邊框與陰影應建立層次；密集盤面仍須保有棋盤交叉點、棋子和提示的辨識。

獲得實作範圍後，可獨立迭代排版、材質、曲線、時間、特效、混音與已授權素材。每輪保留前版、實際截圖／影音及比較理由；獨立 reviewer 看相同證據，不預先告訴它哪個候選應勝出。不要用 token 消耗、測試數或自己的綜合分數宣告「達到爐石水準」。

## 非視覺狀態與素材

- 正式盤面、AP、Mana、提子、Ko、勝負只由 Domain 決定。呈現使用成功 receipt／事件及 before/after snapshot；不能讓動畫回呼執行規則。原版、候選與教學 fixture 明確標示。
- 預覽不播放施法成功或提子音。取消、復原、重開、離場、背景、過期非同步結果不得留下棋子殘影或舊聲音；降低動態仍能知道同一結果。
- 保留現用人物身份和黑／白陣營辨識。新人物／拆層素材若在範圍內，使用可用的 `tacticalgo-character-style`；若不存在，直接依已檢視的現用個別參考鎖定身份，不阻塞其他工作。圖片生成或編輯使用適用的 image generation 工具。
- 先確認聲音生成來源及素材真的存在。來源 manifest、可編輯 source、runtime 成品、來源權利是不同證據。沒有生成器時可在授權範圍建立原創可重現來源，不能把 WAV／舊外部路徑冒稱原始工程。
- 外部遊戲畫面用來研究，不直接成為遊戲素材。需要採用第三方 code／音訊／字體時逐項核對實際授權；不因搜尋 repo 自動安裝依賴、付費或改用另一個引擎。

## 交付與品質判斷

交付能看／聽／操作的候選與同條件前後比較，說清楚哪個差距改善、哪些仍不滿意、證據是 mockup／browser／simulator／真機的哪一種。若工具無法實際聽音或跑 iOS，就明列聽感／原生驗證缺口。

「工程檢查通過」、「風格一致」、「相較前版更好」、「接近指定競品片段」與「Owner 接受」分別陳述。持續迭代以已定義的差距和證據前進；沒有改善或缺少必要評估能力時，保留最佳候選並交出具體待決，不自行升格品質。
