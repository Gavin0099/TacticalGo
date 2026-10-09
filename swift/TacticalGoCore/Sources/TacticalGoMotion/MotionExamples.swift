import TacticalGoCore

/// Small, hand-authored review positions, also exercised by presentation tests.
/// These are actual rule actions rather than fabricated motion-only outcomes.
public enum MotionExample: String, CaseIterable, Sendable {
    case drop = "落子", summon = "召喚", capture = "提子", bastion = "築壘", seal = "封印", swap = "換位", victory = "勝負", expire = "封印到期"
    public var action: GameAction {
        switch self {
        case .drop: .placeSoldier(Point(4, 3))
        case .summon: .summonHero(Point(3, 4))
        case .capture, .victory: .placeSoldier(Point(3, 3))
        case .bastion: .castBastion(Point(2, 3), Point(4, 3))
        case .seal: .castSeal(Point(4, 3))
        case .swap: .castSwap(Point(4, 3))
        case .expire: .endTurn
        }
    }
    public func initialState() throws -> GameState {
        if self == .expire {
            // Advance actual rules to the blocked player's turn; do not inject a seal.
            let before = try MotionExample.seal.initialState()
            let sealed = GameEngine.apply(before, MotionExample.seal.action)
            return GameEngine.apply(sealed.state, .endTurn).state
        }
        let diagram: String, hero: HeroClass
        switch self {
        case .drop, .summon:
            diagram = ".......\n...O...\n.......\n.......\n.......\n...X...\n......."; hero = .warrior
        case .capture:
            diagram = "...O...\n...x...\n..xox..\n.......\n.......\n...X...\n......."; hero = .warrior
        case .bastion, .seal:
            diagram = ".......\n...O...\n.......\n...H...\n.......\n...X...\n......."; hero = self == .seal ? .mage : .warrior
        case .swap:
            diagram = ".......\n...O...\n.......\n...Ho..\n.......\n...X...\n......."; hero = .rogue
        case .victory:
            diagram = ".......\n...x...\n..xOx..\n.......\n.......\n...X...\n......."; hero = .warrior
        case .expire: preconditionFailure("Handled above")
        }
        var config = RuleConfig.board(size: 7); config.mageSkill = .seal
        return try GameSetup.fromDiagram(config: config, diagram: diagram,
                                         classOne: hero, classTwo: .mage, manaOne: 6, manaTwo: 6, ap: 2)
    }
}
