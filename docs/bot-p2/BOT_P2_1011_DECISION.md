# BOT-P2｜1011 判定：有限正例與生命週期工程通過，成本與真人待驗收

先前斬首候選在第40／55回合與三組對局沒有改善，因此不能宣稱後期停滯修復。後續在同一既有工程缺口內，找到一個原版規則、完整官方來源的真實 baseline Pass：43步盜賊對法師來源，候選 G7 形成等待沒有的安全提兵威脅。這補上 G-BP2-2 要求的有限正例；root已補共享全Package212tests零失敗、當前SwiftGolden38組／99步及material trace一致性；新policy三組六場非退化與五項原生生命週期亦已補齊。G-BP2-2以本有限正例與回歸範圍判定工程通過；G-BP2-3成本與G-BP2-4真人各保留Pending。

真實baseline選擇等待會錯過本有限驗證的安全提兵路線；未證明等待在所有長期評估下都錯誤。
## 新候選與實際行動

`materialThreatContinuation` 保留原版及舊斬首候選，預設 baseline 不變。候選只對真實原版等待評估最多一個有限排序的完整己方回合；沒有調 Pass 懲罰或改棋規。真實 baseline 在正例使用144次顯式apply、分數-1228，選等待；G7 原版有限分數-1231，原本落後而未選。

G7 後全部35個完整敵方回合均不送掉己方主將，且每個回合都有下一己方完整回合的實際敵兵提子見證。每個見證後再檢查全部完整敵方回合的己方主將安全。原版等待 → 敵方等待則找不到同等安全的下一己方提兵。候選由此授權 G7，而非因氣數或評分較好。

實際 planner 在 G7 → 敵方等待後，下一回合選 G5、F6，Core 提掉 G6白兵；這條執行也檢查完整後續敵方回合的主將安全。其他34回應僅證明存在安全提兵見證，未宣稱實際 planner 皆會採用。部分防禦保住或移走 G6而損失其他兵／主將棋群；不保證每分支都提同一兵，不是每分支即勝。

正例使用剩餘一AP、零Mana，己方棋群由四氣變三氣；實際提兵後 G6成為新的空點。相同戰士來源等待後也能用築壘提兵，是保留的負向比較，不能拿它冒稱新威脅。既有R3第40及未解55均仍等待，沒有宣稱全部停滯或55修好。

## 新候選成本與執行邊界

完整正例 API 決策用796次顯式apply、192次legal enumeration，含原版144次、等待新意對照、完整35回應及提兵後反制；沿用6000顯式apply上限。legalActions內部驗證不計入此數字，不稱6000總Core工作。預算不足返回原版完整actions；取消維持nil，未完成證明不得發出候選。easy與舊forcing策略隔離，候選可關閉。

沙盒Mac Release暖機後各五次量測：正例baseline median0.0693905秒，候選0.383258167秒，約5.52倍（+452%）；候選mean0.393秒、max0.434秒。這超出合約約25%的規劃目標，不能用6000內或舊40／55成本通過替代新成本驗收。量測期間沒有證明原生建置完全閒置；受控重測、實體iPhone思考／逐手流暢度與偏離成本的Owner接受均Pending。

實際後續G5、F6使用95次apply；候選mean0.046秒。新material在40／55仍Pass，apply分別453／216。這是本機固定測資，不是所有盤面或人機真機效能結論。

## 保留的斬首候選歷史對局

| 設定／標準難度 | baseline／舊forcing候選結果 | 純等待 | 最長連續純等待 |
|---|---|---:|---:|
| 原版戰士對法師 | 同一 Core100回合上限和局 | 61／61 | 58／58 |
| R3戰士對法師 | 同一 Core100回合上限和局 | 65／65 | 57／57 |
| 原版法師對盜賊 | 同一 Core100回合上限和局 | 47／47 | 32／32 |

來源 `three-pairings-pressure-filter-04.json` 保存六場逐步before／action／events／after，無非法行動，Core自行100回合結算和局。這是**舊forcing policy**比較，不能轉標成新material在當前sourceSHA的三組對局。新policy fixedpairings已用當前Core／BotSHA另跑並保存21；新原生五項收據另保存於material-native-07，亦不以少量自動對局推論人類勝率、整體和局率或樂趣。

舊forcing同M3／16GB、macOS26.6.2、無原生建置並行的Release交錯量測：40 median0.4369→0.4552秒（+4.2%），55 0.1252→0.1254秒（+0.13%）。舊兩負例符合25%目標，但這筆歷史結果不能替新material正例的成本作PASS。

## 當前material的三組固定對局

`material-fixed-pairings-21.json`是使用新material policy的實際新run，source-pin20固定當前Core／Bot SHA，前後校驗一致。六場、600完整回合均由官方開局開始，逐動作收據／事件獨立重播，終局完整GameState含歷史完全相等；零非法、零預算耗盡。

