# BOT-P2｜有限提兵候選驗證與待補項

新候選已在正式43步來源確認：真實baseline選擇等待會錯過本有限驗證的安全提兵路線；未證明等待在所有長期評估下都錯誤。root套入修復後的fixture並完成共享212項Package測試。完整來源、候選、安全反制及沙盒結果在`artifacts/bot-p2-1011/noncommander-threat-09/`；共享／原生日誌在`artifacts/autonomous-1011/validation/`。早期失敗與舊forcing證據保持原檔，不覆寫或改稱新policy結果。

## 新material候選

| 證據 | 實際結果 | 限制 |
|---|---|---|
| `controls-02.json`，Rogue／one-AP-after-A7 | 官方newGame、原版、43個合法動作，所有before／after／事件重播；真baseline Pass，score-1228、144apply | 作者安排的密集棋形，不是一般對局發生率 |
| `safety-and-threat-08.json` | G7後35完整敵方回合皆保住己方主將；35實際提兵見證，每見證後完整敵方反制安全 | 每分支存在見證；未宣稱35分支的實際planner都選該見證 |
| 同檔baseline-Pass對照 | 73完整敵方回合中72有下一己方提兵；唯一無提兵回應是敵方Pass | 正例新威脅針對原版等待→敵方等待缺失，未改55診斷 |
| `safety-and-threat-07.json` | 戰士相同來源等待後築壘也能提兵 | 保存負向比較，不能冒稱新提兵或只靠Mana節省通過 |
| `sandbox-bot-regression-13.log` | 37Bot tests、0failure；43步正例、35見證獨立重播、全後續安全、40／55、取消／耗盡／draw邊界、default／easy／舊forcing隔離 | 當時沙盒；後續共享完整Package另驗 |
| 實際後續planner，同13與`sandbox-release-perf-14.json` | G7→敵方Pass→下一planner選G5、F6，Core實際提G6；後續完整敵方回合保住主將 | 只證明這條真實planner路線，其他34為存在性見證 |
| `sandbox-release-perf-14.json` | 正例完整API796顯式apply、192列舉；baseline144；後續planner95 | 6000只含顯式apply，legalActions內部Core驗證另計；本機非真機／受控閒置測試 |
| `swift-full-material-final-1017.log` | 共享完整Package212tests、0failure，46.658秒；新material traced／untraced行動、score、reasons、apply、列舉與續攻比較一致 | root新結果；不代替原生生命週期或人類驗收 |
| `golden-current-1017.log`＋`golden-current-1017-transcript.json` | 當前共享Swift Golden38組／99步PASS | 此次未重跑canonical C#；137跨語言歷史比較保留舊結果 |
| `material-fixed-pairings-21.json` | 新material與baseline三組現有配對、六場／600回合全部Core100Drawn；完整GameState含歷史／收據／事件獨立重播，零非法／零耗盡；相同行動與終盤，material接受0次 | source-pin20當前Core／BotSHA前後一致；新policy非退化，不是一般改善 |
| `material-native-07/completion-summary.json`＋`RESULTS.md`／155檔manifest | 5唯一方法PASS、0primary failure、11原生截圖、4新receipt；positiveG7=1、candidate-cancel=0、selector=0、oldlate人類D5=1、restart／exit人類D5=2；production pins五次一致 | iPhone13／iOS18模擬器；只有G7是Bot提交，沒有原生立即提子或真機成本／趣味驗收 |

預算不足必須返回原版完整actions；取消維持nil，不發布未完成候選。draw或敵方獲勝／己方主將不存在、無下一己方提兵見證，均不能授權續攻。baseline仍為預設；easy與forcing不受新policy影響，候選可關閉。

## 打包修正與保留失敗

`material-candidate-15.patch`曾把無末尾換行的`material-reviewed-source.json`與下一diff段落黏在一起。共享初輪212測試有2failure，JSON line29078／byte910092後有garbage；`swift-full-material-1017.log`、`swift-full-material-trace-1017.log`及root的`material-patch-fixture-repair.json`保留此失敗。root由通過沙盒的910092bytes原檔恢復，內容未改，SHA256 `06bd1920c1af19c50a141fe879df9757d3382395c0651ca786c2d248f115a214`。

