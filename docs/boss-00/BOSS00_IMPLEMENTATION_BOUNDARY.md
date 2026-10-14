# BOSS-00｜未來 BOSS-01 的邊界（未授權）

本輪沒有修改以下路徑。BOSS-01 需 Owner 先核准規則並另行開工，不能因文件齐全就自動開始。

| 未來表面 | 所需改變 / 不可取代的證據 |
|---|---|
| TacticalGoCore/Model.swift、GameEngine.swift | explicit boss mode/environment state、限制合法性、原子轉移收據；original defaults全不變 |
| TacticalGoRecords | 新模式版本/環境journal；拒絕旧reader静默忽略；原存檔無migration、存儲隔離 |
| TacticalGoBot / scripted opponents | 相同公開phase資料；不能只在UI隱藏合法點；固定Budget可重現 |
| Motion / GameStore / CozyBoard | 成功收據播放；预告常驻、Reduced Motion清晰；不以timer推進 phase |
| C#/Swift Golden | original38組不變；future boss需要新增跨平台固定收據，不能只測Swift特例 |

先行測試矩陣：第一1AP豁免、双方2AP與提前end、限制空點仍計氣、召喚/兩點築壘原子拒絕、法師/盜賊移動與封印衝突、每個phase保存恢复/復原、終局優先於環境轉移、非法不扣費、画面离开/背景不觸發、固定方向循環、Bot與人同資訊、原版journal逐字/語義不變。

高風險推擠還需閉合：同時位移或順序、占用/盤外、整串/單子、己敌提子、禁止自殺、雙主將死亡、Ko history歸屬、勝方、玩家反應窗口。缺任一項就HOLD。

Gate：設計材料已足以作決策；MVP方向與產品價值仍OPEN。无程式、無龍模型、無新技能或平衡模擬。
