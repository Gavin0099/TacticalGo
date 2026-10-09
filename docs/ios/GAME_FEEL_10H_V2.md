# GAME-FEEL-10H-v2

Owner 2026-10-10 授權本輪最多約10小時：S0基線、S1六句英文語音、S2英雄召喚、S3魔法之手、S4輕量三職技能、S5棋子回饋、S6原生回歸、S7提交／push／交付。UI繁中；不得修改Core、Domain、Bot决策、技能效果、第二技能、角色身份。可逐Slice獨立驗證及提交並push隔離分支；不可merge、TestFlight或發布。配音使用本機可替換Prototype，不模仿既有配音员，不上传原画／收费API。正式BGM與人耳／美術核准仍Pending，接線支援聲音避讓不自行將HOLD音樂正式啟用。

分支 codex/game-feel-voice-01；沿用已附工作樹 cozy-02-integration，原 Cozy 分支快照保留。基線 main cdab133 加上本輪前已驗證、尚未提交的Cozy02原生接線；S0提交将其保存，後續Slice只新增聲画。

| Slice | 工程狀態 | 產品邊界 |
|---|---|---|
| S0 | PASS／17542ec | 已保存此前 Cozy 原生基線 |
| S1 | PASS／630c40b | 六句 V3 Piper Prototype；正式聲線 Pending |
| S2 | PASS | 三職 460ms 真實召喚／語音／第二 AP／復原 |
| S3 | PASS | 真實魔法之手／雙方／取消／條件提子與勝負 |
| S4 | PASS | 戰士兩兵同步落定／盜賊雙向換位，不改技能 |
| S5 | PASS | 普通落子／提子／主將退場 |
| S6 | PASS（可用工程環境） | Package156／Golden38組99步／phone22／SE2／iPadV3 4；真機 V3 前景／聽感 Pending |
| S7 | 工程交付，push 以 DELIVERY.json 為準 | 原生 Simulator 影片＋明示後製音軌；無 merge／發布 |

已存在：CozyBoard及語意色，B2-B／原B-v02 frozen images、來源hash、成功MagicHand80/220/100ms＋條件提子、真實owner播放器快取、取消／背景／復原、Reduced靜態結果、電腦逐手舊渲染、獨立SFX與HOLD BGM。缺少：英文VO素材及Voice控制、一般真人召喚／築壘／換位／落子完整輕量動畫接線、當前版手機實體手勢／影片。不得為上述再建第二套規則或投影。

驗證來源：artifacts/ios/cozy-02-integration/REPORT.md為本輪前歷史結果（151／38／3905／SE1／iPad2／手機實際player17）。本輪新結果另記 artifacts/ios/game-feel-voice-01；不把歷史報告「未提交」改成當時已有提交。手機最新Wi-Fi tunnel unavailable，即使list為paired/available亦不能宣稱實際可連；不中止可獨立進行的原生模擬器開發。

最新證據：artifacts/ios/game-feel-voice-01/REPORT.md、DELIVERY.json。iPhone Wi-Fi 已安裝獨立 Hero Voice 0.8.0（802），Locked 阻擋前景啟動；iPad本輪為模擬器。正式BGM、美術與Owner產品Gate仍Pending，完成工程交付後停止新增Slice。
