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

    func testOnlySanctumKeepsTheCommanderAliveThroughWhitesNextTurn() throws {
        for practice in PriestSanctumPractice.allCases {
            let start = try practice.state()
            XCTAssertEqual(start.apRemaining, 1); XCTAssertEqual(start.mana(of: .one), 4)
            XCTAssertTrue(whiteCanCaptureCommander(handOver(start)), "\(practice): passing loses the commander")
            var saving: [GameAction] = []
            for action in GameEngine.legalActions(start, expansionCandidateLimit: 512) {
                let outcome = GameEngine.apply(start, action)
                guard outcome.success else { continue }
                if !whiteCanCaptureCommander(handOver(outcome.state)) { saving.append(action) }
            }
            XCTAssertTrue(saving.contains(practice.action), "\(practice): the taught move saves the commander")
            for action in saving {
                guard case .castSanctum = action else { return XCTFail("\(practice): \(action) also saves; the lesson would be wrong") }
            }
            // The two ordinary alternatives the lesson names, explicitly.
            let place = GameEngine.apply(start, .placeSoldier(practice.destination))
            XCTAssertTrue(place.success); XCTAssertTrue(whiteCanCaptureCommander(handOver(place.state)))
            let offering = GameEngine.apply(start, .castOffering(practice.sacrifice))
            XCTAssertTrue(offering.success); XCTAssertTrue(whiteCanCaptureCommander(handOver(offering.state)))
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
