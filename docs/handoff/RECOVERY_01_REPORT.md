# HANDOFF-RECOVERY-01｜差異報告與驗證結果

> 產生時間：2026-10-15 10:0x（Asia/Taipei）。分支：`docs/handoff-recovery-01`，基底：`origin/chore/governance-full-20261014` @ `3c8207b`（PR #7 的 head）。
> 狀態：**待 Owner 審核。未推送、未合併、未開 PR。**

## 1. 為什麼基底是 PR #7 的 head，而不是 `main`

- `AGENTS.md` 的管理區塊與四個 `N/A` 區塊在 `main` 與 #7 都存在；填寫必須與 #7 的最新契約相容，所以直接在 #7 的 head 上做，管理區塊（BEGIN/END 之間）逐位元不動。
- 該分支同時含 `governance/external-tree-inventory-guard.json`，本機 pre-push hook 才不會擋。
- 代價：本分支**依賴 #7**。若 #7 被改動或不合併，本分支需重新基底；若要獨立於 #7，只有 `AGENTS.md` 的四個區塊是衝突點。

## 2. 起點事實核對（對照 Owner 貼來的分析）

| 說法 | 查證（2026-10-15 09:57–10:02） | 結論 |
|---|---|---|
| PR #1 OPEN、已被 #7 取代 | `gh pr list`：#1 OPEN；#7 本文自稱「supersedes #1」 | 成立 |
| PR #2 OPEN、Windows 盜賊換位 UI、基於舊治理分支 | #2 base=`chore/governance-full`、head=`feature/ui-3c` | 成立 |
| PR #7 OPEN、CI 成功、Codex 最後審查無重大發現 | head `3c8207b`；run `38597615544` 等皆 success；Codex 對 `3c8207b`「Didn't find any major issues」 | 成立；**但 PR 本文的 `HEAD cff31e8` 已過期** |
| PR #8 OPEN、1.0／1.1 整合候選 | head `5a826fa`，CLEAN，**無 CI 檢查**；30 commits、**1,655 個變動檔案**（API `changed_files`） | 成立；補充：無 CI；PR 本文測試數字（405+5）已被報告（424）取代 |
| `AGENTS.md` main 與 #7 都有四個 `N/A` | `git show origin/main:AGENTS.md` 與 #7 的檔案各 4 處 | 成立 |
| `docs/handoff` GitHub 找不到遠端分支 | `git ls-remote --heads origin` 無此分支 | 成立 |
| 本機 `docs/handoff` 為 `c55a2e1` | **本機實際為 `e3a78fc`**（比 `c55a2e1` 多一個 commit，2026-10-08 16:39，修改 AGENTS.md、HANDOFF.md，新增 `docs/evidence/handoff-2026-10-08.json`） | **與題目前提不同**：我先讀了兩者；本次修復吸收的是 `e3a78fc` 的內容 |
| 1.0 保全 SHA `d13fdfa`、1.1 保全 SHA `8c80ceb` | `git ls-remote`：兩個 safety 分支分別指向這兩個 SHA | 成立 |

## 3. 改動清單與依據

| 檔案 | 動作 | 依據 |
|---|---|---|
| `AGENTS.md` | 填四個 repo 專屬區塊（風險等級／必測路徑／升級條件／禁止行為），移除對應範本註解與 `N/A`；**管理區塊未動** | 見 §4 的逐項來源 |
| `docs/HANDOFF.md` | **新增**（#7 的基底上原本沒有此檔）。目前產品線入口；所有時效性狀態附查證時間與來源 | §2、§5；`ios/README.md`、`integration/1.0-1.1` 的整合報告與 save 報告 |
| `docs/handoff/WINDOWS_LEGACY.md` | **新增**。舊手冊 `e3a78fc:docs/HANDOFF.md` 原樣保留，加一個「歷史手冊」橫幅（列出已被取代的章節），並移除 4 處個人本機路徑 | 舊手冊內容為 Owner 要求保留的 Windows 工程知識 |
| `tools/probes/README.md`、`tools/probes/seal-search/*` | 自 `docs/handoff` 帶入，未改 | 舊手冊 §7.1 引用的封印搜尋探針，讓數字可重現 |
| `docs/handoff/RECOVERY_01_REPORT.md` | 本檔 | — |

### 刻意不帶入
- `docs/evidence/handoff-2026-10-08.json`（`e3a78fc`）：含多條個人本機路徑與 worktree 清單，不放進公開 repo。它仍在本機 `docs/handoff` 分支（`e3a78fc`），沒有被刪除。
- `e3a78fc` 對舊手冊的「R1 已核准」章節：作為舊手冊內容整段保留在 `WINDOWS_LEGACY.md`；它描述的是 Windows 線 `codex/r1-magic-hand`（遠端 `9970bbb`）的 2026-10-08 狀態，不是現行 iOS 規則。

## 4. AGENTS.md 四個區塊的依據

