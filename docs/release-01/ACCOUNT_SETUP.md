## 2026-10-11 18:42｜AdMob App／獎勵廣告已建立

已在登入的 AdMob UI 建立 iOS、尚未上架的「皇冠戰略」App，及自願觀看的獎勵廣告；重新開啟設定確認獎勵為 1 場對戰。公開識別已同步至帳戶證據及 Release.accounts-draft.xcconfig，沒有接到 Xcode 預設配置，也沒有修改或重建凍結1024包。AdMob帳戶驗證仍待完成，App需上架後連結商店並接受審查；建立單元不是可正式放送的證據。Apple商務重載後付費協議仍為「新」，頁面要求本人在簽署前更新法律實體。未調查或提交銀行／稅務、未接受契約。接續完成此遊戲policy/support與UMP、商品定價metadata、Sandbox、發行簽名／雙機及產品權利驗收；未上傳、送審或發布。實際證據見 artifacts/release-accounts-1024/ADMOB_APP_UNIT.json。

## 最新 AdMob 核對（2026-10-11 18:33）

首頁明確顯示付款資料設定完成；重新載入後紅色未完成警示消失。帳戶仍在審核，尚未核准。電話是選填，不能把空白電話當缺漏原因；姓名與地址已有值，銀行／稅務未調查。沒有代填、儲存、接受條款或提交任何財務資料。實際證據見 artifacts/release-accounts-1024/ADMOB_PAYMENT_DIAGNOSIS.json 與 admob-payment-complete-reloaded.jpg。以下更早的「未建立 AdMob 帳戶」為歷史，不能用來描述最新狀態。

# 皇冠戰略｜正式帳戶與1.0封存設定

2026-10-11。1024仍是本機測試候選，不是已送審版本。Owner登入後已完成Apple App／永久解鎖商品草稿，接續紀錄見[帳戶實際狀態](../../artifacts/release-accounts-1024/REPORT.md)。未接受契約或建立AdMob帳戶。首版方式為免費前三場完整對局；之後一次購買永久去廣告，或自行觀看獎勵廣告取得下一場資格。教學與挑戰不計額度，已開始棋局可以續玩。

## 最新帳戶狀態

已登記explicit bundle `com.tacticalgo.prototype.herobody`；ASC App ID `6821588889`、SKU `CROWNTACTICS-IOS-01`、名稱皇冠戰略／繁體中文。版本1.0草稿採手動發布、不要求遊戲登入，尚未上傳build。

已建立non-consumable `com.tacticalgo.crowntactics.unlock`，Apple IAP ID `6821589396`；繁體中文顯示名稱與說明已儲存。定價、供應地區及review screenshot未完成，NT$60仍是候選。商品UI「準備提交」不代表具備完整metadata或可購買。

Apple免費協議有效，付費協議仍顯示「新」，需本人先處理法律實體及所需稅務／銀行資料；本輪未檢查銀行／稅務內容。AdMob已到註冊條款頁，未勾選協議、未建立帳戶或此遊戲App／rewarded unit／privacy message。帳戶核對JSON記錄真實公開識別，未完成Gate維持false；不含銀行、證件或憑證。

## 已有真實資料

支援Email：`reiko0099@gmail.com`。Copyright：`2026 WU JUI-YI`。依Owner指示從字樹花園公開資料沿用，來源見 `RELEASE_GAPS_1024.md`。既有工程Team是`P358EB3X9H`，僅為工程設定，不代表本遊戲帳戶契約、稅務或銀行已完成。

目前Simulator／未簽名Release的工程預設bundle為`com.tacticalgo.prototype`，行銷版本`0.10.11`，build`1024`；這個測試預設不能當成已定案的正式App身份。Owner既有iPhone／iPad的1022→1023更新實際沿用`com.tacticalgo.prototype.herobody`，依據見`artifacts/ui-board-focus-1023/install/REPORT.md`與`RESULTS.json`，兩台裝置均以同bundle更新，沒有卸載或重設。

