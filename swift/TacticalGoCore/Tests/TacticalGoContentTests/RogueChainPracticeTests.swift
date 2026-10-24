import XCTest
@testable import TacticalGoCore
import TacticalGoContent

final class RogueChainPracticeTests: XCTestCase {
    func testArchivedOpeningTwoActionsAndUndoRetainFullHistory() throws {
        var session = try RogueChainPractice.session()
        let root = session.state
        // Independent fixed expectations from PR #37's archived P1R root/ownAfter.
        XCTAssertEqual(session.log.count,117)
        XCTAssertEqual(root.history.count,118)
        XCTAssertEqual(root.ply,60)
        XCTAssertEqual(root.current,.two)
        XCTAssertEqual(root.apRemaining,2)
        XCTAssertEqual(root.mana(of:.two),6)
        XCTAssertEqual(root.board.diagram,"""
        oo.oooooo
        o.ooOooo.
        ooxxQ.o.o
        xoxooooo.
        xxxxxoxoo
        xx.xxx.xo
        x.x.H.x.x
        .x.xXx.x.
        x.xxxxxxx
        """)
        XCTAssertTrue(session.apply(RogueChainPractice.firstAction).success)
        XCTAssertEqual(session.state.current,.two)
        XCTAssertEqual(session.state.apRemaining,1)
        XCTAssertEqual(session.state.mana(of:.two),6)
        let outcome=session.apply(RogueChainPractice.secondAction)
        XCTAssertTrue(outcome.success)
        let taken=outcome.events.flatMap { event -> [CapturedPiece] in
            if case .piecesCaptured(.two,let pieces)=event { return pieces };return []
        }
        XCTAssertEqual(taken.count,2)
        XCTAssertTrue(taken.allSatisfy { $0.piece == Piece(.one,.soldier) })
        XCTAssertEqual(session.state.mana(of:.two),2,"No opponent turn has been played; do not invent 3 mana")
        XCTAssertEqual(session.state.current,.one)
        XCTAssertEqual(session.state.apRemaining,2,"This is the opponent's AP after handoff")
        XCTAssertEqual(session.state.board.diagram,"""
        oo.oooooo
        o.ooOooo.
        ooQ..oo.o
        xoxooooo.
        xxxxxoxoo
        xx.xxx.xo
        x.x.H.x.x
        .x.xXx.x.
        x.xxxxxxx
        """)
        XCTAssertTrue(session.undo());XCTAssertTrue(session.undo())
        XCTAssertEqual(session.state,root,"Includes resources, flags and exact superko history")
    }

    func testTrialCannotOverwriteArchiveOrAcceptOccupiedFirstMove() throws {
        let session=try RogueChainPractice.session(),root=session.state
        var draft=TwoActionForecast(origin:root)
        XCTAssertFalse(draft.chooseFirst(.placeSoldier(Point(4,2))))
        XCTAssertNil(draft.first)
        XCTAssertEqual(draft.projectedState,root)
        XCTAssertTrue(draft.chooseFirst(RogueChainPractice.firstAction))
        XCTAssertFalse(draft.chooseSecond(.placeSoldier(Point(5,2))))
        XCTAssertNil(draft.second)
        XCTAssertTrue(draft.chooseSecond(RogueChainPractice.secondAction))
        XCTAssertEqual(draft.secondStep?.enemySoldiersCaptured,2)
        XCTAssertEqual(draft.secondStep?.manaBefore,6)
        XCTAssertEqual(draft.secondStep?.manaAfter,2)
        XCTAssertEqual(session.state,root)
    }
}
