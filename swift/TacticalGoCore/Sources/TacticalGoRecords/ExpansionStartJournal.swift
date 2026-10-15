import Foundation

/// INTEG-ACCESS-01 / P1. An expansion start first asks the access ledger (which may reserve a reward credit) and
/// only then used to write its first save, on the first successful move. A stop in between left a reserved credit and
/// no match to resume. The new match is therefore staged as a complete zero-step record BEFORE the ledger is asked:
///
///   stage  ->  ledger authorization  ->  promote (atomic replace of the single saved slot)
///
/// - Nothing touches the existing saved match until the ledger has accepted the start, so a refused start keeps it.
/// - If the process stops after the ledger accepted, the next launch finds the staged record and, because the ledger
///   knows its identity, promotes it: the admitted match is always recoverable and is charged exactly once.
/// - If the ledger never accepted, the staged record is discarded and the old saved match stays as it was.
public struct ExpansionStartJournal: Sendable {
    public enum Outcome: Equatable, Sendable {
        case nothingStaged
        /// Admitted (or an unmetered owner start) and now the saved match.
        case promoted
        /// Admitted and the saved slot already holds this match (possibly further along): only the staging was removed.
        case alreadySaved
        /// Never admitted: staging removed, the previously saved match is untouched.
        case discarded
        /// The ledger could not be consulted: nothing was changed, staging stays for the next launch.
        case deferred
        /// The staged bytes are not a valid record: left in place for diagnosis, nothing else changed.
        case unreadable
    }

    public let slot: URL
    public init(slot: URL) { self.slot = slot }
    public var staging: URL { slot.deletingLastPathComponent().appendingPathComponent("pending-start.json") }

    /// Validates (full replay) and writes the record next to the slot; never touches the slot.
    public func stage(_ record: ExpansionMatchRecord) throws {
        let bytes = try record.data()
        try FileManager.default.createDirectory(at: slot.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: staging, options: .atomic)
    }

    public func discard() { try? FileManager.default.removeItem(at: staging) }

    /// Makes the staged match the saved match. A slot that already holds the same identity is kept (it can be further along).
    @discardableResult
    public func promote() throws -> Outcome {
        guard FileManager.default.fileExists(atPath: staging.path) else { return .nothingStaged }
        guard let stagedData = try? Data(contentsOf: staging), let staged = try? ExpansionMatchRecord.read(stagedData) else {
            return .unreadable
        }
        if let current = try? Data(contentsOf: slot), let existing = try? ExpansionMatchRecord.read(current),
           let id = staged.matchID, existing.matchID == id {
            discard(); return .alreadySaved
        }
        try FileManager.default.createDirectory(at: slot.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: slot.path) {
            _ = try FileManager.default.replaceItemAt(slot, withItemAt: staging)
        } else {
            try FileManager.default.moveItem(at: staging, to: slot)
        }
        return .promoted
    }

    /// Launch recovery. `isRegistered` answers nil when the ledger cannot be read (then nothing is decided).
    @discardableResult
    public func recover(isUnlocked: Bool, isRegistered: (UUID) -> Bool?) -> Outcome {
        guard FileManager.default.fileExists(atPath: staging.path) else { return .nothingStaged }
        guard let data = try? Data(contentsOf: staging), let staged = try? ExpansionMatchRecord.read(data),
              let id = staged.matchID else { return .unreadable }
        if isUnlocked { return (try? promote()) ?? .deferred }
        guard let registered = isRegistered(id) else { return .deferred }
        guard registered else { discard(); return .discarded }
        return (try? promote()) ?? .deferred
    }

    /// Identity of the saved match when it is already finished. `nil` for no file, an unfinished match, a legacy file
    /// without an identity, or anything that fails validation (the file is never modified here).
    public func savedTerminalIdentity() -> UUID? {
        guard let data = try? Data(contentsOf: slot), let record = try? ExpansionMatchRecord.read(data),
              let id = record.matchID, record.expected.status != .ongoing else { return nil }
        return id
    }
}
