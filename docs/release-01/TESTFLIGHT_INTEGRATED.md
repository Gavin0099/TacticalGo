# 整合版 TestFlight（Internal）封存步驟與限制

狀態（2026-10-15）：**設定已備妥並在模擬器驗證；尚未封存、尚未上傳。** 上傳與 App Store Connect 變更需要 Owner 明確授權。
背景與選項分析：`docs/integration/TESTFLIGHT_READINESS.md`（選項 A）。

## 這份設定做了什麼
- `ios/TacticalGo.xcodeproj` 的 **Beta** 設定（只此一個物件）改為使用 `TacticalGo/Info.plist`，並宣告 `CROWN_*` 預設為空。Debug、Release、UITests 設定未改。
- `docs/release-01/Beta.integrated-1119.xcconfig` 提供版本 1.1／build 1119、解鎖商品識別碼、隱私與支援網址、AdMob **應用程式** ID；**不**提供廣告單元 ID。
- 簽署（手動、Apple Distribution、描述檔 `Crown Strategy App Store 20261011`、team `P358EB3X9H`）與擴充旗標 `TACTICALGO_V11` 仍來自專案的 Beta 設定，不在 xcconfig 內（命令列 xcconfig 會一併作用到 Swift package target，不能帶描述檔）。

## 為什麼一定要有 AdMob 應用程式 ID（實測）
Google Mobile Ads SDK 連結進每一個 build。`Info.plist` 的 `GADApplicationIdentifier` 為空時，App 在啟動後立即以
`GADInvalidInitializationException: The Google Mobile Ads SDK was initialized without an application ID` 終止
（模擬器實測）。因此**不能**用「完全不設廣告」來避開廣告風險。折衷：只給應用程式 ID、廣告單元 ID 留空 →
`RewardedAdService` 回報「廣告尚未設定」，**不啟動 SDK、不發出廣告請求**，Owner 的內部 build 不會顯示或點擊正式廣告單元。

## 在封存前先跑（唯讀）
```bash
python3 -B scripts/check-testflight-xcconfig.py docs/release-01/Beta.integrated-1119.xcconfig
python3 -B -m unittest scripts/test_check_testflight_xcconfig.py
```
檢查項目：無行尾反斜線（註解裡的反斜線是續行，曾經吞掉 AdMob 設定）、只含允許的鍵、build 號 > 1118、AdMob 應用程式 ID 為正式格式且不是 Google 範例、網址為 https。
封存後可加 `--app <封存出的 .app>` 比對 Info.plist。

## 封存（Owner 授權後；本機簽署、不含上傳）
從 **乾淨的 `main`** checkout 執行（不要用有未提交變更的 worktree）：
```bash
xcodebuild archive -project ios/TacticalGo.xcodeproj -scheme TacticalGoBeta -configuration Beta \
  -destination 'generic/platform=iOS' -xcconfig docs/release-01/Beta.integrated-1119.xcconfig \
  -archivePath artifacts/testflight-1119/CrownTactics-1.1-1119.xcarchive
```
然後以 Xcode Organizer 上傳（與 1112 相同方式），並在 App Store Connect 把該 build 加入 **Owner 1.1** 群組。
也可用 App Store Connect API 金鑰從命令列上傳（不依賴 Xcode 帳號登入；金鑰由 Owner 保管，只傳路徑，不讀出或複製內容）：
```bash
xcodebuild -exportArchive -archivePath <xcarchive> -exportPath <輸出資料夾> \
  -exportOptionsPlist <destination=upload、testFlightInternalTestingOnly=true 的 plist> \
  -authenticationKeyPath <AuthKey_….p8 路徑> -authenticationKeyID <金鑰 ID> -authenticationKeyIssuerID <Issuer ID>
```
build 號要高於 App Store Connect 上所有已上傳者；上傳前先重新確認（最後已知為 1118，2026-10-18 以 API 金鑰上傳並在 Owner 1.1 群組）。

