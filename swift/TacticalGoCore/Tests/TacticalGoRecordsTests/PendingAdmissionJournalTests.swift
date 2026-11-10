import Testing
import Foundation
import TacticalGoCore
@testable import TacticalGoRecords

/// C0 / R1. Each case builds the on-disk state a crash would leave and checks what the next launch does with it.
@Suite(.tags(.disk))
struct PendingAdmissionJournalTests {
    private func directory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("pending-\(UUID().uuidString)", isDirectory: true)
    }
    private func unplayedRecord() -> MatchRecord {
        MatchRecord(size: 7, one: .warrior, two: .mage, computer: nil, difficulty: "easy", rules: .redeployment)
    }

    @Test
    func testMarkerIsInvisibleToRecordListing() throws {
        let dir = directory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = RecordRepository(directory: dir)
        let journal = PendingAdmissionJournal(directory: dir)
        let record = unplayedRecord()
        try journal.mark(record.id)
        try repo.save(record)
        let listed = try repo.list()
        #expect(listed.records.map(\.id) == [record.id])
        #expect(listed.rejected == 0, "a marker must not be counted as an unreadable record")
        #expect(journal.pendingIDs() == [record.id])
    }

    @Test
    func testCrashBetweenSaveAndAuthorizationDiscardsTheUnplayedRecord() throws {
        let dir = directory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = RecordRepository(directory: dir)
        let journal = PendingAdmissionJournal(directory: dir)
        let record = unplayedRecord()
        try journal.mark(record.id)
        try repo.save(record)          // ... crash before the ledger write
        let outcome = journal.recover(repository: repo, isUnlocked: false) { _ in false }
        #expect(outcome[record.id] == .discardedUnplayedRecord)
        #expect(try repo.list().records.isEmpty, "it must not survive as a free-to-resume legacy match")
        #expect(journal.pendingIDs().isEmpty)
    }

    @Test
    func testCrashAfterAuthorizationOnlyRemovesTheMarkerAndKeepsTheRecord() throws {
        let dir = directory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = RecordRepository(directory: dir)
        let journal = PendingAdmissionJournal(directory: dir)
        let record = unplayedRecord()
        try journal.mark(record.id)
        try repo.save(record)          // ledger write done, marker removal lost
        let outcome = journal.recover(repository: repo, isUnlocked: false) { $0 == record.id }
        #expect(outcome[record.id] == .settled)
        #expect(try repo.list().records.count == 1)
        #expect(journal.pendingIDs().isEmpty)
    }

    @Test
    func testRecordWithMovesIsNeverDeleted() throws {
        let dir = directory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = RecordRepository(directory: dir)
        let journal = PendingAdmissionJournal(directory: dir)
        var record = unplayedRecord()
        var session = try record.rebuild().0
        let before = session.state, outcome = session.apply(.placeSoldier(Point(0, 0)))
        #expect(outcome.success)
        record.steps.append(RecordStep(action: .placeSoldier(Point(0, 0)), before: before, outcome: outcome, difficulty: "easy", decision: nil))
        try journal.mark(record.id)
        try repo.save(record)
        let outcomes = journal.recover(repository: repo, isUnlocked: false) { _ in false }
        #expect(outcomes[record.id] == .keptRecord)
        #expect(try repo.list().records.first?.steps.count == 1)
        #expect(journal.pendingIDs().isEmpty)
    }

    @Test
    func testUnlockedPlayerOnlyLosesTheMarker() throws {
        let dir = directory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = RecordRepository(directory: dir)
        let journal = PendingAdmissionJournal(directory: dir)
        let record = unplayedRecord()
        try journal.mark(record.id)
        try repo.save(record)
        let outcome = journal.recover(repository: repo, isUnlocked: true) { _ in false }
        #expect(outcome[record.id] == .settled)
        #expect(try repo.list().records.count == 1)
    }

    @Test
    func testUnreadableLedgerChangesNothingAndKeepsTheMarker() throws {
        let dir = directory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = RecordRepository(directory: dir)
        let journal = PendingAdmissionJournal(directory: dir)
        let record = unplayedRecord()
        try journal.mark(record.id)
        try repo.save(record)
        let outcome = journal.recover(repository: repo, isUnlocked: false) { _ in nil }
        #expect(outcome[record.id] == .deferred)
        #expect(try repo.list().records.count == 1)
        #expect(journal.pendingIDs() == [record.id])
    }

    @Test
    func testMarkerWithoutRecordAndCorruptRecordAreHandledWithoutDeletingBytes() throws {
        let dir = directory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = RecordRepository(directory: dir)
        let journal = PendingAdmissionJournal(directory: dir)
        let orphan = UUID(), corrupt = UUID()
        try journal.mark(orphan)
        try journal.mark(corrupt)
        try Data("not json".utf8).write(to: repo.url(corrupt))
        let outcome = journal.recover(repository: repo, isUnlocked: false) { _ in false }
        #expect(outcome[orphan] == .settled)
        #expect(outcome[corrupt] == .keptRecord)
        #expect(FileManager.default.fileExists(atPath: repo.url(corrupt).path), "unreadable bytes are preserved")
    }
}
