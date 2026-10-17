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
    private func position(_ stones: [(Point, Character)]) throws -> GameState {
        var rows = Array(repeating: Array(repeating: Character("."), count: 9), count: 9)
        rows[7][4] = "X"; rows[1][4] = "O"
        for (p, c) in stones { rows[p.y][p.x] = c }
        return try GameSetup.fromDiagram(config: TacticalHints.updatedConfig(size: 9), diagram: rows.map { String($0) }.joined(separator: "\n"),
                                         classOne: .priest, classTwo: .mage, manaOne: 4, manaTwo: 3, ap: 1, ply: 9)
    }
    func testThriftyRuleKeepsManaOnlyWhenTheCommanderIsAlreadySafeAndTheGainIsOneLiberty() throws {
        let root = try position([])
        let open = try position([])                                              // commander: 4 liberties
        let squeezed = try position([(Point(3,7),"o"), (Point(5,7),"o")])          // 2 liberties
        let three = try position([(Point(3,7),"o")])                               // 3 liberties
        let threeWithHero = try position([(Point(3,7),"o"), (Point(6,2),"Q")])    // 3 liberties, White hero on board
        let fourWithHero = try position([(Point(6,2),"Q")])                        // 4 liberties, White hero on board
        XCTAssertEqual(open.board.liberties(at: Point(4,7)).count, 4)
        XCTAssertTrue(BotPlanner.keepsMana(root: root, sanctumScore: 1_050, alternativeScore: 1_000, alternativeFinal: open),
                      "safe commander, Sanctum only 50 better: keep the mana")
        XCTAssertTrue(BotPlanner.keepsMana(root: root, sanctumScore: 1_075, alternativeScore: 1_000, alternativeFinal: open),
                      "exactly one liberty's worth is still only a buffer")
        XCTAssertFalse(BotPlanner.keepsMana(root: root, sanctumScore: 1_076, alternativeScore: 1_000, alternativeFinal: open),
                       "more than one liberty's worth: Sanctum buys something real")
        XCTAssertFalse(BotPlanner.keepsMana(root: root, sanctumScore: 1_010, alternativeScore: 1_000, alternativeFinal: squeezed),
                       "2 liberties is below the one-turn line of 3: not safe")
        XCTAssertTrue(BotPlanner.keepsMana(root: root, sanctumScore: 1_010, alternativeScore: 1_000, alternativeFinal: three),
                      "3 liberties meets the line when White's hero is not on the board")
        XCTAssertFalse(BotPlanner.keepsMana(root: root, sanctumScore: 1_010, alternativeScore: 1_000, alternativeFinal: threeWithHero),
                       "a White hero can fill two points with one AP: the line rises to 4")
        XCTAssertTrue(BotPlanner.keepsMana(root: root, sanctumScore: 1_010, alternativeScore: 1_000, alternativeFinal: fourWithHero))
    }
}
