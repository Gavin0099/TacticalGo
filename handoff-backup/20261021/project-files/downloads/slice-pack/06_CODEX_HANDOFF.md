# TacticalGo｜Codex 指令集（可複製貼上）

> **使用方式**：先貼「Prompt 0」要求 Codex 僅核對資料與列執行計畫。日後 Owner 若另行授權某個 Slice 開發，再貼對應的單片 Prompt。**本工作包的製作本身，不構成任何程式修改授權。**
>
> 將整個工作包放在 Codex 可存取的工作目錄內，請它讀 `00_MASTER_CONTRACT.md` 和單片合約；若只有一份文字，直接貼入單片合約全文。不得假設 Codex 能讀 ChatGPT sandbox URL 或使用者 Mac 本機私人路徑。

## Prompt 0｜全局讀取與計畫核對（現在即可使用，READ-ONLY）

```text
你是 TacticalGo 的工程規劃／驗證 agent。本次模式為 PLAN_ONLY（嚴格唯讀），只要輸出一份可審核的執行方案，不修改任何檔案或狀態。

先讀工作包的 00_MASTER_CONTRACT.md、README.md、全部五份 Slice 合約（01_BOT-P2.md、02_CONTENT-03.md、03_BOSS-00.md、04_ANIM-01.md、05_3D-00.md）。

在 TacticalGo repo 內以唯讀方式確認：AGENTS.md 與有效框架、docs/DECISIONS.md、docs/RULES_DRAFT.md、git HEAD / status / 各 worktree、BOT-P1 PR #5、CONTENT-02 PR #6、R3 original/opt-in、現有 ANIM-01 模擬器/手機候選、SELL-01C 候選、3D 身份否決紀錄。不同分支／不同時間的資料不可混為一個已合併產品狀態。

輸出：1) 實際來源／SHA／缺口列表，2) 硬依賴與推薦分支基線，3) 五片先後/可並行計畫，4) 每片允許的檔案路徑/不可改路徑/必要測試，5) 各片 Owner 驗收 Gate，6) 有任何資料衝突就標 BLOCKED 而不自行 merge/rebase。

本次禁止：寫 repo、建立檔案／branch／commit、stash／reset、push／merge、修改源碼／圖片／測試、執行 build 安裝真機、發布或將候選升格正式設定。只在回覆輸出結論與可複製的後續執行指令。請以「結果／原因／下一步」開頭，區分 PLAN_READY、HOLD、BLOCKED；不要宣稱測試已執行。
```

## Prompt 1｜BOT-P2：電腦攻守改善（僅在另行授權工程後使用）

```text
Owner 現在明確授權開始單片 BOT-P2 的隔離候選實作；未授權其他片、合併、推送、安裝或發布。

先讀 00_MASTER_CONTRACT.md、01_BOT-P2.md、07_GATE_CHECKLIST.md，遵守 AGENTS.md / governance。先核對 BOT-P1 PR #5 的 Head、完整兩手反例、40/55回合 replay 與原版/R3 區分，再 freeze baseline。不要 merge/rebase PR #5、#6，除非 Owner 另外明確授權；若基準無法安全建立，就回 BLOCKED 而非搶先修改 main。

限制只改必要的 Swift Bot 決策與測試/驗證，不改 Core 規則、AP/Mana、預設 R3、音效/UI/美術。允許 Pass，不能強迫落子。先證明舊 Pass 的攻守原因，再用最小可切換候選改善安全進度。所有合法性來自 Core；trace on/off 決策等價。

交付：固定40/55和新反例的 baseline/candidate 比較、每步敵方回應與斬首安全、完整對局 replay、性能、測試/Golden、原生 async cancellation，以及 Owner 真人測試說明。逐條核對 G-BP2-0～4。Engineering PASS 不代表遊戲性 GO；不能 commit/push/merge/release。最後列出實際變更與未通過 Gate。
```

## Prompt 2｜CONTENT-03：進階三關（僅在另行授權工程後使用）

```text
Owner 現在明確授權開始單片 CONTENT-03 的隔離候選實作；未授權其他片、合併、推送、安裝或發布。

先讀 00_MASTER_CONTRACT.md、02_CONTENT-03.md、07_GATE_CHECKLIST.md，檢查 CONTENT-02 PR #6 的 Head、Controller、選關/結果/復原/保存隔離。若依賴不存在，只做資料/fixture規格並回報，禁止私自重寫整個既有 Controller 或 merge PR。

新增第二章恰好3關，分別驗證主將多回合救援、佯攻/敵方反制、技能與 Mana/行動順序。三關全部由 Core 合法狀態/動作結算，敵方有真實回應，不能只 Pass。至少各有可解序列、合理失敗序列及有限範圍證據；不聲稱全域唯一解。原版預設、六關舊進度、正式 MatchSave、R3 opt-in 及 golden 不變。

交付：來源局面/Ko歷史、三關成功與反制完整 replay、必要提示和失敗原因、Core/Golden/原生回歸、SE與iPad結果、Owner不看提示的實際驗收表。標出尚未完成的人類難度驗證，禁止把新關卡自動視為有趣或可發布。不 commit/push/merge/release。
```

