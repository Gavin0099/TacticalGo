# VO-01 / S1

結果：六句英文Prototype及成功事件接線完成，原生實際播放器驗證通過。
原因：延用畫面持有的CombatAudio及成功收據；每職一致声線、Voice與SFX/BGM分開，沒有新規則或雲端服務。
下一步：S2召喚動畫及S3完整魔法之手；正式聲音品質及商用權利待Owner，不合併或發布。

改用離線Piper 1.8.0／LibriTTS high，匿名speaker index 0／1／2逐職固定，非真人演員配音。6句約0.6–1.1秒、6個SHA相符、0PCM clipping；來源模型訓練卡及資料集CC BY 4.0歸屬見CREDITS.md。逐職台詞与來源见 ios/TacticalGo/Audio/Voice/manifest.json；無外部API／樣本／原畫上傳／既有英雄聲線模仿。界面繁中。

HeroVoiceCue由before.current職業及成功outcome選台詞，首回合/最後AP切到對方也不會選錯職業。獨立Voice開關／音量，全域靜音及系统静音仍生效。SFX或BGM音量0不會关Voice；普通第二AP不重播或切斷已確認語音。全域只播一条，不排隊；復原／重開／離場／背景／中斷取消過期語音。預覽、取消、非法、不含英雄的普通落子不觸發台詞。

本輪Focused Package4/0；原生Simulator2/0：原Cozy實際owner audit17項仍PASS，新HeroVoiceAudit 64項PASS，涵蓋3職×召喚/技能×黑白施放、失敗與取消、Voice/SFX/Music獨立性、過期播放、普通第二AP及6個有界玩家快取。影片與真機驗證仍在S6，不把此結果宣稱實體手機手勢或人耳驗收。

既有BGM正式HOLD，正常候選不自動啟用。本輪DEBUG --voice-bgm-audit僅用同畫面真正owner播放既有B曲以驗證語音時−5dB平滑避讓和恢復；無新音樂素材，非正式曲風/發布核准。

證據：S1-package-focused-final.log、S1-native.log／xcresult、S1-hero-voice-audit.json、S1-cozy-runtime-audit.json、S1-source-check.json。保留最初rawValue大小寫檔名失配與audit switch未含none的失敗紀錄；修正後才進此Gate。未修改Core、Bot決策、技能或角色素材。

推送前修正：Apple macOS Tahoe SLA 2F不允許System Voice輸出公開分享；早期Apple本機試驗音檔已從此未推送提交替換。原S1-native為歷史接線驗證，Piper素材的新原生結果將另以S6 final及更新audit JSON確認。Piper只在本機產檔，engine／模型／Python不打包進App。原公開模型及資料集條款來源已留存；不宣稱完整商用權利或演員品質核准。

最後素材 VO-01-prototype-v3-piper-seeded 已於 S6 iPad4／phone focused2 及七個成功操作的錄影重驗，actual owner Voice64 PASS。六檔兩次独立進程同SHA，S1-repro-check.json；舊Apple接線測試不作現行音檔證據。真機與聲線品質仍Pending。
