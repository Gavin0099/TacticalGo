import XCTest
@testable import TacticalGoCore
import TacticalGoContent
import TacticalGoMotion

final class ExpansionPresentationTests: XCTestCase {
    func testArchivedRogueChainPresentationRequiresConfirmedTwoCaptureReceipt() throws {
        var session=try RogueChainPractice.session()
        XCTAssertTrue(session.apply(RogueChainPractice.firstAction).success)
        let before=session.state
        let outcome=session.apply(RogueChainPractice.secondAction)
        let plan=try XCTUnwrap(ExpansionPresentation.make(before:before,action:RogueChainPractice.secondAction,outcome:outcome,current:session.state))
        XCTAssertEqual(plan.captures.count,2)
        // One hero travels E3 -> C3 through D3; drawing one actor per leg
        // would duplicate the same hero. Two enemy soldiers complete the rotation.
        let heroes=plan.transfers.filter { $0.piece == Piece(.two,.hero) }
        XCTAssertEqual(heroes.count,1)
        XCTAssertEqual(heroes.first?.from,Point(4,2))
        XCTAssertEqual(heroes.first?.to,Point(2,2))
        XCTAssertEqual(plan.transfers.count,3)
        XCTAssertEqual(plan.board(at:0),before.board)
        XCTAssertEqual(plan.board(at:plan.duration),session.state.board)
        XCTAssertEqual(plan.board(at:0,reduced:true),session.state.board)
        XCTAssertGreaterThan(plan.captureStart,plan.arrival)
        XCTAssertTrue(session.undo())
        XCTAssertNil(ExpansionPresentation.make(before:before,action:RogueChainPractice.secondAction,outcome:outcome,current:session.state))
    }
    func testFourConfirmedFixturesUseSingleClockImmutableFinalBoardAndReducedMotion() throws {
        for f in ExpansionPractice.allCases {
            var s = try f.session(); let before = s.state; let o = s.apply(f.action)
            let p = try XCTUnwrap(ExpansionPresentation.make(before:before,action:f.action,outcome:o,current:s.state))
            XCTAssertEqual(p.before,before); XCTAssertEqual(p.after,s.state)
            XCTAssertEqual(p.board(at:p.arrival-0.001),before.board)
            XCTAssertEqual(p.board(at:p.arrival),s.state.board)
            XCTAssertEqual(p.board(at:0,reduced:true),s.state.board)
            XCTAssertEqual(p.progress(at:0),0); XCTAssertEqual(p.progress(at:p.arrival),1)
            XCTAssertGreaterThan(p.captureStart,p.arrival); XCTAssertGreaterThan(p.duration,p.captureStart)
            XCTAssertTrue(p.isHeroSkill)
            XCTAssertTrue(s.undo()); XCTAssertEqual(s.state,before)
            // A stored receipt becomes stale after Undo; it cannot be recommitted by a completion callback.
            XCTAssertNil(ExpansionPresentation.make(before:before,action:f.action,outcome:o,current:s.state))
        }
    }
    func testFailedAndForgedPayloadCannotCreateAnimation() throws {
        let f = ExpansionPractice.mage, s = try f.session().state
        let failure = GameEngine.apply(s,.castDoublePull(.init(Point(4,5),Point(4,4)),.init(Point(4,3),Point(3,3))))
        XCTAssertFalse(failure.success)
        XCTAssertNil(ExpansionPresentation.make(before:s,action:f.action,outcome:failure,current:s))
        let real = GameEngine.apply(s,f.action)
        let forged = ActionOutcome(state:real.state,events:[.gameWon(.one)],reason:.none)
        XCTAssertNil(ExpansionPresentation.make(before:s,action:f.action,outcome:forged,current:real.state))
    }
    func testMageAndWarriorRetainAcceptedTimingAndAllMovementIdentities() throws {
        for f in [ExpansionPractice.mage,.warrior,.rogue,.priest] {
            let s = try f.session().state, o = GameEngine.apply(s,f.action)
            let p = try XCTUnwrap(ExpansionPresentation.make(before:s,action:f.action,outcome:o,current:o.state))
            if f == .mage { XCTAssertEqual(p.release,0.30); XCTAssertEqual(p.arrival,0.68); XCTAssertEqual(p.duration,1.08); XCTAssertEqual(p.transfers.count,2) }
            if f == .warrior { XCTAssertEqual(p.arrival,0.58); XCTAssertEqual(p.duration,1.02); XCTAssertEqual(p.transfers.count,2) }
            if f == .rogue { XCTAssertEqual(p.transfers.count,3); XCTAssertEqual(p.transfers.filter { $0.piece.kind == .hero }.count,1) }
            if f == .priest { XCTAssertEqual(p.sacrifices,[Point(4,5)]); XCTAssertTrue(p.placements.isEmpty); XCTAssertTrue(p.transfers.isEmpty) }
            for transfer in p.transfers { XCTAssertEqual(s.board[transfer.from],transfer.piece); XCTAssertEqual(o.state.board[transfer.to],transfer.piece) }
        }
    }
}
