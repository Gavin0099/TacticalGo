# R1 魔法之手交付與戰術證據

結果：Owner 已選魔法之手作法師預設，R1 研究收斂；封印保留比較基線。
原因：最新指示取代先前 HOLD；技能可推雙方普通士兵，但尚未證明擴充版策略價值、平衡或好玩。
下一步：G0 實際試玩；G1、G3 不提前。預設切換目前只在本機 R1 Domain，未整合 UI 分支／exe。

## 範圍與版本

- 日期：2026-10-08；授權來源是本次 Owner 的 R1-MAGIC-HAND 指示，規格記入 `docs/DECISIONS.md` 與 `docs/RULES_DRAFT.md`。
- 分支：`codex/r1-magic-hand`，由 `chore/governance-full` @ `761af5da610cfb42aa7e370c229b9549754ae562` 建立隔離 worktree。
- 只改 Domain、規則測試、Golden replay／validator 的新詞彙、研究探針與直接相關文件。`src/TacticalGo.Play`、Play 測試、`assets/`、`.agents/`、`docs/visual/` 均未修改。
- 法師預設魔法之手，`RuleConfig.MageSkill = MageSkill.Seal` 保留封印比較基線。此次核准不開 G3，也不修改現有 UI。
- 本機提交；沒有 push、merge 或新 PR。PR #1 的既有 `governance-drift` 成功只綁定 `761af5d`，不是 R1 CI。

## 行為契約

法師在場，且本回合未施法，可用 1 AP＋2 Mana，將曼哈頓距離 ≤2 的一顆**雙方普通士兵**推往玩家指定的正交相鄰空點，保留歸屬。Owner 本輪另授權己方推動，並確認只含普通士兵。
拒絕雙方主將、英雄、空目標、佔據目的地、出界、無效方向、連鎖推動、資源不足、自殺及重複歷史盤面。
拒絕時回傳原狀態物件，沒有資源消耗、技能旗標變更或事件。成功時法師不移動，原位清空，發出 `PiecePushed`。

幾何性質不需要新增處決規則：A → 相鄰空點 B 後，A 必然是 B 所在敵方棋串的一口氣。最小測試在技能實作前已執行。
若要提掉被推士兵，需要後續落子與適當包圍；不能把單次推動直接提掉該士兵當測資。
己方被推士兵也保留原位作為氣。但己方士兵移入另一敵方棋串的最後一口氣，可以按既有流程當次提掉敵子；測資 `magic_hand_friendly_capture` 展示此行為。不能將原來「推敵兵本身不會直接死」外推為「雙方推動後都不會發生任何提子」。

## 最新預設切換驗證

依最新 Owner 決定，未指定 `MageSkill` 時使用魔法之手；指定 `Seal` 可用原封印。新預設測試在切換前失敗（實際是 Seal），切換後聚焦測試及兩組 Golden 共 3 項通過。舊封印測試改為明確設定，棋盤與行動預期保留；增加 `magic_hand_default`，原預設封印 fixture 改名 `magic_hand_explicit_seal`。

[default-validation.json](evidence/r1-magic-hand/default-validation.json) 保存本輪指令、TRX 計數、來源／原始輸出雜湊：Domain **129**、Windows **47** 通過，Golden **38** 組成功；validator 接受 **38** 組、正反 harness **5** 項通過，漂移 `severity=ok`。Windows 仍是治理基線，未整合 UI-3c；不是合併後測試，也沒有魔法之手 UI。

剩餘路線見 `docs/PLAN.md` 最新 Owner 決定：G0 後到完整可玩版本還有 G1–G4 四個開發 Slice；G5 真人驗收、G6 回饋修正。沒有新 Slice、搜尋、push 或 merge。

## 上一輪雙方推動回歸（7c7abec，歷史驗證）

