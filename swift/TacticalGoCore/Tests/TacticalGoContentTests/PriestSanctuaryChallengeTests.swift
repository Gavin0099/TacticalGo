import XCTest
import TacticalGoCore
import TacticalGoContent

final class PriestSanctuaryChallengeTests: XCTestCase {
    func testMageCanChangeRealEyeToAnAccessibleBoundaryAndCaptureAfterPass() throws {
        var s = try PriestSanctuaryChallenge.counterSession()
        XCTAssertEqual(s.state.current,.two)
        XCTAssertEqual(s.state.board.liberties(at:Point(3,2)),[Point(2,3),Point(4,3)])
        let before = s.state
        XCTAssertTrue(s.apply(PriestSanctuaryChallenge.counterAction).success)
        XCTAssertEqual(s.state.board.liberties(at:Point(3,2)),[Point(2,3),Point(5,3)])
        // Black is allowed to respond. This probe deliberately passes to expose the reply;
        // it does not claim a forced win or that the priest cannot rescue again.
        XCTAssertTrue(s.apply(.endTurn).success)
        XCTAssertTrue(s.apply(.placeSoldier(Point(5,3))).success)
        XCTAssertEqual(s.state.board.liberties(at:Point(3,2)),[Point(2,3)])
        let attack = s.apply(.placeSoldier(Point(2,3)))
        XCTAssertTrue(attack.success);XCTAssertNil(s.state.board.find(.one,.hero))
        XCTAssertNotNil(s.state.board.find(.one,.commander));XCTAssertEqual(s.state.status,.ongoing)
        XCTAssertTrue(attack.events.contains { if case .piecesCaptured(_,let pieces) = $0 { return pieces.contains { $0.at == Point(3,2) && $0.piece == Piece(.one,.hero) } };return false })
        for _ in 0..<4 { XCTAssertTrue(s.undo()) };XCTAssertEqual(s.state,before)
    }
    func testReachableOfferingCreatesTwoRealEyesWithoutReinforcement() throws {
        for cost in [4,5] {
            var s = try PriestSanctuaryChallenge.session(cost:cost)
            let before = s.state
            XCTAssertEqual(before.current,.one)
            XCTAssertEqual(before.board.liberties(at:Point(3,2)),[Point(2,3)])
            XCTAssertFalse(PriestSanctuaryChallenge.solved(before))
            XCTAssertEqual(GameEngine.validate(before,.placeSoldier(Point(2,3))),.suicide)
            let ordinary = GameEngine.apply(before,.placeSoldier(Point(4,6)))
            XCTAssertTrue(ordinary.success)
            XCTAssertEqual(ordinary.state.board.liberties(at:Point(3,2)),[Point(2,3)])
            let outcome = s.apply(PriestSanctuaryChallenge.action)
            XCTAssertTrue(outcome.success); XCTAssertTrue(PriestSanctuaryChallenge.solved(s.state))
            XCTAssertTrue(outcome.events.contains(.pieceSacrificed(.one,Point(4,3))))
            XCTAssertNil(s.state.board[Point(4,6)])
            XCTAssertFalse(outcome.events.contains { if case .piecePlaced = $0 { return true }; return false })
            XCTAssertFalse(outcome.events.contains { if case .piecesCaptured = $0 { return true }; return false })
            let saved = s.state
            // Each internal eye is surrounded by black. Filling one cannot capture the
            // group because the other remains, so an ordinary white intrusion is suicide.
            XCTAssertTrue(s.apply(.endTurn).success)
            for eye in [Point(2,3),Point(4,3)] {
                let attack = GameEngine.apply(s.state,.placeSoldier(eye))
                XCTAssertFalse(attack.success); XCTAssertEqual(attack.reason,.suicide)
                XCTAssertEqual(attack.state,s.state); XCTAssertTrue(attack.events.isEmpty)
            }
            XCTAssertTrue(s.undo()); XCTAssertEqual(s.state,saved)
            var replay = GameSession(try GameSetup.newGame(config:before.config,classOne:.priest,classTwo:.mage))
            for action in s.log { XCTAssertTrue(replay.apply(action).success) }
            XCTAssertEqual(replay.state,saved)
            XCTAssertTrue(s.undo()); XCTAssertEqual(s.state,before)
        }
    }
}
