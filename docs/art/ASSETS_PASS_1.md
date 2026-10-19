# Assets pass 1 — 原創候選與驗收記錄

基底：PR #30 `f2a28b712d3392973f37360a41ea25ce255b0cb7`；分支 `art/assets-pass-1`。
範圍：L1 素材及展示入口；不更改規則、Bot、存檔、手勢、accessibilityIdentifier。候選僅 Beta/DEBUG 且 ArtV2.enabled；Release 原素材不可覆寫。棋盤骨架、clean plate、mask、anchor 與 P02 不變。

## A：改圖前風格檢查（2026-10-19）

直接看過四張 512 肖像及三張 1254 identity-reference，非只讀檔名。牧師無 identity-reference-*，使用既有 priest-v02 1254 身份及 priest-portrait-v03 裁切。

| 檢查項 | 戰士 | 法師 | 盜賊 | 牧師（最弱：一致性） | 統一目標 |
|---|---|---|---|---|---|
| 線條粗細 | 棕色外線、鎧甲內線略密 | 帽緣多層線 | 手套及刀線清楚 | 外線與五官特別重 | 512 外線約2–3px、內線約1px；細節不搶臉 |
| 光源方向 | 左上，金屬亮 | 晶體亮、帽暗 | 左上、刀亮 | 左上但髮高光強 | 左上暖柔光、右下陰影；霧面、局部材料高光 |
| 色盤 | 青綠/銀/金/栗髮 | 梅紫/青晶/奶油 | 靛藍/苔綠/赭黃/銅髮 | 綠/象牙/金/酒紅/金髮，飽和較強 | 保留各自身份色，壓低高光飽和，暖棕共用陰影 |
| 頭身比（半身構圖） | 臉居中上、肩寬 | 帽使臉較小 | 兜帽包臉 | 臉較大、裁切幾乎到底 | 保留各自裁切框、道具手勢；牧師柔化體積差，不換骨架 |
| 表情 | 自信友善、雀斑 | 友善專注 | 狡黠友善 | 明亮友善、眼較突出 | 保留眉眼、笑容與雀斑，不改年齡或身份 |
| 邊緣處理 | 透明、下緣弧形 | 透明、帽/杖細緣 | 透明、刀尖/兜帽 | 透明、手指/書輪廓 | 真alpha無底色光邊；沿用透明畫布及半身錨點 |

先修牧師，再依同一光線/筆觸處理其餘三張。來源至少1024，輸出512/256；36/40/130實際像素樣本及原生截圖分開判讀。所有美術結論是本代理主觀逐張審查，非真人盲測。

## 驗證計畫

每包：固定 iPhone16 capture/priest/impact/lobby 前後；ExpansionLabTests + IntegrationUITests；Debug/Release/Beta 編譯。記錄圖像RGBA/檔案hash、引用清單與來源prompt。音訊以 ffmpeg ebur128、峰值、尾音、loop接點量測；IntegratedAudioAudit及設定UI保護既有行為。測試成功只證明技術檢查，不代表好看/好聽。

## 未驗項目（在完成後按實際證據更新）

實機、真人評分、效能、正式發布權利接受均尚未驗證。棋盤身體不重畫；英文語音不新增、不進Release。

## A：逐張判讀

證據：`artifacts/assets-pass-1/portraits/native-size-before-after.png` 的每對左舊右新；`screens/before` 與 `screens/A` 同 iPhone16、同 fixture、關閉 ambient。來源全為1254×1254；交付512與256，透明輪廓以舊圖 alpha>=13 的底部中心均勻對齊，未拉伸人物。未改棋盤錨點。

| 肖像 | 36（HUD） | 40（操作區） | 130（大廳） | 身份辨識依據 |
|---|---|---|---|---|
| 戰士 | 持平 | 持平 | 改善：護甲與盾面筆觸有分層 | 栗髮/雀斑/青披風/右劍左盾不變 |
| 法師 | 持平：晶杖仍亮 | 持平 | 改善：帽、髮與木杖有不同材質面 | 紫短髮/梅紫尖帽/右手青晶杖不變 |
| 盜賊 | 持平 | 持平 | 改善：兜帽與皮手套層次較清楚 | 銅髮/靛藍帽/赭圍巾/右手單刀不變 |
| 牧師 | 持平：手與書仍可辨 | 持平 | 改善幅度小：布/書/髮材質較接近其他三職 | 金捲髮/琥珀眼/葉徽/綠白袍/酒紅書不變 |

以上是主觀視覺比較，不是身份的客觀自動驗收。沒有任何一項用測試數量作為畫質依據。

| 一致性逐項檢查 | 結果與限制 |
|---|---|
| 暖棕外線與較細內線 | ☑ 四張皆有；牧師眼線仍較重，保留身份 |
| 左上暖光/右下陰影 | ☑ 四張皆有；晶體保留自身明亮面 |
| 共用暖棕陰影、職業色分離 | ☑ 戰青銀/法紫青/賊靛赭/牧綠金，未換衣色 |
| 半身頭身比與姿勢 | ☑ 沿用各自裁切及底部中心；牧師頭較大、法師帽佔位較多的既有差異仍在，不宣稱四張同比例 |
| 友善表情與身份 | ☑ 微笑、眉眼、髮型、道具方向在此代理逐張比較中保留；Owner精確檔案驗收待定 |
| 透明邊緣 | ☑ 有真正alpha、無底色；512/256輸出另有尺寸與hash記錄；未改骨架圖 |

生成方式與完整prompt：`assets/candidates/assets-pass-1/portraits/provenance.json` 及每職 `*-prompt.txt`。使用內建 image_gen，不提供不可得的seed/model/tool版本；這些欄位明列unknown/unavailable。輸入僅專案原創角色和本輪原創戰士，沒有第三方素材；正式發布權利接受仍待Owner，不能將「未用第三方輸入」當成法律審查。

## A 驗證紀錄

Debug、Release、Beta（指定1118 xcconfig）皆建置成功，原始輸出在 `artifacts/assets-pass-1/logs/A-*.log`。初次平行Release/Beta曾因共用build.db鎖衝突失敗，依序重跑Beta成功，未把失敗計為通過。

UI首輪總數62：61 passed、1 failed（`testMonsterHuntAndLootUseSameNineBoardAndResume`，結果檔記錄 `Test crashed with signal term.`）；runner重啟後其餘案例完成。第一次單項補跑在bootstrap前失去連線，檢查時模擬器處於Shutdown，沒有測試通過證據。重新boot後保留的A版binary補跑1/1 passed。不能把此狀態寫成「首輪62/62全過」；termination根因未定位。結果摘要：`A-test-summary.json`、`A-rerun-2-summary.json`；A測試binary SHA在 `tested-app-snapshots.json`。

另檢查light與silhouette的32/36/40/48/64/130原生像素樣本，未見白色底緣或新裁切缺角。四張大廳/36pt徽章/40pt操作區在同fixture截圖中保留辨識；棋盤身體沒有改動。
