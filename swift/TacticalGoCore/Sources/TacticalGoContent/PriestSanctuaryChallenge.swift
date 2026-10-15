import TacticalGoCore

/// A reachable two-eye rescue. Construction uses the public engine from a normal opening.
/// The alternative of filling the sole eye is suicide; remote reinforcement alone does not save the group.
public enum PriestSanctuaryChallenge {
    public static let priest = Point(3,2)
    public static let originalEye = Point(2,3)
    public static let sacrifice = Point(4,3)
    public static let reinforcement = Point(4,6)
    public static let action = GameAction.castOffering(sacrifice)
    public static let brief = "牧師棋群只剩一口氣。能否犧牲一兵救回牧師？試著比較普通落子。"
    public static let hint = "內部已有 C4 一眼。讓 E4 的己兵奉獻，能形成兩個互不相鄰的真眼；不會在別處補子。"
    public static func session(cost: Int = 4) throws -> GameSession {
        var config = RuleConfig.board(size:9)
        config.expansionSkills = true; config.expansionSkillManaCost = cost
        var s = GameSession(try GameSetup.newGame(config:config,classOne:.priest,classTwo:.mage))
        func apply(_ a: GameAction) throws {
            guard s.apply(a).success else { throw ExpansionPracticeError.illegalOpening }
        }
        func turn(_ player: Player) throws {
            if s.state.current != player { try apply(.endTurn) }
        }
        try apply(.placeSoldier(Point(3,3)))
        try turn(.one)
        try apply(.summonHero(priest))
        // Complete the inner rectangle before its surrounding ring closes.
        for y in 2...4 { for x in 1...5 {
            let p = Point(x,y)
            if p == priest || p == originalEye || s.state.board[p] != nil { continue }
            try turn(.one); try apply(.placeSoldier(p))
        } }
        // White commander E2 already forms part of the surrounding top edge.
        for y in 1...5 { for x in 0...6 where x == 0 || x == 6 || y == 1 || y == 5 {
            let p = Point(x,y)
            if s.state.board[p] != nil { continue }
            try turn(.two); try apply(.placeSoldier(p))
        } }
        try turn(.one)
        guard s.state.board.liberties(at:priest) == [originalEye],
              GameEngine.validate(s.state,action) == .none else { throw ExpansionPracticeError.illegalOpening }
        return s
    }
    /// A real reply keeps the rescue from being mistaken for permanent immunity.
    /// White has summoned H4; the next move can fill E4 by pushing black F4 left,
    /// exposing F4 next to the white ring. Two liberties then cease to be two true eyes.
    public static let counterAction = GameAction.castMagicHand(Point(5,3),.left)
    public static func counterSession(cost: Int = 4) throws -> GameSession {
        var s = try session(cost:cost)
        for a in [action,.endTurn,.summonHero(Point(7,3))] {
            guard s.apply(a).success else { throw ExpansionPracticeError.illegalOpening }
        }
        guard GameEngine.validate(s.state,counterAction) == .none else { throw ExpansionPracticeError.illegalOpening }
        return s
    }
    public static func solved(_ state: GameState) -> Bool {
        state.board[priest] == Piece(.one,.hero) &&
        state.board.liberties(at:priest) == [originalEye,sacrifice]
    }
}
