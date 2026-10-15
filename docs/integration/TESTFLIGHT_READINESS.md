# 整合版 TestFlight 準備度分析

日期：2026-10-15。依據：`main` = `a3c1867`、本機簽署前置檢查（唯讀）、`docs/release-01`、`docs/save-1.1`。
> **更新（2026-10-15，Owner 選擇選項 A）：** 設定已備妥於 PR #10（`chore/testflight-integrated-config`），見 `docs/release-01/TESTFLIGHT_INTEGRATED.md`。**實測更正下表：現有 `Beta` 設定不是「只能玩 3 場」，而是啟動即崩潰**（見 B1 更正）。仍未封存、未上傳。

**這是分析，不是授權。** 上傳到 App Store Connect／TestFlight 屬 Owner 決定；我沒有做任何上傳、簽署封存或 App Store Connect 變更，也沒有重新查 Apple 端狀態。

## 結論（一句話）
**工程上可以做出整合版的 Internal TestFlight build，但不能直接把現有 `Beta` 設定拿去封存。** 有 1 個必須先決定的設定缺口（計費設定檔缺漏）與 2 個必做的前置（build 號、乾淨來源）。Owner-only 的 Internal 測試：**條件成立後可以**。外部測試或送審：**還不行**。

## 為什麼不能直接封存 `Beta`

| # | 事實（證據） | 影響 |
|---|---|---|
| **B1** | `Beta` 建置設定使用產生的 Info.plist（`GENERATE_INFOPLIST_FILE = YES`），**沒有** `CrownTacticsUnlockProductID`、`GADApplicationIdentifier`、`CrownTacticsRewardedAdUnitID`、隱私／支援網址。已對 `main` 的 Beta 建置產物確認：plist 內沒有任何 `CrownTactics*` 或 `GADApplication*` 鍵 | 整合版的根畫面是 1.0 外殼（含額度把關）。沒有這些鍵，**解鎖購買與獎勵廣告都不可用**；完成 3 場完整對局（擴充對局共用同一額度）後，測試者只剩教學與挑戰可玩，**無法評估第 4 場與之後**。1.1 的舊 TestFlight 沒有這個問題，因為舊 1.1 外殼沒有額度把關 |
| B2 | `project.pbxproj` 的 `Beta`：`MARKETING_VERSION = 1.1`、`CURRENT_PROJECT_VERSION = 1106`；先前 1109～1112 是命令列覆寫 | 必須以命令列（或審過的 xcconfig）傳入**高於 1112** 的 build 號，否則上傳會被拒或與舊 build 混淆 |
| B3 | 同一個 App 紀錄（app `6821588889`、bundle `com.tacticalgo.prototype.herobody`）同時承載 1.0（1025，等待審查）與 1.1 TestFlight（1112 準備測試，尚未加進 Owner 群組）——來源：2026-10-14 的唯讀記錄 | 新 build 走 1.1 版本線沒有衝突，但**上傳前必須重新確認 App Store Connect 現況**（1.0 的審查結果會改變版本規劃）。我沒有重查 |
| B4 | 沒有任何針對「整合後」`main` 的簽署 archive、沒有實機證據 | 見下方「尚未驗證」 |

## 解法選項（Owner 決定；我不替你選）

| 選項 | 內容 | 優點 | 代價／風險 |
|---|---|---|---|
| **A（建議）** | 為整合版 TestFlight 建立審過的 xcconfig：沿用 `Beta` 的簽署與擴充旗標，補上 `INFOPLIST_FILE`、`GENERATE_INFOPLIST_FILE = NO` 與 `CROWN_*`（解鎖商品識別碼、隱私／支援網址）；build 號 > 1112 | 付費牆、沙盒購買、擴充把關都能真實驗證 | 廣告單元：非 DEBUG 建置**只接受正式 AdMob ID**（Google 範例 ID 會被程式拒絕）。**「完全不填廣告鍵」不可行（會崩潰）**；採用的折衷是：只填 AdMob **應用程式** ID、廣告**單元** ID 留空 → 廣告顯示「尚未設定」、SDK 不啟動、不發廣告請求，只測購買與把關；要測真廣告需 Owner 另外填單元 ID 並接受政策風險 |
| B | 照現有 `Beta` 封存，不補鍵 | — | **更正（實測）：啟動即崩潰**。Google Mobile Ads SDK 連結在每個 build 內，`GADApplicationIdentifier` 為空時會丟出 `GADInvalidInitializationException`，App 在啟動後立即終止（模擬器，`main` @ `a3c1867`）。原先寫的「只能玩 3 場」是我沒有實際啟動就下的推論，是錯的 |
| C | 加「測試者無限額度」開關 | 測試最方便 | **新增計費語意與功能**，違反目前「不改商業額度政策」的界線，需獨立決定與風險評估，不建議 |

