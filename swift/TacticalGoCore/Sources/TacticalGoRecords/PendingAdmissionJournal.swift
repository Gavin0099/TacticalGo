import Foundation

/// C0 / R1: a new original-rules match is saved to disk BEFORE the access ledger authorizes it. If the app stops in
/// between, the record would be indistinguishable from a legacy match that was never registered (free to resume).
/// A marker file `<id>.pending` is written before the record and removed only after the authorization succeeded
/// (or the record was removed again). On the next launch `recover` settles every marker that is still there.
///
/// Markers use a different file extension from records, so record loading never sees them, and no record schema changes.
public struct PendingAdmissionJournal: Sendable {
    public enum Outcome: Equatable, Sendable {
        /// The ledger knows the match, or the player owns the unlock (nothing is metered): only the marker was removed.
        case settled
        /// Never authorized and never played (no steps): the unplayed record was removed, so it cannot become a free match.
        case discardedUnplayedRecord
        /// Never authorized but already has moves, or could not be read: the record is kept untouched.
        case keptRecord
        /// The ledger could not be consulted: nothing was changed, the marker stays for the next launch.
        case deferred
    }

    public let directory: URL
    public init(directory: URL) { self.directory = directory }

    public func marker(_ id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString).appendingPathExtension("pending")
    }

    public func mark(_ id: UUID) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data().write(to: marker(id), options: .atomic)
    }

    public func clear(_ id: UUID) {
        try? FileManager.default.removeItem(at: marker(id))
    }

    public func pendingIDs() -> [UUID] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return [] }
        return files.filter { $0.pathExtension == "pending" }
            .compactMap { UUID(uuidString: $0.deletingPathExtension().lastPathComponent) }
            .sorted { $0.uuidString < $1.uuidString }
    }

    /// `isRegistered` answers nil when the ledger cannot be read; in that case nothing is deleted.
    @discardableResult
    public func recover(repository: RecordRepository, isUnlocked: Bool,
                        isRegistered: (UUID) -> Bool?) -> [UUID: Outcome] {
        var outcomes: [UUID: Outcome] = [:]
        for id in pendingIDs() {
            if isUnlocked { clear(id); outcomes[id] = .settled; continue }
            guard let registered = isRegistered(id) else { outcomes[id] = .deferred; continue }
            if registered { clear(id); outcomes[id] = .settled; continue }
            let url = repository.url(id)
            guard FileManager.default.fileExists(atPath: url.path) else { clear(id); outcomes[id] = .settled; continue }
            if let data = try? Data(contentsOf: url), let record = try? MatchRecord.decode(data), record.steps.isEmpty {
                do { try FileManager.default.removeItem(at: url); clear(id); outcomes[id] = .discardedUnplayedRecord }
                catch { outcomes[id] = .deferred }
            } else {
                clear(id); outcomes[id] = .keptRecord
            }
        }
        return outcomes
    }
}
