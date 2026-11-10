import Testing
import TacticalGoCore
import TacticalGoRecords

@Suite
struct MonsterRecordBoundaryTests {
    @Test(.tags(.rejection))
    func testMonsterActionCannotRoundTripAsReviewedV1Record() {
        let recorded = RecordedAction(.huntMonster(Point(4, 4)))
        #expect(throws: (any Error).self) { try recorded.action() }
        #expect(recorded.label == "討伐（魔物原型不支援正式存局）")
    }

    @Test(.tags(.rejection), arguments: [
        GameAction.useStickyBounce(anchor: Point(3, 4), target: Point(4, 4)),
        GameAction.useShadowStep(Point(3, 2)),
    ])
    func testLootActionsCannotRoundTripAsReviewedV1Record(_ action: GameAction) {
        let recorded = RecordedAction(action)
        #expect(throws: (any Error).self) { try recorded.action() }
        #expect(recorded.label == "戰利能力（魔物原型不支援正式存局）")
    }
}
