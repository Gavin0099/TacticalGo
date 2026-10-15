import XCTest
import TacticalGoCore
import TacticalGoRecords

final class ExpansionBoundaryTests: XCTestCase {
    func testLegacyRecordRejectsPriestAndAllUnknownExpansionActions() throws {
        let record = MatchRecord(size:9,one:.priest,two:.mage,computer:nil,difficulty:"standard")
        XCTAssertThrowsError(try record.rebuild())
        let a = SoldierShift(Point(3,3),Point(3,2)), b = SoldierShift(Point(4,3),Point(4,2))
        let actions: [GameAction] = [.castDoublePull(a,b),.castReformation(a,b),
            .castChainSwap(first:Point(3,3),second:Point(4,3)),.castSanctuary(sacrifice:Point(3,3),destination:Point(4,3))]
        for action in actions { XCTAssertThrowsError(try RecordedAction(action).action()) }
        XCTAssertEqual(try RecordedAction(.castMagicHand(Point(3,3),.up)).action(),.castMagicHand(Point(3,3),.up))
    }
}
