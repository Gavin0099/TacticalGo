# TacticalGo 交接手冊（給 Codex）

> 撰寫日期：2026-10-08（Owner：Gavin0099）。本文件描述 **當天的實際狀態**；任何數字都附出處，過時時請以 `git log`、`docs/DECISIONS.md` 與實測為準。
> 先讀本文件的 §0、§1、§6，再讀 `AGENTS.md`（含框架管理區塊）、`docs/DECISIONS.md`（由上而下，最新在最上面）、`docs/RULES_DRAFT.md`。

---

## 0. 一頁摘要

**TacticalGo** 是「圍棋規則為底層、加上三職業英雄技能的小型戰術棋」，對外定位「英雄包圍戰」：放士兵、包圍敵人、提吃敵方主將就獲勝。最終目標是 **iPhone 原生 App（Swift/SwiftUI）**。

目前的程式是：
- **C# 參考引擎**（`src/TacticalGo.Domain`）＋ 23 組手寫的語言中立**黃金測資**（`tests/golden`）。Swift 版日後必須逐組通過同一批測資。
- **Windows 原型 UI**（`src/TacticalGo.Play`，WinForms，**非正式版**）：7×7 教學第 1 關（3 段）、第 2 關（盜賊換位，2 段）、自由對局（9×9、無職業）。
- 只有**盜賊換位**接上介面；戰士築壘、法師封印的規則在引擎裡，但**沒有介面**。

目前最重要的未知不是工程，而是 **「玩家會不會因為選不同英雄而產生不同的攻守策略」**。工程測試全過 ≠ 好玩 ≠ 新手看得懂。

### 你的第一個 30 分鐘
1. `git worktree list`、`git log --oneline -12`、讀 `docs/DECISIONS.md` 最上面的 5 個條目。
2. 在乾淨 clone（`--recurse-submodules`）或既有 worktree 跑 §5 的建置與測試，確認：Domain **75** 項、Windows（含 UI 冒煙）**61** 項（在 `feature/ui-3c` 分支）。
3. 跑 `dist/TacticalGo.Play/TacticalGo.Play.exe`（若不存在，見 §5 發佈指令），玩第 1、2 關各一次。
4. 讀 §6「硬規則」與 §9「待辦」，然後**先問 Owner 要做哪個 slice**，不要自己挑。

### 絕對不要做的事（完整清單見 §6）
- **不要改規則／預設值／技能效果／費用**，除非 Owner 明確核准。規則的權威來源是 `docs/RULES_DRAFT.md` + Domain + 黃金測資，三者一起改。
- **不要 push、不要 merge、不要開 PR**，除非 Owner 明確說要。**不要用 `git push --no-verify`** 繞過 hooks。
- **不要把 G0／G5 這類「Owner 實際試玩」的 Gate 自己標成通過。**
- **不要宣稱「好玩」「新手看得懂」「職業平衡」**，測試、機器人、搜尋都不能證明這些。
- **不要碰 `assets/`、`.agents/`、Visual worktree**（見 §6.4）。
- 一次只做一個 slice；先提出範圍、影響檔案、驗收、分支基線，Owner 同意再動手。

---

## 1. 產品原則與 Owner 的工作方式

- **30 秒理解操作、3 分鐘理解職業差異、之後仍有值得思考的策略**（設計目標，**不是已達成**）。
- 不要把「功能愈多」當進度。Owner 最怕重演 SnackDelivery：工程完整、卻不知道好不好玩。每個 slice 要有可交付成果、驗收標準與停止條件。
- **簡化介面 ≠ 簡化遊戲**：新手教學要漸進（先 1 次行動，再 2 次），但不能為了好教而刪掉有意思的策略選擇。
- **對手會反應**才是長期樂趣，不是解固定棋局。教學關的對手只會結束回合，所以**沒有教攻守取捨**，不能這樣宣稱。
- 回報要帶證據（指令、檔案:行號、數字）；**工程 Gate 與人類 Gate 分開記錄**；限制要誠實寫出。
- Owner 的語言是繁體中文；程式識別字維持英文。Owner 的審查習慣：會貼外部分析、會挑戰前提，也會明確否決。**被糾正時直接更正並獨立 commit，不要改寫歷史、不要辯解。**（先例：`ccf8c9f` 更正「技能花整回合」的誤讀。）

---

## 2. 目前狀態快照（2026-10-08）

