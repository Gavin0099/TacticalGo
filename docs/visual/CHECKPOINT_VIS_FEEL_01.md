# TacticalGo 視覺階段提交：VIS-FEEL-01

2026-10-08 Owner 授權把目前完成的視覺工作提交並推到 GitHub 獨立分支 `codex/cozy-tabletop-art`，開 PR code review，無阻擋問題後合併。Owner 已接受本輪比較工具、三職業分鏡與 Game Feel Skill 設計方向，並決定本輪到此結案。這是候選與設計草稿的階段保存；不代表正式美術、權利、真人／實機或 Gameplay Gate 核准。

## 審查入口

- [完整離線審查包](../../assets/candidates/vis-feel-01/TacticalGo-VIS-FEEL01-review.zip)：解壓後直接開 `REVIEW.html`。
- [靜態／動態比較頁](../../assets/candidates/vis-feel-01/REVIEW.html)：下載 HTML 後離線開啟，GitHub 檔案頁顯示的是原始碼。
- [三職業四階段動畫分鏡](../../assets/candidates/vis-feel-01/ANIMATION_STORYBOARD.html)。
- [2.5D 與動畫方向](../../assets/candidates/vis-feel-01/ANIMATION_DIRECTION.md)、[驗證報告](../../assets/candidates/vis-feel-01/REPORT.md)、[最小計畫](../../assets/candidates/vis-feel-01/PLAN.md)。
- [角色風格 Skill](../../.agents/skills/tacticalgo-character-style/SKILL.md)：含固定候選參考與來源 SHA-256。
- [Game Feel Skill 草稿](../../assets/candidates/vis-feel-01/skill-draft/tacticalgo-game-feel/SKILL.md)：供審查，尚未安裝。

## 本次保存範圍

保存現有 A 棋盤 Token＋B 人物卡、離線比較、短錄影、代表截圖、三職業動畫分鏡、來源與 SHA-256 Manifest。法師視覺預設為 Owner 選定的魔法之手；參考《皇室戰爭》形體、主道具與光影方向，動畫時間為 TacticalGo 提案。

本次提交只包含 `.agents/skills/tacticalgo-character-style/`、`assets/candidates/vis-feel-01/` 及本次相關視覺文件。舊版 v01／VIS-02／VIS-02.1／直接修稿交付包與實驗仍保存在原本機 Visual worktree；它們的歷史 hash 與來源資訊留在本包 provenance，沒有宣稱所有原始歷史包都隨本次上傳。

`qa/build-review.py` 在已包含六張 PNG 的情況下可重建離線 HTML；`qa/check-review.cjs` 可檢查比較工具。`qa/package-review.py` 可在獨立 checkout 驗證本包並重打 ZIP；若未提供本機上一輪修稿包，明確回報未驗證歷史包，而不假稱來源包已比對。

已有 21 項 Browser 工具檢查通過，審查 ZIP 的 CRC、清單與 SHA-256 檢查通過。真人辨識、實體 iPhone、正式遊戲整合、完整三職業動畫及完整 2.5D 主畫面仍未完成；G0 保持 Pending，G1 不提前。

圖片的 `approval=pending_owner`、`production=false`、`rights=pending_confirmation` 保留。沒有修改 Gameplay、Domain、BoardView、Windows UI、KCK。Game Feel Skill 暫不安裝，每次使用前需核對有效 `RULES_DRAFT.md` 與 `DECISIONS.md`；完整 2.5D 人物動畫暫不啟動。合併授權以最新 PR head 審查及必要檢查通過為條件。