詳見 [friendly-validation.json](evidence/r1-magic-hand/friendly-validation.json) 與 [friendly-mutations.json](evidence/r1-magic-hand/friendly-mutations.json)。這是雙方推動修訂當時的實際執行；其來源雜湊與預設封印都屬歷史版本，不是最新預設切換的驗證。

| 檢查 | 本輪結果 | 證據範圍 |
|---|---|---|
| Domain 完整回歸 | 128 通過、0 失敗／略過 | 包含原規則與 37 組 Golden |
| Windows 回歸 | 47 通過、0 失敗／略過 | 治理基線 UI；仍未整合 UI-3c |
| 五口氣修正聚焦重播 | 2 通過 | 固定起始座標斷言及原 Golden 棋形；沒有改棋盤 |
| 新增己方推動測試 | 舊版 11 失敗 → 實作後 11 通過 | 雙方四方向、目標歸屬、拆串、提子事件、superko 回滾 |
| Golden validator／正反 harness | 37 組接受／5 通過 | 真正重播由 Domain 測試執行；validator 是詞彙／結構驗證 |
| 本輪聚焦變異 | 2 個被抓到、原碼還原後 11 通過 | 恢復敵方限定時 11 失敗；候選漏己方時 8 失敗 |
| 漂移 | `severity=ok` | 本機檢查；不等於 runtime enforcement |

新增三組手寫 Golden：`magic_hand_friendly_two_push_then_place`、`magic_hand_friendly_capture`、`magic_hand_friendly_superko`。費用、射程、技能次數與既有回滾流程沒變；原先「己方目標非法」斷言因 Owner 規格更動而移除，改用正向行為測資。舊版新增測試的失敗紀錄保留，沒有為通過測試而更動戰術起始棋形。

己方推動的提子小例：`o.x.. / x.H.. / ..... / ..... / X...O`，把我兵 `(2,0)` 左推至 `(1,0)`，填掉敵兵 `(0,0)` 最後一口氣；依序發出扣資源、推動、提子事件。這是規則展示，沒有宣稱正式對局的策略優勢。
直接落子 `(1,0)` 也能提同一敵兵，只花 1 AP、0 Mana，且保留 `(2,0)` 原兵。因此此例不能用來證明玩家值得花 2 Mana 推己兵。

```powershell
python tools/probes/magic-hand/check-mutations.py --friendly-only
```

## 驗證

下表是 `191347d` 的原輪驗證，不能視為後續修改的測試結果。數字取自 [validation.json](evidence/r1-magic-hand/validation.json)、[mutations.json](evidence/r1-magic-hand/mutations.json) 與 [search.json](evidence/r1-magic-hand/search.json)。
驗證回執含實際 TRX counters、原始檔雜湊、指令與輸出；TRX／完整 log 留在 worktree 的 `artifacts/r1-validation/`，不入 git，可用下列指令重跑。

| 檢查 | 實際結果 | 範圍 |
|---|---|---|
| 基線 Domain | 75 通過 | `761af5d`，實作前 |
| 基線 Windows | 47 通過 | `761af5d`，實作前 |
| 最小幾何測試 | 1 通過 | 技能實作前 |
| R1 Domain | 115 通過，0 失敗／略過 | 含 34 組 Golden replay（原 23 組＋新 11 組） |
| R1 Windows | 47 通過，0 失敗／略過 | 治理分支的 UI 回歸；未引入 PR #2 |
| Golden vocabulary validator | 34 組接受 | 結構／詞彙檢查，非 replay |
| Validator 正反測資 harness | 5 通過 | 實際執行接受／拒絕副本 |
| 聚焦變異 | 7 個全部被抓到，原碼還原後通過 | 射程邊界、原位清空、Mana、自殺、superko、一次技能、左推候選 |
| 漂移檢查 | `severity=ok` | 本機；不證明 runtime enforcement |
| 交接分支另行核對 | Domain 75、Windows 61 通過 | `docs/handoff` @ `c55a2e1`；與 R1 分開計數 |

