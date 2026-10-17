import XCTest
import TacticalGoCore
import TacticalGoContent

/// The practice claim ("only Sanctum saves the commander") is checked by exhaustive search, not asserted by hand:
/// every legal Black action, followed by every White reply of up to two actions.
final class PriestSanctumPracticeTests: XCTestCase {
    private func whiteCanCaptureCommander(_ state: GameState) -> Bool {
        guard state.status == .ongoing, state.current == .two else { return state.winner == .two }
        for first in GameEngine.legalActions(state, expansionCandidateLimit: 64) {
            let one = GameEngine.apply(state, first)
            guard one.success else { continue }
            if one.state.winner == .two { return true }
            guard one.state.status == .ongoing, one.state.current == .two else { continue }
            for second in GameEngine.legalActions(one.state, expansionCandidateLimit: 64) {
                let two = GameEngine.apply(one.state, second)
                if two.success, two.state.winner == .two { return true }
            }
        }
        return false
    }
    private func handOver(_ state: GameState) -> GameState {
        state.current == .one && state.status == .ongoing ? GameEngine.apply(state, .endTurn).state : state
    }

    private func saving(_ start: GameState) -> [GameAction] {
        GameEngine.legalActions(start, expansionCandidateLimit: 512).filter { action in
            let outcome = GameEngine.apply(start, action)
            return outcome.success && !whiteCanCaptureCommander(handOver(outcome.state))
        }
    }
    private func saves(_ start: GameState, _ action: GameAction) -> Bool {
        let outcome = GameEngine.apply(start, action)
        return outcome.success && !whiteCanCaptureCommander(handOver(outcome.state))
    }

    /// Every lesson's claim, checked exhaustively: what saves the commander and what does not.
    func testEachLessonClaimHoldsUnderExhaustiveSearch() throws {
        for practice in PriestSanctumPractice.allCases {
            let start = try practice.state()
            XCTAssertEqual(start.apRemaining, 1); XCTAssertEqual(start.mana(of: .one), 4)
            XCTAssertEqual(GameEngine.validate(start, practice.action), .none, "\(practice): the Sanctum in question is legal")
            XCTAssertTrue(whiteCanCaptureCommander(handOver(start)), "\(practice): passing loses the commander")
            let rescues = saving(start)
            switch practice.kind {
            case .onlySanctum:
                XCTAssertTrue(rescues.contains(practice.action), "\(practice): the taught Sanctum saves")
                for action in rescues {
                    guard case .castSanctum = action else { return XCTFail("\(practice): \(action) also saves") }
                }
                XCTAssertFalse(saves(start, .placeSoldier(practice.destination)), "\(practice): a stone at the exit is not enough")
                XCTAssertFalse(saves(start, .castOffering(practice.sacrifice)), "\(practice): Offering is not enough")
            case .placementEnough:
                XCTAssertTrue(saves(start, .placeSoldier(practice.destination)), "\(practice): a plain stone saves")
            case .offeringEnough:
                XCTAssertTrue(saves(start, .castOffering(practice.sacrifice)), "\(practice): Offering makes two eyes")
                XCTAssertFalse(saves(start, practice.action), "\(practice): Sanctum fills an own eye and loses")
                XCTAssertFalse(rescues.contains { if case .castSanctum = $0 { return true }; return false }, "\(practice): no Sanctum saves")
            case .nothingSaves:
                XCTAssertEqual(rescues, [], "\(practice): nothing saves, Sanctum included")
            }
            if let recommended = practice.recommended { XCTAssertTrue(rescues.contains(recommended), "\(practice): recommended move saves") }
        }
    }

    func testSacrificeInsightReportsLibertiesAndEyes() throws {
        let start = try PriestSanctumPractice.seven.state()
        let offering = try XCTUnwrap(PriestSacrificeInsight(start, .castOffering(PriestSanctumPractice.seven.sacrifice)))
        XCTAssertEqual(offering.libertiesBefore, 1); XCTAssertEqual(offering.libertiesAfter, 2)
        XCTAssertFalse(offering.eyeFormed, "the vacated point still touches two white stones")
        let sanctum = try XCTUnwrap(PriestSacrificeInsight(start, PriestSanctumPractice.seven.action))
        XCTAssertEqual(sanctum.libertiesBefore, 1); XCTAssertEqual(sanctum.libertiesAfter, 3)
        XCTAssertNil(PriestSacrificeInsight(start, .placeSoldier(Point(5,5))), "only priest sacrifices are described")
        XCTAssertEqual(sanctum.summary, "犧牲後氣 1→3")
    }
}