| 區塊 | 內容 | 依據 |
|---|---|---|
| 風險等級 | 規則核心、付費帳本、存檔相容、發布設定、治理基礎設施 = HIGH；UI 接線／Bot／教學／動畫整合 = MEDIUM；行為不變文件 = LOW；素材至少 L1 | `docs/integration/C0_MATCH_ACCESS_SAVE_CONTRACT.md`／整合報告（帳本、存檔、Release 排除）；Owner 分析的建議；舊 `e3a78fc` 的 HIGH／MEDIUM／LOW 分級（擴大至 iOS） |
| 必測路徑 | C# Golden＋`dotnet test`；Swift `swift test`＋parity；商業 UI 測試；存檔；Release 預檢；治理驗證器 | `ios/README.md` 的驗證指令；整合報告的測試表；#7 的驗證器清單 |
| L1→L2 升級 | 規則核心、跨 Core／UI／存檔、計費語意、發布路徑、治理 Hook／框架 pin／F-7 | Owner 分析；#7 本文的隔離更新邊界 |
| 禁止行為 | 未授權 push／merge／發布、不自行通過 Gate、不 `--no-verify`、**不在載入 agent hooks 的目錄做 F-7 apply**、不清除含未保全變更的 worktree、不改計費語意／不動 Apple 與 AdMob 設定、不進憑證、素材須附來源與驗收 | #7 本文（Stop→session_end 範本風險）；`docs/save-1.*/SAVE_*_REPORT.md`（未保全 worktree 的保全過程）；`RELEASE_GAPS_1024.md`（素材不因舊 HOLD 就非法；Owner 已認定可修改） |

與舊 `e3a78fc` 版 AGENTS.md 的**刻意差異**（不直接複製舊禁令）：
- 移除「不碰 `assets/`、`.agents/`、`docs/visual/`」→ 改成「素材可修改，須附來源／生成紀錄與雜湊並與驗收分開記錄」。理由：該禁令針對當時尚未審查的美術候選；目前素材已大量整合。
- 移除「G1 等 G0」「R1 不自動授權 G3 UI」→ 這些是 Windows 早期 slice 狀態，iOS 線已超越；保留較一般的「Owner Gate 不自行通過」。
- 新增 iOS 專屬項：帳本／計費語意、存檔、發布設定、Release 預檢、憑證與簽署檔案。

## 5. 驗證（本分支，2026-10-15）

| 項目 | 結果 | 備註 |
|---|---|---|
| `governance_drift_checker`（`--framework-root additional/ai-governance-framework`，pin `2a09d54`） | `ok=True`、`severity=ok` | 在本 worktree 初始化的 submodule 上執行 |
| `external_repo_readiness` | `ready=True`、`hooks_ready=True`；`framework_source_canonical`／`framework_version_current`／`framework_version_known` 為 False | 與 #7 本文列的 `framework-version` 警告同源（submodule 型導入不寫 `framework.lock.json`），**不是本次變更造成** |
| `validators/hook_wiring_check.py .` | `ok=True`（2 個設定檔） | |
| `python -m unittest discover -s validators` | 24 項 OK | |
| `validators/golden_fixture_validator.py .` | `ok=True`，24 組 | 只查結構／詞彙／setup／動作參數，不重播 |
| `memory_workflow --check` | `status=no_memory_workflow_required`（本次未改 `memory/**`） | **注意**：輸出的框架路徑指向主 checkout 的 submodule（來自 `.governance/baseline.yaml` 的本機絕對路徑），不是本 worktree 的；這項檢查沒有檢驗記憶完整性（輸出自己也寫「Memory authority has not been checked」） |

### 未驗證（明確列出）
- **記憶寫入**：本次未用 `memory_record` 寫 session 記錄（只改文件）。若治理要求每個 session 留 canonical memory，需 Owner 決定是否補寫；#7 本文已記錄 `missing_canonical_memory` 這類警告。
- **Hook 運行**：只跑了 `hook_wiring_check` 的靜態檢查；沒有測 hooks 在 agent 工作階段的實際行為。
- **Swift／iOS／C# 測試**：本次只改文件，沒有重跑；本機無 Xcode／Swift，Apple 帳戶狀態沒有查。
- **舊手冊中的數字**（Domain 75／Windows 61 等）：沒有重驗，仍是 2026-10-08 的記錄，已由橫幅標示。
- **`docs/HANDOFF.md` §5 的規則指路**：我讀了來源文件的片段，沒有逐項核對 Swift 實作。
- **其他本機 worktree 的未提交變更**：只列出 `git worktree list`，沒有逐一檢查或動它們。

## 6. 遵守的限制