核心規則測試涵蓋四個方向、距離邊界、原位成為氣、第二次行動提子、拆開棋串、主將補氣、非法目標／目的地、AP／Mana／技能次數、選擇開關、完整回滾、舊盤面 superko、事件順序與終局。
Golden 的預期值由 Owner 規格和座標推理手寫，沒有從引擎匯出或為通過測試而調整。語言中立格式增加 `liberties`、`groups`、`skillUsed`，Swift port 之後須支援同一詞彙。

```powershell
dotnet test TacticalGo.sln
dotnet test TacticalGo.Windows.sln
python -m unittest discover -s tests/validators -v
python validators/golden_fixture_validator.py .
python tools/probes/magic-hand/check-mutations.py
python -X utf8 additional/ai-governance-framework/governance_tools/governance_drift_checker.py --repo . --framework-root additional/ai-governance-framework --format human
dotnet run -c Release --project tools/probes/magic-hand -- artifacts/r1-review/search-current.json
```

## 限定搜尋：可區分的棋形與可替代的對照

搜尋為 4 個手選 5×5 棋形、各 3 個方案，完成 6,446 次行動套用嘗試；預算固定 50,000 次／30 秒，沒有增加。
深度最多己方 2 個原子行動＋對手下一回合 2 個行動，共 4；早期斬首立即停止。計數是有序行動序列，不是不同盤面數。

所有起點均有**自訂 5×5 開局**的 `NewGame` → 合法落子／召喚／Pass 重播，保留完整 positional superko 歷史。這些是機制展示；主將不移動，敵方主將在 `(0,1)` 的案例不可能從目前 9×9 主將 `(4,1)` 的開局到達。7×7 主將起點未定，未建立其可達證據。
三方案使用相同棋子位置與 AP。Mage／Rogue 使用各自現有召喚費，因此 Mana 不完全相同，但都足夠施放一次；JSON 記錄實際值。
對手無職業；對每方案選出的單一代表走法，遍歷下一回合全部合法落子與提前結束。不是對所有己方走法作完整 minimax。

| 局面（JSON case） | A 魔法之手＋落子 | B 兩次落子 | C 換位＋落子 | 意義 |
|---|---|---|---|---|
| `connector_range_two` | 1 個當回合斬首序列 | 0 | 0（沒有合法換位起手） | 自訂 5×5 機制展示，非正式 9×9 可達證據 |
| `connector_adjacent` | 1 個當回合斬首序列 | 0 | 1；換位第一手已斬首 | 盜賊部署近時可更快替代 |
| `corner_soldier_capture` | 最多提 1 兵 | 最多提 1 兵 | 最多提 1 兵 | 推＋填原位可提子，但不是唯一解 |
| `commander_relief` | 推後可增加主將的氣 | 代表線可提敵兵，主將 6 氣 | 代表線主將 4 氣 | 補氣效果存在，沒有防守獨占證據 |

### 具體例子：射程兩格，推走連接兵再堵原位

`x/X/H` 是我方士兵／主將／法師，`o/O` 是敵方士兵／主將；座標從左上 `(0,0)` 起，Y 向下。

```text
起點       推 (1,1) ↓   落子 (1,1)
x....      x....       x....
Ooo..      O.o..       .xo..
x....      xo...       xo...
.H...      .H...       .H...
.x..X      .x..X       .x..X
```

起點 O 與兩兵連通，共有 `(1,0)`、`(2,0)`、`(3,1)`、`(1,2)`、`(2,2)` **五口氣**，兩次普通落子堵不完。原報告漏算 `(1,0)`；棋形未更動，新增字面座標斷言及 Domain 查核。
法師在 `(1,3)`，敵兵 `(1,1)` 距離 2。把它推到 `(1,2)` 後，敵主將與右兵分離，主將只剩原位 `(1,1)` 這口氣。
第二 AP 填 `(1,1)`，提掉敵主將；被推士兵仍在 `(1,2)`，法師仍在 `(1,3)`。
同位置盜賊沒有相鄰敵兵可換；把英雄改部署到 `(1,0)` 的對照局，盜賊換位第一手就能斬首。
合法起點重播與資源值在 JSON；`MagicHandReplayTests` 另用手寫盤面及事件預期驗證這條合法對局路徑。

