import XCTest
import TacticalGoCore
@testable import TacticalGoBot
import TacticalGoContent

/// Review item 1 (PRIEST-S2-P0): the engine lists Sanctum, but does the computer actually choose it when it is the
/// only rescue? The bot plans a full turn in each lesson position; its turn is executed, then every White reply of up
/// to two actions is searched for a commander capture.
final class PriestSanctumBotTests: XCTestCase {
    private func whiteCanCaptureCommander(_ state: GameState) -> Bool {
        guard state.status == .ongoing, state.current == .two else { return state.winner == .two }
        for first in GameEngine.legalActions(state, expansionCandidateLimit: 64) {
            let one = GameEngine.apply(state, first)
            guard one.success else { continue }
            if one.state.winner == .two { return true }
            guard one.state.status == .ongoing, one.state.current == .two else { continue }
            for second in GameEngine.legalActions(one.state, expansionCandidateLimit: 64)
                where GameEngine.apply(one.state, second).state.winner == .two { return true }
        }
        return false
    }
    private func execute(_ start: GameState, _ plan: BotTurnPlan) -> GameState {
        var s = start
        for action in plan.actions {
            let o = GameEngine.apply(s, action); XCTAssertTrue(o.success, "\(action): \(o.reason)"); s = o.state
        }
        return s.current == .one && s.status == .ongoing ? GameEngine.apply(s, .endTurn).state : s
    }

    func testBotRescuesTheCommanderAndUsesSanctumOnlyWhereItIsNeeded() throws {
        for practice in PriestSanctumPractice.allCases { for difficulty in BotDifficulty.allCases {
            let start = try practice.state()
            let plan = try XCTUnwrap(BotPlanner.planTurn(start, difficulty: difficulty), "\(practice) \(difficulty)")
            let moves = plan.actions.map(botActionDescription)
            let usedSanctum = plan.actions.contains { if case .castSanctum = $0 { return true }; return false }
            let after = execute(start, plan)
            print("PRIEST-BOT \(practice) \(difficulty): \(moves) sanctum=\(usedSanctum) mana=\(after.mana(of: .one))")
            switch practice.kind {
            case .onlySanctum:
                XCTAssertTrue(usedSanctum, "\(practice) \(difficulty): \(moves) — \(plan.reasons)")
                XCTAssertFalse(whiteCanCaptureCommander(after), "\(practice) \(difficulty): commander still dies")
            case .placementEnough:
                // Both are defensible: the plain stone survives this turn but ends in atari after White's reply;
                // Sanctum keeps two liberties. The standard search looks at that reply and may buy the extra liberty.
                XCTAssertFalse(whiteCanCaptureCommander(after), "\(practice) \(difficulty): \(moves) does not save the commander")
            case .offeringEnough:
                XCTAssertFalse(whiteCanCaptureCommander(after), "\(practice) \(difficulty): \(moves) does not save the commander")
                XCTAssertFalse(usedSanctum, "\(practice) \(difficulty): Sanctum fills an own eye here")
            case .nothingSaves:
                XCTAssertTrue(after.status == .ongoing || after.winner != nil)
            }
        } }
    }

