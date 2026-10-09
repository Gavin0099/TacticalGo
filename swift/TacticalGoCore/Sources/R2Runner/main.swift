import Foundation
import TacticalGoCore

struct Expected: Decodable { let reason: String; let winner: String? }
struct Focus: Decodable {
    let kind: String
    let a: [Int]?
    let b: [Int]?
    let target: [Int]?
    let direction: String?
    var action: GameAction {
        if kind == "bastion" { return .castBastion(Point(a![0], a![1]), Point(b![0], b![1])) }
        return .castMagicHand(Point(target![0], target![1]), PushDirection(rawValue: direction!)!)
    }
}
struct Fixture: Decodable {
    let id: String; let heroClass: HeroClass; let purpose: String; let diagram: String
    let focus: Focus; let expected: [String: Expected]
}
struct Metrics: Encodable {
    let fixture: String; let variant: String; let purpose: String; let occupied: Int
    let legalSkills: Int; let distinctSkillBoards: Int; let directSkillWins: Int
    let ordinaryWinningBoardsWithinTwoPlacements: Int
    let skillThenOptionalPlacementWinningBoards: Int
    let rogueLegalSkillsAtSamePosition: Int; let rogueDirectWinsAtSamePosition: Int
    let minCasterHeroLibertiesAfterSkill: Int?
    let maxBastionTargetDistance: Int?
    let legalEnemyPreemptivePlacements: Int
    let enemySinglePlacementsPreventingAllDirectSkillWins: Int?
    let focusReason: String; let focusWinner: String?
    let focusEvents: [String]; let focusBefore: String; let focusAfter: String
}
func skills(_ state: GameState) -> [GameAction] {
    GameEngine.legalActions(state).filter { action in
        switch action { case .castBastion, .castMagicHand, .castSwap: true; default: false }
    }
}
func soldierActions(_ state: GameState) -> [GameAction] {
    // Enumerate only this experiment's declared comparison action, avoiding unrelated skill combinations.
    state.board.points.filter { state.board[$0] == nil }.map { GameAction.placeSoldier($0) }
        .filter { GameEngine.validate(state, $0) == .none }
}
func hasWon(_ state: GameState) -> Bool { state.status == .won && state.winner == .one }
func ordinaryWins(_ initial: GameState) -> Set<String> {
    var boards: Set<String> = []
    for first in soldierActions(initial) {
        let after = GameEngine.apply(initial, first).state
        if hasWon(after) { boards.insert(after.board.diagram) }
        else if after.current == initial.current {
            for second in soldierActions(after) {
                let last = GameEngine.apply(after, second).state
                if hasWon(last) { boards.insert(last.board.diagram) }
            }
        }
    }
    return boards
}
func config(_ variant: String) -> RuleConfig {
    var result = RuleConfig.board(size: 7)
    if variant == "B" || variant == "D" { result.bastionScope = .connectedGroup }
    if variant == "C" || variant == "D" { result.magicHandDestination = .opposingSoldierExchange }
    return result
}
let input = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "tests/r2/positions.json"
let fixtures = try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: URL(fileURLWithPath: input)))
var report: [Metrics] = []
for fixture in fixtures {
    for variant in ["A", "B", "C", "D"] {
        let cfg = config(variant)
        let state = try GameSetup.fromDiagram(config: cfg, diagram: fixture.diagram, classOne: fixture.heroClass,
                                              classTwo: .rogue, manaOne: 4, manaTwo: 4, ap: 2, ply: 30)
        // Fixtures must be ongoing, with both commanders and the tested hero, and no pre-existing zero-liberty groups.
        guard state.board.find(.one, .hero) != nil, state.board.find(.one, .commander) != nil,
              state.board.find(.two, .commander) != nil,
              state.board.points.filter({ state.board[$0] != nil }).allSatisfy({ !state.board.liberties(at: $0).isEmpty }) else {
            fatalError("Invalid initial fixture \(fixture.id)")
        }
        let focus = GameEngine.apply(state, fixture.focus.action)
        let expected = fixture.expected[variant]!
        guard focus.reason.rawValue == expected.reason, focus.state.winner?.name == expected.winner else {
            fatalError("Fixture expectation failed: \(fixture.id) \(variant) actual \(focus.reason) \(String(describing: focus.state.winner))")
        }
        let actions = skills(state)
        let outcomes = actions.map { GameEngine.apply(state, $0).state }
        let directWins = outcomes.filter(hasWon).count
        var skillWins = Set(outcomes.filter(hasWon).map { $0.board.diagram })
        for after in outcomes where after.status == .ongoing && after.current == .one {
            for follow in soldierActions(after) {
                let final = GameEngine.apply(after, follow).state
                if hasWon(final) { skillWins.insert(final.board.diagram) }
            }
        }
        let rogue = try GameSetup.fromDiagram(config: cfg, diagram: fixture.diagram, classOne: .rogue,
                                            classTwo: .rogue, manaOne: 4, manaTwo: 4, ap: 2, ply: 30)
        let rogueSkills = skills(rogue)
        // One enemy ordinary placement before the threat, then hand back. This is NOT a two-AP minimax defence search.
        let defending = try GameSetup.fromDiagram(config: cfg, diagram: fixture.diagram, classOne: fixture.heroClass,
                                                  classTwo: .rogue, current: .two, manaOne: 4, manaTwo: 4, ap: 2, ply: 29)
        let defenses = soldierActions(defending)
        var prevents = 0
        if directWins > 0 {
            for defense in defenses {
                let afterDefense = GameEngine.apply(defending, defense).state
                if afterDefense.status != .ongoing { prevents += 1; continue }
                let handedBack = GameEngine.apply(afterDefense, .endTurn).state
                if !skills(handedBack).contains(where: { hasWon(GameEngine.apply(handedBack, $0).state) }) { prevents += 1 }
            }
        }
        let heroLiberties = outcomes.compactMap { after in after.board.find(.one, .hero).map { after.board.liberties(at: $0).count } }
        let hero = state.board.find(.one, .hero)!
        let distances = actions.flatMap { action -> [Int] in
            if case .castBastion(let a, let b) = action { return [hero.distance(to: a), hero.distance(to: b)] }
            return []
        }
        report.append(Metrics(fixture: fixture.id, variant: variant, purpose: fixture.purpose,
            occupied: state.board.points.filter { state.board[$0] != nil }.count,
            legalSkills: actions.count, distinctSkillBoards: Set(outcomes.map { $0.board.diagram }).count,
            directSkillWins: directWins, ordinaryWinningBoardsWithinTwoPlacements: ordinaryWins(state).count,
            skillThenOptionalPlacementWinningBoards: skillWins.count,
            rogueLegalSkillsAtSamePosition: rogueSkills.count,
            rogueDirectWinsAtSamePosition: rogueSkills.filter { hasWon(GameEngine.apply(rogue, $0).state) }.count,
            minCasterHeroLibertiesAfterSkill: heroLiberties.min(), maxBastionTargetDistance: distances.max(),
            legalEnemyPreemptivePlacements: defenses.count,
            enemySinglePlacementsPreventingAllDirectSkillWins: directWins > 0 ? prevents : nil,
            focusReason: focus.reason.rawValue, focusWinner: focus.state.winner?.name,
            focusEvents: focus.events.map { $0.name }, focusBefore: state.board.diagram, focusAfter: focus.state.board.diagram))
    }
}
let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
FileHandle.standardOutput.write(try encoder.encode(report)); print("")
