# AV24 品質差距與接觸演出

2026-10-13。Owner 要求分析是否接近爐石，未達則繼續優化，至少90%以上才可停止；並要求本輪 push 和更新未完成 PLAN。基線是已推送的371718e／codex/v11-game-interface，來源分支重新fetch仍為004ed4c。整體接近90%的結論目前**未成立**，這份交付只完成本輪候選和可檢查的改善，不關閉品質目標。

## 比較依據與差距

重新讀[爐石官方VFX設計文章](https://hearthstone.blizzard.com/en-us/news/22552047)：以明確連結、職業材料與事件重要性安排主次，次要動作支持主要動作。這是2018年的設計方法，沒有官方「90%」公式；未把其數值或美術匯入本案。

Magnetic GIF在browser載入並取得靜態樣本；Canvas連續drawImage沒有取得可靠的動畫序列，不能當作動作量測。SuperCollider GIF導覽逾時，雖有可見初始畫面，兩次取樣相同，也沒有完整攻擊或聲音證據。原始URL與限制見quality-assessment.json；研究暫存只留本機，不納入遊戲資產或本次Git推送。現階段比較支持方法和構圖，不能證明競品動態／聽感接近率。

| 面向 | 本輪結果 | 仍缺的證據或工作 |
|---|---|---|
| UI材質與主次 | 保留Owner認可的UI20，未用更多面板装飾掩蓋演出問題 | 實際大廳／對局／結算的原生同尺寸核對 |
| 四職辨識 | 保留原畫和現有分層，接觸形狀各有差異 | 正常速度人物表演、裝備接縫與次要動作仍未完成同條件品質評估 |
| 施法關係 | 法師連線增加暗緣／亮芯；局部材料加大 | 手機實際接觸位置、杖尖連線與密集可讀性 |
| 接觸份量 | 戰士壓地、法師聚焦、盜賊兩次交換、牧師空座；地面效果在棋子下 | 真機正常速度是否有重量、是否過亮／遮擋 |
| 配音與音效 | AV23輸入／配音窗口保留；連鎖兩段接觸分立排程 | 實際聽感、疊音、音樂duck、播放延遲與疲勞 |
| 連續對局與可及性 | browser取消／背景式停止／降低動態仍通過 | Native UI、VoiceOver、Dynamic Type、iPad、FPS、觸控及完整對局 |

不把上述表格通過比例、pixel差異或測試數換算成品質90%。沒有真人盲測或同條件原生聲畫；90%門檻保留為未完成。

## 兩次調整

第一次新增ExpansionContactBeat／Frame與四職地面輪廓：接觸半徑0.38至0.46格，短暫停住後在180ms內收束，裁切於自己的格點；非法／過期／降低動態為quiet。連鎖在0.26與0.36秒各標出兩個交換位置，奉獻只標供體原點，不補兵或創造永久buff。前三個Swift回歸測試預期來自既有合法ExpansionPractice和獨立拍點。

第一輪375／402對照仍過細，僅作增量，保存圖片、結果與來源於iteration-1。第二次放大原有手繪石塵、聚焦環、刀光、光葉與空座；將ExpansionSpellEffects拆為ground與foreground，地面在z6、接觸輪廓z5、棋子z10以上、語義／杖尖／光葉z160，危險與選取仍更高。原畫人物與材質bytes未改。這是真正的原生候選接線；browser依相同材料和參數作比较，但不是SwiftUI等價renderer。

連鎖第一接觸沿用p8-rogue-land.wav，以獨立player alias p8-rogue-land-first在0.26秒播出，音量為主接觸的60%；最終接觸0.36秒。重排同一個AVAudioPlayer會覆蓋先前起點，因此兩次保有獨立player，完整停止／復原／背景都會一起取消。沒有新增WAV或延長技能／輸入窗口；普通下一手的已提交配音保留規則不變。

## 驗證

- 最終 `node scripts/review-animation24.cjs`：41項既有motion／layout回歸與32項接觸／實際Canvas輸出檢查通過。包含375／402七技能、兩次交換位置、正常尺度可見差異、結束後前後Canvas完全相同、降低動態、密集場景及兩次實際browser WAV起播。它不執行Swift／Domain，也不證明美術品質或實機延遲。前兩次版本結果不與最終加總。
- `python scripts/verify-animation24.py`：來源／371718e前版快照、Xcode檔案接線、UI20／原畫／WAV／Domain／AV23窗口不變通過。接線檢查不是編譯。最新checks.json和browser-run3.log為本輪canonical evidence。
- browser第一接觸音量後續校正為主接觸的60%，以review-animation24-audio.cjs局部重驗兩次起播與實際player.volume通過，沒有重算影像檢查或追加品質分數。首次shell inline Node quoting失敗，改成檔案後重跑；失敗保留audio-gain-attempt1.log，不計入通過。
- 三項 `ExpansionContactTests`，以及IntegratedAudioAudit新增「兩個接觸player排程皆成功」回歸已寫，**NOT RUN**。六項AV23音訊audit與三項窗口測試仍待原生執行，不沿用歷史結果。
- `review-animation24-native.sh` 已用Git Bash做語法檢查，**原生命令NOT RUN**。它在Mac記錄來源SHA／工具版本、跑完整Swift套件、Debug／Beta Simulator編譯和串行真實AVAudioPlayer audit；不簽名發布、不推送TestFlight。原生輸出位於忽略的artifacts/v11/animation-24/native。

Windows沒有Swift／Xcode／iOS SDK；本輪基線和新原生編譯、FPS、iPhone聲畫、觸控及聽感都未驗。候選可見改善與原生安全／市場品質是不同結論。Self review未達90%驗收；尚無獨立真人比較。

## 下一關

Mac拉取同一候選分支後，執行 `bash scripts/review-animation24-native.sh`（可帶現有iPhone Simulator UDID）。先修編譯／回歸，再以相同375／402普通與密集局面錄製四職七技能。核對落點、輸入、兩段接觸、配音與音樂，再調人物表演／材質份量。完整未完成項目在docs/PLAN.md；沒有main合併、版本號變更、安裝真機或TestFlight發布。
