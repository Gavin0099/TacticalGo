# TacticalGo 1.1 可測候選

> 最新以 [OWNER_REVIEW_14.md](OWNER_REVIEW_14.md) 為準：原選角/棋盤直接使用四職、第二技能及魔物，13版另頁入口已撤銷；牧師只犧牲、不補子。1102已簽名，手機離線尚未安裝。以下保留12/13版歷史流程與影片，不能當作14版手機交付或奉獻錄影。

結果：牧師、三職第二技能、兩種魔物與戰利能力、動畫/英文語音、試用挑戰及候選存局已整合到手機「皇冠戰略」1.1/1101測試版，普通首頁可直接進入1.1。這是手機測試版整合，沒有Git main合併、推送或公開發布。

原因：Owner要求「直接合併進去讓我測試」，因此從同一個手機App進入新玩法。新玩法保持明確啟用與獨立存局；另一agent的1.0上架來源與封存不改。工程驗證不代替真人玩法或聲音品質判斷。

下一步：開啟「皇冠戰略」→「1.1 新玩法」，試對戰、技能、魔物與聲畫。整合版安裝與啟動成功（PID35893），安裝前六份Documents檔案在更新後hash均相同，設定已備份。新技能/圖像/配音仍待真人驗收，真機聲畫錄影尚未完成。最新證據：artifacts/v11/integrated-phone-13/DELIVERY.json。08:31獨立聲畫版的成功安裝與啟動保留為歷史。

## 先試這幾項

1. 開啟「皇冠戰略」→「1.1 新玩法」→「技能試用」。下方四職按鈕載入從合法開局重播的局面，畫面會顯示選點順序。可以先試普通落子，再用新技能，按復原比較。「返回首頁」回原本選角與原規則Bot。
2. 戰士：戰線重整搬走兩顆己兵，兩个目標都有原盾牌投影與英文B「Hold the line!」。它不加子，注意原位置露出的破口。
3. 法師：雙重牽引同時移兩兵；沿用已接受D和英文B「Move aside!」。不能把另一顆兵本回合才空出的點當目的地。
4. 盜賊：連鎖換位依序點兩顆敵兵，英雄走兩段後停在第二處，看看它是否仍安全。英文「Too slow!」有A/B可切，預設B只是候選。
5. 牧師：「牧師救援挑戰」先不看提示試落子。奉獻E4己兵、E7補援會形成兩真眼；「法師反制」示範破眼回應，不是宣告黑方無法反抗。英文「Stay with me!」同樣A/B。
6. 「開始對戰」→對局設定，可選7/9、四職、第二技能4/5能量；單怪或雙怪需9×9。討伐0/1 AP可比較。魔物能力下次己方回合才解鎖，一次性1 AP/0能量，與英雄技能每回合共享一次。

目前擴充對戰是本機雙人；原規則對照入口保留舊Bot。保存/載入/復原包含AP、能量、技能鎖、魔物能力解鎖與superko重播歷史。初始新局未落子前不覆蓋上次保存。

## 正常速度影片

以下都是實際SwiftUI模擬器畫面，2.35秒正常速度；音訊是明示的後製混音。原始無聲錄影、成功Domain收據與60fps HUD對齊資料都保留。不是手機實錄或實體延遲量測；動畫檢查棋形是合法人工工程圖，不作可達關卡或平衡證据。

法師雙重牽引，390pt／7×7黑方：

![法師原生畫面＋後製英文B混音](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/feel-10/video/mage-double-390-7-native-postmix.mp4)

戰士戰線重整，390pt／7×7黑方：

![戰士原生畫面＋後製英文B混音](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/feel-10/video/warrior-reform-390-7-native-postmix.mp4)

盜賊連鎖換位，390pt／7×7黑方：

![盜賊原生畫面＋後製候選B混音](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/feel-10/video/rogue-390-7-native-postmix.mp4)

牧師奉獻救援，390pt／7×7黑方：

![牧師原生畫面＋後製候選B混音](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/feel-10/video/priest-390-7-native-postmix.mp4)

密集9×9白方、小棋盤版本：[盜賊](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/feel-10/video/rogue-320-9-white-dense-native-postmix.mp4)、[牧師](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/feel-10/video/priest-320-9-white-dense-native-postmix.mp4)。

## 新語音A/B

這些是兩秒離線候選混音，不是遊戲錄音；原始dry/raw均留存。關閉英文語音仍有衣料/工具/落定音，靜音會取消所有排程。法師和戰士保留已選B。

盜賊A：

![Too slow A](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/assets/candidates/feel-10/audio/rogue-A-mix.wav)

盜賊B：

![Too slow B](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/assets/candidates/feel-10/audio/rogue-B-mix.wav)

牧師A：

![Stay with me A](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/assets/candidates/feel-10/audio/priest-A-mix.wav)

牧師B：

![Stay with me B](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/assets/candidates/feel-10/audio/priest-B-mix.wav)

## 驗證與待辦

Swift完整235項通過，來源在該輪後未變；27項不同原生UI測試通過（擴充8、魔物7、法師8、戰士4）。取消、復原、靜音、關閉語音、背景/中斷、減少動態、預覽不動盤面、存局重播、救援/反制与定格檢查涵蓋在內。Debug、Release、簽名真機build與獨立候選安裝通過，Release排除候選素材。

最終可核對證据：[delivery-verification.json](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/feel-10/delivery-verification.json)、[canonical receipt](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/feel-10/delivery-evidence-receipt.json)、[原生圖像檢查](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/artifacts/v11/feel-10/NATIVE_VISUAL_REVIEW.md)。來源：[素材清單](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/assets/candidates/feel-10/CREDITS.md)、[D&D與爐石設計參考](/Users/pc49-58/.codex/worktrees/v11-monster-battlefield/TacticalGo/docs/v11/DESIGN_REFERENCES_12.md)。

待驗收：技能趣味、反制空間、4/5能量與0/1 AP取捨；牧師小尺寸辨識；盜賊/牧師英文演技、四職聲音與動畫整合；單怪/雙怪是否分散主將攻防。沒有正式Bot支援、新素材最終採用、真機聲畫錄影或上架完成的宣稱。
