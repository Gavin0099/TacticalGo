# POSTMERGE-01｜對乾淨 `main` 的合併後驗證

日期：2026-10-15。對象：`origin/main` = `a3c1867`（PR #8 的 merge commit）。
方法：從 `origin/main` 另開**乾淨的 detached worktree**（無未提交變更），不使用整合分支的建置快取（獨立 DerivedData）。
範圍：模擬器、未簽名。**不涵蓋**實機、iPad、簽署 archive、StoreKit 沙盒實購、真實廣告、聽感與美術。

| 檢查 | 結果 |
|---|---|
| `swift test`（`swift/TacticalGoCore`，macOS） | 433 項、0 失敗 |
| Linux 套件 CI（`Swift Core (Linux)`，合併前於 PR 分支） | 433 項、0 失敗 |
| 建置：`TacticalGo`／Debug／模擬器 | 成功 |
| 建置：`TacticalGoBeta`／**Beta 設定**／模擬器 | 成功（注意：腳本首輪誤用 `-configuration Debug`，已另以 `-configuration Beta` 重建並確認） |
| 建置：`TacticalGo`／Release／模擬器 | 成功 |
| `IntegrationUITests` | 9／9（含擴充入口、同一帳本把關、R1 恢復、M6 副本、P1 開局後終止、P2 終局對帳） |
| `MonetizationUITests` | 10／10（購買、恢復、退款、Ask-to-Buy、三場閘門、取消不改結果、擁有者恢復不被誤刪） |
| `RewardedAdNetworkUITests` | 2／2 |

## 沒有重跑的
- 大型對戰 UI 套件（`PlayableGameTests`、`AdvancedChallengeUITests`、`BoardInteractionTests`）：合併前最後一次完整跑與乾淨 1.0 快照比對，**33 個失敗名稱相同（既有）**；合併後沒有再跑，因為合併只是把已測試過的 `5a7d8b8`（程式碼與 `ecfa95b` 相同）併入 `main`，沒有其他來源變更。
- `ExpansionLabTests`、`MonsterLabTests`、`PresentationLabTests`：同上，合併前通過。

## 結論
`main` 在上述範圍內與合併前驗證一致，沒有因最後的 merge 產生可偵測的變化。**這不是發布依據，也不是整合版真人驗收。**