| 固定配對 | baseline／material結果 | 純等待 | 最長連續純等待 | 最大顯式apply |
|---|---|---:|---:|---:|
| 原版戰士對法師 | 100回合CoreDrawn，行動及終盤相同 | 61／61 | 58／58 | 1978／1978 |
| R3戰士對法師 | 100回合CoreDrawn，行動及終盤相同 | 65／65 | 57／57 | 2140／2140 |
| 原版法師對盜賊 | 100回合CoreDrawn，行動及終盤相同 | 47／47 | 32／32 | 2054／2054 |

material在這三局沒有接受新提兵候選（0次），因此新有限正例沒有轉化成這組一般對局改善。這份證據支持當前policy固定對局非退化，不代表人類勝率、整體和局率或強AI。思考耗時保存於同檔；原生工作並行且非交錯閒置量測，不將全局耗時當受控性能Gate。標準規則原有100回合自行Drawn，沒有外部截斷或新終局規則。

## 第55回合的保留診斷

完整Core歷史下的有限被動探針，最多五個己方完整回合、敵方只等待，不剪枝或按diagram合併。上限150000顯式apply，實際5541次、1526狀態，最深四個己方回合；無第五回合非等待分支或獲勝分支，敵主將最少仍兩氣。它不包含己方純等待／存Mana或其他反制，不證明永久僵局、全域最優或應改終局規則。新有限正例不改寫這個負向結果。

## 新原生生命週期收據

`artifacts/bot-01r/material-native-07/completion-summary.json`與`RESULTS.md`記錄五個唯一XCTest方法PASS、0primary failure，11張原生截圖、4筆新收據。所有五次run的production source／assets pins一致，主執行檔與每個dylib各自固定；不只以Debug launcher SHA當程式身份。155檔manifest保存結果、receipt proof、command、截圖索引、source pins與保留診斷。

- 正例：重播43官方動作後的真Bot G7，1receipt；黑ply23剩1AP→白ply24／2AP，Mana5／6不變，整盤只新增G7。這手沒有立即提子；實際後續G5／F6提G6是另項Package證據。
- 候選取消：undo後completion0／discard1，G7仍空，0receipt；不存在晚到候選提交。
- 選單：baselineEasy→Standard→候選→原版，唯一AP header、49格標籤、兩Mana與回合不變，0receipt。
- 舊晚到結果與restart／exit：分別1與2個合法**人類D5**收據啟動思考；無Bot新提交，invalidated generation各completion0／discard1。這3筆不是Bot提兵或候選提交。

selector03曾PASS但AP查詢可能誤匹配動作成本卡，已由authoritative selector-hud07取代；HUD06因SwiftUI AX查詢失敗的診斷保留，不列入五項primary PASS。final07讀棋盤上方真正唯一AP header，未增production accessibility識別。這是iPhone13／iOS18模擬器390×844pt、Xcode26.6；不等於實體iPhone成本／趣味。root的1017簽名／安裝亦不替代這兩種驗收。

## Gate與待補證據

| Gate | 現在判定 | 依據／邊界 |
|---|---|---|
| G-BP2-0來源／重播 | 既有證據具備；新正例43步具備 | 原版正例每步收據／事件核對；40／55保持候選R3原來源與設定 |
| G-BP2-1診斷 | 有限原因與反例具備 | 40防守可接受；55收益未判定；Rogue新威脅與Warrior等待也能提兵分開 |
| G-BP2-2工程 | **PASS：有限正例與生命週期工程候選** | 43步真baseline等待→G7有效威脅；35完整回應／見證後安全、實際G5／F6後續、共享212tests／SwiftGolden／material trace、當前三組六場及五項原生生命週期通過；不宣稱一般停滯全修復 |
| G-BP2-3成本 | **Pending：正例偏離25%規劃目標** | 已量測本機median約+452%；需要受控／真機證據與Owner接受，不能挪用舊成本PASS |
| G-BP2-4真人 | **Pending** | Owner至少兩局的目的／反制／等待與趣味回饋尚未取得 |

修正版patch與可關閉研究接線已套入，預設仍baseline。共享新結果212tests／46.658秒見`swift-full-material-final-1017.log`；新對局21與原生material-native-07五項方法／11截圖／4收據已具備。此輪Golden不是新的C#跨語言run。合併／發布與人類驗收不由工程沙盒測試自動取得。

證據主包：`artifacts/bot-p2-1011/noncommander-threat-09/`。完整SHA及源檔在`proof-manifest-09.json`、`sandbox-review-manifest-16.json`；實際API成本在`sandbox-release-perf-14.json`，回歸在`sandbox-bot-regression-13.log`。
