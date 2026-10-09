import TacticalGoCore

/// Deliberately cooperative, hand-authored full matches for motion continuity QA.
/// Every step starts from newGame and goes through the unchanged rule engine.
/// These examples do not establish strategic quality or balance.
public enum MatchExample: String, CaseIterable, Sendable {
    case warriorMage = "戰士／法師"
    case rogueWarrior = "盜賊／戰士"

    public func initialState() throws -> GameState {
        var config = RuleConfig.board(size: 7); config.mageSkill = .seal
        return try GameSetup.newGame(config: config,
            classOne: self == .warriorMage ? .warrior : .rogue,
            classTwo: self == .warriorMage ? .mage : .warrior)
    }
    public var actions: [GameAction] {
        switch self {
        case .warriorMage:
            [.summonHero(Point(3, 4)), .summonHero(Point(3, 2)), .placeSoldier(Point(6, 6)),
             .castBastion(Point(2, 4), Point(4, 4)), .placeSoldier(Point(3, 3)),
             .castSeal(Point(2, 2)), .placeSoldier(Point(6, 5)),
             .placeSoldier(Point(2, 1)), .placeSoldier(Point(4, 1)),
             .placeSoldier(Point(0, 0)), .placeSoldier(Point(1, 0)),
             .placeSoldier(Point(2, 2)), .placeSoldier(Point(4, 2)),
             .placeSoldier(Point(0, 1)), .placeSoldier(Point(1, 1)), .placeSoldier(Point(3, 0))]
        case .rogueWarrior:
            [.summonHero(Point(3, 4)), .summonHero(Point(3, 2)), .placeSoldier(Point(4, 4)),
             .castSwap(Point(4, 4)), .placeSoldier(Point(6, 0)),
             .castBastion(Point(2, 2), Point(4, 2)), .placeSoldier(Point(2, 5)),
             .placeSoldier(Point(6, 1)), .placeSoldier(Point(6, 2)),
             .placeSoldier(Point(4, 5)), .placeSoldier(Point(3, 6))]
        }
    }
}