### 2.1 分支與 PR
| 項目 | 狀態 |
|---|---|
| `main` | `f42f3ba`：引擎、第 1 關、授權說明 |
| `chore/governance-full` | `761af5d`：治理完整導入。**PR #1 → main，OPEN，可合併，CI `governance-drift` 已在 GitHub 成功** |
| `feature/ui-3c` | `a4ca293`：第 2 關介面＋審查修正，含治理分支的 merge。**PR #2 → `chore/governance-full`（疊在 #1 上），OPEN** |
| `docs/handoff` | 本手冊所在的本機分支（未 push） |
| `codex/cozy-tabletop-art` | Visual worktree：`C:/Users/reiko/.codex/worktrees/cozy-tabletop-art/TacticalGo`，停在 `d1a8352`，只有未追蹤的 `.agents/`、`assets/`、`docs/visual/`，**未 commit、未 push** |

**合併順序必須是 #1 再 #2**（#2 的 base 是 #1 的分支；#1 合併並刪分支後，把 #2 改指向 `main`）。**目前兩個都沒合併，也不需要為了開始新 slice 而合併。**

### 2.2 為什麼 #2 要 merge 治理分支
本機 pre-push hook 要求 `governance/external-tree-inventory-guard.json`，該檔只存在於治理分支。**沒有它的分支推不出去**（這是治理的後果，不是 bug）。因此在 #1 合併進 `main` 之前，新分支請**從 `feature/ui-3c` 或 `chore/governance-full` 開**，不要從 `main` 開。

### 2.3 驗證狀態（引擎面）
| 檢查 | 結果 | 指令 |
|---|---|---|
| Domain 規則測試＋黃金測資 | **75** 通過 | `dotnet test TacticalGo.sln` |
| Windows UI 邏輯與冒煙測試 | **61** 通過（`feature/ui-3c`）；47（`main`／治理分支，少了 3c 的 8 項與 UI 冒煙 6 項） | `dotnet test TacticalGo.Windows.sln` |
| 漂移檢查 | `severity=ok`（本機、乾淨 clone、GitHub CI 皆已驗證） | 見 §5.4 |
| readiness | `ready=True`（乾淨 clone 的 `hooks_ready=False` 是預期，hooks 每個 clone 要自己裝） | 見 §5.4 |
| 黃金測資驗證器 | 23 組通過；故意弄壞的副本會被抓到 | `python validators/golden_fixture_validator.py .` |

### 2.4 驗證狀態（人類面）— **全部 Pending**
- **G0**（Owner 實際操作第 2 關）：**Pending**，Owner 尚未回報。不得自行標通過。
- 我（前一個 agent）**沒有用真滑鼠操作過視窗**；互動是靠控制器邏輯測試、UI 冒煙測試與離屏渲染截圖驗證。
- 沒有任何真人（尤其是不懂圍棋的人）試玩過。

---

## 3. 規則（權威來源與摘要）

**權威順序**：`docs/DECISIONS.md`（Owner 決定，覆蓋其他草稿）＞ `docs/RULES_DRAFT.md`（Draft v0.2；§8 有待審清單）＞ Domain 程式 ＞ 黃金測資。三者必須一致；`validators/golden_fixture_validator.py` 檢查測資用詞與引擎一致。

### 3.1 已由 Owner 確認的回合模型（不要動）
1. 每回合 **2 AP**；放一顆士兵 **1 AP**；使用一次英雄技能 **1 AP ＋ Mana**；每回合**最多一次技能**。
2. 放子＋放子、放子＋技能、技能＋放子，**順序自由**。
3. **先手第一回合 1 AP**（補償，`RuleConfig.FirstTurnAp = 1`）；`RuleConfig.TwoApBaseline` 保留原始 2 AP 當對照。
4. 首回合也 +1 Mana（暫時接受）；Mana 上限 6、初始 3、每個**自己**回合開始 +1。
5. 英雄被提後**不可重召**（`AllowResummon = false`，可切換供對照）。
6. 英雄召喚位置：**與任一己方棋子上下左右相鄰的空點**（不限主將旁）。
7. **「技能花掉整個回合」是誤讀，已作廢**（`docs/DECISIONS.md` 有紀錄）。不要實作。

### 3.2 棋盤機制（引擎）
- 棋串＝同色任何單位（士兵／主將／英雄）正交相連；**生存空格**（框架術語＝氣）＝棋串旁的空點。
- 每個行動**原子**結算：驗證 → 在複本上套用 → **先提對手無氣棋串、再判自己是否自殺（自殺非法）** → 打劫（positional superko，歷史含初始盤面）→ 提交。任何一步失敗，狀態**完全不變**。
- 提吃敵方主將 → 立即獲勝；`MaxPlies`（預設 100）仍無人被斬首 → 和局。
- 技能（皆 1 AP＋2 Mana，英雄必須在場）：**築壘**（戰士：相鄰兩個空點各放一子）、**封印**（法師：距離 1–2 的空點，對手下回合不能放置，到期於對手回合結束）、**換位**（盜賊：與相鄰敵方**士兵**互換位置，再結算）。召喚費：戰士 2／法師 3／盜賊 2。
- 戰士「築壘＋普通落子」一回合可放三子：已列為**平衡風險，先不改**。