### 審查補充：現有 9×9 起點與上一回合反制

[review-supplement.json](evidence/r1-magic-hand/review-supplement.json) 在敵方士兵限定的 `8ae3bd5` 審查基線上執行。原 `search.json` 的計數與來源雜湊保留，只新增審查註記；沒有把新探針假裝成原次執行。

只使用目前 `RuleConfig` 的 9×9、主將 `(4,7)`／`(4,1)`、首回合 1 AP 與現有費用。從 `NewGame` 合法落子及召喚至法師 `(3,3)`，對手此時有完整 2 AP 且已看到法師。建盤走法仍是配合的，不代表可以強迫對手形成此局。

```text
對手上一回合 Pass 後，我方行動前
....x....
...xOx...
....o....
...Ho....
...x.....
.........
.........
....X....
.........
```

法師可把連接兵 `(4,2)` 推到 `(3,2)` 或 `(5,2)`，再落子 `(4,2)`，切斷並提掉主將。此棋串起始有 4 氣，推後主將只剩 `(4,2)`。對手若在上一回合落子 `(3,2)`、`(5,2)`，兩個橫向目的地都被佔據；上下目的地原已被敵主將／敵兵佔據，這組推動不能成立。

| 對手上一回合選擇 | A 推＋落子的當回合斬首序列 | B 兩次落子 | C 換位＋落子 |
|---|---|---|---|
| Pass | 2 | 0 | 0 |
| 先佔 `(3,2)`、`(5,2)` | 0 | 0 | 0 |

只檢查以上兩條手選應對後的全部 A／B／C 行動組合；共 13,284 次 `Apply` 嘗試，固定上限 20,000 次／30 秒，未延長。不是遍歷對手上一回合全部選擇，也不證明必勝、平衡或任何真人感受。JSON 含完整設定、走法、資源、棋盤、獲勝線與來源雜湊。

這補上「現有 9×9 起點下存在合法可重播例子」，仍未證明對正常對手能可靠取得此局、能否形成多種有價值策略，或己方推動擴充後的平衡。當時正式替換為 HOLD；Owner 最新選擇預設魔法之手，不會使這些未驗證項目自動通過。
反制及 A／B／C 計數只綁定當時的敵方限定版本；本輪未重跑雙方推動版本的戰術搜尋，不能宣稱上述反制已擋住擴充版所有攻擊。

## 限制與 Gate

- 原輪只驗證手選 5×5 局面；本輪另補兩個手選 9×9 根局面與上一回合反制。均非隨機樣本、7×7 驗證、長期勝率或完備策略證明。
- 合法可達性使用自訂 5×5 主將起點及配合的建盤對手；不代表從正式 9×9 開局能逼出這些盤面。
- 非終局代表線在此對手下一回合搜尋內未出現我方主將被提；這只限該線、該深度與無技能對手，不能外推穩定防守價值。
- 先前封印 476 局面零獨有勝局及防守面 0 局面的結果，僅引述 `docs/handoff` @ `c55a2e1` 的手冊與 probe README。本輪沒有重跑；不證明封印無用，也沒有與封印直接作本輪對比。
- G0 仍 Pending，G1 仍等 G0，G3 UI 沒有授權，G5 沒有人類驗收。只能宣稱本機 R1 Domain 預設已核准切換，不能宣稱平衡、好玩、新手看懂、UI 整合或發布完成。

實作與證據完成後，可作本機程式／測資審查；若後續要設計 G3，須由 Owner 另行決定，不自動接續。
