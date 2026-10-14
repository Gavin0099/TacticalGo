# ANIM-01R｜補充工程結果 07

本次補上真實獲勝順序與支援裝置的原生操作矩陣。Reviewed fixture 的 AM1-04 終局呈現回歸通過；AM1-07 有完整的支援畫面與操作證據，但**手機橫向畫面不支援、角色身份／小尺寸辨識／表演品質尚未經 Owner 接受**。因此不宣稱整份 ANIM 合約或 G-AM1-3 已全數關閉。

本 agent 只新增 mage UITest、文件及證據。Root 因原生影片揭露的實際缺陷，另行修改 `PlayableGameView`：正常成功演出尚未收勢時，暫緩終局 banner、標題、訊息及結果公告；Core 已提交的棋局、資源與收據不變。Reduced Motion 仍立即呈現終態。沒有改規則、角色原圖、動畫 body renderer、聲音偏好或音檔；沒有提交、上傳、合併或安裝。

## 驗證

證據根目錄：`artifacts/anim-01r/continuation-07/`。可機讀總結為 `completion-summary.json`，原生照片逐檔索引為 `native-photo-index.json`。下表每列是一次真正的 XCTest 執行；三台矩陣使用同一個参数化方法，不能說成 48 個獨立 XCTest。

| 原生執行 | XCTest 方法／內部案例 | 新成功收據 | 完整原生照片 | 可支持的結論 |
|---|---:|---:|---:|---|
| `win-16` | 1／4 | 4 | 16 | 7路黑／白施法者 × 正常／Reduced Motion，真實提主將與獲勝；預覽、確認、undo |
| `se-matrix-11` | 1／16 | 16 | 64 | 375×667pt：8支援直向畫面＋8裝置转橫穩定案例 |
| `phone-matrix-14` | 1／16 | 16 | 64 | 390×844pt：8支援直向畫面＋8裝置转橫穩定案例 |
| `ipad-matrix-15` | 1／16 | 16 | 64 | 744×1133pt／1133×744pt：16支援直向／landscapeLeft畫面 |
| `phone-fit-13` | 1／6 | 0 | 6 | 既有1016原版／R3／電腦六種viewport案例，棋盤與44pt操作項一起可用，不用捲動 |

主要證據合計 **5次成功執行、3個不同 XCTest 方法、52個 mage action 案例／52份不同成功收據／208張 mage 原生照片**；另外是6個viewport案例／6張照片。重跑與失敗不重複累計。矩陣48列明確分為 **32支援 render＋16手機轉橫穩定列**，不是48種直橫画面。

每台矩陣均包含7／9路、黑／白施法者、正常／Reduced Motion、直向／裝置landscapeLeft。使用既有無提子7路 fixture 與 `Anim01Fixture.denseState(caster)` 9路 fixture，不改 Domain 製造特例。真正UI確認預覽未扣費、取消、實際推動、2→1AP、回穩解鎖與undo；棋盤及技能／確認／復原／結束按鈕在viewport內且至少44pt。每個 run 的 `receipt-verification.json` 另以獨立 whole-board delta 核對來源(4,3)→終點(4,2)、施法者Mana4→2、AP2→1、事件只提交一次，沒有額外棋子／提子／獲勝。

9路最後一列原生geometry記錄的法師canvas，在SE為26.611pt、390手機為31.451pt。這些完整截圖是真實尺寸材料；既有32／48／64的獨立樣本不能代替SE實際26.6pt辨識驗收。Dense fixture的外圍棋子多，但沒有把法師四個正交鄰點全部塞滿，所以不宣稱最壞鄰棋遮擋已驗證。landscapeRight與iPad倒置方向沒有在本矩陣另跑。

## AM1-04 的實際失敗與修後證據

既有 `Anim01Fixture.state(capture:true)`：敵主將(3,2)最後一氣為(4,2)，己兵(4,3)上推填入後，Core 真實產生 `piecePushed → piecesCaptured → gameWon`。四種施法者／動態组合均使用這個 fixture，沒有用文字假造勝利。完整收據可見win-16；獨立檢查確認唯一捕獲、正確勝者與其他棋盤／資源完整一致。