### 3.3 尚待審／尚未定案
見 `docs/RULES_DRAFT.md` §8（主將起點、超級打劫、自殺判定、回合上限、封印只擋放置等 13 項）。**Owner 要逐項核准，不要整批視為通過。**

### 3.4 提案中、**未核准**的規則變更（請勿實作，除非 Owner 說開工）
- **火球術**（消滅一顆敵方士兵）：Owner 問過，我給了分析與選項；未決定。
- **魔法之手 Magic Hand**（法師把射程 ≤2 的一顆敵方**士兵**推向相鄰空點）：Owner 目前傾向用它取代封印，並建議 `R1-MAGIC-HAND` 小 slice（只改 Domain＋黃金測資＋RULES_DRAFT，`RuleConfig` 加「法師技能」選擇、預設維持封印）。**等 Owner 核准範圍與兩個規則問題**（見 §9.3）。
- 規則缺口先問：推進「沒有任何生存空格」的點，依現有結算順序敵兵**會被提掉**；Owner 尚未說保留或禁止。

---

## 4. 架構地圖

```
TacticalGo.sln                (跨平台：Domain、Domain.Tests、Sim)
TacticalGo.Windows.sln        (Windows 專用：Domain、Play、Play.Tests)
src/TacticalGo.Domain         規則引擎（net9.0，無 UI 依賴）
src/TacticalGo.Play           Windows 原型 UI（net9.0-windows，WinForms，WinExe）
src/TacticalGo.Sim            啟發式機器人與模擬器（探針用，不是產品）
tests/TacticalGo.Domain.Tests 規則測試＋黃金測資重播
tests/TacticalGo.Play.Tests   UI 邏輯、關卡、控制器、UI 冒煙（net9.0-windows）
tests/golden/*.json           23 組手寫、語言中立的黃金測資（格式見 tests/golden/README.md）
validators/                   治理框架的 repo 專屬驗證器（Python）
tools/probes/                 一次性研究探針（不在 sln 內）
docs/                         PLAN、RULES_DRAFT、DECISIONS、各 Gate 證據、UI 說明、治理設定
additional/ai-governance-framework   治理框架 submodule（釘在 b74bbde）
```

### 4.1 Domain（`src/TacticalGo.Domain`）
| 檔案 | 職責 |
|---|---|
| `GameEngine.cs` | **公開入口** `GameEngine.Apply(state, action)`：純函式，**不修改輸入狀態**，回傳 `ActionOutcome`（成功與否、新狀態、事件） |
| `ActionResolver.cs`（internal） | `Prepare`＝驗證＋在複本上套用＋結算；`Apply`＝提交、扣資源、發事件、必要時換手 |
| `ActionValidator.cs` | `Validate`（與套用同一條路徑）、`GetLegalActions`（含最後一項 `EndTurn`） |
| `BoardRuleEngine.cs` | 棋串、生存空格、提子與自殺結算（先提對手、再判自己） |
| `Board.cs` / `BoardText.cs` | 盤面、Zobrist 雜湊（打劫用）、文字圖（`x/X/H` 黑，`o/O/Q` 白，`.` 空） |
| `GameState.cs` | 完整狀態；`Fingerprint()` 供測試證明回滾；`History` 為共享尾端的鏈，供打劫 |
| `TurnEngine.cs` | 換手、Mana 成長、封印到期、回合上限和局 |
| `RuleConfig.cs` | **所有可調的 Draft 數字都在這裡**，改平衡不碰引擎 |
| `Actions.cs` / `ActionEvent.cs` | 動作（`PlaceSoldier`、`SummonHero`、`CastBastion`、`CastSeal`、`CastSwap`、`EndTurn`）、非法原因列舉、事件 |
| `GameSession.cs` | `GameSetup.NewGame`／`FromDiagram`（情境用，**不**套用回合開始的 Mana）；`GameSession` 記錄動作可重播 |

設計約束：UI 與規則完全分離；**引擎訊息是英文**，UI 透過 `EventText` 翻成中文。

