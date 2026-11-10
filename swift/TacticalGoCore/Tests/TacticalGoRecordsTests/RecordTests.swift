import Testing
import Foundation
import TacticalGoCore
@testable import TacticalGoRecords

@Suite
struct RecordTests {
    func game(size: Int = 7, hero: HeroClass = .warrior, rules: RecordRules = .original) throws -> (MatchRecord, GameSession) {
        let r = MatchRecord(size: size, one: hero, two: .mage, computer: size == 7 ? .two : nil, difficulty: "easy", rules: rules)
        return (r, try r.rebuild().0)
    }
    func append(_ a: GameAction, record: inout MatchRecord, session: inout GameSession) throws {
        let before = session.state, outcome = session.apply(a)
        #expect(outcome.success, "Fixture action must be legal: \(a)")
        record.steps.append(RecordStep(action: a, before: before, outcome: outcome, difficulty: "easy", decision: nil))
    }

    @Test(.tags(.roundTrip), arguments: [7, 9])
    func testSevenNineRoundTripAndUndoPreserveFullState(_ size: Int) throws {
        var (r, s) = try game(size: size)
        try append(.placeSoldier(Point(0, 0)), record: &r, session: &s)
        #expect(s.state.current == .two)
        #expect(s.state.apRemaining == 2)
        let before = s.state
        try append(.summonHero(Point(size / 2, 2)), record: &r, session: &s)
        #expect(s.state.mana(of: .two) == 1)
        var rebuilt = try MatchRecord.decode(r.encoded()).rebuild().0
        #expect(rebuilt.state == s.state)
        let undidLast = rebuilt.undo()
        #expect(undidLast)
        #expect(rebuilt.state == before)
        let undidFirst = rebuilt.undo()
        #expect(undidFirst)
        let opening = try game(size: size).1.state
        #expect(rebuilt.state == opening)
    }

    @Test(.tags(.roundTrip))
    func testSkillReceiptResourceAndHistoryRoundTrip() throws {
        var (r, s) = try game()
        for a: GameAction in [.placeSoldier(Point(3, 4)), .endTurn, .summonHero(Point(3, 3)), .placeSoldier(Point(0, 0)), .endTurn, .castBastion(Point(2, 3), Point(4, 3))] {
            try append(a, record: &r, session: &s)
        }
        #expect(s.state.apRemaining == 1)
        #expect(s.state.mana(of: .one) == 2)
        #expect(s.state.skillUsedThisTurn)
        #expect(s.state.hasSummonedHero(.one))
        let restored = try MatchRecord.decode(r.encoded()).rebuild()
        #expect(restored.0.state == s.state) // Includes exact internal superko history.
        #expect(GameEngine.validate(restored.0.state, .castBastion(Point(2, 4), Point(4, 4))) == .skillAlreadyUsed)
        #expect(restored.1.last?.events.first == .resourcesSpent(.one, ap: 1, mana: 2))
    }

