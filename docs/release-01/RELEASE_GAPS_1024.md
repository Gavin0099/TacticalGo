# 皇冠戰略首版發行缺口｜1024 收尾

日期：2026-10-11。基線為 `artifacts/ui-board-focus-1023/SOURCE.json` 的 237 個來源檔；不是假設遠端 main，也不是本輪已完成封存。Owner 已確認 1023 的操作修正可接受，已選免費前三場完整對局；目前帳戶／AdMob 商品配置尚未建立。此文件是可執行的首版收尾清單，不能當送審完成證據。

## 可以沿用的真實發行資料

依 Owner 指示只讀參考 `/Users/pc49-58/Desktop/english-vocab-trainer`：

| 欄位 | 已取得內容 | 證據與使用邊界 |
|---|---|---|
| Copyright | `2026 WU JUI-YI` | `docs/release/app-store-submission-pack-20260919.md:43` 有既有 Owner 確認；可作本遊戲草稿，不等於已寫入 ASC |
| 支援聯絡 | `reiko0099@gmail.com` | 同文件42、`public/support.html:45`，並在目前公開支援頁中找到；不是 reviewer 私人帳號 |
| 既有公開站 | `https://gavin0099.github.io/english-vocab-trainer/` | privacy.html、support.html 本輪 GET 均200，標題仍字樹花園。可參考部署／格式，不能把網址直接填成皇冠戰略政策 |
| 工程 Team | `P358EB3X9H` | 該 repo `ios/App/App.xcodeproj/project.pbxproj:808`；只證明既有工程設定，沒有查商業契約、稅務、銀行或此遊戲 App record |

不用再請 Owner 重填已找到的公開姓名及 Email。仍需建立本遊戲專用可達的 policy/support 頁及實際 App Store／廣告記錄。沒有讀取 `.env`、權杖、密鑰、登入憑證或完整 Review Contact 電話。

## 首版程式與打包收尾

下列行號為查核當時的 1023 來源，後續改動應再核對：

| 項目 | 實際來源與問題 | 最小處理 |
|---|---|---|
| 技能試驗 | `PlayableGameView.swift:468` 的設定選單入口沒有 DEBUG 保護 | 僅 DEBUG 提供；保留現有正式技能、舊存局與必要練習，不刪既有 Core 合約 |
| AI 研究 | 同檔1091 的 AI policy 切換在正常 Release 可達 | 將研究選單限制 DEBUG；難度簡單／標準保留，首版沿用已核定 baseline。不可因隱藏選單就宣稱 BOT-P2 已驗收 |
| 英文英雄語音 | 同檔1350 有 VO-01 原型 Toggle；`CombatAudio.swift:177–190` 能準備／播語音 | Owner 多次拒絕其品質，首版建議不打包 Voice 並關閉 Release 播放能力；保存原有 `combatAudio.voiceEnabled`／voiceVolume 值，不重設其他偏好。不能只關預設，讓舊開關仍可播 |
| Legacy 模型 | `TacticalGoApp.swift:6–12` 的 legacyReview 已是 DEBUG；但 pbxproj124 Resources 仍含 Models 的 BuildFile `0000000000000000000000D5` | 將 Models 移出正式分發，原候選檔留在 repo。Debug 3D 檢視如要保留，需獨立資源流程／target，不刪來源冒充回歸通過 |
| 舊畫面 launch arguments | `PlayableGameView.swift:637,644` 的 --sell-legacy／--sell01a 未限 DEBUG | Release 固定目前正式外觀；Debug 保留對照。不影響棋盤投影、命中或遊戲資料 |
| Anim01 舊特效／參考 | `CozyStyle.swift:49–53,74` 驗全部 source-pins，並強制 `Anim01Assets.load` | 不能整包刪 Anim01，兵卒仍由其中載入，且 loader 驗全部素材。若縮包，另立 Release 最小 manifest/pin allowlist 並驗所有現用 load path。不要在首版收尾無證據重構 |

Audio 在 Xcode 以整個資料夾 resource 打包；單純刪 Voice 的個別 PBX reference 不會排除它。應改明確分發 allowlist，或以經檢查的 Release 資源步驟排除 Voice；保留候選來源和歷史 manifest，驗封存產物沒有 Voice。

`*-3d`、`identity-reference-*`、`miniature-*` 圖片僅見於 legacy renderer／ModelGallery 與其 BoardArt；正式路徑是 CozyBoard。它們是可排除候選，仍須對最後版本的所有 dynamic image-name 及 Assets.car 做檢查。三職 `warrior/mage/rogue` 立繪、`token-*` 備援、SELL 場景、Cozy／HeroBody／MageBody 及主 icon 目前不要盲刪。

## 素材不是因為舊 HOLD 就「非法」

核對同一檔案 hash、生成／改圖方式、輸入參考權利、Owner 使用決定、產品品質，分開記錄。保留舊 manifest；本轮追加發行證據，不反寫歷史候選為當時正式核准。

