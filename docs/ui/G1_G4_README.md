# G1–G4：7×7 Windows 本機雙人試玩

G1–G4 的工程功能已完成，G0 操作驗收與 G5 遊戲性驗收仍待 Owner。這是開發試玩版。

## 啟動

在 repo 根目錄執行 `./tools/publish-play.ps1`，再雙擊 `dist/TacticalGo.Play/Start-7x7.cmd`。
這個預設發佈需要 .NET 9 Windows Desktop Runtime；本次測試機已有 9.0.7。其他電腦若要包含 Runtime，可用 `./tools/publish-play.ps1 -SelfContained` 另行建置；本輪未驗證該發佈方式。

`Start-Tutorial-2.cmd` 進盜賊教學，供補做 G0。直接開 exe 則維持新手教學入口。

## 家用電腦從 GitHub 建置

在 Windows 安裝 .NET 9 SDK 後，以 PowerShell 在打算放專案的目錄執行。使用新的資料夾，避免切換既有工作的分支：

```powershell
git clone --branch codex/gameplay-g1-g4 --single-branch https://github.com/Gavin0099/TacticalGo.git TacticalGo-playtest
cd TacticalGo-playtest
dotnet publish .\src\TacticalGo.Play\TacticalGo.Play.csproj -c Release -r win-x64 --self-contained false -o .\dist\TacticalGo.Play
.\dist\TacticalGo.Play\TacticalGo.Play.exe --free
```

SDK 供建置使用；程式仍需 .NET 9 Windows Desktop Runtime（Windows SDK 安裝包含該 Runtime）。`--free` 直接進入選角與 7×7 雙人模式；改成 `--level 2` 可測盜賊教學。

Git 分支保存原始碼、嵌入的角色 PNG 與工程證據，ignored `dist/` 的 exe／ZIP 不會隨 push 上傳。僅建置與試玩不需要初始化治理 submodule；若要執行治理檢查，再使用 `git submodule update --init --recursive`。

## 試玩順序

1. 黑、白公開輪流點人物卡選職業；可以同職業。取消選角不會替換原對局。
2. 主將起點是黑 `(3,5)`、白 `(3,1)`，座標從 0 開始。黑先手第一回合只有一次行動，之後雙方每回合兩次。
3. 「放士兵」：點空交叉點看預覽，再按「✔ 放這裡」；Enter 確認、Escape 取消。
4. 「召喚英雄」：選己方任一棋子上下左右的空點，再確認。戰士／盜賊 2 Mana，法師 3 Mana；英雄被提後不能重召。
5. 「技能」消耗 1 行動＋2 Mana，每回合最多一次。築壘選戰士旁兩個不同空點；換位選盜賊旁敵方普通士兵；魔法之手選距法師曼哈頓 ≤2 的雙方普通士兵，再按亮起的方向，最後確認。主將／英雄不能被推。
6. AP 用完自動換手，也可提前結束回合。沒有教學腳本或 AI 替白方下棋；兩人共用滑鼠輪流操作。
7. 提掉敵方主將即獲勝。「復原」或 Ctrl+Z 還原完整上一行動，包含資源、回合、Ko 歷史與勝負；新局會清除復原紀錄。

「新局／選模式…」可回教學，或切自由對局的 AP 比較設定與法師封印比較選項；魔法之手維持預設。

## 已驗證與尚未驗收

- 整合後 Domain 129 項、Windows 91 項通過；38 組 Golden 在 Domain 測試內實際重播，另外 validator 正反 harness 5 項通過。
- 本輪新增 UI／整合關鍵測試的 9 個指定變異都被抓到，原程式還原後全套重驗；這不等於涵蓋所有可能缺陷。
- 三種黑方職業各有從上述正式 7×7 開局開始、雙方召喚／技能／換手直到提吃主將的手寫合法重播。白方三職的技能與資源另有回歸。它們是合作式功能測試，不是對抗強度或策略獨特性證據。
- 900×700、1140×760 client size 的真實 WinForms 離屏畫面檢查了三職預覽、操作按鈕與棋盤界限；實際發佈 exe 另執行三職預覽、勝負與復原共 5 次冒煙。未替代 Owner、其他 DPI／螢幕的實機驗收。
- A 版棋盤 Token、B 版選角／資訊圖來自已合併 PR #3 的六張原始 PNG，嵌入程式避免工作目錄造成遺失。原圖未修改；黑／白外框與角標保留陣營識別。推動使用 Domain 事件的 180ms WinForms 呈現，不阻擋下一個行動，也不搬用 HTML 動畫。
- 素材仍是開發候選，發布權利、正式素材核准與實機驗收未完成。沒有新增規則、搜尋、AI 或 UI 以外新 Slice。

原始命令、計數、檔案雜湊及限制見 [validation.json](../evidence/gameplay-g1-g4/validation.json)。

請先實際打一局，回報「哪一步做不下去／看不懂」及雙方職業；G0、G5 由你判定。