### 4.2 Play（`src/TacticalGo.Play`）
| 檔案 | 職責 |
|---|---|
| `PlayController.cs` | **唯一持有正式狀態**。選取只預覽（`GameEngine.Apply` 回新狀態，不動舊狀態）；`Confirm()`（「✔ 放這裡」／「✔ 確定換位」）才提交；復原＝還原整個 `GameState` 快照；`Mode`（Place／Skill）、`Skill` 狀態（依狀態快取）、`SkillTargets`、`OpponentPolicy`（教學對手，與玩家動作同一個復原步驟）、`Locked` |
| `BoardView.cs` | 只畫圖與把點擊轉成座標；**不含規則**。預覽取自引擎結果（換位預覽直接畫 `Preview.State` 的盤面） |
| `MainForm.cs` | 版面：目標列、側邊欄、棋盤下方**自動計算高度**的兩排操作區（模式列＋確認列）、新局對話框（由 `LevelCatalog.Levels` 產生） |
| `Level.cs` | `LevelStage`／`LevelDefinition`／`LevelSession`／`LevelCatalog`（關卡局面是**文字圖**，由引擎載入） |
| `EventText.cs` | 事件與非法原因的中文；「生存空格」是 UI 用語 |
| `HelpForm.cs` / `HelpScenarios.cs` | 5 頁圖示教學，每頁是真實引擎局面 |
| `Program.cs` | 入口與離屏截圖工具（見 §5.3） |

### 4.3 關卡（`Level.cs`）
- 第 1 關（7×7，教學對手不動）：① 每回合 1 次行動，提掉被圍住的白子；② 1 次行動，白主將與白兵相連共用生存空格；③ 2 次行動，同回合連下兩子。
- 第 2 關（盜賊預置在場）：① 1 次行動，換位一步破陣（換位 1 回合 vs 普通 4 回合）；② 2 次行動，技能＋放子 1 回合（兩種順序皆可）vs 普通 2 回合。
- 這些數字由 `tests/TacticalGo.Play.Tests/Level2Tests.cs` ＋ `LevelSearch.cs`（只針對這兩個局面的有限範圍搜尋）驗證；**只證明局面性質（合法、可解、技能更快、技能非強制），不證明新手看得懂**。
- 搜尋曾抓到一個推理漏掉的錯誤：原本第 2 關第 2 段的局面中「先換位」其實非法（盜賊換位後落在凹槽、沒有生存空格＝自殺）。**新關卡務必用搜尋驗證，不要只憑肉眼設計。**

---

## 5. 環境與指令

### 5.1 環境
- Windows 11；**.NET SDK 9.0.302**、WindowsDesktop runtime 9.0.7；**沒有 .NET 10**（安裝需下載，未擅自處理；升級只需改兩個專案的 `TargetFramework`）。
- Python 3.13；輸出中文的 Python 一律 `python -X utf8`（cp950 陷阱）。
- 沒有 Swift toolchain、沒有 Xcode、沒有 Mac。iOS 建置必須在 macOS（實體或雲端 CI）；Windows 可裝 Swift 官方 toolchain 開發純 Swift Package（Owner 的說法，我未驗證）。
- `dotnet` 的輸出是中文（「已通過!」「失敗!」），解析時請注意。
- git 會有 LF/CRLF 警告（autocrlf），無害。
- 測試暫存路徑請用短路徑，長路徑會 MAX_PATH 假失敗。

### 5.2 建置、測試、執行
```bash
dotnet test TacticalGo.sln                      # Domain 75 項（跨平台）
dotnet test TacticalGo.Windows.sln              # Windows 專用（feature/ui-3c 為 61 項）
dotnet run --project src/TacticalGo.Play        # 直接跑原型
dotnet run --project src/TacticalGo.Play -- --level 2   # 從第 2 關開始；--free 為自由對局
dotnet publish src/TacticalGo.Play -c Release -r win-x64 --self-contained false -o dist/TacticalGo.Play
dotnet run --project src/TacticalGo.Sim -c Release -- ap 1000   # S0 的 AP 比較探針
```
- `dist/`、`bin/`、`obj/` 在 `.gitignore`，**不要 commit**。
- PowerShell 用 `Start-Process` 啟動 GUI exe 會立刻返回；要等它寫檔請另外確認。

### 5.3 離屏截圖（驗證畫面用）
```bash
dotnet dist/TacticalGo.Play/TacticalGo.Play.dll --level 2 --snapshot out.png "k;s3,2"
dotnet dist/TacticalGo.Play/TacticalGo.Play.dll --help-page 4 out.png
```
腳本語彙（以 `;` 分隔）：`p3,4` 選取後按「放這裡」、`s3,4` 只選取、`i4,7` 檢視棋串、`e` 結束回合、`u` 復原、`n` 下一段、`N` 下一關、`r` 重來本段、`c` 取消、`k` 技能模式、`m` 放士兵模式。
截圖畫的是**整個視窗（含標題列）**；曾因只畫 ClientSize 而誤判操作區被切掉。

