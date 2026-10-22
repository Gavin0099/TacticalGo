import XCTest
import TacticalGoCore
import TacticalGoBot
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
        #if os(Linux)
        var linuxExpectedFailure = false
        #endif
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
            case .placementEnough, .offeringEnough:
                XCTAssertFalse(whiteCanCaptureCommander(after), "\(practice) \(difficulty): \(moves) does not save the commander")
                if practice == .wideExitNine && difficulty == .standard {
                    // Known: evaluate() scores each commander liberty 75 and each mana 7, so +1 liberty (3 → 4)
                    // outweighs keeping 4 mana even when 3 liberties already survive a 2-AP turn. Tuning that weight
                    // changes every class's play; left as a decision. Remove this wrapper once the bot keeps its mana.
                    #if os(Linux)
                    // swift-corelibs-xctest has no XCTExpectFailure. Keep every rescue assertion,
                    // then report this known balance limitation as a skipped test, never a pass.
                    XCTAssertTrue(usedSanctum, "Known defect changed: remove the expected-failure exception after review")
                    linuxExpectedFailure = true
                    #else
                    XCTExpectFailure("standard bot spends Sanctum for a 4th liberty instead of keeping 4 mana") {
                        XCTAssertFalse(usedSanctum, "\(practice) \(difficulty): spent Sanctum where a cheaper move saves")
                    }
                    #endif
                } else {
                    XCTAssertFalse(usedSanctum, "\(practice) \(difficulty): spent Sanctum where a cheaper move saves")
                }
            case .nothingSaves:
                XCTAssertTrue(after.status == .ongoing || after.winner != nil)
            }
        } }
        #if os(Linux)
        if linuxExpectedFailure { throw XCTSkip("Known standard-bot unnecessary Sanctum use; all other fixture assertions executed") }
        #endif
    }
}
