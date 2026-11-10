import Testing
import TacticalGoCore
import TacticalGoRecords

@Suite("Monster actions stay outside reviewed v1 records", .tags(.records))
struct MonsterRecordBoundaryTests {
    @Test("A monster hunt cannot round-trip as a reviewed v1 record")
    func monsterActionCannotRoundTripAsReviewedV1Record() {
        let recorded = RecordedAction(.huntMonster(Point(4, 4)))
        #expect(throws: (any Error).self) {
            try recorded.action()
        }
        #expect(recorded.label == "討伐（魔物原型不支援正式存局）")
    }

    @Test("Loot actions cannot round-trip as a reviewed v1 record", arguments: [
        GameAction.useStickyBounce(anchor: Point(3, 4), target: Point(4, 4)),
        .useShadowStep(Point(3, 2))
    ])
    func lootActionsCannotRoundTripAsReviewedV1Record(_ action: GameAction) {
        let recorded = RecordedAction(action)
        #expect(throws: (any Error).self) {
            try recorded.action()
        }
        #expect(recorded.label == "戰利能力（魔物原型不支援正式存局）")
    }
}