## Prompt 3｜BOSS-00：紅龍規則合約（設計專案，不授權遊戲程式）

```text
Owner 授權執行 BOSS-00 規則設計文件，除此以外沒有任何首領實作授權。

讀 00_MASTER_CONTRACT.md、03_BOSS-00.md、AGENTS.md、docs/PLAN.md S4、docs/RULES_DRAFT.md、docs/DECISIONS.md。先區分紅龍歷史構想與目前已採納規則。用文件定義 7×7 最小首領模式，設計視覺 overlay/中立單位、phase/預告時序、三格方向、兩種龍息效果、氣/原子提子/Ko/勝負/重播/存局/AI公平性等所有未決問題。

輸出 BOSS00_RULE_CONTRACT / STATE_MACHINE / OPEN_DECISIONS / EXAMPLES / IMPLEMENTATION_BOUNDARY 五個設計內容（若未另外授權寫 repo，請只在回覆或指定外部工作資料夾產出）。提供四份有座標的手算局面 transcript，以及每項 SELECTED/REJECTED/OPEN。關鍵規則未經 Owner 決定一律 OPEN/HOLD。

禁止修改任何 TacticalGo 遊戲程式、建立 Dragon Mesh、實作 BOSS-01、正式加入龍息事件、啟用 RNG 或調整勝負模式。不得假裝設計文件即證明玩法好玩；最後交付 Owner 決策表。
```

## Prompt 4｜ANIM-01：魔法之手角色動作（僅在另行授權動畫後使用）

```text
Owner 現在明確授權單片 ANIM-01 法師角色動作精修的隔離候選；未授權 3D 建模、其他角色、合併或發布。為避免與既有 ANIM-01 產物衝突，新的 worktree/artifact 請標記 ANIM-01R，不得覆蓋舊來源包。

先讀 00_MASTER_CONTRACT.md、04_ANIM-01.md、docs/ios/V2_ASSET_CONTRACT.md，唯讀盤點本機既有魔法之手候選、B-v02 原畫身份、Core 原生事件、原生影片、後製音效與 source hash。找不到素材就 BLOCKED，不可以自己用不同角色圖替代。

角色必須有可辨識的準備、抬手/揮杖、指向目標、impact、收勢；整張立繪縮放只能是 fallback，不能冒稱有手臂動作。保護原 B-v02 臉、帽、晶杖身份，不動 Core/技能合法性/Mana/AP，也不要新增語音或 BGM。

所有效果只由成功提交的 Core event 觸發；preview/取消無impact；undo/restart/背景/離場/Reduced Motion/快速跨回合要安全。交付含實際 before/after native 影片、來源可編輯素材、影格/階段接觸表、SE/iPad測試、來源 manifest、哪些聲音原生/後製的說明。不得 commit/push/merge/release，不得稱之為已核准的正式 3D 模型。
```

## Prompt 5｜3D-00：身份與風格規格（純文件）

```text
Owner 授權的僅是 3D-00 設計規格；禁止做任何新的頭雕、Mesh、Rig、USDZ、全身、動畫或將 3D 角色替換進 App。

讀 00_MASTER_CONTRACT.md、05_3D-00.md、docs/ios/CHARACTER_PRODUCTION_ROUTES.md、V2_ASSET_CONTRACT.md、既有 Warrior head-v02 REVIEW，以及 B-v02 原畫與來源 manifest。查驗可實際讀到哪些素材（尤其歷史 1254 master 與 512 derivation），切勿從 metadata 推論原始檔已找到。

輸出：Reference Inventory（來源/SHA/尺寸/授權）、戰士身份規格（栗髮/臉型/奶油衣/青綠披風/盾劍與盾徽，不可變項、未知面）、前/3-4/側/背相機與材質標準、64/128px和7×7/9×9可讀性規格、從Blender到iOS的風格/性能風險、是否啟動後續 3D-01 所需的 Owner Gate。

說明 A0仍是可玩基線。先前模型技術驗證不能當身份通過；若缺少多視角資料或 Owner style approval，結案 HOLD。不得編造新的正式角色設計、購買素材、修改程式或提交推送。
```

## 統一結案訊息模板

```text
結果：[PLAN_READY / ENGINEERING_CANDIDATE / OWNER_ACCEPTED / HOLD / BLOCKED]
原因：[最重要的證據與尚有缺口；區分規則正確／動畫技術／真人趣味／身份]
下一步：[下一個需要 Owner 採納的 Gate，禁止自動跨越]
基準：[repo / SHA / worktree / PR / source manifest]
本次變更：[確切路徑；若唯讀則填無]
驗證：[命令 / 環境 / PASS / FAIL / NOT_RUN；如屬文件設計不得填測試已過]
風險與債務：[阻擋性問題、非阻擋性已接受風險、Known debt 分開]
發布狀態：[commit / push / merge / 真機安裝 / release 逐項填未執行或實際狀態]
Owner 待驗收：[真人場次、畫面、風格、權利、決策編號]
```

---

**使用注意**：如果目前只希望 Codex 審查計畫，請始終使用 Prompt 0，而**不要**貼帶有「Owner 現在明確授權開始實作」的 Prompt 1／2／4。Prompt 3／5 即使執行也只能產出設計文件，不授權遊戲實作。
