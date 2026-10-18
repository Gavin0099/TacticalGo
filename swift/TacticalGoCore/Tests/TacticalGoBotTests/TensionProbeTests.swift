import XCTest
@testable import TacticalGoBot
import TacticalGoCore

/// Expected values come from the rules of the position (written next to each fixture), not from the planner's scores.
final class TensionProbeTests: XCTestCase {
    private func state(_ diagram: String, ap: Int = 2) throws -> GameState {
        try GameSetup.fromDiagram(config: .board(size: 7), diagram: diagram, classOne: .none, classTwo: .none, manaOne: 3, manaTwo: 3, ap: ap, ply: 15)
    }
    /// White commander on the top edge with two black soldiers beside it and one liberty below: placing at B2 captures.
    func testDirectCommanderCaptureIsReportedAsWinningTurn() throws {
        let root = try state("xOx....\n.......\n.......\n.......\n.......\n...X...\n.......")
        let position = try XCTUnwrap(TensionProbe.analyze(root))
        XCTAssertEqual(position.verdict, .winningTurn)
        let win = try XCTUnwrap(position.candidates.first { $0.kind == .win })
        XCTAssertTrue(win.actions.contains(.placeSoldier(Point(1, 1))), "the only capturing point is directly below the commander")
        XCTAssertFalse(win.opponentCanWin)
    }
    /// Black commander on the bottom edge, white soldiers on both sides: one liberty (D6) left. White needs one
    /// stone there to capture, so a black turn is safe exactly when it fills D6 (a group with three liberties needs
    /// three white stones; White has two actions).
    func testOnlyTurnsThatExtendTheCommanderSurviveTheExactReplyCheck() throws {
        let root = try state(".......\n.......\n.......\n.......\n.......\n.......\n..oXo..")
        let position = try XCTUnwrap(TensionProbe.analyze(root, maxCandidates: 16))
        XCTAssertGreaterThan(position.candidates.count, 3)
        for turn in position.candidates {
            let extended = turn.actions.contains(.placeSoldier(Point(3, 5)))
            XCTAssertEqual(turn.opponentCanWin, !extended, turn.key)
        }
        XCTAssertTrue(position.candidates.contains { $0.opponentCanWin }, "passing must be reported as losing")
        XCTAssertTrue(position.safe.allSatisfy { $0.actions.contains(.placeSoldier(Point(3, 5))) })
    }
    /// Same position, but the commander has a free point on both sides and only two white stones nearby: nothing
    /// loses at once, so no turn may be reported as losing and the verdict is not a forced defense.
    func testNothingIsReportedLosingWhenNoReplyCanCapture() throws {
        let root = try state(".......\n.......\n.......\n.......\n.......\n.......\n...X...")
        let position = try XCTUnwrap(TensionProbe.analyze(root))
        XCTAssertTrue(position.candidates.allSatisfy { !$0.opponentCanWin })
        XCTAssertNotEqual(position.verdict, .forcedDefense)
        XCTAssertNotEqual(position.verdict, .winningTurn)
    }
    func testProbeDoesNotChangeThePlannerChoice() throws {
        let root = try state(".......\n...O...\n.......\n..x.x..\n.......\n...X...\n.......")
        let before = BotPlanner.planTurn(root)?.actions
        _ = TensionProbe.analyze(root)
        XCTAssertEqual(BotPlanner.planTurn(root)?.actions, before)
    }
    func testFinishedGamesHaveNoPosition() throws {
        let root = try state("xOx....\n.......\n.......\n.......\n.......\n...X...\n.......")
        let won = GameEngine.apply(root, .placeSoldier(Point(1, 1))).state
        XCTAssertEqual(won.status, .won)
        XCTAssertNil(TensionProbe.analyze(won))
    }
}
