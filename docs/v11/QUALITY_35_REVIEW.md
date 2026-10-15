# Quality35：1112已上傳、品質證據與待核實

Owner最新回覆「推上testflight」，已先交付已收斂候選。1.1/1112於Xcode Organizer明示上傳成功，XCODE_UPLOAD_SUCCESS.png及GUI_UPLOAD_RESULT.json保存；首CLI exit70失敗保留，未因此重建。GUI實際上傳IPA另匯出，版本／bundle／54演出檔、其他Audio、兩怪／隱私／簽名／distribution profile均核對。GUI recommended manageBuildNumber=true，实际仍1112；zip SHA與原私有匯出不同，分開記錄，沒有冒稱同一IPA。279來源未變。

ASC網頁reload顯示authResult=FAILED／密碼登入頁；已請Owner登入以核實Apple處理與Owner1.1群組。最後要將Chrome帶到前景時Mac已鎖定，無法自動解鎖；待Owner手動解鎖／登入，不嘗試繞過。現在只能稱已上傳，不能稱已可安裝。此授權不等於爐石80–90%或真人聲畫接受；完整八Slice仍有平台／人類缺口。

## 實作

- UI21：全盤合法target保留；6pt亮綠改4.5pt深青＋奶油細圈。375/402仍可見，選取圈、主將和金色確認較突出。格點hitbox／固定棋盤／200pt操作區不改。
- UI21：成功preview明說確認放兵／召喚英雄／調度己兵等實際pending行動。非法／未召喚限制保持；不再把普通放兵叫「施放」。
- ANIM25：戰士.22準備、.28短持、.34出手，對上release.34/moveStart.35；.58接觸/.64持/1.02收尾不變。最後body24°/Y60、盾28°/局部Y26，身份與底座anchor不改。
- ANIM25/UI21：四職底座前沿保留黑白材質＋既有形狀glyph；只是前半底邊，無額外hit/VoiceOver物件。
- AUDIO25/SYNC25：每玩家／職業首個合格成功技能可播原英B，balanced後至少隔兩招與12秒，全局cadence判斷3秒；静音／關語音／0音量／preview／非法不消耗。缺player或排程失敗不消耗，實際play(atTime:)返回false分支未人工誘發。
- AUDIO25/SYNC25：快速Rogue→endTurn→Mage不截斷上一句，也不重疊新句；每cue在尾音結束後恢復完整SFX量。Undo／背景／terminal全停。原WAV、MageD/英B、Warrior英B和BGM身份保留。
- POLISH27：勝因只從outcome主將被提事件＋正式winner顯示「白方主將已被提，黑方獲勝」。不是畫面推論；Undo不殘留這句。

## 比較及失敗

第一輪本體動作差異小，影片取樣近似，不稱重量成功。第二輪盾Y60在7白／9兩方接觸穿到底座下，獨立review拒用；收為Y26後16精確receipt圖確認明顯穿出台下已消除，7白.58仍有底座厚度內細楔邊。未見新的臉／手／道具斷开或鄰兵遮擋，這是靜圖判斷，非動態／真人品質。

reviewer同局9-preview判改善，mage-preview／原victory持平；新確認／勝因文字判資訊改善。375最終新文字已由主代理查看：一行完整、確認／復原／再玩按鈕不遮蔽。iPad原生四職方法已PASS，截图另保存；不外推真機或放大字體。

首誤用Beta缺DEBUG診斷3fail、初fixture召喚不鄰兵、quiet後倒退時鐘缺守門、zero-duration endTurn待cleanup導致下招切斷尾音、非法newGame先reset cadence、Y60穿底座，均保存原失敗。已修：lastEligibleTime、合法前置、零時長receipt保留尾音、成功新局才reset、盾局部Y26。

## 驗證

| 實際證據 | 結果／邊界 |
|---|---|
| shield-fixed-full-swift-tests.log | 最新Swift310/0；iOS文案另原生驗 |
| context-final-beta-main/Sequence.xcresult | 402正式Beta1/0/0，7/9完整正常首頁→preview/cancel→召喚→調度→提主將→勝負→Undo；三種確認文案／勝因assert；12圖、96.53秒正常速度無聲raw |
| ContextSmallFinalBeta.xcresult | 375同最新完整7/9序列1/0/0，12圖 |
| SmallFinalBeta.xcresult | 最新文案前、現用盾／聲音的375四方法4/0/0：四職固定盤/200pt/44pt、合法点／限制、兩怪討伐／戰利／resume、完整序列；非同一最後batch |
| FinalIPadBeta.xcresult | 最新Beta四職固定棋盤／dock／44pt／preview/help/handoff/Undo1/0/0，Simulator portrait，不是實機／橫向 |
| zero-handoff-audio-native/integrated-cadence-final-audit.json | native實際player54項皆PASS，合法快速交棒／每cue gain／非法新局保留頻率；文案前、後續audio邏輯未變；固定audit clock不是長局疲勞 |
| volume22／既有audio49 | 在zero-handoff版本各自原生重測PASS，不合成另一統一batch |
| warrior-exact-shield-fixed/FRAMES.json | 16成功精確静態receipt，9兩方5phase、7兩方出手／接觸、9兩方Reduced；人工擺盘，不作自然開局可達證明 |
| final-skill-native/RECORDINGS.json | 最終文案前，現用盾／audio的四職7招＋兩怪討伐／loot共11成功正常速度silent；兩本體片另存；不是每招非法／中斷／Reduced全矩陣 |
| release/VERIFIED_PACKAGE.json | 1112 App Store簽名/匯出、279源、54演出檔、兩怪解碼像素、隱私、internal-only、73原藝聲檔及5Core/Bot對1111未變 |

首輪112秒基線保持baseline-native-main；最新版完整片段是context-final-beta-main。compare/warrior-corrected-native-crops.png為同UI／同結果的精確靜圖，不能當影片。warrior-exact-final及warrior-exact-pose-sheet.png是拒用Y60；原檔保留不能交作最佳。

## 八Slice狀態

| Slice | 本輪已保存 | 未完成 |
|---|---|---|
| PRES00 | 凍結1111與1106歷史映射、正常7/9完整片段／來源 | 原始真機含聲 |
| UI21 | 合法点／確認／勝因／陣營前沿、375/402、iPad portrait | 真機、DynamicType／VoiceOver、無提示第一視線 |
| ANIM25 | 戰士三輪與現用接觸修正、法師D保留 | 動態重量／十次出手人類評審 |
| AUDIO25 | 低頻英B／逐cue混音／來源与原檔 | 喇叭／耳機、Rogue/Priest演技盲聽 |
| SYNC25 | confirmed receipt／cancel、快速尾音／失败路径 | 真機50ms量測 |
| ANIM26 | 11成功片、共用底座、戰士Reduced密集圖 | 每招非法／中斷／Reduced原生全矩陣、人類視聽 |
| POLISH27 | 勝因／Undo、完整合法對局 | 三局疲勞及高光評審 |
| QA28 | Swift／Beta／簽名／來源／failure保留 | 真機P95、觸控、至少3位無提示玩家 |

iPhone仍unavailable，Owner改先TestFlight。本輪不存在80–90%評分或八Slice全部PASS。未改Core戰鬥/AP/Mana/Bot/存局；不commit/push/merge、其他checkout不動、heartbeatPAUSED。Owner盜賊新局缺牌未重現、牧師一般局價值仍開放，不把聲畫改善說成全部玩法已修。
