import Testing
import TacticalGoCore
import TacticalGoRecords

@Suite
struct ExpansionBoundaryTests {
    @Test(.tags(.rejection, .roundTrip))
    func testLegacyRecordRejectsPriestAndMagicHandStillRoundTrips() throws {
        let record = MatchRecord(size: 9, one: .priest, two: .mage, computer: nil, difficulty: "standard")
        #expect(throws: (any Error).self) { try record.rebuild() }
        #expect(try RecordedAction(.castMagicHand(Point(3, 3), .up)).action() == .castMagicHand(Point(3, 3), .up))
    }

    @Test(.tags(.rejection), arguments: [
        GameAction.castDoublePull(SoldierShift(Point(3, 3), Point(3, 2)), SoldierShift(Point(4, 3), Point(4, 2))),
        GameAction.castReformation(SoldierShift(Point(3, 3), Point(3, 2)), SoldierShift(Point(4, 3), Point(4, 2))),
        GameAction.castChainSwap(first: Point(3, 3), second: Point(4, 3)),
        GameAction.castSanctuary(sacrifice: Point(3, 3), destination: Point(4, 3)),
    ])
    func testUnknownExpansionActionsCannotRoundTrip(_ action: GameAction) {
        #expect(throws: (any Error).self) { try RecordedAction(action).action() }
    }
}
