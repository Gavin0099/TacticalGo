import Foundation
import Testing
import TacticalGoCore
import TacticalGoContent
@testable import TacticalGoRecords

/// INTEG-ACCESS-01 P1/P2 at the file level: each case builds the on-disk state a stop would leave.
@Suite("Expansion start journal", .tags(.records, .admission, .expansion, .persistence))
struct ExpansionStartJournalTests {
    private func newSession() throws -> GameSession {
        // The same opening the app's "start match" builds (no actions yet).
        GameSession(try GameSetup.newGame(config: TacticalHints.updatedConfig(size: 7, advancedCost: 4), classOne: .warrior, classTwo: .mage))
    }

    private func fresh(_ id: UUID? = UUID()) throws -> ExpansionMatchRecord {
        try ExpansionMatchRecord(session: newSession(), matchID: id)
    }

    private func played(id: UUID) throws -> ExpansionMatchRecord {
        var session = try newSession()
        #expect(session.apply(.placeSoldier(Point(0, 0))).success)
        return try ExpansionMatchRecord(session: session, matchID: id)
    }

    private func finished(id: UUID) throws -> ExpansionMatchRecord {
        var session = try newSession()
        for action: GameAction in [
            .placeSoldier(Point(3, 2)), .endTurn, .placeSoldier(Point(2, 1)),
            .placeSoldier(Point(4, 1)), .endTurn, .placeSoldier(Point(3, 0))
        ] {
            #expect(session.apply(action).success)
        }
        #expect(session.state.status != .ongoing)
        return try ExpansionMatchRecord(session: session, matchID: id)
    }

    @Test("Staging never touches the saved match")
    func stagingNeverTouchesTheSavedMatch() throws {
        try TemporaryDirectory.withURL(prefix: "exp") { directory in
            let url = directory.appendingPathComponent("latest.json")
            let journal = ExpansionStartJournal(slot: url)
            let old = try played(id: UUID())
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try old.data().write(to: url)
            try journal.stage(try fresh())
            let onDisk = try Data(contentsOf: url)
            let freshBytes = try old.data()
            #expect(onDisk == freshBytes, "the old saved match must survive until the ledger accepted")
            #expect(FileManager.default.fileExists(atPath: journal.staging.path))
        }
    }

    @Test("A refused start discards staging and keeps the old match")
    func refusedStartDiscardsStagingAndKeepsTheOldMatch() throws {
        try TemporaryDirectory.withURL(prefix: "exp") { directory in
            let url = directory.appendingPathComponent("latest.json")
            let journal = ExpansionStartJournal(slot: url)
            let old = try played(id: UUID())
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try old.data().write(to: url)
            try journal.stage(try fresh())
            #expect(journal.recover(isUnlocked: false) { _ in false } == .discarded)
            let onDisk = try Data(contentsOf: url)
            let freshBytes = try old.data()
            #expect(onDisk == freshBytes)
            #expect(FileManager.default.fileExists(atPath: journal.staging.path) == false)
        }
    }

    @Test("A stop after the ledger accepted leaves a recoverable zero-step match")
    func stopAfterTheLedgerAcceptedLeavesARecoverableZeroStepMatch() throws {
        try TemporaryDirectory.withURL(prefix: "exp") { directory in
            let url = directory.appendingPathComponent("latest.json")
            let journal = ExpansionStartJournal(slot: url)
            let id = UUID()
            try journal.stage(try fresh(id)) // ledger accepted, then the process stopped before promote
            #expect(journal.recover(isUnlocked: false) { $0 == id } == .promoted)
            let record = try ExpansionMatchRecord.read(Data(contentsOf: url))
            #expect(record.matchID == id)
            #expect(record.actions.isEmpty)
            #expect(journal.savedTerminalIdentity() == nil)
            #expect(journal.recover(isUnlocked: false) { _ in true } == .nothingStaged, "recovery is idempotent")
        }
    }

