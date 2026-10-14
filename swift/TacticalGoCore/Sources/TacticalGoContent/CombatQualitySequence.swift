import TacticalGoCore

/// A short, reachable presentation comparison, replayed from an ordinary opening.
/// It does not add a game mode, change rules, or prove competitive balance.
public struct CombatQualitySequence: Sendable {
    public let size: Int
    public init(size: Int) { precondition(size == 7 || size == 9); self.size = size }
    public var source: Point { Point(size / 2 + 1, size - 2) }
    public var hero: Point { Point(size / 2 + 1, size - 3) }
    public var destination: Point { Point(size / 2, size - 3) }
    public var enemyCommander: Point { Point(size / 2, 1) }
    public var initial: GameState {
        get throws { try GameSetup.newGame(config: TacticalHints.updatedConfig(size: size), classOne: .mage, classTwo: .mage) }
    }
    public var actions: [GameAction] {
        let c = size / 2
        return [.placeSoldier(source), .placeSoldier(Point(0, 0)), .endTurn,
                .summonHero(hero), .placeSoldier(Point(c - 1, 1)),
                .placeSoldier(Point(size - 1, size - 1)), .endTurn,
                .castFriendlyRedeploy(source, destination), .placeSoldier(Point(c, 0)),
                .placeSoldier(Point(0, 1)), .endTurn,
                .placeSoldier(Point(c + 1, 1)), .placeSoldier(Point(c, 2))]
    }
}


/// Two different classes can cast across a quick turn handoff, from a legal opening.
public enum CombatVoiceHandoff {
    public static let first: GameAction = .castSwap(Point(5,4))
    public static let second: GameAction = .castFriendlyRedeploy(Point(4,4),Point(3,4))
    public static func session() throws -> GameSession {
        var session = GameSession(try GameSetup.newGame(config:TacticalHints.updatedConfig(size:9),classOne:.rogue,classTwo:.mage))
        let opening:[GameAction] = [.placeSoldier(Point(4,5)),.placeSoldier(Point(5,4)),.placeSoldier(Point(5,3)),
                                    .summonHero(Point(4,4)),.endTurn,.summonHero(Point(4,3)),.endTurn]
        for action in opening { guard session.apply(action).success else { throw ExpansionPracticeError.illegalOpening } }
        guard GameEngine.validate(session.state,first) == .none else { throw ExpansionPracticeError.illegalOpening }
        return session
    }
}
