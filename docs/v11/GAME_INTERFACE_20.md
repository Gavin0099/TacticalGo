# UI20 主畫面與技能圖示

2026-10-13。Owner已認可新風格，指定先完成主畫面和icon，再開始動畫。這輪完成可檢視的UI候選及SwiftUI接線，沒有編譯、安裝或發布；「風格不錯」不等於整體品質已達爐石。

## 畫面與素材

工作分支 `codex/v11-game-interface`，以最新指定來源 `origin/codex/v11-monster-battlefield` 的 `004ed4cdc661bc20261a587e11d91e54dc649b9d` 為基線。原工作樹和舊AV候選保留，沒有切回main取舊素材。

- 主畫面採安靜灰青背景，HUD與技能座採霧面，木與古銅集中在棋盤及手繪操作框。減少UI19重複的棕色紋理，建立桌面、棋盤、操作區的前後關係。
- 44pt英雄徽章、分面能量晶石、保留數字的AP小點；選取底線移到技能卡底緣，避免穿過文字。大廳選角增加可見勾選，主要開始對局置於教學前，續玩與棋譜入口沿用至少44pt的共用按鈕樣式。
- 七技能各有獨立構圖：築壘雙兵下壓、重整戰線移動、單手單兵、雙手雙兵、兩方換位、三點連鎖、奉獻向上消散與空座。牧師仍只有奉獻，II不再代替第二技能插畫。
- 圖集為4×3等大透明格，按runtime尺寸取樣；源PNG原始像素未改。手繪框中心透明。人物身份、棋盤素材、PhoneMatchLayout、200pt操作區、Domain規則與費用來源保留。

## 迭代與比較

UI19原圖在 `artifacts/game-interface-19`，UI20前SwiftUI來源在 `artifacts/game-interface-20/baseline`。UI20首輪截圖與圖集在 `iteration-1`；原始生成路徑、全部verbatim prompt與SHA256在 `provenance.json` 和 `prompts`。

首框過厚且外緣留白太大，重生為薄框，減少對內容的壓迫。首版圖集牧師金葉跨格，法師圖示下方出現小金角；重生後水平分格边界alpha最大值為0和1，實際小尺寸圖已無可見串色。沒有用裁切修圖掩蓋生成問題。

| 面向 | 本輪判斷 | 證據與界線 |
|---|---|---|
| 桌面、HUD、棋盤與操作區層次 | 改善 | 375完整主畫面、402選角與UI19同類圖對照，棕紋不再到處競爭；browser候選 |
| 基本／進階技能身份 | 改善 | 四職技能列、七技能32／48／64px，雙手、單手和三點交換輪廓不同；未做真人盲辨識 |
| 主動作與選取 | 改善 | 金色合法確認、灰色不可用、選角勾選；50布局情境未移動棋盤 |
| 英雄人物／棋盤原畫 | 持平 | 沿用最新分支素材；這輪沒有重新設計人物或盤面 |
| 原生字體、觸控、效能、聲音、動畫 | 未檢查 | Windows無Xcode/iOS SDK；browser不是原生證據 |
| 是否達到爐石完整品質 | 未成立 | 仍缺原生整合、四職聲畫與玩家體驗驗收；不使用自评分數 |

競品比較依據及實際觀看範圍見 [差距分析](HEARTHSTONE_GAP_20.md)。本案採用官方圖中「平靜中心、實體槽座與集中角落細節」的設計方法，沒有匯入競品美術或聲音。

## 驗證

最終 browser 執行 `node scripts/review-game-interface20.cjs`，50布局情境、9類fixture互動及21個圖示尺寸樣本通過；375／402四職、ready／preview／loot／locked／result／lobby、兩組法師方向均涵蓋。固定200px操作區、棋盤frame一致、操作區主要按鈕至少44px及無水平溢出只對此browser fixture成立。

已查看375完整對局、375／402選角、375結算、四職操作區及七技能小尺寸圖。`python -X utf8 artifacts/game-interface-20/verify.py` 檢查資產與生成來源byte相同、Contents.json、分格alpha、框中心透明、Xcode來源註冊及AV21不在active runtime。skill quick_validate和git diff --check另存 `validation.log`。

**原生build／UI tests、VoiceOver、Dynamic Type、iPad旋轉、真機皆NOT RUN。** UI19已更新的原生回歸仍未執行，不沿用舊版本通過紀錄。browser是獨立HTML/CSS和互動fixture，棋盤仍固定7×7示意，大廳未移植所有原生設定；不能推論9×9點擊、規則、聲畫、儲存或SwiftUI像素相同。

## 接續

在目前checkout啟動 `python -m http.server 8771 --bind 127.0.0.1`，開 `http://127.0.0.1:8771/tools/game-interface-20/`。Playwright使用已安裝Chrome，依環境指定NODE_PATH。

先在Mac編譯當前Debug／Beta並取得375／402四職、選角與終局native圖；執行UI19列出的原生回歸，核對图集取樣、手繪框內緣與實際字體。接著才以固定UI比較四職完整施法與終局收束。

先前已開始的AV21改動保存在 `artifacts/av21-pending`，七個tracked檔案已回到本輪基線，兩個新Motion檔案也移出active來源。`tracked.patch`、完整source及hash可恢復；混合ExpansionLabTests備份含UI19內容，後續只恢復新增的defeat assert。這些AV21來源未編譯，奉獻與終局音路由問題仍待修，不能稱已解決。沒有Git commit／push／merge、建置號遞增、TestFlight上傳或安裝。
