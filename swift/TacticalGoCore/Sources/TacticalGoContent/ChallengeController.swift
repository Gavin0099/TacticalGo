import Foundation
import TacticalGoCore
import TacticalGoRecords

public enum ChallengeError: Error { case version, corrupt, unknownChallenge, locked }
public struct ChallengeProgress: Codable, Equatable, Sendable {
    public var version = 1
    public var selectedID: String?
    public var runs: [String: [RecordedAction]] = [:]
    /// Verified successful action receipts; retry/undo does not erase past completion.
    public var completed: [String: [RecordedAction]] = [:]
    public var hints: [String: Int] = [:]
    public init() {}
}

/// Owns challenge lifecycle only. TutorialSession and Core own pedagogical goals and rules.
public struct ChallengeController: Sendable {
    public let catalog: [TutorialScenario]
    public private(set) var progress: ChallengeProgress
    public private(set) var session: TutorialSession?
    public var scenario: TutorialScenario? { session?.scenario }
    public var assessment: TutorialAssessment? { session?.assessment }
    public var locked: Bool {
        guard case .incomplete = assessment else { return true }
        return false
    }
    public var completedIDs: Set<String> { Set(progress.completed.keys) }
    public init(progress: ChallengeProgress = ChallengeProgress()) throws {
        let catalog = try TutorialCatalog.all()
        guard progress.version == 1 else { throw ChallengeError.version }
        let known = Set(catalog.map(\.id))
        guard Set(progress.runs.keys).isSubset(of: known), Set(progress.completed.keys).isSubset(of: known),
              Set(progress.hints.keys).isSubset(of: known), progress.selectedID.map({ known.contains($0) }) ?? true else { throw ChallengeError.corrupt }
        for scenario in catalog {
            if let moves = progress.runs[scenario.id] { _ = try Self.replay(scenario, moves) }
            if let moves = progress.completed[scenario.id] {
                guard try Self.replay(scenario, moves).assessment == .completed else { throw ChallengeError.corrupt }
            }
            if let count = progress.hints[scenario.id] {
                guard (0...scenario.optionalHints.count).contains(count) else { throw ChallengeError.corrupt }
            }
        }
        self.catalog = catalog; self.progress = progress
        if let id = progress.selectedID, let scenario = catalog.first(where: { $0.id == id }) {
            session = try Self.replay(scenario, progress.runs[id] ?? [])
        }
    }
    private static func replay(_ scenario: TutorialScenario, _ moves: [RecordedAction]) throws -> TutorialSession {
        guard moves.count <= 3 else { throw ChallengeError.corrupt }
        var session = try TutorialSession(scenario)
        for move in moves {
            guard case .incomplete = session.assessment else { throw ChallengeError.corrupt }
            let outcome = session.apply(try move.action())
            guard outcome.success else { throw ChallengeError.corrupt }
        }
        return session
    }
    public mutating func choose(_ id: String) throws {
        guard let scenario = catalog.first(where: { $0.id == id }) else { throw ChallengeError.unknownChallenge }
        let rebuilt = try Self.replay(scenario, progress.runs[id] ?? [])
        progress.selectedID = id; session = rebuilt
    }
    public mutating func leave() { progress.selectedID = nil; session = nil }
    public func preview(_ action: GameAction) -> ActionOutcome? {
        guard !locked, let state = session?.state else { return nil }
        return GameEngine.apply(state, action)
    }
    @discardableResult public mutating func commit(_ action: GameAction) throws -> ActionOutcome {
        guard !locked, var session else { throw ChallengeError.locked }
        let outcome = session.apply(action)
        if outcome.success {
            self.session = session
            progress.runs[session.scenario.id, default: []].append(RecordedAction(action))
            // Freeze before any opponent execution or further input can be scheduled.
            if session.assessment == .completed { progress.completed[session.scenario.id] = progress.runs[session.scenario.id] }
        }
        return outcome
    }
    @discardableResult public mutating func undo() throws -> Bool {
        guard let scenario, var moves = progress.runs[scenario.id], !moves.isEmpty else { return false }
        moves.removeLast()
        let rebuilt = try Self.replay(scenario, moves)
        progress.runs[scenario.id] = moves; session = rebuilt
        return true
    }
    public mutating func retry() throws {
        guard let scenario else { throw ChallengeError.unknownChallenge }
        let fresh = try TutorialSession(scenario)
        progress.runs[scenario.id] = []; progress.hints[scenario.id] = 0; session = fresh
    }
    @discardableResult public mutating func revealHint() -> Bool {
        guard let scenario else { return false }
        let count = progress.hints[scenario.id, default: 0]
        guard count < scenario.optionalHints.count else { return false }
        progress.hints[scenario.id] = count + 1; return true
    }
    public var visibleHints: [String] {
        guard let scenario else { return [] }
        return Array(scenario.optionalHints.prefix(progress.hints[scenario.id, default: 0]))
    }
}

/// No MatchRepository or Onboarding access; journal and validated completion receipts live here.
public struct ChallengeRepository {
    public let directory: URL
    public var file: URL { directory.appendingPathComponent("challenges-v1.json") }
    public init(directory: URL) { self.directory = directory }
    public func load() throws -> ChallengeController {
        guard FileManager.default.fileExists(atPath: file.path) else { return try ChallengeController() }
        let data = try Data(contentsOf: file)
        guard data.count <= 64_000 else { throw ChallengeError.corrupt }
        return try ChallengeController(progress: JSONDecoder().decode(ChallengeProgress.self, from: data))
    }
    public func save(_ progress: ChallengeProgress) throws {
        _ = try ChallengeController(progress: progress)
        let data = try JSONEncoder().encode(progress)
        guard data.count <= 64_000 else { throw ChallengeError.corrupt }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: file, options: .atomic)
    }
}