正式候選保留`com.tacticalgo.prototype.herobody`，避免另裝一個App及失去原安裝的存局／偏好。ASC記錄及其StoreKit商品已按此身份建立；AdMob App及App Store provisioning profile仍待設定及核對，既有開發簽名不證明可以發行。若最終必須更名，須另外設計並驗證資料轉移，不能直接視為原版更新。正式1.0候選準備完成後才以`MARKETING_VERSION=1.0`封存，不為了通過檢查提前把開發版標為1.0。

## 帳戶持有人需完成的設定

1. 此遊戲的iOS App記錄已建立，真實bundle、SKU及數字App ID見上表及JSON。SKU是ASC內部識別，不是StoreKit商品ID，也不是玩家看見的名稱。[Apple建立App記錄](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
2. 要提供一次購買，先核對Paid Apps Agreement狀態及稅務／銀行要求，由有權限的帳戶持有人處理。本機簽名Team或其他App曾上架不能替代這次狀態確認。[Apple契約](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/)
3. `Non-Consumable`永久去廣告商品已建立，沿用`com.tacticalgo.crowntactics.unlock`；中文名稱與說明已保存。仍需選在售地區、本地化價格，完成必要metadata與review畫面。NT$60是候選價格，App顯示值由StoreKit的`displayPrice`取得；ASC草稿存在不代表實際Sandbox已測。
4. 在AdMob建立本遊戲iOS App與Rewarded ad unit，記錄真實App ID和ad-unit ID。正式App不可用Google sample publisher `3940256099942544`；開發測試仍使用測試廣告，不能為驗證而點擊自己的正式廣告。[Google測試廣告](https://developers.google.com/admob/ios/test-ads)
5. 配置UMP適用的隱私message及privacy options，按實際供應地區、年齡設定、SDK版本與資料行為完成政策／ASC隱私回答。非個人化請求不等於沒有收集資料，拒絕ATT不可變成強制購買。本機沒有宣稱consent配置已存在。[Google UMP](https://developers.google.com/admob/ios/privacy)
6. 公開本遊戲專屬HTTPS support/privacy頁，完成現有本機草稿的待填項目。不能把字樹花園頁直接填入；不能公開仍寫「草稿／尚未定稿」的政策。頁面使用目前公開Email及Copyright，商業描述需對應最後程式。

## 正式build設定對應

| Xcode設定 | 編譯後Info.plist key | 正式來源 |
|---|---|---|
| `PRODUCT_BUNDLE_IDENTIFIER` | `CFBundleIdentifier` | 優先沿用Owner真機既有`com.tacticalgo.prototype.herobody`；須與ASC／商品所屬App／AdMob／profile核對 |
| `CROWN_UNLOCK_PRODUCT_ID` | `CrownTacticsUnlockProductID` | ASC真實non-consumable商品ID |
| `CROWN_ADMOB_APP_ID` | `GADApplicationIdentifier` | AdMob此遊戲App ID，格式`ca-app-pub-…~…` |
| `CROWN_REWARDED_AD_UNIT_ID` | `CrownTacticsRewardedAdUnitID` | 此App的Rewarded unit，格式`ca-app-pub-…/…` |
| `CROWN_PRIVACY_URL` | `CrownTacticsPrivacyURL` | 此遊戲已公開且可達政策 |
| `CROWN_SUPPORT_URL` | `CrownTacticsSupportURL` | 此遊戲已公開且可達支援 |
| `MARKETING_VERSION=1.0` | `CFBundleShortVersionString` | 最後準備送審的1.0候選 |

目前Release五個商業／URL欄位都是空白，刻意不能啟動正式收費或Google sample廣告。Debug的StoreKit測試和測試廣告不代表上述帳戶資料已建立。公開ID與URL可存正式設定；不要把Apple登入、Google登入、API私鑰、銀行資料或稅務文件放入repo／聊天。

## ASC／帳戶核對紀錄

ASC SKU不是標準bundle欄位，preflight另讀`--account-evidence`指定的JSON；預設`docs/release-01/account-release-evidence.json`。該檔已依本次實際UI核對建立部分資料，未通過Gate仍保留空值及false並阻擋檢查。以下為空白格式示意，不是現行帳戶的完成宣告：

```json
{
  "appStoreConnect": {
    "appID": "",
    "sku": "",
    "bundleIdentifier": "",
    "productID": "",
    "productType": "nonConsumable",
    "productMetadataComplete": false
  },
  "adMob": {
    "appID": "",
    "rewardedAdUnitID": "",
    "privacyMessageConfigured": false
  },
  "ownerAccountChecks": {
    "paidAppsAgreementActive": false,
    "bankAndTaxReady": false,
    "privacyDeclarationReviewed": false,
    "verifiedAt": ""
  }
}
```

`verifiedAt`用實際核對ISO-8601時間。只寫核對狀態與公開識別，不保存契約全文、銀行帳號或私人證件。本次JSON來自已登入UI的直接觀察，未驗證／未完成項目不可填true；後續須有Owner或實際頁面證據才能更新。腳本只是讀取本機交接紀錄，不能藉此宣稱已透過ASC／AdMob API查核。

## 只讀preflight

```sh
python3 scripts/check-release-readiness.py \
  --app ios/Build/Products/Release-iphoneos/TacticalGo.app \
  --report artifacts/monetization-02/release-audit/RELEASE_PREFLIGHT_1024.json
```

腳本只讀來源plist、傳入的App及公開核對紀錄，訪問已設定的HTTPS政策頁，使用codesign／security檢查封存簽名，並將JSON報告寫入repo的artifacts。它不建置、修改App、不讀env或帳戶憑證，也不登入／發布。空ID、Google sample ID、空或錯誤public URL、開發／未簽名、StoreKit配置／Voice／Models混入包、非1.0版本，都以非零exit擋下。有效ID的格式不證明帳戶實際存在。

目前未簽名Release build應預期FAIL。等取得正式配置及distribution archive，再以archive中的`Products/Applications/TacticalGo.app`執行同一檢查。不要刪掉FAIL項或提供偽造帳戶紀錄讓它變綠。

## 只封存、不上傳的重建入口

`Release.xcconfig.example`已備好1.0候選骨架，bundle優先沿用既有真機`com.tacticalgo.prototype.herobody`；公開ID、URL、正式Team與profile故意留空。先核對同一App身份，再複製成經檢查的`Release.xcconfig`、填真實值與帳戶核對JSON後使用：

```sh
bash scripts/archive-release.sh \
  --config docs/release-01/Release.xcconfig \
  --archive-path artifacts/monetization-02/CrownTactics-1.0.xcarchive \
  --report artifacts/monetization-02/release-audit/ARCHIVE_PREFLIGHT.json
```

本入口先阻擋空欄／sample ID／非1.0／缺少ASC SKU等資料，再呼叫本機Xcode archive。僅接受已檢查的簡單設定，不讀外部include或任意build-setting覆寫；必須已有本機可用的Apple Distribution證書與此App的App Store profile。腳本不接受契約、不申請新profile、不使用`-allowProvisioningUpdates`，不export或upload。已有archive不覆寫；封存成功後仍需通過包內簽名與配置檢查，任何FAIL保留為未ready。

**xcconfig的HTTPS不能直接寫成`https://…`**，因為`//`可能開始註解。請用`https:/$()/實際主機/路徑`，空巨集展開後回復第二個斜線；最後以App的Info.plist和public GET證據確認真正URL。本機pre-archive parser也會將被截成`https:`的值擋下。不要把此書寫形式直接填成商店URL，商店要填完整HTTPS網址。

## preflight之後仍需真實驗證

同來源StoreKit Sandbox購買／恢復／取消／pending／撤銷、Google測試廣告完成／未完成／無填充／背景返回、雙機完整局與續局，均需有實際記錄。預覽／取消／復原不得扣商業額度，教學／挑戰保持免費。凍結最終source、SDK lock與archive SHA，再完成商店metadata、分級／加密／隱私問卷。local preflight PASS不代表這些外部與真人驗證已完成，也不授權接受契約、上傳、送審或公開發布。
