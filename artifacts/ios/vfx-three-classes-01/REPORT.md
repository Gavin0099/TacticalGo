# 三職 VFX 強化候選（finite-bursts-03）

結果：完成原生特效強化候選與研究；工程驗證及 iPhone 操作通過，整體美術／產品驗收仍 Pending。未 merge／TestFlight／發布。
原因：Owner 看過最初細線與光圈版本，判定效果偏弱；新版本將蓄能、能量傳遞與命中分開，避免只把戰術提示加亮。
下一步：Owner 用正常速度完整棋盤影片／測試 App 比較三職；iPad 連線恢復後補實際操作驗證。英文語音、音樂與整體美術未升格。

## 研究與實際採用

[完整比較及凍結原始碼](research/DECISION.md)。已看 Vortex 的 Fireworks／Magic 原始碼及 Pow 的 ParticleLayer／SprayEffect，不只讀 README；固定 upstream commit、保存 LICENSE 和 SHA-256。

- Vortex：有限多段發射、飛行拖尾、到點爆發、阻尼及生命期衰減。使用這些原理自行實作 receipt-time 的解析粒子；沒有安裝／複製 Vortex 引擎或素材。
- Pow：棋盤級兄弟圖層避開單一 Token 裁切。沒有導入 UI 彈跳當英雄動作。
- 既有 tacticalgo-cutout-animation Skill：保留原畫本體、陣營、小尺寸及成功收據／取消合約。它不保證 VFX 美術品質，本次不以 Skill 的名稱宣稱氣勢已通過。

## 可以直接觀看

- [三職正常速度完整棋盤總覽](media-strong-final/three-class-vfx-overview.mp4)
- [戰士：黑白／提子／密集／減少動態](media-strong-final/warrior-vfx-full-board.mp4)
- [法師：黑白／提子／密集／減少動態](media-strong-final/mage-vfx-full-board.mp4)
- [盜賊：黑白／提子／密集／減少動態](media-strong-final/rogue-vfx-full-board.mp4)
- [320pt／9×9 密集與 Reduced Motion](media-strong-final/three-class-dense-reduced.mp4)
- [戰士預覽／取消／確認／復原](media-strong-final/warrior-preview-cancel-undo.mp4) · [法師](media-strong-final/mage-preview-cancel-undo.mp4) · [盜賊](media-strong-final/rogue-preview-cancel-undo.mp4)
- [同 Core 棋形、原生390px棋盤，70%蓄能階段舊新並排](mage-native-old-new.png)。不是放大角色展示；新法師 release 時點調整，因此使用同階段，不宣稱同絕對毫秒。

影片為真實 Simulator SwiftUI/XCTest 操作；靜音、無後製聲軌、沒有重繪效果或加速。初始錄影是 VFR；剪輯將保留時間戳的靜止畫面重複成30fps，不插入假動作。用 DEBUG 左上角小型 AP2→AP1 色碼定位實際影片幀，不假設 Host 與 Simulator 的時鐘完全一致；色碼不出現在一般使用介面。Caption 位於 viewport 外。影像／播放器時間戳不是 iPhone FPS 或人耳同步驗收。

舊版及中間版 raw、失敗剪輯與 log 保存在本機，沒有覆寫或宣稱成功；正式交付以 media-strong-final 的 edit-audit.json 與每片 SHA 為準。

## 視覺改動與時間表

戰士：較大、短暫暖金蓄勢底座；雙落點竪向召喚光；盾接觸與兩兵同時落定的局部震波／碎光。法師：杖尖核心與聚集光點、短符文、亮芯能量彈、單格推動尾跡及落點爆發。盜賊：兩條與原身分／相反交換軌跡一致的速度帶，以及兩端短爆發；不以整張 Token 旋轉替代本體。

地面場在人物後方，前景方向及落地帶避開身體繪製範圍；戰術提示仍在上層。特效不參與命中／投影。每個解析粒子群最多28樣本，有有限生命期；不新增常駐 emitter、第三方引擎或獨立 timer。總存活仍受 receipt 約束，移除 receipt 即停止。

