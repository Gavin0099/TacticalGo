# S2｜三職召喚

結果：三職原生召喚、成功收據語音及復原操作完成。
原因：沿用 MotionPlan 與既有 sprite adapter，單一450–460ms出現／落定；沒有新增角色 Mesh 或規則。
下一步：保留正式美術、聲音及實體手勢驗收 Pending，繼續魔法之手與輕量技能演出。

原生 SwiftUI CozyBoard 於成功召喚以0.62→1比例、淡入、小幅離地落定及局部雙圈呈現原 B-v02；halo 最大0.82格，不改圖片身份。真正 Core state 已結算一次，畫面只是 receipt before/action/events/after 的呈現。無效／取消不建成功 receipt。召喚演出約0.46秒解鎖，Voice可以繼續，普通第二AP不截斷語音。Reduced Motion直接呈現正確落定，不等動畫或靜音。復原清除過期演出並重播Core回到2AP。

驗證：S2-native-final.log／xcresult：2 tests / 0 failures。testThreeHeroSummonsAreRealNativeActionsWithVoiceAndUndo 逐職真實點選空點、預覽2AP、確認1AP、正確語音key、復原2AP；HeroVoiceActualOwner audit仍64項PASS。S2-screens 是真正Simulator截圖；此時尚非實體iPhone錄影／人耳美術驗收。

保留初始SwiftUI builder及import build失敗紀錄、stale product測試中止紀錄，成功結果只取 S2-native-build-r3.log 與 S2-native-final。工程驗證當時的Apple本機語音僅歷史試驗；推送前會以已記錄來源的替代TTS素材重跑影音測試。沒有把歷史音檔授權升格為發布許可。