| 現用材料 | 已找到的來源 | 剩餘邊界 |
|---|---|---|
| 三職 B-v02 | `assets/candidates/vis-feel-01/sources/asset-provenance.json` 鎖 image_gen 原輸出、reference、512匯出與 prompt；三張輸出與 Cozy 檔相同 hash | 最上游 reference 的原始權利需在清冊串起；美術方向接受不自動變成已完成公開權利清查 |
| 法師／戰士／盜賊補圖 | `anim-mage-body-01/provenance.json`、`anim-warrior-rogue-01/provenance.json` 記內建 image_gen，補遮擋布料，臉與主道具用原畫 | 不是重做人臉；沿原畫輸入權利，保存生成與來源鏈即可，不因歷史 Pending 重新生成 |
| SELL 木盘／桌面／紙張 | ui-sell-01c 外部 worktree 的 assets/manifest.json 與 revision-01/assets/manifest.json 明載 built-in image_gen；四張 runtime hash相同 | 來源／用途可證；保留引用與最新 Owner 外观回饋，最後一份權利清冊仍需具體列檔 |
| B2-B 兵卒及原 ANIM-01 | 視覺worktree `vis-board-b2/visual/exports/handoff.json` 與 `qa/independent-provenance-audit.json` 鎖兩張1254來源；原始SHA與Anim01來源SHA吻合，紀錄4次文字生成、沒有圖片輸入。runtime再增加64px透明padding，不改兵卒像素 | frame及整包仍需留來源；不因 historical `productionApproved=false` 一律判不可用。被棄用的B2新英雄沒有作正式人物來源 |
| AUDIO-01 | `Audio/manifest.json`：Python 合成、自寫音符／DSP、無外部取樣；12個WAV均hash吻合 | 來源可證，不是第三方錄音；Owner 公開使用／聽感決策另記 |
| B 對戰曲 | audio-02-theme-candidates 的 `audio/AUDIO-02/dynamic-b/manifest.json`：自編樂譜／DSP、無外部取樣或library；五個 runtime WAV均hash吻合 | 包內 b-manifest 的 source_spec 寫 source-manifest.json，但來源實際是 manifest.json，清冊引用應修正，不能假裝缺檔等於無來源 |
| 英文六句語音 | 包內manifest是Piper六句，模型／CC BY attribution有紀錄且六WAVhash吻合 | 因品質未接受，首版推薦排除；不以引擎GPL自行推定音檔禁止商用，也不以CC BY自行宣稱完整聲音權利清查通過 |
| App icon | cozy-02-integration 的 brand-01/manifest.json 記內建image_gen、owner-selection.json記Owner選A-crown；1024RGB輸出hash吻合 | 中文《皇冠戰略》為Owner選定名稱；英文 Crown Tactics 曾記錄Steam已有同名作品，公開英文名稱仍須定案，不宣稱名稱權利已清查 |

OpenAI 2026-01-01 Terms of Use 的 Content 條款把服務輸出權利交給用戶，並要求用戶有輸入權限；這支持「生成素材不是因為歷史 HOLD 而禁止商用」的判斷，不能替代輸入來源／第三方權利確認，也不證明作品享有獨占或法定著作權。[來源](https://openai.com/policies/terms-of-use/)

## 可送審前的剩餘實際工作

1. 用 StoreKit 真正商品／已驗證交易完成一次購買與恢復；取消、pending、退款／撤销、離線、重裝、重複確認不得誤發權限。價格來自StoreKit，不硬編碼 NT$60。
2. 三場完整局與廣告續玩計數獨立於棋譜、AP/Mana及規則；續局／復原／取消不得多扣。廣告失敗／未完成不給假獎勵；沒廣告可看要有清楚出路，不能把已開棋局鎖住。
3. 實際廣告 provider／SDK 版本／資料用途／consent及分級核對，重建公開policy與ASC隱私回答。不能沿用1023「未加入廣告」清單；拒絕ATT不能觸發功能限制。
4. 採用清晰首版 Release 入口，排除研究／未接受VO，完成素材清冊。權利確認與聽感／美術驗收分開。
5. 本遊戲的可達支援／政策頁、正式bundle／版本／商品ID／ad App+Unit IDs、Paid Apps Agreement／稅務／銀行、年齡問卷與實際商店文案。帳戶持有人親自處理契約及受控資料。
6. 凍結可重建來源與生成包、同來源 iPhone／iPad 完整對局、9關／教學、背景返回／續局、StoreKit Sandbox與測試廣告。既有UI認可有效保留，不拿新數量重做已驗收美術。
7. App Store distribution archive的bundle/version/icon/privacy/resources/SDK manifests/簽名與entitlements核對，保存archive SHA與release宣告；development安裝成功不是distribution archive證據。

## 本輪驗證與未執行

132個資源／JSON／privacy baseline rows 與1023來源相同；23個WAV逐一對manifest，0不符。字樹花園兩公開頁目前GET200，metadata來源與Email可追溯。機器清冊見 `artifacts/monetization-02/release-audit/AUDIT_INVENTORY.json`。

沒有執行遊戲測試、建置、真機、Account操作、契約接受、資料上傳、TestFlight、merge或發布。主Agent可能同時加入商業功能，這份靜態查核不能冒充其最後程式版本驗證。商店／支援／policy本機草稿在同一release-audit目錄，缺口明確標記，不把draft頁當公開可達URL。
