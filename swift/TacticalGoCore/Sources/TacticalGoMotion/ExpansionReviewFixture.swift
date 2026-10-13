import TacticalGoCore

/// Legal diagram for engineering board/frame QA only; not a reachable challenge or balance proof.
public enum ExpansionReviewFixture {
    public static func action(hero: HeroClass) -> GameAction {
        switch hero {
        case .warrior: .castReformation(.init(Point(3,4),Point(2,4)),.init(Point(4,4),Point(5,4)))
        case .mage: .castDoublePull(.init(Point(3,4),Point(2,4)),.init(Point(4,3),Point(4,2)))
        case .rogue: .castChainSwap(first:Point(4,3),second:Point(4,2))
        case .priest: .castSanctuary(sacrifice:Point(3,4),destination:Point(2,5))
        case .none: .endTurn
        }
    }
    public static func state(hero: HeroClass,owner: Player = .one,size: Int = 9,dense: Bool = false) throws -> GameState {
        guard [7,9].contains(size),hero != .none else { throw SetupError.invalidConfiguration }
        var rows = Array(repeating:Array(repeating:Character("."),count:size),count:size)
        let friend: Character = owner == .one ? "x":"o",enemy: Character = owner == .one ? "o":"x"
        rows[5][3] = owner == .one ? "X":"O"; rows[1][3] = owner == .one ? "O":"X"; rows[3][3] = owner == .one ? "H":"Q"
        switch hero {
        case .warrior: rows[4][3] = friend;rows[4][4] = friend
        case .mage: rows[4][3] = friend;rows[3][4] = enemy
        case .rogue: rows[3][4] = enemy;rows[2][4] = enemy
        case .priest: rows[4][3] = friend
        case .none: break
        }
        if dense {
            for x in 0..<size { rows[0][x] = x%2 == 0 ? friend:enemy;rows[size-1][x] = x%2 == 0 ? friend:enemy }
            rows[0][3] = ".";rows[size-1][3] = "."
            for y in 2...4 { rows[y][0] = enemy;rows[y][size-1] = friend }
        }
        var c = RuleConfig.board(size:size);c.expansionSkills = true
        return try GameSetup.fromDiagram(config:c,diagram:rows.map { String($0) }.joined(separator:"\n"),classOne:owner == .one ? hero:.mage,classTwo:owner == .two ? hero:.mage,current:owner,manaOne:6,manaTwo:6)
    }
}
