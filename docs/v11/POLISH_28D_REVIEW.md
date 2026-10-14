# P28D：討伐接觸與戰利取得回饋

窗口ACTIVE至台北2026-10-14 09:54:08；手機仍1108，候選不提前安裝／發布。

## 基線與改動

四段正常DEBUG整合棋盤影片已保存：slime-hunt／slime-loot／wolf-hunt／wolf-loot。局面由MonsterPresentationPractice合法開局重播，使用正式select、preview、confirm及成功receipt，沒有手擺局面或另頁技能路徑。新增DEBUG入口只供錄影，正式選單不增加模式。

基線討伐只是魔物晃動再消失，盤面沒有表示已取得獎勵。黏彈的單兵方向與影步的英雄直線結果在影格中可辨，先保留其動作，不增加通用粒子。候選只改討伐：史萊姆接觸前短壓縮，狼的既有頭像小幅收勢，不虛構不可見四肢；在.44接觸後短顯對應能力圖示及持有陣營底座，.76前消散。最大占位小於一格，危險標記仍在上層。

新lootGrants欄位直接由驗證過的monsterLootGranted事件產生，保留owner、ability、unlockPly；Core完整receipt比較仍拒絕偽造event。無獎勵討伐不顯圖示，Reduced Motion不播形變／圖示，但保留文字與實際戰利庫。討伐的標頭／原畫保持施作者與魔物，固定訊息列明示誰取得哪招、下個己方回合可用；普通技能牌與回合資源仍依正式状態。

Domain、費用、AI、原畫、WAV、聲音key、.44接觸與.76解鎖完全不改。已核對Core／Bot檔案與1108基線雜湊相同。取消／Undo／背景仍由原有生命週期取消receipt與音訊，不由動畫回呼寫規則。

## 比較／檢視界線

artifacts/v11/polish-28d/baseline是1108魔物動作（P28C UI＋錄影入口），原pose與1108來源一致；candidate是首圖示候選，candidate-caption是補上取得文字的最後候選。兩招caption-comparison-silent.mp4左基線／右最後候選，同尺寸、棋局、Core前後棋盤／AP／Mana、時間線及soundKeys逐欄核對相同。初候選比較檔保留，不冒稱它已有最後文字。

四段基線影格與.41確認receipt精確原生定格已檢視；史萊姆壓縮仍在同一交叉點，不盖相鄰士兵。NativeReward及最後NativeRewardCaption的.50精確圖已檢視：綠黏彈／紫影步、持有陣營底座可辨；最後文字說黑方取得，降低動態圖只有空點與文字，無假棋子／圖示殘留。

影片沒有音訊。按檔案mtime裁切只近似對齊，抽圖coil／move／land名稱不保證準確相位，不能拿它量測真機AV延遲；.41／.50另外由明確reviewTime確認。精確定格的HUD使用已提交的正式after状态，圖像使用指定receipt相位，不能把它當成真人當下操作畫面。正常演出期間操作仍鎖定、落定後恢復，正式產品没有工程定格入口。

未經Owner、獨立真人或實機正常速度可讀性驗收；新增戰利圖示是可逆候選，不是爐石品質結論。

## 驗證／實際失敗

Content3/0：四場開局重播、正式preview不改状態、逐招apply與完整Undo，真正戰利解鎖，黏彈動士兵／影步動英雄。完整Motion76/0，含新增4項：實際grant與固定時間；無獎勵不出圖示、偽造grant不能成receipt；接觸壓縮／一格尺寸上限／參數有界；僅arrival後圖示、結束無殘留／Reduced Motion／非有限clock回退。首聚焦Motion編譯因測試要建立偽造ActionOutcome卻未@testable import Core而失敗，修測試import範圍，沒有開放生產initializer或移除防偽驗證；失敗log保留。

NativeReward兩方法PASS0skip：兩怪.50真實commit／freeze／Undo與Reduced Motion、autoplay背景不晚提交。補標頭文字後NativeRewardCaption重跑reward方法PASS0skip，新增文字斷言；背景guard來源未變且已通過，不重跑。共3次執行、2種方法，不能冒稱3種不同原生案例；其中reward方法包含兩怪與Reduced Motion三次實際App啟動。

SOURCE_PIN268含runtime、原素材、Package／project、測試及錄影script；PROGRESS記錄接續。未報本輪全Swift／Beta／真機聲畫測試完成；所有既有dirty與基線保留。

下一步P29-A從現有真實材質stems和已接受英文B配音建立同响度混音對照，检查重叠峰值、預備／命中／收勢及BGM duck。現有P08來源位於assets/candidates/feel-10/audio與scripts/build-expansion-presentation-audio.py，不是不存在的expansion-08目录；原始權利逐項核對，不能只靠名稱假定CC0。最終Beta／全套／簽名Wi-Fi交付仍在窗口末收斂。