## 模擬器驗證（已做）
| 檢查 | 結果 |
|---|---|
| `Beta` 設定＋xcconfig 建置（模擬器、未簽名） | 成功 |
| 產出 Info.plist | 版本 1.1、build 1119、`com.tacticalgo.prototype.herobody`、解鎖商品與網址已填、`GADApplicationIdentifier` 為正式應用程式 ID、廣告單元 ID 為空 |
| 啟動 | 進入大廳：「免費完整對局剩餘 3/3」、開始對戰、新手入門、戰術挑戰、**擴充玩法** |
| 不帶 xcconfig 的 `Beta` 建置 | **啟動即崩潰**（空的 AdMob 應用程式 ID）——這就是不能直接封存現有 `Beta` 的原因 |
| 工具腳本 | 8 項單元測試；對 xcconfig 與產出 App 皆 OK；刻意放入反斜線註解會被抓到 |

## 尚未驗證
簽署 archive、上傳、Apple 處理、TestFlight 安裝；實機與 iPad；StoreKit 沙盒實購／恢復／退款（模擬器 StoreKit 測試不等同）；解鎖畫面與 UMP 同意流程在 Beta 設定下的實際表現；真實廣告（刻意不啟用）；音訊／動畫手感與英文語音聽感（D5 未結，語音隨 Beta 內含，僅限內部）。


## 歷史
build 1113（`Beta.integrated-1113.xcconfig`，來自 `main` `f9e3fe7`）已於 2026-10-15 上傳並加入「Owner 1.1」群組；該設定檔已移除，避免誤用。1114 包含「1.1 外殼成為根畫面」等變更。
build 1114（來自 `main` `1ada030`）已於 2026-10-17 上傳、手動回答出口合規並加入「Owner 1.1」群組；設定檔改名為 1115。1115 包含出口合規鍵（#12）、外殼文字修正（#13）與 1114 試玩回饋修正（#14）。
build 1115（來自 `main` `19f49be`）已於 2026-10-17 上傳，Apple 處理時**沒有再問出口合規**，已加入「Owner 1.1」群組；設定檔改名為 1116。1116 加入牧師第二技能「聖所」Beta 候選與專用圖示（#16）。
build 1116（來自 `main` `da1597c`）已於 2026-10-17 由 Owner 以 Xcode Organizer 上傳（命令列以 Xcode 帳號上傳一直回 `Failed to Use Accounts`）；設定檔改名為 1117。1117 加入牧師犧牲預覽與新上身照（#19）、復原相關測試與修正（#20–#22、技能後復原測試），**不含** PR #18（電腦保留能量規則、六個課題）。

build 1117（來自 `main` `1d8c274`）已於 2026-10-18 用 App Store Connect API 金鑰上傳，處理完成、沒有再問出口合規，已加入「Owner 1.1」群組；設定檔改名為 1118。1118 加入牧師聖所的電腦救援測試與六個課題局面、兩步操作錯誤流程（#26）、牧師預覽先講犧牲的取捨（#27）、選單點擊測試修正（#28）、量測工具與停滯診斷（#25），**不含** PR #18（電腦保留能量規則）。

build 1118（來自 `main` `0cec7f3`）已於 2026-10-18 用 API 金鑰上傳、加入「Owner 1.1」群組；設定檔改名為 1119。1119 加入素材與回饋第一輪（#30：站立主將、刻印棋盤、玩家面板、特效、橫幅）與 v30 肖像、操作圖示、原創合成音效（#31，僅 Beta；音效在 Release 打包時剔除），**不含** PR #18。

## 出口合規（ITSAppUsesNonExemptEncryption）
`Info.plist` 現在直接宣告 `ITSAppUsesNonExemptEncryption = false`，與 1.0（1025）在 App Store Connect 的答案一致（只用系統網路／StoreKit 與 CryptoKit SHA256 完整性檢查，沒有自製加密）。
根因：Beta 設定改用手寫 `Info.plist`（`GENERATE_INFOPLIST_FILE = NO`）後，設定裡的 `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` 會被忽略，所以 1114 的封存沒有這個鍵，App Store Connect 會再問一次。
`check-testflight-xcconfig.py --app` 現在會檢查這個鍵；**已封存的 1114 沒有這個鍵**（需手動回答一次出口合規）。下一個 build（1115 以後）才會自動帶上。
