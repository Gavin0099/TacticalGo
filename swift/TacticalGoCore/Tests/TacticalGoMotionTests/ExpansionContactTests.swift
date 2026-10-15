import XCTest
import TacticalGoCore
import TacticalGoContent
import TacticalGoMotion

final class ExpansionContactTests: XCTestCase {
    private func receipt(_ fixture: ExpansionPractice) throws -> ExpansionPresentation {
        let before=try fixture.session().state,result=GameEngine.apply(before,fixture.action)
        return try XCTUnwrap(ExpansionPresentation.make(before:before,action:fixture.action,outcome:result,current:result.state))
    }
    func testChainMarksTwoExchangesAtActualSocketsWithoutAddingPlacements() throws {
        let p=try receipt(.rogue),beats=p.contactBeats
        XCTAssertEqual(beats.count,4)
        XCTAssertEqual(beats.filter { abs($0.start-0.26)<0.0001 }.map(\.at),[Point(4,4),Point(5,4)])
        XCTAssertEqual(beats.filter { abs($0.start-0.36)<0.0001 }.map(\.at),[Point(5,4),Point(5,3)])
        XCTAssertTrue(p.placements.isEmpty)
        XCTAssertEqual(p.after,GameEngine.apply(p.before,p.action).state)
    }
    func testFourClassContactsBelongOnlyToAffectedPointsAndOfferingStaysAtDonor() throws {
        for fixture in ExpansionPractice.allCases {
            let p=try receipt(fixture),points=Set(p.transfers.flatMap { [$0.from,$0.to] }+p.placements+p.sacrifices)
            XCTAssertFalse(p.contactBeats.isEmpty)
            XCTAssertTrue(p.contactBeats.allSatisfy { points.contains($0.at) })
            if fixture == .priest {
                XCTAssertEqual(p.contactBeats.map(\.at),[Point(4,5)])
                XCTAssertNil(p.contactBeats.first?.from)
            }
        }
        var session=try ExpansionPractice.rogue.session()
        let before=session.state,result=session.apply(.placeSoldier(Point(8,8)))
        let ordinary=try XCTUnwrap(ExpansionPresentation.make(before:before,action:.placeSoldier(Point(8,8)),outcome:result,current:result.state))
        XCTAssertTrue(ordinary.contactBeats.isEmpty)
    }
    func testFirmContactIsFiniteShortLocalAndSilentForReducedOrInvalidTime() {
        func sample(_ t:Double)->ExpansionContactFrame { .sample(at:t,start:0.26,end:0.70) }
        XCTAssertEqual(sample(0.26).opacity,1)
        XCTAssertEqual(sample(0.28).opacity,1)
        XCTAssertLessThan(sample(0.36).opacity,1)
        for t in [0.25,0.44,0.70,Double.nan,Double.infinity] { XCTAssertEqual(sample(t),.quiet) }
        XCTAssertEqual(ExpansionContactFrame.sample(at:0.26,start:0.26,end:0.70,reduced:true),.quiet)
        XCTAssertEqual(ExpansionContactFrame.sample(at:0.26,start:0.70,end:0.26),.quiet)
        for t in stride(from:0.26,through:0.43,by:0.01) {
            let f=sample(t);XCTAssertLessThanOrEqual(f.radius,0.46);XCTAssertGreaterThanOrEqual(f.opacity,0)
        }
    }
}
