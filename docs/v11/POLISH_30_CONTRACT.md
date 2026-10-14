# P30：收斂1108後的聲畫候選

接續P29B，窗口仍至UTC2026-10-14 01:54:08。P27限制牌、P28戰士投影／連鎖接觸／討伐接觸及提示、P29 mix／獨立音量已分項驗證。這轮不新增玩法、不改規則／費用／Bot／角色／WAV；保存目前候選、既有失敗與同條件影音，補不同編譯條件及完整組合的缺口。

## 所需證據

1. 最新Swift完整套件首次收斂（前一完整282為P27，不冒稱現在完整已通過）。來源固定，比對Core／Bot與1108，所有preset聲音與圖像來源不換。已有P29B Debug4＋375pt1與22/49個真player檢查的來源未變，不再單純重跑。
2. 正式Beta組態`TACTICALGO_V11`且無DEBUG，在真首頁／玩法練習／正常solo及本機雙人驗證四職合法提示、新普通技能、第二技能、牧師、討伐／戰利、200pt dock與44pt控制、preview/cancel/undo/save/resume。根據既有fixture／固定版面契約，比較原生結果。P29B聲音sheet的UI測試加Beta從真入口進入／續玩路徑；Debug條件的API審核及工程注入不能冒稱Beta可測。xcodebuild全部串行，375pt選相關UI布局／獨立音量等缺口驗證，不為計數重複未變項。
3. 可看／聽比較索引：1108原來源、P28固定receipt無聲正常影片與P29同LUFS30對試聽，保留相同盤面／資源／結果和來源。靜態圖、模擬器無聲影片、離線混音、真機分開。必要只补尚缺的最終組合影格，不重錄完全未變片段。沒有真人聽感、真機FPS／AV同步／VoiceOver／長對局疲勞即明記，不能把工程通過當爐石品質。
4. 核對候選聲畫素材、Info.plist／簽名／profile／source pin；已授權herobody單獨保存1.1／1109 development包（未上傳）。檢查54 PresentationLab素材byte與兩魔物編譯像素對1108。保留1108簽名App與來源，window末fresh備份Documents／Preferences後以Wi-Fi更新同App；未連線或鎖定保存結果，不等待Owner、不提前安装。

先建置／測試，再保存實際結果、review表與手機交付待辦。若發現可重現缺陷，另明確標記修復、保留失敗並補相應回歸；不以降低assertion／扩大scope取得PASS。若各可驗工程完成，保留最佳候選及未驗的品質面向，不為剩餘時間新增技能或換美術／聲音身份。截止後停止新增實作、核對交付並統一回報，heartbeat PAUSED。

P29B已檢視375pt／iOS18截圖：聲音sheet完成鈕仍系統藍，Form內tint／foreground不涵蓋toolbar。P30只為此Button指定共用cream文字色，保留44pt、關閉closure及所有其他來源。11項Beta主流程已通過的來源保留`BETA_MAIN_SOURCE_PIN`及當時PlayableGameView；補最終375pt版面／設定頁和402pt設定頁，其他不變路徑不重跑11項。此變化只支持顏色一致性，不能冒稱動態演出或音質改善。