### 5.4 治理檢查
```bash
FW=additional/ai-governance-framework
python $FW/governance_tools/governance_drift_checker.py --repo . --framework-root $FW           # 期望 severity = ok
python $FW/governance_tools/external_repo_readiness.py --repo . --framework-root $FW --format human   # 期望 ready = True
python validators/golden_fixture_validator.py .
# 新 clone 必須自己裝 hooks（hooks 在 .git/hooks，不會跟著 clone）：
git clone --recurse-submodules https://github.com/Gavin0099/TacticalGo.git
cd additional/ai-governance-framework && python -m governance_tools.hook_installer --repo ../.. --framework-root . --hooks-only
```
詳見 `docs/GOVERNANCE_SETUP.md`。

---

## 6. 硬規則（Owner 的授權邊界與治理）

### 6.1 需要 Owner 明確同意才能做
- 規則、預設值、技能效果、費用、召喚限制的任何變更。**規則缺口先提出選項，不要擅自補規則。**
- `git push`、merge、開／改 PR、刪分支。（Owner 某次明確說「先幫我推上去」才推；那只授權那一次。）
- 進入下一個 slice；把 G0／G5 標成通過。
- 專案授權（License）、引入美術資產、新增依賴、改 `.NET` 目標版本。

### 6.2 不要繞過檢查
- pre-commit／pre-push hooks 是本機、建議性的治理檢查。**被擋住時先讀診斷、找根因，不要 `--no-verify`**（那會關掉全部 pre-push 治理）。先例：hook 因缺治理檔擋下 `feature/ui-3c`，解法是 merge 治理分支，而不是繞過。

### 6.3 回報規則（Owner 的「宣稱不是證據」）
- 「已通過」「已修好」必須重跑驗證才算；結論附指令或檔案:行號。
- 測試通過 ≠ 好玩；機器人／搜尋結果只是探針；弱機器人的勝率**不能**用來宣稱職業平衡。
- 黃金測資的預期值是**手寫**的，**不要為了讓測試通過而改預期值去符合引擎輸出**（那會讓單一引擎的錯誤變成「標準答案」）。
- 新測試要做**變異測試**：暫時還原修正，確認測試會失敗（前一個 agent 對 UI 冒煙測試與黃金測資都做過）。

### 6.4 Visual 與 Gameplay 分工
- Gameplay：`feature/*`、`rule/*`、`docs/*`；負責 `MainForm`、`BoardView` 操作接線、`PlayController`、技能預覽、Domain、測試。
- Visual：`codex/cozy-tabletop-art` worktree；負責角色素材、棋盤美術、視覺規格；**不得改 Gameplay、Domain 或正式 `BoardView` 操作邏輯**。
- **不要碰 `assets/`、`.agents/`、`docs/visual/`**。那些是 AI 生成的候選素材，來源與授權**尚未審查**，在審查前**不得進公開 repo**。
- 注意：Visual worktree 路徑在 `.codex` 底下。若你就是那個 Visual 工作者，請與 Gameplay 工作明確區分身分與分支；若你要接 Gameplay，請在**自己的** `feature/*` worktree 工作。
- 同一資料夾切分支會動到 submodule（`additional/ai-governance-framework` 在沒有 `.gitmodules` 的分支上會變成殘留目錄）。**用 `git worktree add` 開新分支，不要在有 submodule 的工作目錄來回切換。**

### 6.5 治理流程（框架已完整導入，但**不要過度宣稱**）
- 狀態：`full_candidate`；**未證明** runtime enforcement、記憶完整、版本鎖定、domain 正確性、release readiness。
- `CLAUDE.md`／`AGENTS.md`／`GEMINI.md` 含框架管理區塊（BEGIN/END 之間不要手改），要求在任務開始、里程碑、範圍改變等時點輸出 `[Governance Contract]` 區塊；session 結束 closeout 規則見 `AGENTS.md`。
- 記憶用框架的**正式寫入器**（不要手改 `memory/` 當一般 markdown）：
  ```bash
  cd additional/ai-governance-framework
  python -m governance_tools.memory_record --project-root ../.. --what-changed "..." --next-step "..." --test-evidence "..." --plan-reconciliation not_applicable
  ```
  `--test-evidence` 必須是真的（沒跑就寫 `NOT RUN: <原因>` 或 `NOT CLAIMED: <邊界>`）。
- pre-commit 的 memory 警告（`missing_canonical_memory`、`mixed_scope_memory_binding`）是**建議性**，不擋 commit。
- 框架更新走 F-7（`docs/GOVERNANCE_SETUP.md`），不要手動 `git checkout` submodule。
- commit 訊息結尾沿用：`Co-Authored-By: <你的模型名稱> <noreply@anthropic.com>` 之類的署名行（依你的環境規定調整）。

