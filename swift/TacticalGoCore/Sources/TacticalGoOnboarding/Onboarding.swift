import Foundation
import TacticalGoCore

public struct OnboardingLesson: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let goal: String
    public let instruction: String
    public let explanation: String
    public let diagram: [String]
    public let recommended: Point
    public let inspect: Point?
    public let opening: Bool
    public let targetSeconds: Int
    public func initialState() throws -> GameState {
        let config = RuleConfig.board(size: 7)
        if opening { return try GameSetup.newGame(config: config, classOne: .none, classTwo: .none) }
        return try GameSetup.fromDiagram(config: config, diagram: diagram.joined(separator: "\n"),
            classOne: .none, classTwo: .none, current: .one, manaOne: 3, manaTwo: 3, ap: 2, ply: 3)
    }
    public static func catalog() throws -> [Self] {
        let url = Bundle.module.url(forResource: "onboard-v1", withExtension: "json", subdirectory: "Fixtures")!
        return try JSONDecoder().decode([Self].self, from: Data(contentsOf: url))
    }
}

/// A read-only Core query, also used by the UI overlay. No parallel liberty or capture rules.
public struct GroupInspection: Sendable {
    public let owner: Player
    public let kind: PieceKind
    public let group: Set<Point>
    public let liberties: Set<Point>
    public static func read(_ state: GameState, at point: Point) -> Self? {
        guard state.board.contains(point), let piece = state.board[point] else { return nil }
        return Self(owner: piece.owner, kind: piece.kind, group: Set(state.board.group(at: point)),
                    liberties: state.board.liberties(at: point))
    }
}
public struct OnboardingProgress: Codable, Equatable, Sendable {
    public var version: Int = 1
    public var lessonIndex: Int = 0
    public var actions: [[Point]] = Array(repeating: [], count: 5)
    public var observed: [Point?] = Array(repeating: nil, count: 5)
    public init() {}
}
public enum OnboardingError: Error { case corruptProgress, unsupportedVersion, lessonComplete, wrongTurn, observationRequired }

public struct OnboardingSession: Sendable {
    public let lessons: [OnboardingLesson]
    public private(set) var progress: OnboardingProgress
    private var session: GameSession
    public var state: GameState { session.state }
    public var finished: Bool { progress.lessonIndex == lessons.count }
    public var lesson: OnboardingLesson? { finished ? nil : lessons[progress.lessonIndex] }
    public var completed: Bool {
        guard let lesson else { return true }
        return Self.completed(lesson, state: state, actions: progress.actions[progress.lessonIndex],
                              observed: progress.observed[progress.lessonIndex])
    }
    public init(progress: OnboardingProgress = OnboardingProgress()) throws {
        let lessons = try OnboardingLesson.catalog()
        guard progress.version == 1 else { throw OnboardingError.unsupportedVersion }
        guard lessons.count == 5, (0...lessons.count).contains(progress.lessonIndex),
              progress.actions.count == lessons.count, progress.observed.count == lessons.count else { throw OnboardingError.corruptProgress }
        var current: GameSession?
        for (index, lesson) in lessons.enumerated() {
            let moves = progress.actions[index]
            guard moves.count <= 16, index <= progress.lessonIndex || moves.isEmpty else { throw OnboardingError.corruptProgress }
            // The journal must obey commit's observation-before-action contract too.
            guard lesson.id != "breathing" || moves.isEmpty || progress.observed[index] != nil else { throw OnboardingError.corruptProgress }
            let initial = try lesson.initialState()
            if let observed = progress.observed[index] {
                guard index <= progress.lessonIndex, lesson.id == "breathing", let anchor = lesson.inspect,
                      initial.board.group(at: anchor).contains(observed) else { throw OnboardingError.corruptProgress }
            }
            var replay = GameSession(initial)
            var applied: [Point] = []
            for point in moves {
                guard replay.state.current == .one, !Self.completed(lesson, state: replay.state, actions: applied, observed: progress.observed[index]) else { throw OnboardingError.corruptProgress }
                let result = replay.apply(.placeSoldier(point))
                guard result.success else { throw OnboardingError.corruptProgress }
                applied.append(point)
            }
            if index < progress.lessonIndex {
                guard Self.completed(lesson, state: replay.state, actions: moves, observed: progress.observed[index]) else { throw OnboardingError.corruptProgress }
            }
            if index == min(progress.lessonIndex, lessons.count - 1) { current = replay }
        }
        self.lessons = lessons; self.progress = progress; self.session = current!
    }
    private static func completed(_ lesson: OnboardingLesson, state: GameState, actions: [Point], observed: Point?) -> Bool {
        guard !actions.isEmpty else { return false }
        switch lesson.id {
        case "goal": return state.status == .won && state.winner == .one
        case "place": return true // One actual successful Core action, including first-turn handover.
        case "breathing":
            guard observed != nil, let anchor = lesson.inspect else { return false }
            return state.board.group(at: anchor).count >= 3 && state.board.liberties(at: anchor).count >= 6
        case "capture": return state.board[Point(3, 2)] == nil && state.status == .ongoing
        case "rescue":
            guard let commander = state.board.find(.one, .commander) else { return false }
            return state.status == .ongoing && state.board.liberties(at: commander).count >= 2
        default: return false
        }
    }
    public mutating func observe(_ point: Point) {
        guard let lesson, lesson.id == "breathing", let anchor = lesson.inspect,
              let initial = try? lesson.initialState(), initial.board.group(at: anchor).contains(point) else { return }
        progress.observed[progress.lessonIndex] = point
    }
    public func preview(_ point: Point) -> ActionOutcome? {
        guard !finished, !completed else { return nil }
        return GameEngine.apply(state, .placeSoldier(point))
    }
    @discardableResult public mutating func commit(_ point: Point) throws -> ActionOutcome {
        guard !finished, !completed else { throw OnboardingError.lessonComplete }
        guard state.current == .one else { throw OnboardingError.wrongTurn }
        if lesson?.id == "breathing", progress.observed[progress.lessonIndex] == nil { throw OnboardingError.observationRequired }
        let result = session.apply(.placeSoldier(point))
        if result.success { progress.actions[progress.lessonIndex].append(point) }
        return result
    }
    @discardableResult public mutating func undo() -> Bool {
        guard !finished, session.undo() else { return false }
        progress.actions[progress.lessonIndex].removeLast()
        return true
    }
    public mutating func advance() throws {
        guard !finished, completed else { throw OnboardingError.corruptProgress }
        progress.lessonIndex += 1
        if !finished { session = GameSession(try lessons[progress.lessonIndex].initialState()) }
    }
}

/// Its own directory and journal; this target does not depend on MatchRecords.
public struct OnboardingRepository {
    public let directory: URL
    public var file: URL { directory.appendingPathComponent("onboard-v1.json") }
    public init(directory: URL) { self.directory = directory }
    public func load() throws -> OnboardingSession {
        guard FileManager.default.fileExists(atPath: file.path) else { return try OnboardingSession() }
        let data = try Data(contentsOf: file)
        guard data.count <= 64_000 else { throw OnboardingError.corruptProgress }
        let progress = try JSONDecoder().decode(OnboardingProgress.self, from: data)
        return try OnboardingSession(progress: progress)
    }
    public func save(_ progress: OnboardingProgress) throws {
        _ = try OnboardingSession(progress: progress)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(progress).write(to: file, options: .atomic)
    }
}
