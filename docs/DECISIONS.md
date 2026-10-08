# Decision log

Owner decisions, newest first. A decision here overrides any conflicting Draft text elsewhere; `docs/RULES_DRAFT.md` is updated to match.

## 2026-10-08 — rules, AP, tech, governance (Owner message "TacticalGo 下一步決策")

| Topic | Decision |
|---|---|
| 首回合也 +1 Mana | 暫時接受，雙方對稱；觀察技能是否太早爆發 |
| 英雄被提後重新召喚 | 第一版禁止（`AllowResummon=false`），讓英雄死亡有代價 |
| 英雄召喚位置 | 改為與**任一己方棋子**上下左右相鄰的合法空點（不再限主將兩格內） |
| 其他 `【補】` 項目 | 不整批核准，保持待審（見 RULES_DRAFT §8） |
| AP | 先手第一回合 1 AP 為暫定預設，後續 2 AP；2 AP 原始版本留作比較基線。啟發式模擬不是最終平衡驗收 |
| 技術 | 維持 Swift/SwiftUI；C# 引擎保留為參考與交叉驗證來源；S2 前建立 Swift Package，用共同測資（`tests/golden`）驗證兩版一致 |
| CI | 先用手動觸發的 macOS CI（公開 repo 的標準 GitHub-hosted runner 免費，Owner 已核對官方文件），不急著買 Mac、不建大量 UI 測試 |
| Governance | 確認公開 repo 無敏感內容後建立第一個 commit → `adopt_governance.py --refresh` → 再 commit → drift check；維持 audit-only，不宣稱 governed runtime |
| 範圍 | 不擴充卷軸、神器、紅龍完整系統或大量美術；自動化 PASS 不取代真人遊戲性驗收 |

Owner 補充的技術更正：Windows 可以用 Swift 官方 Windows toolchain 開發並執行純 Swift Package；SwiftUI 與完整 iOS App 的建置、模擬器除錯仍需 macOS/Xcode。