| 限制 | 狀況 |
|---|---|
| 不修改遊戲邏輯、素材或正式發行設定 | 只動 `AGENTS.md`、`docs/`、`tools/probes/`；無程式碼／素材／xcconfig 變更 |
| 不合併 PR | 未合併 |
| 不更動 Apple 設定 | 未存取 |
| 不刪除原 worktree | 未刪；新增 `TacticalGo-handoff-recovery` worktree，原 `TacticalGo-3c`（`docs/handoff` @ `e3a78fc`）與主 checkout 不變 |
| 不執行 `--no-verify` | 未使用 |
| 不把未核准決策寫成正式規格 | M6 option (a) 寫成「實作但尚未正式決定」；#7 三項決策列為 Owner 待決 |
| 不自動 push | 未推送 |

## 7. 建議的後續（等 Owner）

1. 審核本分支；同意後再決定是否推送、開 PR（目標分支與 #7 的關係見 §1）。
2. 決定 `docs/handoff` 本機分支（`e3a78fc`）的去留；其中含個人本機路徑的證據 JSON 不應推送。
3. 若 #7 先合併，本分支可直接以 #7 合併後的 `main` 為基底重新對齊。

## 8. 提交時的 pre-commit 建議性輸出（2026-10-15）

提交 `f015a72` 時本機 hook 輸出 `warning_codes=missing_canonical_memory,test_evidence_artifact_metadata_missing`，`completion_claim_allowed=True`，明寫「commit is not blocked」。兩者都在 #7 本文的已知警告清單內（記憶缺口、舊記錄證據來源）；本次沒有寫 canonical memory，**這些警告未被解除**。若要消除，需 Owner 決定是否補寫 session 記錄（用 `governance_tools.memory_record`，且 `--test-evidence` 必須是實際執行結果）。

## 9. 更正（2026-10-15 10:10）

首次提交的 HANDOFF 把 PR #8 寫成「100 檔」：那是 `gh pr view --json files` 的上限，不是實際數字。以 `gh api repos/Gavin0099/TacticalGo/pulls/8` 核對為 **1,655 個變動檔案**（30 commits）；#7 為 46 檔／22 commits，與先前一致。已更正 `docs/HANDOFF.md`。另外，目前 6 個 PR（#1、#2、#5、#6、#7、#8）全部 OPEN。

## 10. CLOSEOUT-09 變更（2026-10-15 10:5x，依 Owner 指示）

| 變更 | 檔案 | 依據 |
|---|---|---|
| HANDOFF 狀態表直接改正（#7、#1 已 merged；`main`=`dca10d2`；#9 已推送、base=`main`；#8 HOLD；移除追加式更新區塊） | `docs/HANDOFF.md` | `gh api`／`git ls-remote`，2026-10-15 10:45 |
| `PR8_BLOCKER_ANALYSIS.md` 重寫：補 P1（開局預留額度但棋局未保存）、P2（終局對帳只在進入擴充畫面時執行）；廣告 callback 寫入失敗另列為 R；**更正首版低估與漏讀行內審查** | `docs/handoff/PR8_BLOCKER_ANALYSIS.md` | `gh api …/pulls/8/comments`（Codex 行內審查，review `@748d3e4`）；原始碼 `GameStore.swift:19–34`、`ExpansionLabView.swift:196/355/374/382–388`、`ExpansionGameView.swift:150–153`、`PlayableGameView.swift:293–304` |
| **AGENTS.md 授權規則拆成兩層**（供 Owner 審核；見下方差異） | `AGENTS.md`（Forbidden Behaviors 第一項） | Owner 指示；原規則造成每次 commit／push 都需重新請示 |

### AGENTS.md 規則差異（待 Owner 審核）

```diff
- - 未經本次明確授權，不 push、merge、開／改／關閉 PR、刪分支、發布或提交審查；不自行將 Owner Gate（G0／G5、試玩、美術、聽感、審查）標為通過。
+ - **授權分兩層，不要混用：**
+   - **日常工程授權**：Owner 核准某個 slice 後，在**該 slice 指定的分支**內可修改、測試、commit、push，並建立或更新該 slice 對應的 Draft PR，不需逐次請示；持續有效至該 slice 完成或 Owner 撤回。範圍僅限指定分支與其對應 PR，不含 force push 他人分支、刪分支。
+   - **產品與主線授權（每次都需 Owner 明確同意）**：合併 `main`、關閉或改動非自己建立的 PR、刪分支、修改計費語意或商業額度政策、正式發布設定、App Store Connect／AdMob、提交審查或發布。
+   - 不自行將 Owner Gate（G0／G5、試玩、美術、聽感、審查）標為通過。
+   - 本規則不改變 Claude Code 等工具自身的權限分類器；被工具拒絕的動作，不以改規則或換工具繞過，回報後由 Owner 決定。
```

注意：
- 這個規則只約束 agent 的行為契約，**不能**取代工具自身的權限分類器（先前 `gh pr merge` 即被分類器拒絕）。
- 「持續有效至 slice 完成」把授權綁在 slice 而非單次對話；若 Owner 希望更窄（例如每個 PR 一次），可改為「於該 PR 範圍內」。
- 此變更屬治理規則，**未經 Owner 審核不應視為生效**；它在 PR #9 內，合併即生效。
