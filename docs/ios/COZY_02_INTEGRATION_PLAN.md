# Cozy-02 原生整合驗證

隔離基線 main cdab133；不納入 PR5/6、不更動 Core/Domain、Bot、技能、資源或正式素材核准狀態。Owner 本輪授權 Cozy-02 元件、V1.1 B 棋盤主導布局、B2-B 兵與原 B-v02 三職，以及既有 ANIM-01/AUDIO-01 原生接線驗證。BGM 正式整合仍 HOLD，本候選預設不啟動音樂；SFX 與 Reduced Motion 分開。

先固定 Visual 工作樹 Cozy-02 色彩／圖片及 ANIM-01 宣告匯出／音效 manifest 的 SHA、尺寸、anchor、裁切規範。原圖逐位元匯入；不生成角色，不修失敗 3D。不使用未採納 B2 英雄。棋盤8:9 contain-fit、格線、棋子、提示、hit inverse 使用同一矩形與 Core BoardProjection。

Cozy 棋盤緊接 HUD 和操作台，避免等分垂直剩餘空間；不足高度則明確捲動／提供既有大按鍵選點。三職保留原 B-v02，另以盾／星／短刃徽記及職業底座提供小尺寸非臉部辨識，不遮鄰點。使用元件深色字、厚底邊、選取勾號、座標暖描邊。

魔法之手只由成功提交的單一 piecePushed 建立80/220/100ms及條件180ms提子演出；預覽原棋子不移動／不扣費。聲畫共用收據起始時鐘；mage/落定/有資料才capture/gameWon才勝負。取消、非法、復原、重開、離場、背景、中斷及新receipt取消舊任務與聲音；禁止快速重複確認。Reduced Motion 呈現靜態正式結果，保留必要音效。候選調度不冒充一格推動。

驗證：Package/共享Golden回歸；7/390、9/320、密集局面原生畫面、投影與命中、正常／Reduced、成功／非法／取消／復原／背景／重開／重複確認。檢查真正畫面持有的音訊owner，記錄request與player起播時間及事件差值，不以設計表或player活動聲稱聽感通過。保留真機安裝／原生audit與可檢查示範；系統錄影沒有音軌時，事件對齊後製須清楚標示。

交付候選、來源／hash、畫面／影片與驗證報告，分開工程結果、真機觸控、耳機／揚聲器與Owner美術驗收。無commit/push/merge/發布授權，不擅自交付至main。

## 本輪交付結果（2026-10-10）

固定來源及同投影 renderer 已接入；成功事件聲畫、取消／復原／背景／中斷與 Reduced Motion 完成工程候選。Swift 151／0、Golden 38 組99步、最新390模擬器5／0、SE 320內容約束1／0、iPad真機手勢及實際播放器2／0。iPhone前景實際播放器17／17，但Xcode手勢worker啟動失敗，手機觸控不能列PASS。雙裝置Wi-Fi已安裝0.7.0（702）；最新版iPad重新啟動Locked、手機最後普通入口重新啟動失聯，各自保留診斷。BGM正式整合、整體美術及耳機／揚聲器聽感維持HOLD。實際錄影沒有系統收音，示範使用明示後製的原始AUDIO-01音效。

修正首cue建播放器與首次SwiftUI渲染延遲（同owner預熱、即時cue），停止Timeline強制最終結果（有獨立回歸），DEBUG audit等待真正scene active。無Core/Domain/Bot規則變更；無commit/push/merge/發布。完整證據 artifacts/ios/cozy-02-integration/REPORT.md。
