# R1 魔法之手交付與戰術證據

結果：R1 保留機制候選；已修正五口氣與可達性分類，補充現有 9×9 起點下的合法重播及上一回合反制。
原因：原 5×5 案例只屬機制展示；9×9 補充證明特定部署可產生戰術差異，也證明對手提前補強能阻止這組攻擊。
下一步：正式技能替換仍 HOLD，封印仍預設；G0 Pending，G1、G3 不提前。

## 範圍與版本

- 日期：2026-10-08；授權來源是本次 Owner 的 R1-MAGIC-HAND 指示，規格記入 `docs/DECISIONS.md` 與 `docs/RULES_DRAFT.md`。
- 分支：`codex/r1-magic-hand`，由 `chore/governance-full` @ `761af5da610cfb42aa7e370c229b9549754ae562` 建立隔離 worktree。
- 只改 Domain、規則測試、Golden replay／validator 的新詞彙、研究探針與直接相關文件。`src/TacticalGo.Play`、Play 測試、`assets/`、`.agents/`、`docs/visual/` 均未修改。
- 法師仍預設封印。`RuleConfig.MageSkill = MageSkill.MagicHand` 才能施放魔法之手，封印是另一個可切換基線；不改正式 UI。
- 本機提交；沒有 push、merge 或新 PR。PR #1 的既有 `governance-drift` 成功只綁定 `761af5d`，不是 R1 CI。

## 行為契約

法師在場，且本回合未施法，可用 1 AP＋2 Mana，將曼哈頓距離 ≤2 的一顆敵方普通士兵推往玩家指定的正交相鄰空點。
拒絕主將、英雄、己方、空目標、佔據目的地、出界、無效方向、連鎖推動、資源不足、自殺及重複歷史盤面。
拒絕時回傳原狀態物件，沒有資源消耗、技能旗標變更或事件。成功時法師不移動，原位清空，發出 `PiecePushed`。

幾何性質不需要新增處決規則：A → 相鄰空點 B 後，A 必然是 B 所在敵方棋串的一口氣。最小測試在技能實作前已執行。
若要提掉被推士兵，需要後續落子與適當包圍；不能把單次推動直接提掉該士兵當測資。

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
dotnet run -c Release --project tools/probes/magic-hand -- docs/evidence/r1-magic-hand/search.json
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

這補上「現有 9×9 起點下存在合法可重播例子」，仍未證明對正常對手能可靠取得此局、能否形成多種有價值策略，或己方推動擴充後的平衡。正式替換仍 HOLD。

## 限制與 Gate

- 原輪只驗證手選 5×5 局面；本輪另補兩個手選 9×9 根局面與上一回合反制。均非隨機樣本、7×7 驗證、長期勝率或完備策略證明。
- 合法可達性使用自訂 5×5 主將起點及配合的建盤對手；不代表從正式 9×9 開局能逼出這些盤面。
- 非終局代表線在此對手下一回合搜尋內未出現我方主將被提；這只限該線、該深度與無技能對手，不能外推穩定防守價值。
- 先前封印 476 局面零獨有勝局及防守面 0 局面的結果，僅引述 `docs/handoff` @ `c55a2e1` 的手冊與 probe README。本輪沒有重跑；不證明封印無用，也沒有與封印直接作本輪對比。
- G0 仍 Pending，G1 仍等 G0，G3 UI 沒有授權，G5 沒有人類驗收。不能宣稱平衡、好玩、新手看懂、正式技能更換或發布完成。

實作與證據完成後，可作本機程式／測資審查；若後續要設計 G3，須由 Owner 另行決定，不自動接續。
