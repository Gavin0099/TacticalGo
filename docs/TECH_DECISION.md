# 技術路線決策：iOS 原生 Swift / SwiftUI

> 日期：2026-10-08 · 狀態：**Owner 已選定方向**（Swift/SwiftUI 原生），移植時機見下。

## 決定

- 最終產品：iPhone 原生 App，**Swift + SwiftUI**。
- 規則引擎以獨立 **Swift Package** 實作（不依賴 UIKit/SwiftUI），UI 只消費引擎事件。
- 現有 `src/TacticalGo.Domain`（C#，44 個測試）是 **規格參考實作與黃金測試來源**，不是產品程式碼。

## 為什麼

- 產品只做 iPhone；原生 Swift 沒有引擎執行環境負擔，9×9 回合制棋盤不需要遊戲引擎。
- 引擎約 600 行，語言風險小；真正的風險在 UI 與玩法，由 PLAN 的 S3 把關。

## 環境事實（2026-10-08 查證）

- 開發機為 Windows 11，目前**沒有安裝 `swift`、沒有 `xcodebuild`**。
- 更正（Owner 查證官方文件）：Windows 可以安裝 Swift 官方 toolchain，開發並執行**純 Swift Package**；SwiftUI 與完整 iOS App 的建置、模擬器除錯、簽署仍需 macOS/Xcode。
- 公開 repo 使用標準 GitHub-hosted runner（含 macOS）免費。決定：先用**手動觸發（`workflow_dispatch`）**的 macOS workflow 驗證 Swift Package，不在每次 push 執行；要做可互動的 SwiftUI 棋盤時，再安排實體 Mac 做模擬器與真機測試。
- 在 Swift Package 存在前，規則與玩法驗證（S0/S1）繼續使用 C# 引擎與模擬器。macOS workflow 要等 Package.swift 存在才建立（沒有目標的 workflow 只會失敗）。

## 移植原則（避免兩份規則悄悄分叉）

1. 規則的唯一書面來源是 `docs/RULES_DRAFT.md`；C# 與 Swift 都是它的實作。
2. 以語言中立的**黃金重播檔**驗證移植：`tests/golden/*.json`（格式見該目錄 README.md），每步檢查成功與否、拒絕原因、格子、AP、Mana、封印、事件順序與勝負。預期值是**手寫**的，不是從引擎匯出，所以單一引擎的 bug 不會自動變成「正確答案」。C# 版 23 組全數通過；Swift 版必須逐組通過。
   注意：C# 的測試全過**不代表** Swift 移植後也正確；Swift Package 也必須通過同一批檔案才算一致。
3. 移植觸發條件：S1 通過（規則凍結為 Accepted）後、S2 開工前。S3 之前不做正式 UI 美術。
4. 治理規則包：Swift 專案使用框架的 `swift` 規則包（concurrency、native_interop），`context_aware`，出現 `.swift` 檔後啟用。

## 尚未決定

- 實體 Mac 何時購入（暫時用手動 macOS CI）。
- 觸控試玩要怎麼發給 S3 的 6–8 位試玩者（TestFlight 需要 Apple Developer 帳號）。
