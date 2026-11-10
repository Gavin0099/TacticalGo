import Foundation
import Testing
import TacticalGoCore
@testable import TacticalGoRecords

/// C0 / R1. Each case builds the on-disk state a crash would leave and checks what the next launch does with it.
@Suite("Pending admission journal", .tags(.records, .admission, .persistence))
struct PendingAdmissionJournalTests {
    private func unplayedRecord() -> MatchRecord {
        MatchRecord(size: 7, one: .warrior, two: .mage, computer: nil, difficulty: "easy", rules: .redeployment)
    }

    @Test("A marker is invisible to record listing")
    func markerIsInvisibleToRecordListing() throws {
        try TemporaryDirectory.withURL(prefix: "pending") { directory in
            let repo = RecordRepository(directory: directory)
            let journal = PendingAdmissionJournal(directory: directory)
            let record = unplayedRecord()
            try journal.mark(record.id)
            try repo.save(record)
            let listed = try repo.list()
            #expect(listed.records.map(\.id) == [record.id])
            #expect(listed.rejected == 0, "a marker must not be counted as an unreadable record")
            #expect(journal.pendingIDs() == [record.id])
        }
    }

    @Test("A crash between save and authorization discards the unplayed record")
    func crashBetweenSaveAndAuthorizationDiscardsTheUnplayedRecord() throws {
        try TemporaryDirectory.withURL(prefix: "pending") { directory in
            let repo = RecordRepository(directory: directory)
            let journal = PendingAdmissionJournal(directory: directory)
            let record = unplayedRecord()
            try journal.mark(record.id)
            try repo.save(record) // ... crash before the ledger write
            let outcome = journal.recover(repository: repo, isUnlocked: false) { _ in false }
            #expect(outcome[record.id] == .discardedUnplayedRecord)
            #expect(try repo.list().records.isEmpty, "it must not survive as a free-to-resume legacy match")
            #expect(journal.pendingIDs().isEmpty)
        }
    }

    @Test("A crash after authorization only removes the marker and keeps the record")
    func crashAfterAuthorizationOnlyRemovesTheMarkerAndKeepsTheRecord() throws {
        try TemporaryDirectory.withURL(prefix: "pending") { directory in
            let repo = RecordRepository(directory: directory)
            let journal = PendingAdmissionJournal(directory: directory)
            let record = unplayedRecord()
            try journal.mark(record.id)
            try repo.save(record) // ledger write done, marker removal lost
            let outcome = journal.recover(repository: repo, isUnlocked: false) { $0 == record.id }
            #expect(outcome[record.id] == .settled)
            #expect(try repo.list().records.count == 1)
            #expect(journal.pendingIDs().isEmpty)
        }
    }

    @Test("A record with moves is never deleted")
    func recordWithMovesIsNeverDeleted() throws {
        try TemporaryDirectory.withURL(prefix: "pending") { directory in
            let repo = RecordRepository(directory: directory)
            let journal = PendingAdmissionJournal(directory: directory)
            var record = unplayedRecord()
            var session = try record.rebuild().0
            let before = session.state
            let outcome = session.apply(.placeSoldier(Point(0, 0)))
            #expect(outcome.success)
            record.steps.append(RecordStep(action: .placeSoldier(Point(0, 0)), before: before, outcome: outcome, difficulty: "easy", decision: nil))
            try journal.mark(record.id)
            try repo.save(record)
            let outcomes = journal.recover(repository: repo, isUnlocked: false) { _ in false }
            #expect(outcomes[record.id] == .keptRecord)
            #expect(try repo.list().records.first?.steps.count == 1)
            #expect(journal.pendingIDs().isEmpty)
        }
    }

    @Test("An unlocked player only loses the marker")
    func unlockedPlayerOnlyLosesTheMarker() throws {
        try TemporaryDirectory.withURL(prefix: "pending") { directory in
            let repo = RecordRepository(directory: directory)
            let journal = PendingAdmissionJournal(directory: directory)
            let record = unplayedRecord()
            try journal.mark(record.id)
            try repo.save(record)
            let outcome = journal.recover(repository: repo, isUnlocked: true) { _ in false }
            #expect(outcome[record.id] == .settled)
            #expect(try repo.list().records.count == 1)
        }
    }

    @Test("An unreadable ledger changes nothing and keeps the marker")
    func unreadableLedgerChangesNothingAndKeepsTheMarker() throws {
        try TemporaryDirectory.withURL(prefix: "pending") { directory in
            let repo = RecordRepository(directory: directory)
            let journal = PendingAdmissionJournal(directory: directory)
            let record = unplayedRecord()
            try journal.mark(record.id)
            try repo.save(record)
            let outcome = journal.recover(repository: repo, isUnlocked: false) { _ in nil }
            #expect(outcome[record.id] == .deferred)
            #expect(try repo.list().records.count == 1)
            #expect(journal.pendingIDs() == [record.id])
        }
    }

    @Test("A marker without a record and a corrupt record are handled without deleting bytes")
    func markerWithoutRecordAndCorruptRecordAreHandledWithoutDeletingBytes() throws {
        try TemporaryDirectory.withURL(prefix: "pending") { directory in
            let repo = RecordRepository(directory: directory)
            let journal = PendingAdmissionJournal(directory: directory)
            let orphan = UUID()
            let corrupt = UUID()
            try journal.mark(orphan)
            try journal.mark(corrupt)
            try Data("not json".utf8).write(to: repo.url(corrupt))
            let outcome = journal.recover(repository: repo, isUnlocked: false) { _ in false }
            #expect(outcome[orphan] == .settled)
            #expect(outcome[corrupt] == .keptRecord)
            #expect(FileManager.default.fileExists(atPath: repo.url(corrupt).path), "unreadable bytes are preserved")
        }
    }
}
