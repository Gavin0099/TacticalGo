# 1109聲畫候選：已準備，Wi-Fi交付受阻

結果：十小時優化窗口已結束，1.1／1109工程、比較素材與兩種簽名包保存完成，但未更新iPhone／TestFlight；排程已PAUSED，未Git提交／上傳／合併或公開發布。
原因：技能牌提示、連鎖與魔物接觸、聲音焦點及獨立音量已逐項驗證；窗口末iPhone不可連線，TestFlight被Xcode帳戶上傳權限阻擋。不能把工程通過當真人品質通過。
下一步：Owner先看比較素材；完成已開啟的Xcode原開發者帳戶登入後，續傳既有已授權1109 archive並核對Apple處理／Owner群組，不必重建未變來源。真機舒適度與聽感仍待交付後驗收。

[比較影片／四職試聽／主小手機圖索引](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/polish-30/COMPARE.md)

## 可觀察改動及品質界線

| 面向 | 本輪可觀察差異 | 狀態／驗收界線 |
|---|---|---|
| 技能牌／提示層級 | 已用技能、未召喚等受限牌有鎖／降低飽和，仍可點看原因；討伐提示使用該動作的控制數、費用及戰利解鎖 | 靜態可讀性改善，真人無解說理解未驗；global readiness不等於目標合法 |
| 戰士 | 築壘投影變小、.78消散，減少落定後遮新兵；本體、.58接觸／1.02恢復、英文B保留 | 投影遮擋改善；不能說本輪重作本體或更多重量已被接受 |
| 盜賊 | 連鎖第一接觸.26–.29短停，.36第二接觸及.70解鎖保留 | 接觸位置停留可指出，俐落感仍Owner待驗 |
| 法師／牧師 | 法師D與牧師原畫本體保留，新版普通技能與奉獻意義未改 | 持平；不虛構四職全換動畫或新美術 |
| 史萊姆／暗影狼 | 討伐接觸縮壓，grant event授權圖示及取得者文字，下一己方回合解鎖；黏彈／影步動作保留 | 接觸／結果回饋改善，縮壓表情與快感真人待驗 |
| 分層聲音 | 次要蓄勢／移動較低，保留命中與英B；預設80%音效／85%語音維持P29A；各自可調、零值取消不復播 | 排程／音量／取消工程PASS；代理未聽，不能判定更好聽或更像爐石 |
| 配樂 | 原三層、-5dB duck、英文尾音窗口及終局music bus保留 | 原生玩家／同步／取消已驗；手機喇叭／長時間疲勞未驗 |
| 操作與固定棋盤 | 200pt dock、44pt控制與preview／cancel／undo／help／handoff／save／resume保持 | 正式Beta主小手機流程PASS，真人触控／VoiceOver／Dynamic Type／iPad未驗 |
| 聲音設定 | 原頁補獨立音量與保存，inline可見標題、百分比同行，iOS18完成鈕cream色與版面一致 | 主375／402圖已看；非零音量立即更新當前／排程cue，關到零再開等下次成功施放，語音開關不取消動畫／SFX、不復播旧cue |
| 爐石標竿 | 已讀官方sound／VFX原則，以事件、材質、角色識別作方向 | 未看同一競品片段、未實際聽競品與本候選，沒有等同或百分比品質結論 |

## 驗證

完整Swift300／0（`polish-30/swift-full.log`），是P27以後首次全套收斂；旧282／277不重報當作本輪結果。正式Beta（TACTICALGO_V11、無DEBUG）主11／0skip，加toolbar文字色後小375pt2／0skip及402pt設定頁1／0skip：共14次執行、11種方法。主11來源保存BETA_MAIN_SOURCE_PIN及當時PlayableGameView，最終唯一runtime差異是聲音完成鈕foreground，補測對應頁及返回固定棋盤；没有宣稱11全在最後同一binary重跑。

Beta涵蓋真正入口、四職固定版面、沿棋群築壘／調度己兵、三職第二招、牧師奉獻、主将／魔物／戰利、黑先／白後與標準AI、Undo跨AI／resume、音量保存。DEBUG22真volume檢查＋49音訊檢查來源未變，沿用P29B，不宣稱是本轮Beta內跑的71項或71個UI方法。Actor／音檔來源与Domain／Bot不改，不等於完整對局策略／平衡已驗收。

54份PresentationLab素材byte對source及1108相同；兩怪編譯解碼像素對原始素材與1108皆相同。codesign strict、development get-task-allow、P358EB3X9H及Owner註冊裝置／profile有效、1.1／1109／herobody核對PASS。274來源固定、簽名binary SHA及source pin SHA保存SIGNED_BUILD；check-only只核對簽名與來源，没有接觸／安裝手機。

installer5個手寫文件／plist／receipt pass-fail fixture通過，非真機交付；時間窗gate提早呼叫exit75、没有手機操作。正式脚本`python3 scripts/install-polish30-wifi.py`要求先兩個fresh備份成功，才會安裝；保留安裝、啟動、手機版本、前後數據的獨立界線。launch／後複製失敗也不抹除實際成功安裝紀錄。再次執行前先看既有install-*/RESULT，成功交付不重複更新。

## 保留失敗及尚缺

首P30 native誤用了Debug的xctestrun，發現target為prototype後手動中斷exit73；`BetaMain.xcresult`／beta-main.log只作錯誤來源紀錄，不能算Beta。更正使用TacticalGoBeta_iphonesimulator清單，實際herobody11通過。首兩PNG驗證錯給不存在的ios圖路徑，Swift工具NativePNG Code1（不是App crash）且沒生成JSON，保留first-pixel-path，個別exit當時未捕捉；後以實際assets路徑分開重新驗證，四份equal=true才列圖像PASS。P29B遞迴崩潰及P28／P29之前失敗仍保留，不加總通過數。

沒有真機聲畫錄影／FPS／物理AV延遲、獨立真人美術／聲音／玩法驗收、密集盤面所有極端遮擋、任意用户最大音量疊音削波保證。30對離線同響度試聽不能冒充手機錄音，無聲原生影片不能證明音畫物理同步。P30準備完成不等於十小時任務已包含手機交付／Owner品質通過。

1108原簽名App與258份基準来源留在polish-27／ux-26；可供需要時核對回退，未在本窗口執行回退，不宣稱已驗回退安装流程。只在指定worktree保留dirty，未改另一1.0checkout、技能規則／費用／Bot、未Git commit/push/merge或TestFlight。後續來源未變保持安靜，不為剩餘時間新增玩法或重複測試。

## 實際交付檢查（UTC01:42:43）

iPhone配對存在但本次unavailable，tunnel unavailable；窗口末installer在Wi-Fi連線階段退出，installAttempted=false。額外有界device info apps也exit1／CoreDeviceError1011無法找到裝置，沒有備份或手機更新；最後實際核對版本是1108，不能推論現在已裝1109。保存兩種1109簽名結果。Owner另授權TestFlight，distribution核對完成，但兩次上傳exit70 Failed to Use Accounts，Apple尚未收到；已開Xcode原開發者登入入口。
