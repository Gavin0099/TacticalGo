import XCTest
import Foundation
import TacticalGoCore
@testable import TacticalGoRecords

/// C0 / R1. Each case builds the on-disk state a crash would leave and checks what the next launch does with it.
final class PendingAdmissionJournalTests: XCTestCase {
    private func directory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pending-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
    private func unplayedRecord() -> MatchRecord {
        MatchRecord(size: 7, one: .warrior, two: .mage, computer: nil, difficulty: "easy", rules: .redeployment)
    }

    func testMarkerIsInvisibleToRecordListing() throws {
        let dir = directory(); let repo = RecordRepository(directory: dir); let journal = PendingAdmissionJournal(directory: dir)
        let record = unplayedRecord()
        try journal.mark(record.id); try repo.save(record)
        let listed = try repo.list()
        XCTAssertEqual(listed.records.map(\.id), [record.id])
        XCTAssertEqual(listed.rejected, 0, "a marker must not be counted as an unreadable record")
        XCTAssertEqual(journal.pendingIDs(), [record.id])
    }

    func testCrashBetweenSaveAndAuthorizationDiscardsTheUnplayedRecord() throws {
        let dir = directory(); let repo = RecordRepository(directory: dir); let journal = PendingAdmissionJournal(directory: dir)
        let record = unplayedRecord()
        try journal.mark(record.id); try repo.save(record)          // ... crash before the ledger write
        let outcome = journal.recover(repository: repo, isUnlocked: false) { _ in false }
        XCTAssertEqual(outcome[record.id], .discardedUnplayedRecord)
        XCTAssertTrue(try repo.list().records.isEmpty, "it must not survive as a free-to-resume legacy match")
        XCTAssertTrue(journal.pendingIDs().isEmpty)
    }

    func testCrashAfterAuthorizationOnlyRemovesTheMarkerAndKeepsTheRecord() throws {
        let dir = directory(); let repo = RecordRepository(directory: dir); let journal = PendingAdmissionJournal(directory: dir)
        let record = unplayedRecord()
        try journal.mark(record.id); try repo.save(record)          // ledger write done, marker removal lost
        let outcome = journal.recover(repository: repo, isUnlocked: false) { $0 == record.id }
        XCTAssertEqual(outcome[record.id], .settled)
        XCTAssertEqual(try repo.list().records.count, 1)
        XCTAssertTrue(journal.pendingIDs().isEmpty)
    }

    func testRecordWithMovesIsNeverDeleted() throws {
        let dir = directory(); let repo = RecordRepository(directory: dir); let journal = PendingAdmissionJournal(directory: dir)
        var record = unplayedRecord()
        var session = try record.rebuild().0
        let before = session.state, outcome = session.apply(.placeSoldier(Point(0, 0)))
        XCTAssertTrue(outcome.success)
        record.steps.append(RecordStep(action: .placeSoldier(Point(0, 0)), before: before, outcome: outcome, difficulty: "easy", decision: nil))
        try journal.mark(record.id); try repo.save(record)
        let outcomes = journal.recover(repository: repo, isUnlocked: false) { _ in false }
        XCTAssertEqual(outcomes[record.id], .keptRecord)
        XCTAssertEqual(try repo.list().records.first?.steps.count, 1)
        XCTAssertTrue(journal.pendingIDs().isEmpty)
    }

    func testUnlockedPlayerOnlyLosesTheMarker() throws {
        let dir = directory(); let repo = RecordRepository(directory: dir); let journal = PendingAdmissionJournal(directory: dir)
        let record = unplayedRecord()
        try journal.mark(record.id); try repo.save(record)
        let outcome = journal.recover(repository: repo, isUnlocked: true) { _ in false }
        XCTAssertEqual(outcome[record.id], .settled)
        XCTAssertEqual(try repo.list().records.count, 1)
    }

    func testUnreadableLedgerChangesNothingAndKeepsTheMarker() throws {
        let dir = directory(); let repo = RecordRepository(directory: dir); let journal = PendingAdmissionJournal(directory: dir)
        let record = unplayedRecord()
        try journal.mark(record.id); try repo.save(record)
        let outcome = journal.recover(repository: repo, isUnlocked: false) { _ in nil }
        XCTAssertEqual(outcome[record.id], .deferred)
        XCTAssertEqual(try repo.list().records.count, 1)
        XCTAssertEqual(journal.pendingIDs(), [record.id])
    }

    func testMarkerWithoutRecordAndCorruptRecordAreHandledWithoutDeletingBytes() throws {
        let dir = directory(); let repo = RecordRepository(directory: dir); let journal = PendingAdmissionJournal(directory: dir)
        let orphan = UUID(), corrupt = UUID()
        try journal.mark(orphan); try journal.mark(corrupt)
        try Data("not json".utf8).write(to: repo.url(corrupt))
        let outcome = journal.recover(repository: repo, isUnlocked: false) { _ in false }
        XCTAssertEqual(outcome[orphan], .settled)
        XCTAssertEqual(outcome[corrupt], .keptRecord)
        XCTAssertTrue(FileManager.default.fileExists(atPath: repo.url(corrupt).path), "unreadable bytes are preserved")
    }
}
