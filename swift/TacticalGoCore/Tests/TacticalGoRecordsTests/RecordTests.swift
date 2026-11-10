import Foundation
import Testing
import TacticalGoCore
@testable import TacticalGoRecords

enum RecordPayloadRejection: Sendable, CustomTestStringConvertible {
    case unknownSchema
    /// Occupied commander in the formal 7×7 setup.
    case occupiedCommanderAction
    case manaReceipt

    var testDescription: String {
        switch self {
        case .unknownSchema: "schema 2"
        case .occupiedCommanderAction: "occupied commander action"
        case .manaReceipt: "mana receipt 999"
        }
    }

    func payload(from record: MatchRecord) throws -> Data {
        var json = try #require(JSONSerialization.jsonObject(with: try record.encoded()) as? [String: Any])
        switch self {
        case .unknownSchema:
            json["schema"] = 2
        case .occupiedCommanderAction:
            var steps = try #require(json["steps"] as? [[String: Any]])
            steps[0]["action"] = ["kind": "soldier", "points": [["x": 3, "y": 5]]]
            json["steps"] = steps
        case .manaReceipt:
            var steps = try #require(json["steps"] as? [[String: Any]])
            var receipt = try #require(steps[0]["after"] as? [String: Any])
            receipt["mana"] = [999, 3]
            steps[0]["after"] = receipt
            json["steps"] = steps
        }
        return try JSONSerialization.data(withJSONObject: json)
    }
}

@Suite("Match records", .tags(.records))
struct RecordTests {
    private func game(size: Int = 7, hero: HeroClass = .warrior, rules: RecordRules = .original) throws -> (MatchRecord, GameSession) {
        let record = MatchRecord(size: size, one: hero, two: .mage, computer: size == 7 ? .two : nil, difficulty: "easy", rules: rules)
        return (record, try record.rebuild().0)
    }

    private func append(_ action: GameAction, record: inout MatchRecord, session: inout GameSession) {
        let before = session.state
        let outcome = session.apply(action)
        #expect(outcome.success, "Fixture action must be legal: \(action)")
        record.steps.append(RecordStep(action: action, before: before, outcome: outcome, difficulty: "easy", decision: nil))
    }

    @Test("Seven and nine round trip and undo preserve full state", arguments: [7, 9])
    func sevenNineRoundTripAndUndoPreserveFullState(size: Int) throws {
        var (record, session) = try game(size: size)
        append(.placeSoldier(Point(0, 0)), record: &record, session: &session)
        #expect(session.state.current == .two)
        #expect(session.state.apRemaining == 2)
        let before = session.state
        append(.summonHero(Point(size / 2, 2)), record: &record, session: &session)
        #expect(session.state.mana(of: .two) == 1)
        var rebuilt = try MatchRecord.decode(record.encoded()).rebuild().0
        #expect(rebuilt.state == session.state)
        let firstUndo = rebuilt.undo()
        #expect(firstUndo)
        #expect(rebuilt.state == before)
        let secondUndo = rebuilt.undo()
        #expect(secondUndo)
        let opening = try game(size: size).1.state
        #expect(rebuilt.state == opening)
    }

    @Test("Skill receipt, resources, and history round trip")
    func skillReceiptResourceAndHistoryRoundTrip() throws {
        var (record, session) = try game()
        for action: GameAction in [
            .placeSoldier(Point(3, 4)), .endTurn, .summonHero(Point(3, 3)),
            .placeSoldier(Point(0, 0)), .endTurn, .castBastion(Point(2, 3), Point(4, 3))
        ] {
            append(action, record: &record, session: &session)
        }
        #expect(session.state.apRemaining == 1)
        #expect(session.state.mana(of: .one) == 2)
        #expect(session.state.skillUsedThisTurn)
        #expect(session.state.hasSummonedHero(.one))
        let restored = try MatchRecord.decode(record.encoded()).rebuild()
        #expect(restored.0.state == session.state) // Includes exact internal superko history.
        #expect(GameEngine.validate(restored.0.state, .castBastion(Point(2, 4), Point(4, 4))) == .skillAlreadyUsed)
        #expect(restored.1.last?.events.first == .resourcesSpent(.one, ap: 1, mana: 2))
    }