    // Owner 2026-10-17: the thrifty rule (do not spend Sanctum for a liberty the commander does not need), on its own.
    private func position(_ stones: [(Point, Character)], whiteMana: Int = 0) throws -> GameState {
        var rows = Array(repeating: Array(repeating: Character("."), count: 9), count: 9)
        rows[7][4] = "X"; rows[1][4] = "O"
        for (p, c) in stones { rows[p.y][p.x] = c }
        return try GameSetup.fromDiagram(config: TacticalHints.updatedConfig(size: 9), diagram: rows.map { String($0) }.joined(separator: "\n"),
                                         classOne: .priest, classTwo: .mage, manaOne: 4, manaTwo: whiteMana, ap: 1, ply: 9)
    }
    func testThriftyRuleNeedsRealSavingsASafeCommanderAndAOneLibertyGap() throws {
        let root = try position([])
        let spent = try position([]).withMana(0)                                   // the Sanctum turn's end: 0 mana
        let open = try position([])                                                // 4 liberties, 4 mana kept
        let squeezed = try position([(Point(3,7),"o"), (Point(5,7),"o")])         // 2 liberties
        let three = try position([(Point(3,7),"o")])                               // 3 liberties
        let threeHero = try position([(Point(3,7),"o"), (Point(6,2),"Q")])        // 3 liberties, White hero on board
        let threeCanSummon = try position([(Point(3,7),"o")], whiteMana: 3)       // 3 liberties, White can summon next turn
        let fourHero = try position([(Point(6,2),"Q")])
        func keeps(_ final: GameState, gap: Int = 50, sanctum: GameState? = nil) -> Bool {
            BotPlanner.keepsMana(root: root, sanctumScore: 1_000 + gap, alternativeScore: 1_000,
                                 sanctumFinal: sanctum ?? spent, alternativeFinal: final)
        }
        XCTAssertEqual(open.board.liberties(at: Point(4,7)).count, 4)
        XCTAssertTrue(keeps(open), "safe commander, Sanctum only 50 better, 4 mana kept")
        XCTAssertTrue(keeps(open, gap: 75), "exactly one liberty's worth is still only a spare liberty")
        XCTAssertFalse(keeps(open, gap: 76), "more than one liberty's worth: Sanctum buys something real")
        XCTAssertFalse(keeps(open, sanctum: open), "an alternative that ends with no more mana is not 'keeping mana'")
        XCTAssertFalse(keeps(squeezed), "2 liberties is below the line of 3")
        XCTAssertTrue(keeps(three), "3 liberties meets the line when White has no hero and cannot summon one")
        XCTAssertFalse(keeps(threeHero), "a White hero can fill two points with one AP: the line rises to 4")
        XCTAssertFalse(keeps(threeCanSummon), "White can summon then use a two-point skill: the line rises to 4")
        XCTAssertTrue(keeps(fourHero))
    }

    // The whole path, not just the condition: search → Sanctum chosen → own-Sanctum-free re-search → compare → replace.
    // A wide gap forces the replacement deterministically; the 75 threshold itself is covered above.
    func testFullPlanReplacesASanctumTurnWhenTheRuleAccepts() throws {
        let practice = PriestSanctumPractice.wideExitNine
        var c = TacticalHints.updatedConfig(size: 9); c.boardSize = 9
        let start = try GameSetup.fromDiagram(config: c, diagram: practice.diagram, classOne: .priest, classTwo: .mage,
                                              manaOne: 4, manaTwo: 0, ap: 1, ply: 9)       // White cannot summon next turn
        let usual = try XCTUnwrap(BotPlanner.planTurn(start, difficulty: .standard))
        XCTAssertTrue(usual.actions.contains { if case .castSanctum = $0 { return true }; return false },
                      "precondition: the standard bot casts Sanctum here (\(usual.actions.map(botActionDescription)))")
        let thrifty = try XCTUnwrap(BotPlanner.planTurn(start, difficulty: .standard, sanctumGap: 1_000_000))
        XCTAssertFalse(thrifty.actions.contains { if case .castSanctum = $0 { return true }; return false })
        XCTAssertTrue(thrifty.reasons.contains { $0.contains("保留能量") }, "\(thrifty.reasons)")
        let after = execute(start, thrifty)
        XCTAssertEqual(after.mana(of: .one), 4, "kept the 4 mana")
        XCTAssertFalse(whiteCanCaptureCommander(after), "the replacement still saves the commander this turn")
    }
}

private extension GameState {
    func withMana(_ mana: Int) throws -> GameState {
        try GameSetup.fromDiagram(config: config, diagram: board.diagram, classOne: heroClass(of: .one), classTwo: heroClass(of: .two),
                                  current: current, manaOne: mana, manaTwo: self.mana(of: .two), ap: apRemaining, ply: ply)
    }
}
