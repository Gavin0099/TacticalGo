import TacticalGoCore

/// Internal 1.2 prototype: familiar legally reached positions, a longer objective horizon.
/// Unlike C03, the player must endure the final enemy reply before success is assessed.
public enum ExpeditionCatalog {
    public static func all() throws -> [TutorialScenario] {
        let titles = ["守住補給線", "突破後守住戰果", "出手後的退路"]
        let goals = [
            "兩輪攻防後，主將與戰士都存活。選擇：向外拓路，兩群各至少五氣；或守住 D7 據點，兩群各至少三氣。",
            "三輪攻防後，累計提走至少兩名敵兵，主將與法師各至少三氣。",
            "三輪攻防後，累計提走至少兩名敵兵，主將至少三氣、盜賊至少兩氣。"
        ]
        return try AdvancedCatalog.all().enumerated().map { index, source in
            return TutorialScenario(id: "tg12-expedition-\(index + 1)", title: titles[index],
                instructions: [goals[index], "完成本關所有敵方反擊後才結算；提前達標仍需守住。每場獨立，不繼承資源。"],
                optionalHints: index == 0 ? [
                    "D7 是據點：築壘能同時補上 E6 與 D7，但要花能量；普通落子可以把行動用於向外拓路。",
                    "對手會優先壓縮主將的氣；在遠方丟孤兵不應讓它放棄封鎖。",
                    "每次反擊後重新看出口，最後仍須守住三氣加據點，或拓出五氣。"
                ] : source.optionalHints + ["不要急著填滿自己的氣。達標後仍要預留兩手反擊的空間。"],
                heroClass: source.heroClass, goal: source.goal, sourceActions: source.sourceActions,
                branches: [], expeditionTurns: index == 0 ? 2 : 3)
        }
    }
}
