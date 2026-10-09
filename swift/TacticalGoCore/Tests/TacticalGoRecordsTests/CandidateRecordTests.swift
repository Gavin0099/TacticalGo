import Foundation
import XCTest
import TacticalGoCore
@testable import TacticalGoRecords

final class CandidateRecordTests: XCTestCase {
    private func append(_ action: GameAction, record: inout MatchRecord, session: inout GameSession) throws {
        let before = session.state, outcome = session.apply(action)
        XCTAssertTrue(outcome.success, "Official newGame fixture action \(action) rejected: \(outcome.reason)")
        guard outcome.success else { throw RecordError.invalidAction(record.steps.count) }
        let index = record.steps.count
        record.steps.append(RecordStep(action: action, before: before, outcome: outcome,
            difficulty: index.isMultiple(of: 2) ? "standard" : "easy", decision: "reviewed fixture step \(index)"))
    }
    /// No synthetic boards: the complete official source is retained in RecordStep receipts.
    private func mageSource(size: Int = 7, rules: RecordRules = .original, computer: Player? = .two) throws -> (MatchRecord, GameSession) {
        var record = MatchRecord(size: size, one: .mage, two: .warrior, computer: size == 9 ? nil : computer,
                                 difficulty: "standard", rules: rules)
        var session = try record.rebuild().0
        let x = size / 2
        for action in [GameAction.placeSoldier(Point(x, size - 3)), .endTurn,
            .summonHero(Point(x, size - 4)), .placeSoldier(Point(0, 0)), .endTurn] {
            try append(action, record: &record, session: &session)
        }
        return (record, session)
    }
    private func redeploy(_ size: Int) -> GameAction {
        .castFriendlyRedeploy(Point(size / 2, size - 3), Point(size / 2 - 1, size - 4))
    }
    private func json(_ record: MatchRecord) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: record.encoded()) as? [String: Any])
    }
    private func rawRecord(_ value: [String: Any]) throws -> MatchRecord {
        try JSONDecoder().decode(MatchRecord.self, from: JSONSerialization.data(withJSONObject: value))
    }
    private func assertReceiptMismatch(_ body: () throws -> Void, step: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try body(), file: file, line: line) { error in
            guard case RecordError.receiptMismatch(let actual) = error else { return XCTFail("Expected receiptMismatch, got \(error)", file: file, line: line) }
            XCTAssertEqual(actual, step, file: file, line: line)
        }
    }
    func testCandidateRulesExplicitlyEnableRedeployWithoutExchange() {
        for size in [7, 9] {
            let config = RecordRules.redeployment.config(size: size)
            XCTAssertEqual(config.boardSize, size)
            XCTAssertEqual(config.bastionScope, .connectedGroup)
            XCTAssertEqual(config.mageSkill, .magicHand)
            XCTAssertEqual(config.magicHandDestination, .emptyOnly)
            XCTAssertTrue(config.experimentalFriendlyRedeploy)
            XCTAssertFalse(RecordRules.original.config(size: size).experimentalFriendlyRedeploy)
        }
    }
    func testCandidateCopyPreservesAllStepsAndMetadataWithNewIdentityBothSizes() throws {
        for size in [7, 9] {
            let (original, originalSession) = try mageSource(size: size)
            let originalBytes = try original.encoded()
            let candidate = try original.candidateCopy()
            XCTAssertNotEqual(candidate.id, original.id)
            XCTAssertNotEqual(candidate.created, original.created)
            XCTAssertEqual(candidate.created, candidate.updated)
            XCTAssertEqual(candidate.rules, .redeployment)
            XCTAssertEqual(candidate.schema, original.schema)
            XCTAssertEqual(candidate.engineVersion, original.engineVersion)
            XCTAssertEqual(candidate.size, original.size)
            XCTAssertEqual(candidate.one, original.one); XCTAssertEqual(candidate.two, original.two)
            XCTAssertEqual(candidate.computer, original.computer)
            XCTAssertEqual(candidate.difficulty, original.difficulty)
            XCTAssertEqual(candidate.steps, original.steps) // Includes actor, receipt, events, step difficulty and decision.
            XCTAssertEqual(try original.encoded(), originalBytes)
            XCTAssertEqual(try original.rebuild().0.state, originalSession.state)
            XCTAssertEqual(StateReceipt(try candidate.rebuild().0.state), StateReceipt(originalSession.state))
            XCTAssertEqual(try MatchRecord.decode(candidate.encoded()).steps, original.steps)
        }
        let (humanOnly, _) = try mageSource(computer: nil)
        XCTAssertNil(try humanOnly.candidateCopy().computer)
    }
    func testCandidateRedeployOfficialReplayUndoAPManaOnceAndRealSuperko() throws {
        for size in [7, 9] {
            let (original, _) = try mageSource(size: size)
            var candidate = try original.candidateCopy(), session = try candidate.rebuild().0
            let before = session.state, command = redeploy(size)
            XCTAssertEqual(before.apRemaining, 2)
            XCTAssertEqual(before.mana(of: .one), 3)
            try append(command, record: &candidate, session: &session)
            XCTAssertEqual(session.state.apRemaining, 1)
            XCTAssertEqual(session.state.mana(of: .one), 1)
            XCTAssertTrue(session.state.skillUsedThisTurn)
            XCTAssertTrue(session.state.hasSummonedHero(.one))
            XCTAssertEqual(GameEngine.validate(session.state, command), .skillAlreadyUsed)
            let encoded = try candidate.encoded()
            let decoded = try MatchRecord.decode(encoded)
            var restored = try decoded.rebuild().0
            XCTAssertEqual(restored.state, session.state) // Equality includes exact historical boards.
            XCTAssertTrue(restored.undo()); XCTAssertEqual(restored.state, before)
            XCTAssertTrue(restored.apply(command).success)
            XCTAssertEqual(restored.state, session.state)
            let movement = try XCTUnwrap(decoded.rebuild().1.last?.events.first { if case .piecePushed = $0 { return true }; return false })
            XCTAssertEqual(movement, .piecePushed(caster: .one, from: Point(size / 2, size - 3),
                to: Point(size / 2 - 1, size - 4), piece: Piece(.one, .soldier)))
            for action in [GameAction.endTurn, .endTurn] { try append(action, record: &candidate, session: &session) }
            let reverse = GameAction.castFriendlyRedeploy(Point(size / 2 - 1, size - 4), Point(size / 2, size - 3))
            let replay = try MatchRecord.decode(candidate.encoded()).rebuild().0
            XCTAssertEqual(replay.state, session.state)
            XCTAssertEqual(replay.state.mana(of: .one), 2)
            XCTAssertFalse(replay.state.skillUsedThisTurn)
            let rejected = GameEngine.apply(replay.state, reverse)
            XCTAssertEqual(rejected.reason, .ko, "A real prior official-source board is reconstructed, not injected")
            XCTAssertEqual(rejected.state, replay.state); XCTAssertTrue(rejected.events.isEmpty)
            XCTAssertEqual(GameEngine.apply(session.state, reverse), rejected)
        }
    }
    func testStableV1RedeployWireAndOldActionsNeedNoMigration() throws {
        let command = GameAction.castFriendlyRedeploy(Point(3, 4), Point(2, 3))
        let wire = RecordedAction(command)
        XCTAssertEqual(wire.kind, "redeploy")
        XCTAssertEqual(wire.points, [Point(3, 4), Point(2, 3)])
        XCTAssertNil(wire.direction)
        XCTAssertEqual(wire.label, "重新部署 D5、C4")
        XCTAssertEqual(try wire.action(), command)
        let encoded = try JSONEncoder().encode(wire)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(Set(object.keys), Set(["kind", "points"]))
        let old = Data(#"{"kind":"push","points":[{"x":3,"y":4}],"direction":"Left"}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(RecordedAction.self, from: old).action(), .castMagicHand(Point(3, 4), .left))
        let (original, _) = try mageSource()
        XCTAssertEqual(original.schema, 1); XCTAssertEqual(original.engineVersion, "tacticalgo-actions-v1")
        XCTAssertEqual(try MatchRecord.decode(original.encoded()).steps, original.steps)
    }
    func testRepeatedCandidateCopyThrowsAlreadyCandidate() throws {
        let (original, _) = try mageSource()
        let candidate = try original.candidateCopy(), bytes = try candidate.encoded()
        XCTAssertThrowsError(try candidate.candidateCopy()) { error in
            guard case RecordError.alreadyCandidate = error else { return XCTFail("Unexpected error: \(error)") }
        }
        XCTAssertEqual(try candidate.encoded(), bytes)
    }
    func testOriginalRulesRejectRedeployAndCannotImportCandidateReceipts() throws {
        let (original, source) = try mageSource()
        let rejected = GameEngine.apply(source.state, redeploy(7))
        XCTAssertEqual(rejected.reason, .skillNotSelected)
        XCTAssertEqual(rejected.state, source.state); XCTAssertTrue(rejected.events.isEmpty)
        var candidate = try original.candidateCopy(), session = try candidate.rebuild().0
        try append(redeploy(7), record: &candidate, session: &session)
        var value = try json(candidate); value["rules"] = "original"
        XCTAssertThrowsError(try MatchRecord.decode(JSONSerialization.data(withJSONObject: value))) { error in
            guard case RecordError.invalidAction(let index) = error else { return XCTFail("Unexpected error: \(error)") }
            XCTAssertEqual(index, original.steps.count)
        }
    }
    func testR2ExchangeSourceRejectsCandidateConversionWithoutRewriting() throws {
        var original = MatchRecord(size: 7, one: .mage, two: .warrior, computer: .two,
                                   difficulty: "standard", rules: .mage)
        var session = try original.rebuild().0
        for action in [GameAction.placeSoldier(Point(3, 4)), .placeSoldier(Point(5, 3)), .endTurn,
            .summonHero(Point(3, 3)), .placeSoldier(Point(4, 3)), .endTurn, .castMagicHand(Point(4, 3), .right)] {
            try append(action, record: &original, session: &session)
        }
        XCTAssertEqual(session.state.board[Point(4, 3)], Piece(.two, .soldier))
        XCTAssertEqual(session.state.board[Point(5, 3)], Piece(.one, .soldier))
        let bytes = try original.encoded()
        XCTAssertEqual(try MatchRecord.decode(bytes).rebuild().0.state, session.state)
        XCTAssertThrowsError(try original.candidateCopy()) { error in
            guard case RecordError.invalidAction(let index) = error else { return XCTFail("Unexpected error: \(error)") }
            XCTAssertEqual(index, original.steps.count - 1)
        }
        XCTAssertEqual(try original.encoded(), bytes)
    }
    func testCandidateCopyValidatesSourceReceiptsEventsAndActorBeforeCopying() throws {
        let (original, _) = try mageSource()
        for mode in ["mana", "events", "actor"] {
            var value = try json(original), steps = try XCTUnwrap(value["steps"] as? [[String: Any]])
            switch mode {
            case "mana":
                var after = try XCTUnwrap(steps[0]["after"] as? [String: Any]); after["mana"] = [999, 999]; steps[0]["after"] = after
            case "events": steps[0]["events"] = ["ResourcesSpent:0:1:999"]
            default: steps[0]["actor"] = 1
            }
            value["steps"] = steps
            let tampered = try rawRecord(value), bytes = try tampered.encoded()
            assertReceiptMismatch({ _ = try tampered.candidateCopy() }, step: 0)
            XCTAssertEqual(try tampered.encoded(), bytes)
        }
    }
    func testMalformedRedeployWireAndTamperedCandidateReceiptRejected() throws {
        let (original, _) = try mageSource()
        var candidate = try original.candidateCopy(), session = try candidate.rebuild().0
        try append(redeploy(7), record: &candidate, session: &session)
        let valid = try json(candidate)
        let malformed: [[String: Any]] = [
            ["kind": "redeploy", "points": []],
            ["kind": "redeploy", "points": [["x": 3, "y": 4]]],
            ["kind": "redeploy", "points": [["x": 3, "y": 4], ["x": 2, "y": 3], ["x": 1, "y": 3]]],
            ["kind": "redeploy", "points": [["x": 3, "y": 4], ["x": 2, "y": 3]], "direction": "Left"],
            ["kind": "redeploy", "points": [["x": 3, "y": 4], ["x": -1, "y": 3]]],
            ["kind": "redeploy", "points": [["x": 3, "y": 4], ["x": 3, "y": 4]]]
        ]
        for action in malformed {
            var value = valid, steps = try XCTUnwrap(value["steps"] as? [[String: Any]])
            steps[steps.count - 1]["action"] = action; value["steps"] = steps
            XCTAssertThrowsError(try MatchRecord.decode(JSONSerialization.data(withJSONObject: value)))
        }
        for mode in ["ap", "events"] {
            var value = valid, steps = try XCTUnwrap(value["steps"] as? [[String: Any]])
            let last = steps.count - 1
            if mode == "ap" {
                var after = try XCTUnwrap(steps[last]["after"] as? [String: Any]); after["ap"] = 999; steps[last]["after"] = after
            } else { steps[last]["events"] = ["PiecePushed:0:3,4:2,3:1:0"] }
            value["steps"] = steps
            assertReceiptMismatch({ _ = try MatchRecord.decode(JSONSerialization.data(withJSONObject: value)) }, step: last)
        }
    }
    func testSavingCandidateLeavesOriginalDiskBytesUntouchedAndReloadsBoth() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = RecordRepository(directory: directory), (original, _) = try mageSource()
        try repository.save(original)
        let originalBytes = try Data(contentsOf: repository.url(original.id))
        var candidate = try original.candidateCopy(), session = try candidate.rebuild().0
        try append(redeploy(7), record: &candidate, session: &session)
        try repository.save(candidate)
        XCTAssertNotEqual(repository.url(candidate.id), repository.url(original.id))
        XCTAssertEqual(try Data(contentsOf: repository.url(original.id)), originalBytes)
        XCTAssertEqual(try original.encoded(), originalBytes)
        let listing = try RecordRepository(directory: directory).list()
        XCTAssertEqual(listing.rejected, 0); XCTAssertEqual(Set(listing.records.map(\.id)), Set([original.id, candidate.id]))
        let savedCandidate = try XCTUnwrap(listing.records.first { $0.id == candidate.id })
        XCTAssertEqual(try savedCandidate.rebuild().0.state, session.state)
        XCTAssertEqual(Array(savedCandidate.steps.prefix(original.steps.count)), original.steps)
    }
}
