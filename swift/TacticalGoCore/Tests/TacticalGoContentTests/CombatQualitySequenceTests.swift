import XCTest
import TacticalGoCore
import TacticalGoContent

final class CombatQualitySequenceTests: XCTestCase {
    func testNormalOpeningCastCaptureWinReplayAndUndoForBothSizes() throws {
        for size in [7, 9] {
            let fixture = CombatQualitySequence(size: size), initial = try fixture.initial
            var session = GameSession(initial)
            for (index, action) in fixture.actions.enumerated() {
                let before = session.state
                XCTAssertEqual(GameEngine.validate(before, action), .none, "step \(index), size \(size)")
                XCTAssertEqual(session.state, before, "preview is read-only")
                let result = session.apply(action)
                guard result.success else { XCTFail("step \(index): \(result.reason)"); return }
                if index < 12 { XCTAssertEqual(session.state.status, .ongoing) }
                if index == 7 {
                    XCTAssertNil(session.state.board[fixture.source])
                    XCTAssertEqual(session.state.board[fixture.destination], Piece(.one, .soldier))
                    XCTAssertEqual(session.state.mana(of: .one), before.mana(of: .one) - 2)
                }
            }
            XCTAssertEqual(session.state.status, .won)
            XCTAssertEqual(session.state.winner, .one)
            XCTAssertNil(session.state.board[fixture.enemyCommander])
            for point in [Point(size / 2 - 1, 1), Point(size / 2, 0), Point(size / 2 + 1, 1), Point(size / 2, 2)] {
                XCTAssertEqual(session.state.board[point], Piece(.one, .soldier))
            }
            var replay = GameSession(initial)
            for action in session.log { XCTAssertTrue(replay.apply(action).success) }
            XCTAssertEqual(replay.state, session.state)
            XCTAssertTrue(session.undo());XCTAssertEqual(session.state.status, .ongoing)
            XCTAssertEqual(session.state.board[fixture.enemyCommander], Piece(.two, .commander))
            while session.canUndo { XCTAssertTrue(session.undo()) }
            XCTAssertEqual(session.state, initial)
        }
    }
    func testQuickVoiceHandoffReplaysReachableBothClassCasts() throws {
        var session = try CombatVoiceHandoff.session()
        let before = session.state
        XCTAssertEqual(before.heroClass(of:.one),.rogue)
        XCTAssertEqual(before.heroClass(of:.two),.mage)
        XCTAssertTrue(session.apply(CombatVoiceHandoff.first).success)
        XCTAssertEqual(session.state.current,.one)
        XCTAssertTrue(session.apply(.endTurn).success)
        XCTAssertEqual(session.state.current,.two)
        let mageBefore = session.state
        XCTAssertTrue(session.apply(CombatVoiceHandoff.second).success)
        XCTAssertNil(session.state.board[Point(4,4)])
        XCTAssertEqual(session.state.board[Point(3,4)],Piece(.two,.soldier))
        XCTAssertEqual(session.state.mana(of:.two),mageBefore.mana(of:.two)-2)
        XCTAssertEqual(session.state.status,.ongoing)
        XCTAssertTrue(session.undo());XCTAssertTrue(session.undo());XCTAssertTrue(session.undo())
        XCTAssertEqual(session.state,before)
    }
    func testInvalidSelectionDoesNotSpendOrMoveBeforeTheReviewedCast() throws {
        let fixture = CombatQualitySequence(size: 9)
        var session = GameSession(try fixture.initial)
        for action in fixture.actions.prefix(7) { XCTAssertTrue(session.apply(action).success) }
        let before = session.state
        let invalid = session.apply(.castFriendlyRedeploy(fixture.source, fixture.hero))
        XCTAssertFalse(invalid.success);XCTAssertEqual(session.state, before)
        XCTAssertEqual(GameEngine.validate(before, fixture.actions[7]), .none)
        XCTAssertEqual(session.state, before)
    }
}
