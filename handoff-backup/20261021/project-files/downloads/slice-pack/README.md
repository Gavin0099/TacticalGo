# TacticalGo｜五個 Slice 的 Codex 工作包

**版次：2026-10-11 / Planning v1.0**  
**唯一已授權行為：產出與審查工作合約／Codex 指令。**  
**未授權：在 TacticalGo 儲存庫中修改程式、建立提交、推送、合併 PR、安裝真機或發布。**

本包將已核准納入規劃的五個項目拆為獨立合約。核准「規劃範圍」**不等於**核准「程式實作」或「升格正式規則」。

## 文件清單

| 文件 | 用途 |
|---|---|
| `00_MASTER_CONTRACT.md` | 權限、基準、依賴、整合策略、跨 Slice Gate、測試與風險 |
| `01_BOT-P2.md` | 改善電腦中後期攻守、區分合理／不合理 Pass |
| `02_CONTENT-03.md` | 三個有多回合反制的進階戰術關卡 |
| `03_BOSS-00.md` | 紅龍戰場規則設計合約（只定義，不寫遊戲程式） |
| `04_ANIM-01.md` | 法師「魔法之手」角色動作精修（沿用既有候選） |
| `05_3D-00.md` | 3D 角色身份、風格、製作規格（只定義，不建模） |
| `06_CODEX_HANDOFF.md` | 可直接貼給 Codex 的「先讀取／檢查」指令、五個單片啟動指令範本 |
| `07_GATE_CHECKLIST.md` | Owner 驗收／決策紀錄格式 |

## 建議閱讀順序

`00_MASTER_CONTRACT.md` → 選定 `01`～`05` 的單片合約 → `06_CODEX_HANDOFF.md` → `07_GATE_CHECKLIST.md`。

## 現有專案資料與確認邊界

- 2026-10-11 查詢的 GitHub `main` 最新提交：[`cdab133`](https://github.com/Gavin0099/TacticalGo/commit/cdab133cd469dd185fd8ca3f47fea2e217cfb139)（提交日 2026-10-09）。
- [BOT-P1 PR #5](https://github.com/Gavin0099/TacticalGo/pull/5) 與 [CONTENT-02 PR #6](https://github.com/Gavin0099/TacticalGo/pull/6) 提供實作候選與證據。**Codex 執行前須重新查驗 PR、工作樹與實際 Head，不得假設已合併。**
- 近期本機另有法師 ANIM-01 候選及 SELL-01C UI 候選；這些內容未必存在於 GitHub `main` 或同一個 worktree，需由 Codex 本機核對。此包不宣稱已讀取本機 ZIP、模擬器錄影或工作樹。
- 權威優先序：Owner 最新明確決策 → 最新有效 repo 指令與 `docs/DECISIONS.md` → 生效規則／Core 與 Golden → 候選 PR／實驗資料 → 本包建議。若衝突，列出衝突並保持 HOLD，不擅自選擇。

## 所有 Slice 共有的結案格式

1. **結果**：`PLAN_READY`、`ENGINEERING_CANDIDATE`、`OWNER_ACCEPTED`、`HOLD` 或 `BLOCKED`，不能混用。
2. **範圍**：讀取的基準 SHA、工作樹、PR、變更路徑；是否改動規則、預設與存局格式。
3. **證據**：命令、實際 PASS/FAIL、Golden 回歸、固定局面重播、對照圖／影片及其版本。
4. **仍待驗收**：真人策略、美術身份、iPhone/iPad 真機、相容性、發布權利逐一標註。
5. **下一個 Gate**：由 Owner 決策；不得把可編譯／可運作當作自動合併或發布授權。
