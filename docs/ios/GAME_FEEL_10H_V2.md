# GAME-FEEL-10H-v2

Owner 2026-10-10 授權本輪最多約10小時：S0基線、S1六句英文語音、S2英雄召喚、S3魔法之手、S4輕量三職技能、S5棋子回饋、S6原生回歸、S7提交／push／交付。UI繁中；不得修改Core、Domain、Bot决策、技能效果、第二技能、角色身份。可逐Slice獨立驗證及提交並push隔離分支；不可merge、TestFlight或發布。配音使用本機可替換Prototype，不模仿既有配音员，不上传原画／收费API。正式BGM與人耳／美術核准仍Pending，接線支援聲音避讓不自行將HOLD音樂正式啟用。

分支 codex/game-feel-voice-01；沿用已附工作樹 cozy-02-integration，原 Cozy 分支快照保留。基線 main cdab133 加上本輪前已驗證、尚未提交的Cozy02原生接線；S0提交将其保存，後續Slice只新增聲画。

| Slice | 優先／預算 | 狀態／Gate |
|---|---|---|
| S0 | P0／0.5h | 已盤點；固定Cozy02现有成功收据／8:9投影／11SFX／151Swift及38Golden歷史證據，保留手機XCTest啟動阻擋 |
| S1 | P0／2h | 工程PASS：6句本機Prototype、獨立Voice設定、雙方6種成功事件、取消／不疊加、音量隔離及實際owner BGM duck；4個Package與2個原生測試通過。正式聲線Pending |
| S2 | P0／1.5h | 待開始：三職真實召喚450–550ms，语音不锁整句 |
| S3 | P0／2h | 已有ANIM01可重用；補語音、雙方士兵、預覽取消與真機／錄影證據 |
| S4 | P1／1h | 待開始：已有MotionPlan築壘／換位，延用輕量原生渲染 |
| S5 | P1／1h | 待開始：已有drop/capture cue，接真人提交receipt，主將退場更清楚 |
| S6 | P0／1.5h | 必須保留：Package/Golden/Release、phone/pad、7/9、兩AP、Bot/儲存/取消/Reduced/聲音設定；真機缺失列Pending |
| S7 | P0／0.5h | 必須保留：逐Slicecommit、push隔離分支、來源SHA、實際原生影片、實體與模擬器分開；完成後停止 |

已存在：CozyBoard及語意色，B2-B／原B-v02 frozen images、來源hash、成功MagicHand80/220/100ms＋條件提子、真實owner播放器快取、取消／背景／復原、Reduced靜態結果、電腦逐手舊渲染、獨立SFX與HOLD BGM。缺少：英文VO素材及Voice控制、一般真人召喚／築壘／換位／落子完整輕量動畫接線、當前版手機實體手勢／影片。不得為上述再建第二套規則或投影。

驗證來源：artifacts/ios/cozy-02-integration/REPORT.md為本輪前歷史結果（151／38／3905／SE1／iPad2／手機實際player17）。本輪新結果另記 artifacts/ios/game-feel-voice-01；不把歷史報告「未提交」改成當時已有提交。手機最新Wi-Fi tunnel unavailable，即使list為paired/available亦不能宣稱實際可連；不中止可獨立進行的原生模擬器開發。
