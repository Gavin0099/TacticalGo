import TacticalGoCore

/// Three original-rule scenarios with a full official opening replay. The six introductory
/// scenarios stay unchanged; accepted actions, not matching an answer sequence, decide success.
public enum AdvancedCatalog {
    public static func all() throws -> [TutorialScenario] { try [rescue(), counterattack(), timing()] }
    private struct Source {
        var state: GameState
        var actions: [GameAction] = []
        init(_ hero: HeroClass) throws {
            state = try GameSetup.newGame(config: .board(size: 7), classOne: hero, classTwo: .none)
        }
        mutating func add(_ owner: Player, _ action: GameAction) throws {
            if state.current != owner { try append(.endTurn) }
            try append(action)
        }
        mutating func append(_ action: GameAction) throws {
            let result = GameEngine.apply(state, action)
            guard result.success else { throw TutorialError.illegalSource(id: "advanced source", step: actions.count, reason: result.reason) }
            state = result.state; actions.append(action)
        }
        mutating func soldiers(_ owner: Player, _ points: [Point]) throws {
            for p in points { try add(owner, .placeSoldier(p)) }
        }
        mutating func ready() throws -> [GameAction] {
            if state.current == .one && (state.apRemaining != 2 || state.skillUsedThisTurn) { try append(.endTurn) }
            if state.current == .two { try append(.endTurn) }
            return actions
        }
    }
    private static func rescue() throws -> TutorialScenario {
        var source = try Source(.warrior)
        try source.soldiers(.one, [Point(5, 6)])
        try source.add(.one, .summonHero(Point(4, 6)))
        try source.soldiers(.two, [Point(2, 5), Point(3, 4)])
        return TutorialScenario(id: "c03-1-commander-rescue", title: "守住下一回合", instructions: ["黑方主將遭夾攻。先建立生路，再面對敵方兩次行動的追擊。", "完成兩個自己的回合：主將與戰士都存活，兩個棋群均至少保有六氣，形成能再延伸的防線。技能不是必要條件。"], optionalHints: ["不要只數眼前的氣。想想敵方連下兩兵後，主將能接到哪一群。", "右下方的英雄與己兵有外氣；築壘可省下一個行動，但不能亂填出口。", "比較先築壘連接右下，再往外延伸；下一回合要根據敵方封鎖重新選出口。"], heroClass: .warrior, goal: .advancedRescue, sourceActions: try source.ready(), branches: [])
    }
    private static func counterattack() throws -> TutorialScenario {
        var source = try Source(.mage)
        try source.soldiers(.one, [Point(3, 4)])
        try source.add(.one, .summonHero(Point(3, 3)))
        try source.soldiers(.one, [Point(5, 3), Point(4, 4), Point(2, 1), Point(2, 3), Point(1, 2), Point(4, 1), Point(5, 1)])
        try source.soldiers(.two, [Point(3, 2), Point(4, 2), Point(5, 2)])
        return TutorialScenario(id: "c03-2-feint-counterattack", title: "引出回應，再反打", instructions: ["敵兵的連線有兩個可施壓位置。製造一個威脅，觀察對方救哪一串，再完成反打。", "經過敵方回應，在自己的第二回合結束前提走至少兩名敵兵；主將與法師棋群均至少三氣。"], optionalHints: ["敵方不會站著等你提子。先想它可能補哪一口氣。", "中央連接兵與左側敵兵都在法師射程內；推兵後的原位會成為關鍵。", "比較立刻提中央兵與先製造雙威脅；第二回合再利用對手留下的另一側缺口。"], heroClass: .mage, goal: .advancedCounterattack, sourceActions: try source.ready(), branches: [])
    }
    private static func timing() throws -> TutorialScenario {
        var source = try Source(.rogue)
        try source.soldiers(.one, [Point(2, 3)])
        try source.add(.one, .summonHero(Point(3, 3)))
        try source.soldiers(.one, [Point(3, 2), Point(3, 4), Point(5, 4), Point(5, 2)])
        try source.soldiers(.two, [Point(4, 3), Point(5, 3)])
        return TutorialScenario(id: "c03-3-skill-timing", title: "出手，還是留力", instructions: ["換位能快速拆散敵兵，但英雄會進入前線。普通落子也可能達到同樣戰果。", "先選計畫，再承受敵方反擊。最多兩個自己的回合內提走至少兩名敵兵；主將至少三氣，盜賊存活且至少兩氣。比較行動效率與能量代價；氣數不是生命值。"], optionalHints: ["不要只看能不能換位。換完後，敵方兩次行動會封哪裡？兩口氣是否能合法被填，也要看周圍棋群。", "普通落子可以直接封住兩名敵兵的外氣，省下能量並保留英雄原位。", "比較 E3、E5 兩次落子誘導對方延伸，與換位 E4 再封 G4。前者要多一回合，後者花能量提高效率。"], heroClass: .rogue, goal: .advancedTiming, sourceActions: try source.ready(), branches: [])
    }
}