    @Test(.tags(.roundTrip, .rejection))
    func testCommanderCaptureTerminalEventsAndPostGameRejection() throws {
        var (r, s) = try game()
        for a: GameAction in [.placeSoldier(Point(3, 2)), .endTurn, .placeSoldier(Point(2, 1)), .placeSoldier(Point(4, 1)), .endTurn, .placeSoldier(Point(3, 0))] {
            try append(a, record: &r, session: &s)
        }
        #expect(s.state.status == .won)
        #expect(s.state.winner == .one)
        let rebuilt = try MatchRecord.decode(r.encoded()).rebuild()
        #expect(rebuilt.0.state == s.state)
        #expect(rebuilt.1.last!.events.contains(.gameWon(.one)))
        let captures = rebuilt.1.last!.events.compactMap { e -> [CapturedPiece]? in
            if case .piecesCaptured(.one, let pieces) = e { return pieces }; return nil
        }.flatMap { $0 }
        #expect(captures.count == 1)
        #expect(captures[0].at == Point(3, 1))
        #expect(captures[0].piece == Piece(.two, .commander))
        let rejected = GameEngine.apply(s.state, .endTurn)
        r.steps.append(RecordStep(action: .endTurn, before: s.state, outcome: rejected, difficulty: "easy", decision: nil))
        let payload = try r.encoded()
        #expect(throws: (any Error).self) {
            try MatchRecord.decode(payload)
        }
    }

    @Test(.tags(.roundTrip))
    func testUndoTruncationCannotResurrectComputerMove() throws {
        var (r, s) = try game()
        for a: GameAction in [.placeSoldier(Point(0, 0)), .placeSoldier(Point(1, 0)), .placeSoldier(Point(2, 0))] { try append(a, record: &r, session: &s) }
        let didUndo = s.undo()
        #expect(didUndo)
        r.steps.removeLast()
        let restored = try MatchRecord.decode(r.encoded()).rebuild().0
        #expect(restored.state == s.state)
        #expect(restored.state.board[Point(2, 0)] == nil)
        #expect(restored.state.apRemaining == 1)
    }

    @Test(.tags(.rejection))
    func testUnknownVersionInvalidActionAndReceiptRejected() throws {
        var (r, s) = try game(); try append(.placeSoldier(Point(0, 0)), record: &r, session: &s)
        var json = try JSONSerialization.jsonObject(with: r.encoded()) as! [String: Any]
        json["schema"] = 2
        let unknownSchema = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: (any Error).self) {
            try MatchRecord.decode(unknownSchema)
        }
        json["schema"] = 1
        var steps = json["steps"] as! [[String: Any]]
        steps[0]["action"] = ["kind": "soldier", "points": [["x": 3, "y": 5]]]
        json["steps"] = steps // Occupied commander in formal 7×7 setup.
        let illegalAction = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: (any Error).self) {
            try MatchRecord.decode(illegalAction)
        }
        steps = (try JSONSerialization.jsonObject(with: r.encoded()) as! [String: Any])["steps"] as! [[String: Any]]
        var receipt = steps[0]["after"] as! [String: Any]; receipt["mana"] = [999, 3]
        steps[0]["after"] = receipt; json["steps"] = steps
        let badReceipt = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: (any Error).self) {
            try MatchRecord.decode(badReceipt)
        }
    }

    @Test(.tags(.rejection))
    func testEventPayloadMismatchRejectedEvenWithSameBoard() throws {
        var (r, s) = try game(); try append(.placeSoldier(Point(0, 0)), record: &r, session: &s)
        var json = try JSONSerialization.jsonObject(with: r.encoded()) as! [String: Any]
        var steps = json["steps"] as! [[String: Any]]; steps[0]["events"] = ["ResourcesSpent:0:1:999"]
        json["steps"] = steps
        let payload = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: (any Error).self) {
            try MatchRecord.decode(payload)
        }
    }

    @Test(.tags(.disk))
    func testDiskRestartAndCorruptFilesPreserved() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        var (r, s) = try game(); try append(.placeSoldier(Point(0, 0)), record: &r, session: &s)
        let repo = RecordRepository(directory: directory); try repo.save(r)
        let broken = directory.appendingPathComponent("broken.json"), data = Data("not json".utf8)
        try data.write(to: broken)
        let restarted = RecordRepository(directory: directory), listing = try restarted.list()
        #expect(listing.records.count == 1)
        #expect(listing.rejected == 1)
        #expect(try listing.records[0].rebuild().0.state == s.state)
        #expect(try Data(contentsOf: broken) == data)
    }

    @Test(.tags(.disk, .rejection))
    func testFailedWriteLeavesPreviousSaveIntact() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        var (r, s) = try game(); let repo = RecordRepository(directory: directory); try repo.save(r)
        let bytes = try Data(contentsOf: repo.url(r.id))
        try append(.placeSoldier(Point(0, 0)), record: &r, session: &s)
        r.schema = 999
        let rejectedSave = r
        #expect(throws: (any Error).self) {
            try repo.save(rejectedSave)
        }
        #expect(try Data(contentsOf: repo.url(r.id)) == bytes)
        r.schema = 1
        let blocked = directory.appendingPathComponent("not-a-directory")
        try Data("occupied path".utf8).write(to: blocked)
        let blockedSave = r
        #expect(throws: (any Error).self) {
            try RecordRepository(directory: blocked).save(blockedSave)
        }
        #expect(try Data(contentsOf: repo.url(r.id)) == bytes)
        #expect(try Data(contentsOf: blocked) == Data("occupied path".utf8))
    }

    @Test(.tags(.roundTrip), arguments: RecordRules.allCases)
    func testReplayDoesNotChangeLiveSessionOrRules(_ rules: RecordRules) throws {
        var (r, s) = try game(rules: rules); try append(.placeSoldier(Point(0, 0)), record: &r, session: &s)
        let before = s.state, frames = try r.rebuild().1
        #expect(frames.count == 2)
        #expect(frames[0].state.board[Point(0, 0)] == nil)
        #expect(frames[1].state.board[Point(0, 0)] == Piece(.one, .soldier))
        #expect(s.state == before)
        #expect(frames[1].state.config == rules.config(size: 7))
    }
}
