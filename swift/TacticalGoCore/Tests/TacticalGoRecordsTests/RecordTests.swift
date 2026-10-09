import XCTest
import Foundation
import TacticalGoCore
@testable import TacticalGoRecords

final class RecordTests: XCTestCase {
    func game(size: Int = 7, hero: HeroClass = .warrior, rules: RecordRules = .original) throws -> (MatchRecord, GameSession) {
        let r = MatchRecord(size: size, one: hero, two: .mage, computer: size == 7 ? .two : nil, difficulty: "easy", rules: rules)
        return (r, try r.rebuild().0)
    }
    func append(_ a: GameAction, record: inout MatchRecord, session: inout GameSession) throws {
        let before = session.state, outcome = session.apply(a)
        XCTAssertTrue(outcome.success, "Fixture action must be legal: \(a)")
        record.steps.append(RecordStep(action: a, before: before, outcome: outcome, difficulty: "easy", decision: nil))
    }
    func testSevenNineRoundTripAndUndoPreserveFullState() throws {
        for size in [7,9] {
            var (r,s) = try game(size: size)
            try append(.placeSoldier(Point(0,0)), record: &r, session: &s)
            XCTAssertEqual(s.state.current,.two); XCTAssertEqual(s.state.apRemaining,2)
            let before = s.state
            try append(.summonHero(Point(size/2,2)), record: &r, session: &s)
            XCTAssertEqual(s.state.mana(of:.two),1)
            var rebuilt = try MatchRecord.decode(r.encoded()).rebuild().0
            XCTAssertEqual(rebuilt.state,s.state)
            XCTAssertTrue(rebuilt.undo()); XCTAssertEqual(rebuilt.state,before)
            XCTAssertTrue(rebuilt.undo()); XCTAssertEqual(rebuilt.state,try game(size:size).1.state)
        }
    }
    func testSkillReceiptResourceAndHistoryRoundTrip() throws {
        var (r,s) = try game()
        for a: GameAction in [.placeSoldier(Point(3,4)), .endTurn, .summonHero(Point(3,3)), .placeSoldier(Point(0,0)), .endTurn, .castBastion(Point(2,3),Point(4,3))] {
            try append(a, record:&r,session:&s)
        }
        XCTAssertEqual(s.state.apRemaining,1); XCTAssertEqual(s.state.mana(of:.one),2)
        XCTAssertTrue(s.state.skillUsedThisTurn); XCTAssertTrue(s.state.hasSummonedHero(.one))
        let restored = try MatchRecord.decode(r.encoded()).rebuild()
        XCTAssertEqual(restored.0.state,s.state) // Includes exact internal superko history.
        XCTAssertEqual(GameEngine.validate(restored.0.state,.castBastion(Point(2,4),Point(4,4))),.skillAlreadyUsed)
        XCTAssertEqual(restored.1.last?.events.first,.resourcesSpent(.one,ap:1,mana:2))
    }
    func testCommanderCaptureTerminalEventsAndPostGameRejection() throws {
        var (r,s) = try game()
        for a: GameAction in [.placeSoldier(Point(3,2)),.endTurn,.placeSoldier(Point(2,1)),.placeSoldier(Point(4,1)),.endTurn,.placeSoldier(Point(3,0))] {
            try append(a,record:&r,session:&s)
        }
        XCTAssertEqual(s.state.status,.won); XCTAssertEqual(s.state.winner,.one)
        let rebuilt = try MatchRecord.decode(r.encoded()).rebuild()
        XCTAssertEqual(rebuilt.0.state,s.state)
        XCTAssertTrue(rebuilt.1.last!.events.contains(.gameWon(.one)))
        let captures = rebuilt.1.last!.events.compactMap { e -> [CapturedPiece]? in
            if case .piecesCaptured(.one,let pieces) = e { return pieces }; return nil
        }.flatMap { $0 }
        XCTAssertEqual(captures.count,1); XCTAssertEqual(captures[0].at,Point(3,1))
        XCTAssertEqual(captures[0].piece,Piece(.two,.commander))
        let rejected = GameEngine.apply(s.state,.endTurn)
        r.steps.append(RecordStep(action:.endTurn,before:s.state,outcome:rejected,difficulty:"easy",decision:nil))
        XCTAssertThrowsError(try MatchRecord.decode(r.encoded()))
    }
    func testUndoTruncationCannotResurrectComputerMove() throws {
        var (r,s) = try game()
        for a: GameAction in [.placeSoldier(Point(0,0)),.placeSoldier(Point(1,0)),.placeSoldier(Point(2,0))] { try append(a,record:&r,session:&s) }
        XCTAssertTrue(s.undo()); r.steps.removeLast()
        let restored = try MatchRecord.decode(r.encoded()).rebuild().0
        XCTAssertEqual(restored.state,s.state); XCTAssertNil(restored.state.board[Point(2,0)])
        XCTAssertEqual(restored.state.apRemaining,1)
    }
    func testUnknownVersionInvalidActionAndReceiptRejected() throws {
        var (r,s) = try game(); try append(.placeSoldier(Point(0,0)),record:&r,session:&s)
        var json = try JSONSerialization.jsonObject(with:r.encoded()) as! [String:Any]
        json["schema"] = 2
        XCTAssertThrowsError(try MatchRecord.decode(JSONSerialization.data(withJSONObject:json)))
        json["schema"] = 1
        var steps = json["steps"] as! [[String:Any]]
        steps[0]["action"] = ["kind":"soldier","points":[["x":3,"y":5]]]
        json["steps"] = steps // Occupied commander in formal 7×7 setup.
        XCTAssertThrowsError(try MatchRecord.decode(JSONSerialization.data(withJSONObject:json)))
        steps = (try JSONSerialization.jsonObject(with:r.encoded()) as! [String:Any])["steps"] as! [[String:Any]]
        var receipt = steps[0]["after"] as! [String:Any]; receipt["mana"] = [999,3]
        steps[0]["after"] = receipt; json["steps"] = steps
        XCTAssertThrowsError(try MatchRecord.decode(JSONSerialization.data(withJSONObject:json)))
    }
    func testEventPayloadMismatchRejectedEvenWithSameBoard() throws {
        var (r,s) = try game(); try append(.placeSoldier(Point(0,0)),record:&r,session:&s)
        var json = try JSONSerialization.jsonObject(with:r.encoded()) as! [String:Any]
        var steps = json["steps"] as! [[String:Any]]; steps[0]["events"] = ["ResourcesSpent:0:1:999"]
        json["steps"] = steps
        XCTAssertThrowsError(try MatchRecord.decode(JSONSerialization.data(withJSONObject:json)))
    }
    func testDiskRestartAndCorruptFilesPreserved() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:directory) }
        var (r,s) = try game(); try append(.placeSoldier(Point(0,0)),record:&r,session:&s)
        let repo = RecordRepository(directory:directory); try repo.save(r)
        let broken = directory.appendingPathComponent("broken.json"), data = Data("not json".utf8)
        try data.write(to:broken)
        let restarted = RecordRepository(directory:directory), listing = try restarted.list()
        XCTAssertEqual(listing.records.count,1); XCTAssertEqual(listing.rejected,1)
        XCTAssertEqual(try listing.records[0].rebuild().0.state,s.state)
        XCTAssertEqual(try Data(contentsOf:broken),data)
    }
    func testFailedWriteLeavesPreviousSaveIntact() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:directory) }
        var (r,s) = try game(); let repo = RecordRepository(directory:directory); try repo.save(r)
        let bytes = try Data(contentsOf:repo.url(r.id))
        try append(.placeSoldier(Point(0,0)),record:&r,session:&s)
        r.schema = 999; XCTAssertThrowsError(try repo.save(r))
        XCTAssertEqual(try Data(contentsOf:repo.url(r.id)),bytes)
        r.schema = 1
        let blocked = directory.appendingPathComponent("not-a-directory")
        try Data("occupied path".utf8).write(to:blocked)
        XCTAssertThrowsError(try RecordRepository(directory:blocked).save(r))
        XCTAssertEqual(try Data(contentsOf:repo.url(r.id)),bytes)
        XCTAssertEqual(try Data(contentsOf:blocked),Data("occupied path".utf8))
    }
    func testReplayDoesNotChangeLiveSessionOrRules() throws {
        for rules in RecordRules.allCases {
            var (r,s) = try game(rules:rules); try append(.placeSoldier(Point(0,0)),record:&r,session:&s)
            let before = s.state, frames = try r.rebuild().1
            XCTAssertEqual(frames.count,2); XCTAssertNil(frames[0].state.board[Point(0,0)])
            XCTAssertEqual(frames[1].state.board[Point(0,0)],Piece(.one,.soldier))
            XCTAssertEqual(s.state,before); XCTAssertEqual(frames[1].state.config,rules.config(size:7))
        }
    }
}
