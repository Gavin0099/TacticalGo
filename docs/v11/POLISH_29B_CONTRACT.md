# P29-B：獨立音效／英文施法語音音量

在原對戰聲音 sheet 增加兩個明確音量控制，保留靜音、配樂、減少動態與完成返回。未操作過的新偏好預設音效80%、語音85%，恰好維持P29A實際cue gain與英文B音量；不沿用舊模式CombatAudio的音效偏好（其原生預設65%，不是80%），不改舊模式。新鍵`combatAudio.expansionSFXVolume`、`combatAudio.castVoiceVolume`、`combatAudio.castVoiceEnabled`保留於既有Preferences；不更改存局或主動寫入尚未使用的預設鍵。

音效80%表示P29A基準，實際gain=原cue gain×音效值/0.80，上限1。語音gain=原cue gain×語音值/0.85。調整保留蓄勢／移動／命中各層比例，不把所有player設成同一音量；slider100%各player不超1。輸入有限且0…1，非有限值歸零。語音音量0或開關關閉時，下一招用P29A無語音層次；目前已排程的音效不因語音開關改變而突然加大。

調低或调高非零音量，更新正在／已排程player，不能重新play、修改Core、取消動畫、縮短inputEnd或改BGM duck。任一群組調到0時停止該群組當前和延遲cue，另一群組不受影響；重新提高／啟用只影響下一次成功confirm，不能復播先前cue。原mute、Undo、背景、離場取消仍全部有效。英文開關本身只取消語音，不再用store.stop取消視覺與其他音效。配樂與終局樂句仍由原CombatAudio音樂bus獨立控制。

驗證使用真正AVAudioPlayer：預設不變、比例調整、0取消與提高不復播、非有限值、語音與音效独立、BGM独立、Core/receipt/inputEnd不變、偏好重建與新store讀取。UI實際拖曳滑桿、切換語音、返回、重開、375/402pt可達，保存同局面前後聲音sheet截圖。既有49原生音訊審核因player混音管理改動需重跑，不能冒稱是49個UI方法。波形／音檔／配音身份不改，預設可沿用P29A同響度試聽；任意個人提高音量不保證所有疊音都不削波，Owner聽感與真機仍待窗口末驗收。

原生P29A／首P29B截圖共同顯示聲音sheet上方空白標題區。使用inline可見cream標題及44pt完成，百分比與slider同列，減少三個額外列高，不改root棋盤尺寸。DEBUG錄影固定80/85與語音開關不能写Owner偏好；真實偏好與工程錄影參數明確隔離，加入原生重建/字典比較檢查。
