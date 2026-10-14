import XCTest
import TacticalGoMotion
import TacticalGoCore
import TacticalGoContent

final class SpellAccentTests: XCTestCase {
    func testFocusOnlySoftensUnrelatedPiecesAndFullyRestoresThem() throws {
        for fixture in ExpansionPractice.allCases {
            let before=try fixture.session().state,result=GameEngine.apply(before,fixture.action)
            let p=try XCTUnwrap(ExpansionPresentation.make(before:before,action:fixture.action,outcome:result,current:result.state))
            XCTAssertEqual(p.contextOpacity(at:Point(8,8),time:p.arrival-0.01),0.88,accuracy:0.001)
            for point in p.transfers.flatMap({ [$0.from,$0.to] })+p.placements+p.sacrifices+[try XCTUnwrap(p.hero)] {
                XCTAssertEqual(p.contextOpacity(at:point,time:p.arrival-0.01),1)
            }
            for t in [0,p.arrival+0.18,p.duration,Double.nan] { XCTAssertEqual(p.contextOpacity(at:Point(8,8),time:t),1) }
            XCTAssertEqual(p.contextOpacity(at:Point(8,8),time:p.arrival,reduced:true),1)
        }
    }
    func testLocalAccentPeaksOnlyAtArrivalAndEndsWithoutResidue() {
        let release=0.30,arrival=0.68,duration=1.08
        func frame(_ t:Double)->SpellAccentFrame { .sample(at:t,release:release,arrival:arrival,duration:duration) }
        XCTAssertEqual(frame(0).charge,0);XCTAssertEqual(frame(arrival-0.001).impact,0)
        XCTAssertEqual(frame(arrival).impact,1);XCTAssertEqual(frame(arrival).charge,0)
        XCTAssertGreaterThan(frame(arrival).impact,frame(arrival+0.10).impact)
        XCTAssertEqual(frame(arrival+0.22).impact,0)
        for t in [-1,duration,Double.nan,Double.infinity] { XCTAssertEqual(frame(t),.quiet) }
        XCTAssertEqual(SpellAccentFrame.sample(at:arrival,release:release,arrival:arrival,duration:duration,reduced:true),.quiet)
        XCTAssertEqual(SpellAccentFrame.sample(at:0.4,release:0.7,arrival:0.3,duration:1),.quiet)
    }
    func testNewActingDistinguishesChainAndOfferingButKeepsRestAndReducedMotion() {
        XCTAssertLessThan(ExpansionHeroPose.rogue(at:0.28,chained:true).hand,0,"Second exchange has a new windup")
        XCTAssertGreaterThan(ExpansionHeroPose.rogue(at:0.30,chained:true).hand,0,"Second exchange commits")
        XCTAssertNotEqual(ExpansionHeroPose.rogue(at:0.28,chained:true),ExpansionHeroPose.rogue(at:0.28))
        XCTAssertLessThan(ExpansionHeroPose.priest(at:0.42,offering:true).handY,ExpansionHeroPose.priest(at:0.42).handY)
        for t in [-1,1.08,Double.nan,Double.infinity] {
            XCTAssertEqual(ExpansionHeroPose.rogue(at:t,chained:true),.rest)
            XCTAssertEqual(ExpansionHeroPose.priest(at:t,offering:true),.rest)
        }
        XCTAssertEqual(ExpansionHeroPose.rogue(at:0.28,reduced:true,chained:true),.rest)
        XCTAssertEqual(ExpansionHeroPose.priest(at:0.42,reduced:true,offering:true),.rest)
    }
}
