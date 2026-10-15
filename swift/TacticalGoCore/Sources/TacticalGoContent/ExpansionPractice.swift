import TacticalGoCore

/// Demonstrations replayed from a normal legal opening; not hand-placed puzzle proofs of balance.
public enum ExpansionPractice: String, Sendable, CaseIterable {
    case warrior, mage, rogue, priest
    public var hero: HeroClass {
        switch self { case .warrior: .warrior; case .mage: .mage; case .rogue: .rogue; case .priest: .priest }
    }
    public var action: GameAction {
        switch self {
        case .warrior: .castReformation(.init(Point(4,6),Point(5,5)),.init(Point(5,6),Point(6,6)))
        case .mage: .castDoublePull(.init(Point(4,5),Point(5,5)),.init(Point(4,3),Point(3,3)))
        case .rogue: .castChainSwap(first:Point(5,4),second:Point(5,3))
        case .priest: .castOffering(Point(4,5))
        }
    }
    public var instruction: String {
        switch self {
        case .warrior: "選 E7 → F6，再選 F7 → G7。搬走兩兵，觀察原戰線露出的空點。"
        case .mage: "選 E6 → F6，再選 E4 → D4。兩兵同時移動，敵我陣營維持原樣。"
        case .rogue: "選 F5，再選 F4。英雄沿兩顆敵兵突入；新位置也可能被包圍。"
        case .priest: "選 E6 的己兵奉獻。它會消失並打開空點，不會在E7補子。比較失去兵力與新增氣的取捨。"
        }
    }
    public func session(cost: Int = 4, updatedBaseSkills: Bool = false) throws -> GameSession {
        var c = RuleConfig.board(size:9); c.expansionSkills = true; c.expansionSkillManaCost = cost
        if updatedBaseSkills { c.bastionScope = .connectedGroup; c.experimentalFriendlyRedeploy = true }
        var session = GameSession(try GameSetup.newGame(config:c,classOne:hero,classTwo:.mage))
        let opening: [GameAction]
        switch self {
        case .warrior:
            opening = [.placeSoldier(Point(4,6)),.placeSoldier(Point(0,0)),.endTurn,.summonHero(Point(4,5)),.placeSoldier(Point(5,6)),.endTurn]
        case .mage:
            opening = [.placeSoldier(Point(4,5)),.placeSoldier(Point(4,3)),.placeSoldier(Point(5,3)),.summonHero(Point(4,4)),.placeSoldier(Point(3,4)),.endTurn]
        case .rogue:
            opening = [.placeSoldier(Point(4,5)),.placeSoldier(Point(5,4)),.placeSoldier(Point(5,3)),.summonHero(Point(4,4)),.placeSoldier(Point(3,5)),.endTurn]
        case .priest:
            opening = [.placeSoldier(Point(4,5)),.placeSoldier(Point(0,0)),.endTurn,.summonHero(Point(3,5)),.placeSoldier(Point(2,5)),.endTurn]
        }
        for a in opening { guard session.apply(a).success else { throw ExpansionPracticeError.illegalOpening } }
        let needed = self == .priest ? c.skillManaCost : cost
        while session.state.mana(of:.one) < needed {
            guard session.state.current == .one, session.apply(.endTurn).success,
                  session.apply(.endTurn).success, session.state.ply < 30 else { throw ExpansionPracticeError.illegalOpening }
        }
        guard GameEngine.validate(session.state,action) == .none else { throw ExpansionPracticeError.illegalOpening }
        return session
    }
}
public enum ExpansionPracticeError: Error { case illegalOpening }