---

## 7. 決策與證據索引

| 想知道 | 看哪裡 |
|---|---|
| Owner 的所有決定（最新在上） | `docs/DECISIONS.md` |
| 規則全文＋待審清單 | `docs/RULES_DRAFT.md` |
| 1 AP vs 2 AP 的探針、職業矩陣（粗略） | `docs/S0_AP_GATE.md` |
| 下一個玩家驗證 Gate 的設計 | `docs/NEXT_GATE.md` |
| 技術路線（Swift/SwiftUI、移植原則） | `docs/TECH_DECISION.md` |
| 原始計畫（Draft v0.1） | `docs/PLAN.md` |
| UI 操作說明與驗證狀態 | `docs/ui/UI1_README.md`（`UI0_layout.html` 是早期概念草圖） |
| 治理設定與已知限制 | `docs/GOVERNANCE_SETUP.md` |
| 黃金測資格式 | `tests/golden/README.md` |
| 一次性探針 | `tools/probes/README.md` |

### 7.1 已做過的探針（結論與限制）
| 探針 | 結果 | 限制 |
|---|---|---|
| 1 AP / 2 AP / 先手首回合 1 AP（啟發式機器人各 1000 局，無職業） | 2 AP 基線先手 **59.6%**；先手首回合 1 AP 為 49.9%/50.1% | 一步前瞄機器人；不懂技能；不是玩家行為 |
| 純搶攻算術（`TempoRaceTests`） | 2 AP 基線先手 ply 3 斬首；1 AP ply 7；先手首回合 1 AP 時**後手** ply 4 | 雙方都不防守 |
| 職業矩陣（預設規則，每格 300 局） | 戰士最弱、法師／盜賊較強（方向性） | 機器人沒有技能策略；±5.6 點雜訊；**不可用來調數值** |
| 攻防分配（全攻／全守／一攻一守，各 300 局，固定策略） | 勝率約 59%／51%／40%，無剪刀石頭布循環 | 防守策略不會吃掉攻擊子；非玩家行為 |
| 1 AP 下封印（單一局面） | 唯一能避免立刻被殺的行動，但只是拖延，Mana 用完（ply 12）仍被提 | 單一局面、被動對手 |
| **封印價值搜尋**（`tools/probes/seal-search`，7×7、2 AP、對手會反應） | 476 局面：**0** 個只有封印才能贏；防守面**未測到**（篩選條件缺陷） | 見 `tools/probes/README.md`；**不是證明封印無用** |
| 第 2 關局面搜尋（`Level2Tests`） | 換位／技能比普通走法快；技能非強制 | 只證明局面性質 |

---

## 8. 已知問題、風險、延後事項

### 8.1 玩法風險（待真人驗證）
- **職業是否真的改變策略**：未驗證（G4／G5 才能回答）。
- **戰士築壘**一回合三子可能過強；**法師封印**價值未證明；**法師（推動／消滅）與盜賊（換位）都是「淨 0、改位置」**，有定位重疊風險。
- **英雄不值得召喚**（放兩顆士兵永遠更有效率）、**英雄早死後整局失去特色**、**選職業只是選強度**——都是待觀察的風險。
- 先手首回合 1 AP 的補償在**純搶攻**局裡讓後手 100% 贏（探針），在有防守時接近 50/50；仍待真人驗證。

### 8.2 程式面（Code review 延後項）
- **技能字串與邏輯散在 `PlayController`／`MainForm`／`BoardView`**（Rogue 換位寫死）。加第二、第三個技能前，應先做「每職業技能描述」小重構（標籤、說明、目標、原因文字）。這是 PR #2 審查唯一延後的項目。
- `FromDiagram` 是情境載入器，不套用回合開始的 Mana；`NewGame` 才套用（首回合也 +1）。
- 教學對手由 `OpponentPolicy` 實作，與玩家動作同一個復原步驟；`LevelSession` 要在 `MainForm` 之前建立（事件順序）。
- UI 的版面與繪製**沒有人類驗證**；只有 6 項冒煙測試（STA 執行緒、離螢幕）與離屏截圖。

### 8.3 流程面
- 工具產生的 `.governance/baseline.yaml` 與 `governance/.update-receipt.json` 含本機絕對路徑（`E:\BackUp\Git_EE\TacticalGo\...`，無使用者名稱）；有雜湊檢查，勿手改。
- 歷史中仍有一份**未發佈的** `governance/MEMORY_PROTOCOL.md` 草稿文字（最新版本已還原成框架公開版）。
- 專案本身的授權**尚未決定**（`THIRD_PARTY_NOTICES.md` 已說明）。
- `framework.lock.json` 對 submodule consumer 不存在，readiness 因此有 3 項 `framework_version` 警告（不阻擋）。

