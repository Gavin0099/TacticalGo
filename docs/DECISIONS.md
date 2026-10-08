# Decision log

Owner decisions, newest first. A decision here overrides any conflicting Draft text elsewhere; `docs/RULES_DRAFT.md` is updated to match.

## 2026-10-08 (newest) — beginner-friendly "英雄包圍戰" direction, revised order

**產品方向**：即使完全不懂圍棋也能快速上手；對外定位「英雄包圍戰」；圍棋的氣與棋串留在底層。設計目標（尚未達成、不是結果）：30 秒理解操作、3 分鐘理解職業差異、之後仍有值得思考的策略。長期樂趣來自「對手會反應」，不是解固定棋局；三職業都能玩之後，有戰術能力的對手是下一個重要方向（本輪不做強 AI）。

| 決定 | 內容 |
|---|---|
| 第 2 關 | 改為防守題「法師逆轉危機」；不強制唯一解，必須確認封印有普通落子無法取代的戰術價值 |
| 第 3 關 | 玩家自選戰士／法師／盜賊，對抗現有弱機器人（新手練習對手）；機器人不懂技能，**不得用其結果宣稱職業平衡**；不要求每職業只有一條正解 |
| 英雄召喚 | 新手教學先預置英雄，先體驗技能，之後再教召喚 |
| 名稱 | 採用「生存空格」，UI 必須顯示相連棋串共用同一組，不可誤當每顆棋子的 HP |
| 新手模式 | 7×7、第 1 關 1 AP、之後逐步引入 2 AP；不顯示無用途的 Mana；為獨立設定，不改完整規則與黃金測資 |
| 關卡驗證 | 不先做通用求解器；只對具體關卡做有限範圍搜尋（驗證局面合法、預期解成立、無明顯無技能捷徑） |

**實作順序**（每步先交付、保留可回退提交、未經確認不擴大範圍）：
1. 修復 UI-1.1（恢復編譯、操作提示、主將危險資訊）→ **已完成，待 Owner 試玩確認**
2. 7×7 第 1 關（包圍與相連棋子）
3. 職業技能介面與第 2 關防守挑戰
4. 第 3 關職業自由挑戰（弱機器人）
5. 真人遊戲性驗證（含不懂圍棋的玩家）

## 2026-10-08 (later) — UI first, bots paused

- 暫停技能型機器人與大量背景平衡模擬；優先做可視化、可操作的棋盤，讓 Owner 親自玩三職業。
- 順序：UI-0 草圖 → UI-1 可點擊 9×9（落子、氣數、提子）→ UI-2 三職業技能介面 → PLAY-1 本機雙人＋載入固定局面 → PLAY-2 真人驗證 → BOT-1（視需要）→ 正式美術。
- Windows 原型用 WinForms 直接呼叫現有 C# 引擎，不重寫判定；不取代 iPhone 觸控驗收；正式版仍是 Swift/SwiftUI，用 `tests/golden` 驗證一致。
- 不擴張治理流程，不投入正式美術、角色動畫、完整紅龍。每個階段先交付可檢查成果。

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
