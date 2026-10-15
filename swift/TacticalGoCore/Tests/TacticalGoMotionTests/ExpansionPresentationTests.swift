import XCTest
@testable import TacticalGoCore
import TacticalGoContent
import TacticalGoMotion

final class ExpansionPresentationTests: XCTestCase {
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
