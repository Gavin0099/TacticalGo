# PRESENT-01 魔法之手聲畫比較

獨立 Debug 入口 `--presentation-lab`。A 是保存的 M3 原候選（來源 `c13f23e019eef6d5492a511c93e55df6dd6007f7`），不是目前 1.0/main 的正式演出；B 是本輪節奏候選。兩版原畫、切層、規則、輸入與 outcome 相同。

| 時刻 | A 原 M3 | B 新版 |
| --- | ---: | ---: |
| 蓄勢姿態到位 | 0.18 s | 0.10 s |
| 出手／聲音 | 0.28 s | 0.22 s |
| 士兵開始移動 | 0.30 s | 0.22 s |
| 落定／命中音 | 0.54 s | 0.52 s |
| 正式提子事件開始淡出 | 0.66 s | 0.52 s |
| 身體、頭部與披風收勢 | 0.95 s | 0.70 s |

原畫的頭帽、法杖與握持手使用相同像素，肩肘使用巢狀 pivot；背板僅補原圖移動後露出的衣服區域。陣營底座獨立於角色動作。法師只在 Domain 確認的存活盤面出現；被提角色不能因播放動畫重新出現。中途取消立即顯示已提交結果，復原另由 GameSession 執行。

新版音訊使用 Kenney [Impact Sounds](https://kenney.nl/assets/impact-sounds) 與 [RPG Audio](https://kenney.nl/assets/rpg-audio)，兩套 CC0 來源 license 與 zip 已保存。布料／反轉水晶蓄势、短風切、木質與水晶落定分為六層與四個 cue；不宣稱素材一定來自實物錄音。原音、处理腳本、聲音量測與資源 hash 在 `assets/candidates/present-01/audio/manifest.json`。

已有 Qwen VoiceDesign 英文「Off you go!」作可選試聽，預設關閉，重設後首次施法才播放。聲音不綁定 Domain、不計入規則；不宣稱已完成新的中文職業配音。原始 voice、模型與 runtime pin、台詞／提示和舊生成腳本一併保存於 `assets/candidates/present-01/sources`。

預覽不提交、不播放成功聲音。聲畫僅接收成功並與當前 state 一致的 receipt；單調時間軸與取消世代防止舊演出延遲。Reduced Motion 立即顯示 final board、角色靜止，不改音訊時間表；靜音另外控制。語音與 SFX 分開，沿用既有 BGM duck 和 audio interruption 機制。

模式局面是手工合法演出 fixture，密集局面含法師四個正交鄰子；不以此证明自然對局可達性或技能平衡。驗證證據另見 `artifacts/v11/present-01/REPORT.md`；模擬器錄影、後混音、實機操作與真人聽感分開記錄。不更換引擎、不修改本輪 Domain、不合併或發布。