修正版另存`material-candidate-corrected-18.patch`（SHA256 `f2d505aaa3335e9ac8c43ffaf662b3833161c1832caf012c5de063fac3a81ce8`）。以標準無末尾換行diff標記修正，在新暫存baseline套入後，六檔SHA全等於測試沙盒／manifest16，三JSON全部可解析；詳見`patch-packaging-repair-19.json`。最終共享212 tests零失敗使用恢復後fixture，不以初輪失敗當作通過。

沙盒log10保留測試過度假設每分支都提G6及缺少push解碼的失敗，log12保留benchmark Swift6 actor隔離編譯失敗。後續修正以新11／13／14保存；35分支實際提任一敵兵與敵方Pass專項提G6分開，不刪失敗紀錄。

## 舊forcing與既有診斷歷史

| 證據 | 實際結果 | 適用邊界 |
|---|---|---|
| `bot-offline-04.log` | 9tests零失敗，40／55完整來源與反例 | 有限兩手診斷，不證明永久安全 |
| `bot-continuation-05.log` | 4tests零失敗，舊forcing default／easy、注入Pass正向機制、耗盡、取消 | 注入oracle不是新的真baseline失誤 |
| `swift-full-03.log` | 當時全Package206tests零失敗 | 歷史source／policy；不是当前共享212 |
| `golden-parity-02.log` | 當時fresh C#／Swift38組、99步、137快照一致 | 此次未新增C#run |
| `reachable-*-control*.json` | 四個官方來源baseline本來就行動，舊候選相同 | 負向控制，不能通過新增改善條件 |
| `passive-frontier-five.json` | 55被動有限探針5541顯式apply、1526狀態、0獲勝分支 | 未包含所有長期計畫／反制 |
| `reviewed-comparison-release-04.json` | 舊forcing同M3／16GB無原生建置並行：40median+4.2%、55+0.13% | 不能替新material正例成本作PASS |
| `three-pairings-pressure-filter-04.json` | 舊forcing三組六場皆Core100回合和局、選擇與baseline相同 | 舊policy的無改善結果，不冒稱新material對局 |

G-BP2-2的有限正例條件已具備，共享Package／當前Swift Golden與material trace對照通過；當前policy三組六場非退化已具備；新原生五項唯一方法亦通過，G-BP2-2以有限正例與生命週期工程候選判定PASS。正例本機median約5.52倍（+452%）偏離成本目標，G-BP2-3保持Pending，需要受控／實體iPhone量測與Owner接受。G-BP2-4真人至少兩局／趣味Pending。詳見`BOT_P2_1011_DECISION.md`與`BOT_P2_1011_OWNER_PLAYTEST.md`。


## 原生最終證據與失敗邊界

正式原生主包`artifacts/bot-01r/material-native-07/`：`completion-summary.json`、`RESULTS.md`、`evidence-manifest.json`共155檔，source archive93個exact pins，主執行檔及每個dylib各自核對。五個primary run沒有production source／asset漂移。positive整盤對照只新增G7，AP1→白AP2、Mana5／6不變；candidate-cancel觀察thinking→undo→completion0／discard1、G7空；selector-hud07讀真實唯一AP header並保持49格／Mana／回合。兩個既有late／restart／exit用人類D5啟動思考，共3合法人類收據，晚到Bot零提交。

selector03保留但被最終07AP查詢取代；HUD06的AX查詢FAIL保留為測試診斷，不是production改動或消除後的五項primary failure。最新G2工程PASS使用07正確AP查詢與上述五個唯一方法，沒有將早期測試缺陷重標PASS。

原生positive只證明真Bot G7落子／交手，後續G5／F6提G6另由Package真planner重播證明；11張截圖不冒充35個完整反制或即勝。這是模擬器驗證；root1017簽名／安裝不視為實體裝置成本、兩局趣味或Owner接受通過。
