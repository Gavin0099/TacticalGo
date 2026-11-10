import Testing
import TacticalGoCore
import TacticalGoRecords

@Suite("Legacy records reject expansion setup and actions", .tags(.records, .expansion))
struct ExpansionBoundaryTests {
    @Test("A legacy record rejects a priest setup")
    func legacyRecordRejectsPriest() {
        let record = MatchRecord(size: 9, one: .priest, two: .mage, computer: nil, difficulty: "standard")
        #expect(throws: (any Error).self) {
            try record.rebuild()
        }
    }

    @Test("A legacy record rejects expansion actions", arguments: [
        GameAction.castDoublePull(SoldierShift(Point(3, 3), Point(3, 2)), SoldierShift(Point(4, 3), Point(4, 2))),
        .castReformation(SoldierShift(Point(3, 3), Point(3, 2)), SoldierShift(Point(4, 3), Point(4, 2))),
        .castChainSwap(first: Point(3, 3), second: Point(4, 3)),
        .castSanctuary(sacrifice: Point(3, 3), destination: Point(4, 3))
    ])
    func legacyRecordRejectsExpansionAction(_ action: GameAction) {
        #expect(throws: (any Error).self) {
            try RecordedAction(action).action()
        }
    }

    @Test("A reviewed magic-hand action still round-trips")
    func reviewedMagicHandStillRoundTrips() throws {
        let action = try RecordedAction(.castMagicHand(Point(3, 3), .up)).action()
        #expect(action == .castMagicHand(Point(3, 3), .up))
    }
}
