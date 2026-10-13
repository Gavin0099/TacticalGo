import XCTest
import TacticalGoCore
import TacticalGoRecords

final class MonsterRecordBoundaryTests: XCTestCase {
    func testMonsterActionCannotRoundTripAsReviewedV1Record() {
        let recorded = RecordedAction(.huntMonster(Point(4, 4)))
        XCTAssertThrowsError(try recorded.action())
        XCTAssertEqual(recorded.label, "討伐（魔物原型不支援正式存局）")
    }
    func testLootActionsCannotRoundTripAsReviewedV1Record() {
        for a: GameAction in [.useStickyBounce(anchor: Point(3,4), target: Point(4,4)), .useShadowStep(Point(3,2))] {
            let recorded = RecordedAction(a)
            XCTAssertThrowsError(try recorded.action())
            XCTAssertEqual(recorded.label, "戰利能力（魔物原型不支援正式存局）")
        }
    }
}
