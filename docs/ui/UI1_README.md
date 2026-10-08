# UI-1：Windows 可操作棋盤（原型）

> 目的：讓 Owner 親手操作 9×9 規則。**UI-1 通過不等於玩法驗證通過**：三職業要到 UI-2 才進入畫面，真正的遊戲性判斷在 PLAY-2。
> 這是 Windows 滑鼠原型，不能取代 iPhone 觸控驗收。

## 執行

```bash
dotnet build TacticalGo.Windows.sln                      # 建置
dotnet run --project src/TacticalGo.Play                  # 直接跑
dotnet publish src/TacticalGo.Play -c Release -r win-x64 --self-contained false -o dist/TacticalGo.Play
```

可執行檔：`dist/TacticalGo.Play/TacticalGo.Play.exe`（framework-dependent，需 .NET 9 Desktop Runtime；`dist/` 不進 git）。

## 操作

| 動作 | 做法 |
|---|---|
| 落子 | 點空交叉點 = **選取**（顯示幽靈棋、預覽會提的子、或非法原因）→ 再點同一點，或按「確認落子」/ Enter |
| 看棋串與氣 | 點任何棋子：藍圈 = 該棋串，藍點 = 它的氣，訊息列顯示子數與氣數 |
| 取消選取 | 「取消選取」/ Esc |
| 結束回合 / 復原 | 按鈕；Ctrl+Z 復原（可跨回合，還原盤面、AP、Mana、封印、打劫歷史與紀錄） |
| 氣數顯示 | 下拉：關 / 僅危險棋串與主將（預設，2 氣橘、1 氣紅） / 全部 |
| 新局 | 選規則：先手首回合 1 AP（預設）、2 AP 基線、1 AP 對照 |

不依賴 Hover：非法原因在「選取」後直接顯示於訊息列（紅底），之後移植到 iPhone 同樣成立。

## 架構（為什麼不會有第二套規則）

- `PlayController`：唯一持有正式狀態。合法性 = `ActionValidator.Validate`；預覽與結果 = `GameEngine.Apply`（回傳新狀態，不改舊狀態）；復原 = 還原先前的整個 `GameState`。
- `BoardView`：只畫圖、把點擊轉成棋盤座標。提子預覽圈取自預覽結果的事件，不自己計算。
- `EventText`：把引擎事件翻成中文紀錄。
- Windows 專案與 Domain/Tests 隔離：`TacticalGo.Windows.sln`（Play + Play.Tests + Domain）；`TacticalGo.sln`（Domain、Domain.Tests、Sim）不含任何 Windows-only 專案，可在 Mac/Linux 建置。

## 驗證狀態（誠實分欄）

**已由我驗證**
- `dotnet test TacticalGo.sln`：75 項通過（Domain 規則＋23 組黃金測資，未改動）。
- `dotnet test TacticalGo.Windows.sln`：8 項通過，專門守：預覽不改正式狀態、非法選取顯示原因且不能確認、第二次點擊確認、復原還原整個狀態與紀錄、提子預覽先於提子且復原可還原、點擊像素 → 交叉點對應。
- 發佈的 exe 實際啟動，4 秒後仍在執行並可正常關閉。
- 以 `--snapshot` 離屏渲染兩張畫面並目視檢查（氣數徽章、提子預覽圈、選取標記、紀錄）。
- 工具鏈：此機器只有 .NET SDK 9.0.302，**沒有 .NET 10**；安裝 SDK 需要下載，未擅自處理。升級只需改 `src/TacticalGo.Play` 與測試專案的 `TargetFramework`。

**我無法驗證，請 Owner 實際操作確認**
- [ ] 滑鼠點擊手感：點交叉點附近就能選到，不需要精準點像素。
- [ ] 落子 → 預覽 → 確認的流程順不順，會不會誤觸。
- [ ] 提子、打吃（1 氣紅色）、勝負橫幅在實戰中看得懂。
- [ ] 復原跨回合後，AP / Mana / 誰的回合都正確。
- [ ] 高 DPI 或視窗縮放下排版是否正常。
- [ ] 資訊量：預設的氣數顯示是否太多或不夠。

## 不在 UI-1 範圍

英雄召喚與三職業技能（UI-2）、固定戰術局面與本機雙人流程優化（PLAY-1）、機器人、正式美術與動畫。
