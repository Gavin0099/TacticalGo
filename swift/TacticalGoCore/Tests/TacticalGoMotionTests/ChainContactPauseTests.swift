import XCTest
import TacticalGoCore
import TacticalGoContent
@testable import TacticalGoMotion

final class ChainContactPauseTests: XCTestCase {
    func receipt() throws -> ExpansionPresentation {
        let s = try ExpansionPractice.rogue.session(updatedBaseSkills:true).state
        let a = ExpansionPractice.rogue.action,o = GameEngine.apply(s,a)
        XCTAssertTrue(o.success)
        return try XCTUnwrap(.make(before:s,action:a,outcome:o,current:o.state))
    }
    func testFirstContactStopsAllThreeAtDistinctCorrectPointsWithoutMutatingBoard() throws {
        let p = try receipt(),before = p.before,after = p.after
        let origin=(x:0.0,y:0.0),first=(x:40.0,y:0.0),second=(x:40.0,y:-40.0)
        for t in [0.26,0.275,0.29] {
            let u = p.progress(at:t)
            XCTAssertEqual(u,0.5,accuracy:1e-12)
            let h = RogueChainPath.position(from:origin,to:second,via:first,progress:u,pitch:40,hero:true,firstEnemy:false)
            let a = RogueChainPath.position(from:first,to:origin,via:first,progress:u,pitch:40,hero:false,firstEnemy:true)
            let b = RogueChainPath.position(from:second,to:first,via:first,progress:u,pitch:40,hero:false,firstEnemy:false)
            XCTAssertEqual(h.x,first.x);XCTAssertEqual(h.y,first.y)
            XCTAssertEqual(a.x,origin.x);XCTAssertEqual(a.y,origin.y)
            XCTAssertEqual(b.x,second.x);XCTAssertEqual(b.y,second.y)
            XCTAssertEqual(p.board(at:t),before.board,"The middle stance is presentation only")
        }
        XCTAssertEqual(p.before,before);XCTAssertEqual(p.after,after)
        XCTAssertEqual(p.board(at:0.36),after.board)
        XCTAssertEqual(p.contactBeats.map(\.start),[0.26,0.26,0.36,0.36])
        XCTAssertEqual(p.duration,0.70)
    }
    func testBoundedMonotonicContinuousAndSecondMoveFinishesAtOriginalContact() throws {
        let p = try receipt()
        XCTAssertEqual(p.progress(at:0.16),0)
        XCTAssertEqual(p.progress(at:0.36),1)
        var last=0.0
        for i in 0...700 {
            let u=p.progress(at:Double(i)/1000)
            XCTAssertTrue((0...1).contains(u));XCTAssertGreaterThanOrEqual(u,last);last=u
        }
        for edge in [0.26,0.29] {
            XCTAssertEqual(p.progress(at:edge-1e-7),p.progress(at:edge+1e-7),accuracy:1e-5)
        }
        XCTAssertGreaterThan(p.progress(at:0.30),0.5)
        XCTAssertEqual(p.progress(at:0.20,reduced:true),1)
        XCTAssertEqual(p.progress(at:.nan),1)
    }
    func testBodyContactsThenWindsUpForSecondExchangeButOrdinarySwapIsUnchanged() throws {
        let a=ExpansionHeroPose.rogue(at:0.26,chained:true),b=ExpansionHeroPose.rogue(at:0.29,chained:true)
        XCTAssertLessThan(b.hand,0,"The body prepares the second strike while the board position holds")
        XCTAssertGreaterThan(ExpansionHeroPose.rogue(at:0.32,chained:true).hand,a.hand)
        XCTAssertEqual(ExpansionHeroPose.rogue(at:0.36,chained:true).hand,a.hand)
        let s=try ExpansionPractice.rogue.session(updatedBaseSkills:true).state
        let action=GameAction.castSwap(Point(5,4)),o=GameEngine.apply(s,action)
        let normal=try XCTUnwrap(ExpansionPresentation.make(before:s,action:action,outcome:o,current:o.state))
        XCTAssertEqual(normal.progress(at:0.26),0.5,accuracy:1e-12)
        XCTAssertGreaterThan(normal.progress(at:0.29),0.5)
        XCTAssertEqual(ExpansionHeroPose.rogue(at:0.29,reduced:true,chained:true),.rest)
    }
}
