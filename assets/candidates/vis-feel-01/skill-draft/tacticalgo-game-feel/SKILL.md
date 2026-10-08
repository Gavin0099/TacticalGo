---
name: tacticalgo-game-feel
description: Improve TacticalGo board readability and selection, skill-preview, and capture feedback using existing assets; create static/motion comparisons and review evidence. Use for TacticalGo visual interaction work, not hero generation or gameplay rule changes.
metadata:
  status: draft_owner_review
---

# TacticalGo Game Feel

讓玩家看清棋局、知道操作對象與確認結果，同時保留可愛木質微縮桌遊感。先使用現有 A 職業符號棋子＋B 人物卡，不以全身立繪縮圖承擔小棋盤辨識。

先讀當次 Owner 指示、視覺計畫與資產來源，確認允許檔案、技能版本與未通過的 Gate。預設在獨立 Visual worktree 的候選素材與比較文件內工作；不因視覺比較修改 Domain、Gameplay、BoardView、Windows UI、KCK 或推進 Gate。使用者明確要求正式整合時另依該範圍處理。

每次使用前，必須核對當時有效的 `RULES_DRAFT.md` 與 `DECISIONS.md`，記錄規格版本或有效檔案 SHA-256。以下魔法之手描述是本輪視覺 fixture 的規格快照，不能當作永久正式規則。若與當次有效規格不同，先按有效規格調整比較與預期結果；有未決衝突時明列，不自行決定規則。

固定同一局面與輸入，比較即時靜態結果和少量動態回饋。優先處理選取英雄、技能預覽／確認、成功提子；不建立大型素材流程或受試系統。需要時間、圖層或中斷處理時讀 [motion.md](references/motion.md)。

- 職業由盾、帽／水晶、兜帽／短刃辨識，陣營由高對比圓／六角底座辨識；主將使用皇冠與外環。人物卡在棋盤下方呈現角色魅力。
- 預覽可取消，正式單位、資源與結果只由已確認事件更新。比較 fixture 要明說沒有規則判定；不能宣稱接上 Domain。
- 本輪視覺預設「魔法之手」，核對最新 R1 規格：雙方普通士兵、正交推至相鄰空點、保留歸屬、法師不移動。不得推主將／英雄，不連鎖推動。視覺預設不等於正式規則替換通過；封印如作基線，封印空點仍算氣。
- 動態不能改動落點、命中區或規則結果。效果限於棋子、目標點或已確認的一格推動路徑，讓主將危險、氣與技能目標保持在前景。
- 系統或手動減少動態時，用相同持續標記、文字與最終盤面替代，不要求玩家等動畫才知道結果。

以當次實際小尺寸與代表性狀態檢查預覽、取消、確認、重設中斷、減少動態、灰階與鍵盤／pointer。交付代表截圖與可離線開啟的比較文件。Browser 自動化不能當成真人辨識或 iPhone 實機驗收；清楚列出仍未驗證的 Gate。

沿用素材 ID、來源 commit／版本、SHA-256、approval、availability 和 rights；引用不等於升格核准。新人物生成由現有 `tacticalgo-character-style` 處理，本 Skill 不重定人物比例或膚色。未來若授權製作 sprite，使用同一已核准 seed、固定比例與 anchor，檢查透明邊緣和遊戲尺寸；本輪只需現有素材。

需要方法來源或未來 sprite 工作時讀 [sources.md](references/sources.md)。Game Studio Skills 不必安裝也可使用這些方法，不因此更換引擎。草稿不授權安裝、發布、push、merge 或正式素材整合。
