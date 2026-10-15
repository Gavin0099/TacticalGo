import XCTest
import Foundation
import TacticalGoCore
import TacticalGoContent
@testable import TacticalGoRecords

/// INTEG-ACCESS-01 P1/P2 at the file level: each case builds the on-disk state a stop would leave.
final class ExpansionStartJournalTests: XCTestCase {
    private func slot() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("exp-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir.appendingPathComponent("latest.json")
    }
    private func newSession() throws -> GameSession {
        // The same opening the app's "start match" builds (no actions yet).
        GameSession(try GameSetup.newGame(config: TacticalHints.updatedConfig(size: 7, advancedCost: 4), classOne: .warrior, classTwo: .mage))
    }
    private func fresh(_ id: UUID? = UUID()) throws -> ExpansionMatchRecord {
        try ExpansionMatchRecord(session: newSession(), matchID: id)
    }
    private func played(id: UUID) throws -> ExpansionMatchRecord {
        var s = try newSession()
        XCTAssertTrue(s.apply(.placeSoldier(Point(0, 0))).success)
        return try ExpansionMatchRecord(session: s, matchID: id)
    }
    private func finished(id: UUID) throws -> ExpansionMatchRecord {
        var s = try newSession()
        for a: GameAction in [.placeSoldier(Point(3,2)), .endTurn, .placeSoldier(Point(2,1)), .placeSoldier(Point(4,1)), .endTurn, .placeSoldier(Point(3,0))] {
            XCTAssertTrue(s.apply(a).success)
        }
        XCTAssertNotEqual(s.state.status, .ongoing)
        return try ExpansionMatchRecord(session: s, matchID: id)
    }

    func testStagingNeverTouchesTheSavedMatch() throws {
        let url = slot(); let journal = ExpansionStartJournal(slot: url)
        let old = try played(id: UUID())
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try old.data().write(to: url)
        try journal.stage(try fresh())
        XCTAssertEqual(try Data(contentsOf: url), try old.data(), "the old saved match must survive until the ledger accepted")
        XCTAssertTrue(FileManager.default.fileExists(atPath: journal.staging.path))
    }

    func testRefusedStartDiscardsStagingAndKeepsTheOldMatch() throws {
        let url = slot(); let journal = ExpansionStartJournal(slot: url)
        let old = try played(id: UUID())
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try old.data().write(to: url)
        try journal.stage(try fresh())
        XCTAssertEqual(journal.recover(isUnlocked: false) { _ in false }, .discarded)
        XCTAssertEqual(try Data(contentsOf: url), try old.data())
        XCTAssertFalse(FileManager.default.fileExists(atPath: journal.staging.path))
    }

    func testStopAfterTheLedgerAcceptedLeavesARecoverableZeroStepMatch() throws {
        let url = slot(); let journal = ExpansionStartJournal(slot: url)
        let id = UUID()
        try journal.stage(try fresh(id))            // ledger accepted, then the process stopped before promote
        XCTAssertEqual(journal.recover(isUnlocked: false) { $0 == id }, .promoted)
        let record = try ExpansionMatchRecord.read(Data(contentsOf: url))
        XCTAssertEqual(record.matchID, id)
        XCTAssertTrue(record.actions.isEmpty)
        XCTAssertNil(journal.savedTerminalIdentity())
        XCTAssertEqual(journal.recover(isUnlocked: false) { _ in true }, .nothingStaged, "recovery is idempotent")
    }

    func testPromotionReplacesTheOldSlotOnlyAfterAcceptance() throws {
        let url = slot(); let journal = ExpansionStartJournal(slot: url)
        let id = UUID()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try played(id: UUID()).data().write(to: url)
        try journal.stage(try fresh(id))
        XCTAssertEqual(try journal.promote(), .promoted)
        XCTAssertEqual(try ExpansionMatchRecord.read(Data(contentsOf: url)).matchID, id)
    }

    func testAlreadyFurtherAlongSlotIsNeverRolledBackByARecoveredStaging() throws {
        let url = slot(); let journal = ExpansionStartJournal(slot: url)
        let id = UUID()
        try journal.stage(try fresh(id))
        let further = try played(id: id)             // the player moved; slot written by saveCandidate; staging leaked
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try further.data().write(to: url)
        XCTAssertEqual(journal.recover(isUnlocked: false) { $0 == id }, .alreadySaved)
        XCTAssertEqual(try ExpansionMatchRecord.read(Data(contentsOf: url)).actions.count, 1)
    }

    func testUnreadableLedgerDecidesNothingAndKeepsBothFiles() throws {
        let url = slot(); let journal = ExpansionStartJournal(slot: url)
        let old = try played(id: UUID())
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try old.data().write(to: url)
        try journal.stage(try fresh())
        XCTAssertEqual(journal.recover(isUnlocked: false) { _ in nil }, .deferred)
        XCTAssertEqual(try Data(contentsOf: url), try old.data())
        XCTAssertTrue(FileManager.default.fileExists(atPath: journal.staging.path))
    }

    func testOwnerStartIsNeverMeteredSoStagingIsPromotedWithoutALedgerEntry() throws {
        let url = slot(); let journal = ExpansionStartJournal(slot: url)
        let id = UUID()
        try journal.stage(try fresh(id))
        XCTAssertEqual(journal.recover(isUnlocked: true) { _ in false }, .promoted)
    }

    func testCorruptStagingIsLeftUntouchedAndNothingElseChanges() throws {
        let url = slot(); let journal = ExpansionStartJournal(slot: url)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let junk = Data("not json".utf8)
        try junk.write(to: journal.staging)
        XCTAssertEqual(journal.recover(isUnlocked: false) { _ in true }, .unreadable)
        XCTAssertEqual(try Data(contentsOf: journal.staging), junk)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    // P2: the saved slot alone tells the shared layer which finished match still needs a ledger completion.
    func testFinishedSavedMatchIsReportedByIdentityAndOngoingOrLegacyIsNot() throws {
        let url = slot(); let journal = ExpansionStartJournal(slot: url)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let id = UUID()
        try finished(id: id).data().write(to: url)
        XCTAssertEqual(journal.savedTerminalIdentity(), id)
        try played(id: UUID()).data().write(to: url)
        XCTAssertNil(journal.savedTerminalIdentity())
        try finished(id: UUID()).data().write(to: url)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        object.removeValue(forKey: "matchID")
        try JSONSerialization.data(withJSONObject: object).write(to: url)
        XCTAssertNil(journal.savedTerminalIdentity(), "a legacy file without identity is never charged")
    }
}