## 必做前置（不論選哪個選項）
1. **乾淨來源**：從 `main` `a3c1867`（或其後經審查的 commit）的乾淨 checkout 封存，記錄來源指紋（沿用 `SOURCE_PIN` 作法）；不要從有未提交變更的 worktree 封存。
2. **build 號**：> 1112，明確記錄是命令列注入，並在 `UPLOAD.json` 類似檔記錄時間與上傳方式。
3. **本機簽署前置已具備**：機器上有 `Apple Distribution: Wu Jui-Yi (P358EB3X9H)` 身分，以及描述檔 `Crown Strategy App Store 20261011`（對應 `com.tacticalgo.prototype.herobody`，到期 2027-08-14）。（僅查名稱與到期日，未動鑰匙圈。）
4. **語音**：`Beta` 產物含 `Audio/Voice` 與 `PresentationLab` 英文語音；內部測試可以，**聽感審查（D5）未結，不得隨公開版本出貨**。
5. **同一條規則**：Owner 另行明確授權後才上傳；上傳後要把 build 加入「Owner 1.1」群組才裝得上（1112 目前就是沒加）。

## 尚未驗證（TestFlight 之後才有的資訊）
- 實機（iPhone）與 iPad：觸控、動畫、語音、記憶體、啟動時間。
- StoreKit 沙盒實購／恢復／退款、Ask-to-Buy 在實機上的行為（模擬器的 StoreKit 測試不等同）。
- 真實 AdMob 廣告與 UMP／追蹤同意流程。
- 1.0 實機產生的真實存檔（S5）能否被整合版讀取續玩：目前只有單元層級證據。
- 兩套視覺系統並存（D1）、1.1 法師動畫 `r2` 改用共用時序後的觀感。
- 大型對戰 UI 套件有 33 個與 1.0 快照相同的既有失敗，另案。

## 已知風險（測試者可能碰到）
- 單存檔槽邊界：終局補登失敗後，同一次執行內開下一場擴充局會覆蓋該終局存檔。
- 擁有者在 StoreKit 回應前的極短時間內開局，會被記成試玩准入（1.0 既有行為）。
- 廣告看完但額度寫入失敗不保留請求識別碼，需重看。
- M6：副本沿用原局准入（選項 a）已實作但尚未正式決定。

## 建議的 TestFlight 驗收清單（人眼與手感，不是自動測試）
1. 1.0 原版：新遊戲→三場完整對局→第 4 場出現閘門→（沙盒）購買／恢復。
2. 擴充入口：大廳「擴充玩法」→牧師、魔物、第二技能各打一場；擴充對局與原版共用額度。
3. 存局：中途離開→重開→續玩；擴充存局與原版存局互不覆蓋（注意單槽行為）。
4. 動畫與語音：兩種外殼的角色動畫節奏是否一致、語音是否合適。
5. 這整體是不是比 1.0 更完整、更好玩（產品問題，不是工程問題）。

## 我建議的順序
1. Owner 決定選項 A／B／C 與廣告鍵策略。
2. 重新確認 App Store Connect 現況（1.0 審查結果、1112 群組、IAP 狀態）。
3. 由 Owner 授權後，從乾淨 `main` 封存並上傳 Internal build（build 號 > 1112）。
4. 實機跑上方驗收清單，再決定要不要進入外部測試或送審。