法師 full：.18 蓄勢完成→.26出手→.38推動開始→.60到位→.70正式提子演出→.95收勢／解鎖。
compact：.12→.20→.30→.48→.57→.76。
原先 full 出手到推動僅20ms，新版保留120ms可見能量傳遞；整體950/760ms不延長。身體／士兵／VFX／既有 SFX 共讀同一 MageTempo，沒有重複 apply、扣費或判勝。戰士／盜賊時間不變。

Reduced Motion 直接顯示正式結果，保留最多240ms靜態方向／落點提示；不播放爆發、回彈或本體過場。原版 Magic Hand 基準仍是一格推動；候選遠距調度不冒用此演出。

## 驗證

- [177 Swift tests](package-strong-final.log)：包含有限粒子的負時間／到期／NaN／上限、確定性、鄰點距離界線；真實三職雙方7/9、提子／勝負、原子資源、錯誤與候選隔離。
- [137 Golden snapshots](golden-strong-compare.log)：38 fixtures、99 steps，fresh Swift 對 cached C#。C#未重跑；等價不代表玩法正確或有趣。
- [156真實Core/GameStore檢查＋57原生checkpoint](skill-vfx-strong-03-audit.json)：有新runID、開始完成時間；成功／非法／取消／重複確認／復原／換手／重開／離場／背景／Reduced隔離。PNG繪製時間不是實際FPS。
- [4項非零Simulator UI tests](delivery-verification.json)：稽核、320/9密集第二AP與背景、真實Bot事件、18次施放錄影。
- [Release ARM64 build](release-strong.log)與[signed device build1007](device-strong-build.log)。
- [iPhone實際UI2項通過](native-strong-iphone.log)：原生無縮窄Magic Hand提子／復原；三職正常／Reduced 320/9、背景、第二AP及兩次復原。這是工程操作，不是人類美術或聽感通過。
- [原畫／來源／演出合約](../../../assets/candidates/vfx-three-classes-01/manifest.json)。未改 Domain、Bot、GameStore、BoardProjection、人物身份像素或角色本體拆層。

## 真機與已知限制

iPhone與iPad均已安裝獨立測試App「TacticalGo Heroes」1007（com.tacticalgo.prototype.herobody），原Prototype及原存局未覆寫。iPhone已啟動到選角，英文語音與BGM關閉、既有SFX保留；不把啟動視為聽感通過。

iPad先前啟動遭 CoreDevice／remote XPC 連線錯誤。Owner 要求「再測一次」後，新重試已取得 tunnel 與 developer image services，但系統以 Locked（FBSOpenApplicationErrorDomain7／CoreDevice10002）拒絕啟動。等待解鎖後才能取得新版原生UI／內建稽核報告；本次尚未執行測試。先前取回檔案沒有新版revision／runID，仍是1006舊檔，因此不宣稱重現或修復舊的rogue-leave-no-stale失敗；iPad回歸維持HOLD。既有UIrunner認證取消也未被當作通過。

- 新效果是否夠有力、三職差異是否理想，等Owner正常速度觀看；程式測試不會自動通過美術。
- 原畫是頭胸像，沒有新全身／朝向／3D；黑白身份使用已接受薄環與外側提示。
- 密集極小棋盤仍會讓部分高處拖尾被人物遮罩裁掉，刻意優先保護面部與棋形；需要實際試玩判斷是否仍不足。
- 無實體錄影／實體持續FPS／揚聲器或耳機聲畫聽感證據；native電影全部為Simulator。
- 英文英雄語音未通過，保持關閉；不加新台詞、BGM、震動系統或第二技能。

## 修改範圍與交付狀態

分支 codex/vfx-three-classes-01；基線60ffa998c4d31c23b05acc1bc2332f786c5784ae。
核心改動：SkillVFX.swift／SkillVFXView.swift、BoardPlayback接線、CozyBoard圖層、MagePerformance唯一演出時鐘、DEBUG原生稽核／fixture與錄影marker、聚焦 tests、剪輯及delivery verifier、source manifest、研究與slice文件。

隔離候選可commit/push；本輪不merge、不TestFlight、不正式發布。工程候選交付不代表整體美術／產品結案。
