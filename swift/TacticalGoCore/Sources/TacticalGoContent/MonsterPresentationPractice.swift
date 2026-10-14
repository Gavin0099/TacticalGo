import TacticalGoCore

/// Reachable recording fixtures, not hand-placed proofs of gameplay value.
public enum MonsterPresentationPractice: String, CaseIterable, Sendable {
    case slimeHunt = "slime-hunt", slimeLoot = "slime-loot"
    case wolfHunt = "wolf-hunt", wolfLoot = "wolf-loot"
    public var kind: MonsterKind { self == .slimeHunt || self == .slimeLoot ? .slime : .shadowWolf }
    public var isHunt: Bool { self == .slimeHunt || self == .wolfHunt }
    public var action: GameAction {
        switch self {
        case .slimeHunt,.wolfHunt: .huntMonster(Point(4,4))
        case .slimeLoot: .useStickyBounce(anchor:Point(3,3),target:Point(3,4))
        case .wolfLoot: .useShadowStep(Point(3,2))
        }
    }
    public var points: [Point] {
        switch self {
        case .slimeHunt,.wolfHunt: [Point(4,4)]
        case .slimeLoot: [Point(3,3),Point(3,4)]
        case .wolfLoot: [Point(3,2)]
        }
    }
    public func session() throws -> GameSession {
        var config = TacticalHints.updatedConfig(size:9)
        config.monsterBattlefield = .init(huntAPCost:1,kind:kind,awardsLoot:true)
        var session = GameSession(try GameSetup.newGame(config:config,classOne:.warrior,classTwo:.mage))
        var opening: [GameAction] = kind == .slime
            ? [.placeSoldier(Point(3,4)),.placeSoldier(Point(0,0)),.endTurn,.placeSoldier(Point(5,4))]
            : [.placeSoldier(Point(3,5)),.placeSoldier(Point(0,0)),.endTurn,.summonHero(Point(3,4)),.endTurn,.endTurn,.placeSoldier(Point(5,4))]
        if !isHunt {
            opening += [.huntMonster(Point(4,4)),.endTurn]
            if kind == .slime { opening.append(.placeSoldier(Point(3,3))) }
        }
        for a in opening { guard session.apply(a).success else { throw ExpansionPracticeError.illegalOpening } }
        guard GameEngine.validate(session.state,action) == .none else { throw ExpansionPracticeError.illegalOpening }
        return session
    }
}