---

## 9. 待辦與路線圖

### 9.1 Owner 的 slice roadmap
G0（Owner 實際試玩 3c，**Pending**）→ **G1** 開局選職業＋最小召喚 → **G2** 戰士築壘 UI → **G3** 法師技能 UI（前置：封印／魔法之手價值驗證）→ **G4** 7×7 本機雙人自由對戰（第一個完整可玩里程碑）→ **G5** 真人試玩（關鍵 Go/No-Go）→ G6 針對性修正。
後續候選：BOT-01（反應型對手）、IOS-01（Swift 移植，以黃金測資驗證）。Visual：V1 英雄 Token 比較、V2 整合（等 Gameplay 介面穩定）。

### 9.2 G1 已核准的規格（**G0 通過後才能動工**）
- 範圍＝方案 B：開局選職業＋**最小召喚模式**；**不改 Domain、不改英雄規則**。
- 開局採**輪流公開選擇**（不做盲選）。
- 內容：自由對局新局對話框加兩步職業選擇（戰士／法師／盜賊文字卡，數字取自 `RuleConfig`，不寫死）；`PlayController.NewGame` 已支援 `classOne/classTwo`；側邊欄顯示雙方職業與英雄狀態；模式列新增「召喚英雄」（點空格預覽合法位置、確認；能量足夠才可用；英雄被提後不可重召）；戰士／法師顯示「技能介面尚未開放」。
- 預期影響檔案：`MainForm.cs`、新增 `ClassPickDialog.cs`、`PlayController.cs`、`EventText.cs`、`tests/TacticalGo.Play.Tests/*`、`docs/*`；**不碰** `BoardView` 繪製、Domain、黃金測資。
- 驗收：雙方可選不同職業；開局英雄不在場、Mana 符合現有規則；召喚預覽不消耗、確認才扣 1 行動與能量（戰士 2／法師 3／盜賊 2）、位置不合法或能量不足時顯示中文原因；只能召喚自己選的職業；已有英雄不能再召、被提後不能重召；盜賊召喚後可用現有換位；復原能還原召喚；不影響第 1、2 關與既有測試（Domain 75、Windows 61）；新增 UI 冒煙測試。
- **注意**：召喚英雄**不代表能立刻用技能**（盜賊要與敵方士兵相鄰才能換位，且召喚與施法都要行動與 Mana）；不要承諾開局召喚後馬上能體驗換位。
- 分支基線：從 `feature/ui-3c` @ `a4ca293` 開 `feature/g1-class-select`（用 worktree）。完成只 commit，**不 push、不 merge、不進 G2**。

### 9.3 等 Owner 回覆的問題
1. G0 試玩結果（沒有重大阻擋，才開 G1）。
2. **R1-MAGIC-HAND** 要不要開？範圍：只改 Domain＋黃金測資＋`RULES_DRAFT`；新增 `CastMagicHand(目標, 方向)`（法師在場、本回合未用技能、能量足夠、射程 ≤2、目標是敵方士兵、目的地是相鄰空點且在棋盤內；用現有原子流程結算；新增「棋子被推動」事件）；`RuleConfig` 加法師技能選擇（預設維持封印）；分支建議 `rule/r1-magic-hand` 從 `chore/governance-full` 開。
3. 「推進死點會提掉敵兵」保留還是禁止？
4. 封印的防守面要不要補跑 10 分鐘搜尋（修掉篩選缺陷）？
5. PR #1、#2 的合併時機。
6. 專案授權、`assets/` 的來源與授權審查由誰處理。
7. 取得 Mac 的方式（暫定：手動觸發的 macOS CI；Swift Package 存在後再建 workflow）。

### 9.4 G4 前置（容易漏掉）
- 目前自由對局是 **9×9**，主將起點 (4,7)／(4,1)；**7×7 需要 `RuleConfig` 指定主將起點**（例如 (3,5)／(3,1)），這是設定不是規則變更，但要加測試與（可能）黃金測資。
- 本機雙人要處理 AP／Mana 顯示、雙方職業標示、召喚與技能切換、勝負結算；**不依靠教學腳本也能完成一局**。
- 驗收要把「工程 Gate」與「人類 Gate」分開記錄。

### 9.5 不在目前範圍
額外職業、紅龍、神器、卷軸、完整動畫、線上對戰、13×13、正式美術、AI 擴充。

---

## 10. 開工與收工檢查清單（每個 slice）

