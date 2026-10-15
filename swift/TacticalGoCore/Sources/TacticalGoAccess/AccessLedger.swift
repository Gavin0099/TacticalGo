import Foundation

/// Commercial access is separate from board rules, replay records and StoreKit entitlements.
public enum AccessMatchKind: String, Codable, Equatable, Sendable {
    case battle
    case tutorial
    case challenge
}

public enum AccessMatchAuthorization: String, Codable, Equatable, Sendable {
    case trial
    case rewarded
    case unlocked
    case notMetered
}

public enum AccessStartAvailability: Equatable, Sendable {
    case trial(remainingCompletedMatches: Int)
    case rewardCredit
    case unlocked
    case requiresRewardOrPurchase
}

public enum AccessLedgerError: Error, Equatable, Sendable {
    case corruptData
    case unsupportedVersion(Int)
    case accessRequired
    case completedMatchCannotRestart
    case matchKindMismatch
}

public struct AccessLedgerSnapshot: Equatable, Sendable {
    public let completedTrialMatches: Int
    public let remainingTrialMatches: Int
    public let rewardCredits: Int
    public let registeredMatches: Int
}

/// A missing file is a new installation. Any other read/decode failure must stay an error.
public protocol AccessLedgerPersistence {
    func load() throws -> Data?
    func save(_ data: Data) throws
}

public struct FileAccessLedgerPersistence: AccessLedgerPersistence {
    public let fileURL: URL

    public init(fileURL: URL) { self.fileURL = fileURL }

    public func load() throws -> Data? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try Data(contentsOf: fileURL)
    }

    public func save(_ data: Data) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }
}

private struct AccessMatchEntry: Codable, Equatable {
    let id: UUID
    let kind: AccessMatchKind
    let authorization: AccessMatchAuthorization
    let rewardRequestID: UUID?
    var completed: Bool
    /// C0 / M6: a playable copy of an admitted match. It keeps its own identity but is the SAME admission:
    /// it never adds a counted trial, never reserves a second reward, and its completion settles its parent.
    var continuationOf: UUID?
}

private struct AccessLedger: Codable, Equatable {
    let schemaVersion: Int
    var matches: [AccessMatchEntry]
    var rewardRequests: [UUID]

    static let empty = AccessLedger(schemaVersion: 1, matches: [], rewardRequests: [])
    static let trialLimit = 3

    var completedTrialMatches: Int {
        matches.filter { $0.authorization == .trial && $0.completed && $0.continuationOf == nil }.count
    }

    var availableRewards: [UUID] {
        let reserved = Set(matches.compactMap(\.rewardRequestID))
        return rewardRequests.filter { !reserved.contains($0) }
    }

    func validate() throws {
        guard schemaVersion == 1 else { throw AccessLedgerError.unsupportedVersion(schemaVersion) }
        guard Set(matches.map(\.id)).count == matches.count,
              Set(rewardRequests).count == rewardRequests.count else {
            throw AccessLedgerError.corruptData
        }
        var reserved = Set<UUID>()
        for match in matches {
            let isMetered = match.kind == .battle
            guard (match.authorization == .notMetered) == !isMetered else {
                throw AccessLedgerError.corruptData
            }
            if let parentID = match.continuationOf {
                guard let parent = matches.first(where: { $0.id == parentID }), parent.continuationOf == nil,
                      parent.kind == match.kind, parent.authorization == match.authorization,
                      match.rewardRequestID == nil, parentID != match.id else {
                    throw AccessLedgerError.corruptData
                }
                continue
            }
            if match.authorization == .rewarded {
                guard let requestID = match.rewardRequestID,
                      rewardRequests.contains(requestID),
                      reserved.insert(requestID).inserted else {
                    throw AccessLedgerError.corruptData
                }
            } else if match.rewardRequestID != nil {
                throw AccessLedgerError.corruptData
            }
        }
    }
}

/// All mutations are serialized, then saved before becoming visible to the UI.
/// `isUnlocked` must come from the current verified StoreKit entitlement; it is never cached here.
@MainActor
public final class AccessLedgerStore {
    private let persistence: any AccessLedgerPersistence
    private var ledger: AccessLedger

    public init(storage: any AccessLedgerPersistence) throws {
        persistence = storage
        if let data = try storage.load() {
            let decoded: AccessLedger
            do { decoded = try JSONDecoder().decode(AccessLedger.self, from: data) }
            catch { throw AccessLedgerError.corruptData }
            try decoded.validate()
            ledger = decoded
        } else {
            // Persist initialization so a write failure cannot silently grant a volatile trial.
            try storage.save(Self.encode(.empty))
            ledger = .empty
        }
    }

    public var snapshot: AccessLedgerSnapshot {
        AccessLedgerSnapshot(
            completedTrialMatches: ledger.completedTrialMatches,
            remainingTrialMatches: max(0, AccessLedger.trialLimit - ledger.completedTrialMatches),
            rewardCredits: ledger.availableRewards.count,
            registeredMatches: ledger.matches.count
        )
    }