    @Test("Promotion replaces the old slot only after acceptance")
    func promotionReplacesTheOldSlotOnlyAfterAcceptance() throws {
        try TemporaryDirectory.withURL(prefix: "exp") { directory in
            let url = directory.appendingPathComponent("latest.json")
            let journal = ExpansionStartJournal(slot: url)
            let id = UUID()
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try played(id: UUID()).data().write(to: url)
            try journal.stage(try fresh(id))
            #expect(try journal.promote() == .promoted)
            #expect(try ExpansionMatchRecord.read(Data(contentsOf: url)).matchID == id)
        }
    }

    @Test("A slot that is already further along is never rolled back by recovered staging")
    func alreadyFurtherAlongSlotIsNeverRolledBackByARecoveredStaging() throws {
        try TemporaryDirectory.withURL(prefix: "exp") { directory in
            let url = directory.appendingPathComponent("latest.json")
            let journal = ExpansionStartJournal(slot: url)
            let id = UUID()
            try journal.stage(try fresh(id))
            let further = try played(id: id) // the player moved; slot written by saveCandidate; staging leaked
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try further.data().write(to: url)
            #expect(journal.recover(isUnlocked: false) { $0 == id } == .alreadySaved)
            #expect(try ExpansionMatchRecord.read(Data(contentsOf: url)).actions.count == 1)
        }
    }

    @Test("An unreadable ledger decides nothing and keeps both files")
    func unreadableLedgerDecidesNothingAndKeepsBothFiles() throws {
        try TemporaryDirectory.withURL(prefix: "exp") { directory in
            let url = directory.appendingPathComponent("latest.json")
            let journal = ExpansionStartJournal(slot: url)
            let old = try played(id: UUID())
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try old.data().write(to: url)
            try journal.stage(try fresh())
            #expect(journal.recover(isUnlocked: false) { _ in nil } == .deferred)
            let onDisk = try Data(contentsOf: url)
            let freshBytes = try old.data()
            #expect(onDisk == freshBytes)
            #expect(FileManager.default.fileExists(atPath: journal.staging.path))
        }
    }

    @Test("An owner start is never metered, so staging is promoted without a ledger entry")
    func ownerStartIsNeverMeteredSoStagingIsPromotedWithoutALedgerEntry() throws {
        try TemporaryDirectory.withURL(prefix: "exp") { directory in
            let url = directory.appendingPathComponent("latest.json")
            let journal = ExpansionStartJournal(slot: url)
            let id = UUID()
            try journal.stage(try fresh(id))
            #expect(journal.recover(isUnlocked: true) { _ in false } == .promoted)
        }
    }

    @Test("Corrupt staging is left untouched and nothing else changes")
    func corruptStagingIsLeftUntouchedAndNothingElseChanges() throws {
        try TemporaryDirectory.withURL(prefix: "exp") { directory in
            let url = directory.appendingPathComponent("latest.json")
            let journal = ExpansionStartJournal(slot: url)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let junk = Data("not json".utf8)
            try junk.write(to: journal.staging)
            #expect(journal.recover(isUnlocked: false) { _ in true } == .unreadable)
            #expect(try Data(contentsOf: journal.staging) == junk)
            #expect(FileManager.default.fileExists(atPath: url.path) == false)
        }
    }

    // P2: the saved slot alone tells the shared layer which finished match still needs a ledger completion.
    @Test("A finished saved match is reported by identity, and an ongoing or legacy file is not")
    func finishedSavedMatchIsReportedByIdentityAndOngoingOrLegacyIsNot() throws {
        try TemporaryDirectory.withURL(prefix: "exp") { directory in
            let url = directory.appendingPathComponent("latest.json")
            let journal = ExpansionStartJournal(slot: url)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let id = UUID()
            try finished(id: id).data().write(to: url)
            #expect(journal.savedTerminalIdentity() == id)
            try played(id: UUID()).data().write(to: url)
            #expect(journal.savedTerminalIdentity() == nil)
            try finished(id: UUID()).data().write(to: url)
            var object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
            object.removeValue(forKey: "matchID")
            try JSONSerialization.data(withJSONObject: object).write(to: url)
            #expect(journal.savedTerminalIdentity() == nil, "a legacy file without identity is never charged")
        }
    }
}
