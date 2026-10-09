import XCTest
import TacticalGoCore
@testable import TacticalGoMotion

final class MatchExampleTests: XCTestCase {
    func testWarriorMageFromOpeningThroughSealExpiryAndTwoPieceVictory() throws {
        var session = GameSession(try MatchExample.warriorMage.initialState())
        XCTAssertEqual(session.state.apRemaining, 1)
        for (i, action) in MatchExample.warriorMage.actions.enumerated() {
            let before = session.state, result = session.apply(action)
            XCTAssertTrue(result.success, "step \(i + 1)")
            XCTAssertGreaterThan(MotionPlan.make(before: before, action: action, outcome: result).duration, 0)
            if i == 5 {
                XCTAssertTrue(result.state.isSealed(Point(2, 2), for: .one))
                XCTAssertEqual(result.state.mana(of: .two), 0)
            }
            if i == 6 {
                let denied = session.apply(.placeSoldier(Point(2, 2)))
                XCTAssertEqual(denied.reason, .sealed)
                XCTAssertEqual(session.state, result.state)
                XCTAssertTrue(denied.events.isEmpty)
            }
            if i == 8 {
                XCTAssertTrue(result.events.contains(.sealExpired(Point(2, 2))))
                XCTAssertTrue(result.state.seals.isEmpty)
            }
            if i == 15 {
                let capture = try XCTUnwrap(result.events.first {
                    if case .piecesCaptured = $0 { return true }; return false
                })
                guard case .piecesCaptured(let player, let pieces) = capture else { return XCTFail("Missing capture") }
                XCTAssertEqual(player, .one)
                XCTAssertEqual(pieces.map(\.at), [Point(3, 1), Point(3, 2)])
                XCTAssertEqual(pieces.map(\.piece), [Piece(.two, .commander), Piece(.two, .hero)])
            }
        }
        XCTAssertEqual(session.state.board.diagram, "oo.x...\noox.x..\n..x.x..\n...x...\n..xHx..\n...X..o\n......o")
        XCTAssertEqual(session.state.winner, .one)
        XCTAssertEqual(session.state.ply, 9)
        XCTAssertEqual(session.state.mana(of: .one), 4)
        XCTAssertEqual(session.state.mana(of: .two), 2)
        assertFinishedAndUndo(&session)
    }
    func testRogueSwapThenOppositeTeamWinsWithSurvivingHero() throws {
        var session = GameSession(try MatchExample.rogueWarrior.initialState())
        for (i, action) in MatchExample.rogueWarrior.actions.enumerated() {
            let result = session.apply(action)
            XCTAssertTrue(result.success, "step \(i + 1)")
            if i == 3 {
                XCTAssertEqual(result.state.board[Point(4, 4)], Piece(.one, .hero))
                XCTAssertEqual(result.state.board[Point(3, 4)], Piece(.two, .soldier))
                XCTAssertTrue(result.events.contains(.piecesSwapped(.one, Point(3, 4), Point(4, 4))))
            }
        }
        XCTAssertEqual(session.state.board.diagram, "......x\n...O..x\n..oQo.x\n.......\n...oH..\n..o.o..\n...o...")
        XCTAssertEqual(session.state.winner, .two)
        XCTAssertEqual(session.state.ply, 6)
        XCTAssertEqual(session.state.mana(of: .one), 2)
        XCTAssertEqual(session.state.mana(of: .two), 2)
        XCTAssertEqual(session.state.board[Point(4, 4)], Piece(.one, .hero))
        assertFinishedAndUndo(&session)
    }
    private func assertFinishedAndUndo(_ session: inout GameSession) {
        let final = session.state, log = session.log
        let denied = session.apply(.endTurn)
        XCTAssertEqual(denied.reason, .gameOver)
        XCTAssertEqual(session.state, final)
        XCTAssertEqual(session.log, log)
        XCTAssertEqual(MotionPlan.make(before: final, action: .endTurn, outcome: denied), .empty)
        XCTAssertTrue(session.undo())
        XCTAssertEqual(session.state.status, .ongoing)
        XCTAssertNil(session.state.winner)
        XCTAssertTrue(session.apply(log.last!).success)
        XCTAssertEqual(session.state, final)
    }
}