`win-10` 的終態測試雖通過，原片15.0s仍可看到 **落定前就出現勝利 banner／結束標題／終局訊息**；其 `visual-finding.json` 明列視覺 FAIL，原片、15.0／16.0s原影格與檢視表保留，不改寫成完整PASS。

修後 `win-16/native-full.mp4` 為1170×2532原生全畫面、55.063333秒、只有H.264視訊軌。既有8pt DEBUG標記依真實AP由cyan变magenta，登記4次提交；不改動畫速度或棋局。正常兩例的同一份 post-confirm accessibility snapshot 都真正觀察到「行動演出中」，該快照沒有勝者／`matchResult`／結束標題。Reduced兩例沒有觀察到正常播放階段，立即終态正確。

`win-16/frame-verification-v2/visual-order-verification.json` **12／12影格通過**：正常兩例提交後+.10／+.60／+.80s沒有勝者、終局標題、终局訊息，+1.10s都有完整結果；Reduced兩例+.10／+1.10s已有結果。工程逐張檢視黑／白+.80s，己兵已到(4,2)、敵主將已移除且仍無終局banner；+1.10s同盤面才顯示正確勝者。影片時間以30fps显示時間线登記，不能聲稱物理延遲或逐像素精確時計。原影格在同目錄`frames/`，手工工程觀察為 `manual-frame-review.json`，真正 native phase trace 已篩為 `fresh-render-observations.json`。

測試在已驗證終態後保留1.25秒供錄影查看，再undo；沒有延長950ms角色動畫。最初v1用 `-ss` 擷取稀疏更新的native影片，跳到了下一次undo更新，造成錯誤影格與FAIL。v2完整decode顯示時間線後依影格索引取樣；v1失敗檔仍在，不以它判定產品FAIL，也不刪掉診斷。

## 來源與回退

各run都有 `command.json`、完整 `native.log`、`native.xcresult`、source-before／after、實際成功收據、audio／render trace、geometry及原生attachment。主要5次執行的來源前後均相同；這不代表每次run是同一版來源。SE矩陣在終局UI修正前，以非終局fixture完成，不能用它聲稱SE已測過修後四種獲勝。

新的 `source-pin-snapshot-07.zip` 保存win-16實際source pins中的93個檔案，31,712,350bytes，SHA256 `f8c148859ad66e80fe9b5f230e5c76badceee7e3e2731b5b9d411f67d1118d77`；逐檔在 `source-pin-snapshot-07-manifest.json`。它保留後續Bot候選接線前的可編輯來源與既有 mage／音檔輸入，是來源pin archive，不能冒充完整簽名發行包。

`runtime.json` 的主executable SHA是Debug launcher stub；它前後相同**不能證明Swift程式碼未改**。win-16／兩個後續矩陣另外有 `runtime-code-pins.json`，實際 `TacticalGo.debug.dylib` SHA為 `8eaa34bbca559fdebf8122849bc03198a38cb172db8c35e6db2e47974805f8f6`。較早run沒有捕獲Debug dylib，不回填不存在的舊binary證据。Source、真實執行log、原生快照與原片分別保留。

保留的其他診斷：win-08選中0測試，NOT RUN；win-09因`1 AP`兩個UIlabel造成metadata selector失敗；win-12修後4例UI通過，但Reduced終態停留不足一個影片frame且v1擷取失败。它們均不算本表主要成功次數。原M3參考／R1前後片、舊編號來源包與ZIP保持原樣。

## 尚未關閉的 Gate

- iPhone產品只支援portrait；literal「手機橫向render」沒有驗證，也沒有為了測試擴張產品支援。
- 本次全部是iOS18 Simulator，deployment17不等於iOS17／真機已驗證。真機觀看／觸控、温度／記憶體／幀時間、物理聲畫延遲與VoiceOver聽感不在本次證據。
- Owner身份、不看文字的抬手／揮杖／收勢辨識、方向可信、黑白字牌小尺寸辨識、重量與節奏仍待`ACCEPT_CANDIDATE / REVISE / HOLD`，自動測試不代做Owner決策。
- 原生錄影沒有音軌；英雄語音保持第一輪關閉，沒有新增後製聲或把無聲片冒充系統音訊實錄。
- 這些來源snapshot未包含後续opt-in Bot續攻候選接線；其UI、取消、棋局與真機檢查由新證據另列，不能用本次矩陣稱它已驗證。