    @Test("Commander capture records terminal events and rejects a post-game action")
    func commanderCaptureTerminalEventsAndPostGameRejection() throws {
        var (record, session) = try game()
        for action: GameAction in [
            .placeSoldier(Point(3, 2)), .endTurn, .placeSoldier(Point(2, 1)),
            .placeSoldier(Point(4, 1)), .endTurn, .placeSoldier(Point(3, 0))
        ] {
            append(action, record: &record, session: &session)
        }
        #expect(session.state.status == .won)
        #expect(session.state.winner == .one)
        let rebuilt = try MatchRecord.decode(record.encoded()).rebuild()
        #expect(rebuilt.0.state == session.state)
        let lastEvents = try #require(rebuilt.1.last).events
        #expect(lastEvents.contains(.gameWon(.one)))
        let captures = lastEvents.compactMap { event -> [CapturedPiece]? in
            if case .piecesCaptured(.one, let pieces) = event { return pieces }
            return nil
        }.flatMap { $0 }
        #expect(captures.count == 1)
        #expect(captures[0].at == Point(3, 1))
        #expect(captures[0].piece == Piece(.two, .commander))
        let rejected = GameEngine.apply(session.state, .endTurn)
        record.steps.append(RecordStep(action: .endTurn, before: session.state, outcome: rejected, difficulty: "easy", decision: nil))
        let payload = try record.encoded()
        #expect(throws: (any Error).self) {
            try MatchRecord.decode(payload)
        }
    }

    @Test("Undo truncation cannot resurrect a computer move")
    func undoTruncationCannotResurrectComputerMove() throws {
        var (record, session) = try game()
        for action: GameAction in [.placeSoldier(Point(0, 0)), .placeSoldier(Point(1, 0)), .placeSoldier(Point(2, 0))] {
            append(action, record: &record, session: &session)
        }
        let undone = session.undo()
        #expect(undone)
        record.steps.removeLast()
        let restored = try MatchRecord.decode(record.encoded()).rebuild().0
        #expect(restored.state == session.state)
        #expect(restored.state.board[Point(2, 0)] == nil)
        #expect(restored.state.apRemaining == 1)
    }

    @Test("Unknown schema, illegal action, and receipt mismatch are rejected", arguments: [
        RecordPayloadRejection.unknownSchema, .occupiedCommanderAction, .manaReceipt
    ])
    func unknownVersionInvalidActionAndReceiptRejected(_ rejection: RecordPayloadRejection) throws {
        var (record, session) = try game()
        append(.placeSoldier(Point(0, 0)), record: &record, session: &session)
        let payload = try rejection.payload(from: record)
        #expect(throws: (any Error).self) {
            try MatchRecord.decode(payload)
        }
    }

    @Test("Event payload mismatch is rejected even when the board matches")
    func eventPayloadMismatchRejectedEvenWithSameBoard() throws {
        var (record, session) = try game()
        append(.placeSoldier(Point(0, 0)), record: &record, session: &session)
        var json = try #require(JSONSerialization.jsonObject(with: try record.encoded()) as? [String: Any])
        var steps = try #require(json["steps"] as? [[String: Any]])
        steps[0]["events"] = ["ResourcesSpent:0:1:999"]
        json["steps"] = steps
        let payload = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: (any Error).self) {
            try MatchRecord.decode(payload)
        }
    }

    @Test("Disk restart keeps the readable record and preserves corrupt bytes", .tags(.records, .persistence))
    func diskRestartAndCorruptFilesPreserved() throws {
        try TemporaryDirectory.withURL(prefix: "records") { directory in
            var (record, session) = try game()
            append(.placeSoldier(Point(0, 0)), record: &record, session: &session)
            let repo = RecordRepository(directory: directory)
            try repo.save(record)
            let broken = directory.appendingPathComponent("broken.json")
            let data = Data("not json".utf8)
            try data.write(to: broken)
            let restarted = RecordRepository(directory: directory)
            let listing = try restarted.list()
            #expect(listing.records.count == 1)
            #expect(listing.rejected == 1)
            #expect(try listing.records[0].rebuild().0.state == session.state)
            #expect(try Data(contentsOf: broken) == data)
        }
    }

    @Test("A failed write leaves the previous save and the blocking file intact", .tags(.records, .persistence))
    func failedWriteLeavesPreviousSaveIntact() throws {
        try TemporaryDirectory.withURL(prefix: "records") { directory in
            var (record, session) = try game()
            let repo = RecordRepository(directory: directory)
            try repo.save(record)
            let bytes = try Data(contentsOf: repo.url(record.id))
            append(.placeSoldier(Point(0, 0)), record: &record, session: &session)
            record.schema = 999
            #expect(throws: (any Error).self) {
                try repo.save(record)
            }
            #expect(try Data(contentsOf: repo.url(record.id)) == bytes)
            record.schema = 1
            let blocked = directory.appendingPathComponent("not-a-directory")
            try Data("occupied path".utf8).write(to: blocked)
            #expect(throws: (any Error).self) {
                try RecordRepository(directory: blocked).save(record)
            }
            #expect(try Data(contentsOf: repo.url(record.id)) == bytes)
            #expect(try Data(contentsOf: blocked) == Data("occupied path".utf8))
        }
    }

    @Test("Replay does not change the live session or the recorded rules", arguments: RecordRules.allCases)
    func replayDoesNotChangeLiveSessionOrRules(_ rules: RecordRules) throws {
        var (record, session) = try game(rules: rules)
        append(.placeSoldier(Point(0, 0)), record: &record, session: &session)
        let before = session.state
        let frames = try record.rebuild().1
        #expect(frames.count == 2)
        #expect(frames[0].state.board[Point(0, 0)] == nil)
        #expect(frames[1].state.board[Point(0, 0)] == Piece(.one, .soldier))
        #expect(session.state == before)
        #expect(frames[1].state.config == rules.config(size: 7))
    }
}