**開工前（提給 Owner 看，同意才動手）**：目標／範圍外／影響檔案／驗收項目／分支基線／風險與停止條件。
**開發中**：用獨立 worktree 與分支；小步 commit；UI 不重寫規則（合法性取自 `ActionValidator`，預覽與結果取自 `GameEngine.Apply`）。
**收工**：
1. `dotnet test TacticalGo.sln` 與 `dotnet test TacticalGo.Windows.sln` 全過（附數字）。
2. 對新測試做變異測試。
3. 漂移檢查 `severity=ok`。
4. 有 UI 變更：發佈 exe、啟動確認、離屏渲染檢查畫面（含操作區是否完整可見）。
5. commit（不 push）；回報：做了什麼、證據、已知限制、**人類 Gate 狀態（Pending）**、與 Visual 分支的潛在衝突路徑。
6. 若動到 `memory/`，用正式寫入器；回報建議性警告。

---

## 11. 經驗教訓與陷阱（前一個 agent 踩過的）

- **UI 版面**：WinForms 若在設定 `ClientSize` **之後**才設 `Font`，視窗會被重新縮放而超出螢幕、把底部操作區切掉。順序：先 `Font`，再依螢幕可用範圍設尺寸。動態改變 Dock 底部面板高度時位置不會跟著調整，改用 `AutoSize` 的 `TableLayoutPanel`。
- **鍵盤**：全域 Enter／Esc／Ctrl+Z 要設 `SuppressKeyPress`，並在點按鈕後把焦點還給棋盤，否則聚焦中的按鈕可能一起被觸發。
- **版面不能靠肉眼**：用 UI 冒煙測試驗證「確認鈕一定在視窗內」、「按鈕列在段落完成時不消失」。
- **測資預期值手寫**：前一個 agent 曾發現 `ResolveCaptures` 把「先提對手」與「再判自己自殺」的順序做反（落子點無氣但能提子的合法著被誤判為自殺）；是手寫測資與單元測試抓到的。
- **用搜尋驗證關卡**：見 §4.3 的非法換位教訓。
- **機器人結果不是證據**：前一個 agent 的「戰士最弱」是機器人不會用築壘造成的假象風險；不要用它調數值。
- **誤讀要記錄與更正**：先確認 Owner 的原話與先前決定是否衝突，再記成決策；不確定時問。
- **`PowerShell` vs `bash`**：兩者在這台機器上都可用；`bash` heredoc 遇到特殊字元可能被截斷，複雜的編輯腳本請先寫成檔案再執行。
- **`Point` 名稱衝突**：Play 專案同時有 `System.Drawing.Point` 與 `TacticalGo.Domain.Point`，檔案內用 `using Point = TacticalGo.Domain.Point;`。

---

## 12. 附錄

### 12.1 術語
| 用語 | 意思 |
|---|---|
| 生存空格（＝氣） | 棋串旁邊的空點；相連的棋共用；降到 0 就被提掉。UI 對新手用「生存空格」 |
| 棋串 | 同色、正交相連的所有單位 |
| 行動／AP | 每回合可做的事的次數；UI 對新手說「還能行動 N 次」 |
| 預覽／確認 | 點空格只是預覽（不消耗）；按「✔ 放這裡」／「✔ 確定換位」才提交 |
| 輪／ply | 一輪＝黑白各一個 ply；引擎的 ply 數值不變，UI 顯示「第 N 輪」 |
| 打劫 | 盤面不得重複歷史上任何盤面（positional superko） |
| Gate | Owner 驗收點；人類 Gate（G0、G5）不得由 agent 自行通過 |

### 12.2 重要路徑
- repo：`E:\BackUp\Git_EE\TacticalGo`（目前停在 `chore/governance-full`）；Gameplay worktree：`E:\BackUp\Git_EE\TacticalGo-3c`（`feature/ui-3c`／`docs/handoff`）；Visual：`C:\Users\reiko\.codex\worktrees\cozy-tabletop-art\TacticalGo`。
- 遠端：`https://github.com/Gavin0099/TacticalGo`（**Public**）；框架：`https://github.com/Gavin0099/ai-governance-framework`。
- exe：`E:\BackUp\Git_EE\TacticalGo\dist\TacticalGo.Play\TacticalGo.Play.exe`（由 `feature/ui-3c` 發佈，未入 git）。

### 12.3 Owner 的 Gate 與停止條件（摘自 PLAN §6）
停止並重新設計：玩家選職業後最佳走法幾乎沒有不同；2 AP 讓一方難以反制；大量時間花在記例外規則；紅龍造成的主要是壞運氣；玩家看懂規則卻不想再試其他戰術。