    /// True when this match identity has an entry (any authorization, completed or not).
    public func isRegistered(id: UUID) -> Bool { ledger.matches.contains { $0.id == id } }

    public func newMatchAccess(isUnlocked: Bool) -> AccessStartAvailability {
        if isUnlocked { return .unlocked }
        if snapshot.remainingTrialMatches > 0 {
            return .trial(remainingCompletedMatches: snapshot.remainingTrialMatches)
        }
        return ledger.availableRewards.isEmpty ? .requiresRewardOrPurchase : .rewardCredit
    }

    /// Call only when actually creating a new match, never while showing a preview or resuming.
    /// An already admitted unfinished match keeps its access if the quota expires or a purchase is revoked.
    @discardableResult
    public func beginMatch(
        id: UUID, kind: AccessMatchKind = .battle, isUnlocked: Bool
    ) throws -> AccessMatchAuthorization {
        if let existing = ledger.matches.first(where: { $0.id == id }) {
            guard existing.kind == kind else { throw AccessLedgerError.matchKindMismatch }
            guard !existing.completed else { throw AccessLedgerError.completedMatchCannotRestart }
            return existing.authorization
        }
        let authorization: AccessMatchAuthorization
        let rewardID: UUID?
        if kind != .battle {
            authorization = .notMetered
            rewardID = nil
        } else if isUnlocked {
            authorization = .unlocked
            rewardID = nil
        } else if ledger.completedTrialMatches < AccessLedger.trialLimit {
            authorization = .trial
            rewardID = nil
        } else if let available = ledger.availableRewards.first {
            authorization = .rewarded
            rewardID = available
        } else {
            throw AccessLedgerError.accessRequired
        }
        var candidate = ledger
        candidate.matches.append(AccessMatchEntry(
            id: id, kind: kind, authorization: authorization,
            rewardRequestID: rewardID, completed: false, continuationOf: nil
        ))
        try commit(candidate)
        return authorization
    }

    /// C0 / M6 option (a): a playable copy continues its parent's admission.
    /// - parent never registered (legacy, or an unlocked-only start): the copy is not metered either, nothing is written;
    /// - parent registered and unfinished: the copy is recorded as its continuation (no new quota use, no new reward);
    /// - parent already completed: the copy cannot be a continuation and throws, so the caller must not offer it.
    /// Idempotent for the same copy/parent pair. Returns whether the copy is now registered.
    @discardableResult
    public func beginContinuation(id: UUID, of parentID: UUID) throws -> Bool {
        if let existing = ledger.matches.first(where: { $0.id == id }) {
            guard existing.continuationOf == parentID else { throw AccessLedgerError.matchKindMismatch }
            return true
        }
        guard let parent = ledger.matches.first(where: { $0.id == parentID }) else { return false }
        guard !parent.completed else { throw AccessLedgerError.completedMatchCannotRestart }
        // A copy of a copy continues the original admission, never a chain.
        let rootID = parent.continuationOf ?? parent.id
        guard let root = ledger.matches.first(where: { $0.id == rootID }) else { throw AccessLedgerError.corruptData }
        guard !root.completed else { throw AccessLedgerError.completedMatchCannotRestart }
        var candidate = ledger
        candidate.matches.append(AccessMatchEntry(
            id: id, kind: root.kind, authorization: root.authorization,
            rewardRequestID: nil, completed: false, continuationOf: rootID
        ))
        try commit(candidate)
        return true
    }

    /// Only the game's real terminal result calls this. Undoing/replaying cannot erase its history.
    /// Legacy matches that were never registered remain free to resume and are not retroactively metered.
    @discardableResult
    public func completeMatch(id: UUID) throws -> Bool {
        guard let index = ledger.matches.firstIndex(where: { $0.id == id }),
              !ledger.matches[index].completed else { return false }
        var candidate = ledger
        candidate.matches[index].completed = true
        // Finishing a continuation settles the one admission it shares with its parent (exactly once).
        if let parentID = candidate.matches[index].continuationOf,
           let parentIndex = candidate.matches.firstIndex(where: { $0.id == parentID }) {
            candidate.matches[parentIndex].completed = true
        }
        try commit(candidate)
        return true
    }

    /// The ad adapter calls this only after a verified completed reward, with its original unique request ID.
    /// The ledger deliberately does not pretend to validate an advertising SDK callback itself.
    @discardableResult
    public func grantReward(requestID: UUID) throws -> Bool {
        guard !ledger.rewardRequests.contains(requestID) else { return false }
        var candidate = ledger
        candidate.rewardRequests.append(requestID)
        try commit(candidate)
        return true
    }

    private func commit(_ candidate: AccessLedger) throws {
        try candidate.validate()
        try persistence.save(Self.encode(candidate))
        ledger = candidate
    }

    private static func encode(_ value: AccessLedger) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }
}
