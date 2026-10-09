import Foundation
import TacticalGoCore

public enum RecordRules: String, Codable, Sendable, CaseIterable {
    case original, warrior, mage, both, redeployment
    public func config(size: Int) -> RuleConfig {
        var c = RuleConfig.board(size: size)
        if self == .warrior || self == .both { c.bastionScope = .connectedGroup }
        if self == .mage || self == .both { c.magicHandDestination = .opposingSoldierExchange }
        if self == .redeployment {
            c.bastionScope = .connectedGroup
            c.mageSkill = .magicHand
            c.magicHandDestination = .emptyOnly
            c.experimentalFriendlyRedeploy = true
        }
        return c
    }
}
public enum RecordError: Error { case unsupportedVersion, invalidSetup, invalidAction(Int), receiptMismatch(Int), oversized, alreadyCandidate }

/// Stable wire format: only reviewed game setups and successful Domain actions.
public struct RecordedAction: Codable, Equatable, Sendable {
    public let kind: String
    public let points: [Point]
    public let direction: String?
    public init(_ action: GameAction) {
        switch action {
        case .placeSoldier(let p): kind = "soldier"; points = [p]; direction = nil
        case .summonHero(let p): kind = "summon"; points = [p]; direction = nil
        case .castBastion(let a, let b): kind = "bastion"; points = [a,b]; direction = nil
        case .castMagicHand(let p, let d): kind = "push"; points = [p]; direction = d.rawValue
        case .castFriendlyRedeploy(let from, let to): kind = "redeploy"; points = [from,to]; direction = nil
        case .castSwap(let p): kind = "swap"; points = [p]; direction = nil
        case .castSeal(let p): kind = "seal"; points = [p]; direction = nil
        case .endTurn: kind = "end"; points = []; direction = nil
        }
    }
    public func action() throws -> GameAction {
        if kind == "push", points.count == 1, let direction,
           let d = PushDirection(rawValue: direction), d != .invalid { return .castMagicHand(points[0], d) }
        guard direction == nil else { throw RecordError.invalidSetup }
        if kind == "end", points.isEmpty { return .endTurn }
        if kind == "bastion", points.count == 2 { return .castBastion(points[0], points[1]) }
        if kind == "redeploy", points.count == 2 { return .castFriendlyRedeploy(points[0], points[1]) }
        guard points.count == 1 else { throw RecordError.invalidSetup }
        switch kind {
        case "soldier": return .placeSoldier(points[0])
        case "summon": return .summonHero(points[0])
        case "swap": return .castSwap(points[0])
        case "seal": return .castSeal(points[0])
        default: throw RecordError.invalidSetup
        }
    }
    public var label: String {
        func c(_ p: Point) -> String { "\(p.x >= 0 && p.x < 26 ? String(UnicodeScalar(65 + p.x)!) : "?")\(p.y + 1)" }
        let coordinates = points.map(c).joined(separator: "、")
        switch kind {
        case "soldier": return "落子 \(coordinates)"
        case "summon": return "召喚英雄 \(coordinates)"
        case "bastion": return "築壘 \(coordinates)"
        case "swap": return "換位 \(coordinates)"
        case "seal": return "封印 \(coordinates)"
        case "redeploy": return "重新部署 \(coordinates)"
        case "push":
            let d = ["Up":"上", "Right":"右", "Down":"下", "Left":"左"][direction ?? ""] ?? "？"
            return "魔法之手 \(coordinates) 向\(d)"
        default: return "結束回合"
        }
    }
}
public struct StateReceipt: Codable, Equatable, Sendable {
    public let diagram: String
    public let current: Player
    public let ply: Int
    public let ap: Int
    public let mana: [Int]
    public let summoned: [Bool]
    public let skillUsed: Bool
    public let status: GameStatus
    public let winner: Player?
    public let seals: [SealEffect]
    public init(_ s: GameState) {
        diagram = s.board.diagram; current = s.current; ply = s.ply; ap = s.apRemaining
        mana = Player.allCases.map(s.mana); summoned = Player.allCases.map(s.hasSummonedHero)
        skillUsed = s.skillUsedThisTurn; status = s.status; winner = s.winner; seals = s.seals
    }
}
public func recordedEvents(_ events: [ActionEvent]) -> [String] {
    func p(_ point: Point) -> String { "\(point.x),\(point.y)" }
    return events.map { e in
        let data: String
        switch e {
        case .resourcesSpent(let who, let ap, let mana): data = "\(who.rawValue):\(ap):\(mana)"
        case .piecePlaced(let who, let at, let kind): data = "\(who.rawValue):\(p(at)):\(kind.rawValue)"
        case .piecesSwapped(let who, let a, let b): data = "\(who.rawValue):\(p(a)):\(p(b))"
        case .piecePushed(let who, let from, let to, let piece): data = "\(who.rawValue):\(p(from)):\(p(to)):\(piece.owner.rawValue):\(piece.kind.rawValue)"
        case .sealPlaced(let who, let blocked, let at): data = "\(who.rawValue):\(blocked.rawValue):\(p(at))"
        case .sealExpired(let at): data = p(at)
        case .piecesCaptured(let who, let pieces): data = "\(who.rawValue):" + pieces.map { "\(p($0.at)):\($0.piece.owner.rawValue):\($0.piece.kind.rawValue)" }.joined(separator: ";")
        case .turnEnded(let who, let ply): data = "\(who.rawValue):\(ply)"
        case .turnStarted(let who, let ply, let ap, let mana): data = "\(who.rawValue):\(ply):\(ap):\(mana)"
        case .gameWon(let who): data = String(who.rawValue)
        case .gameDrawn(let reason): data = reason
        }
        return e.name + ":" + data
    }
}
public struct RecordStep: Codable, Equatable, Sendable {
    public let action: RecordedAction
    public let actor: Player
    public let after: StateReceipt
    public let events: [String]
    public let difficulty: String
    public let decision: String?
    public init(action: GameAction, before: GameState, outcome: ActionOutcome, difficulty: String, decision: String?) {
        self.action = RecordedAction(action); actor = before.current; after = StateReceipt(outcome.state)
        events = recordedEvents(outcome.events); self.difficulty = difficulty; self.decision = decision
    }
}
public struct ReplayFrame: Sendable {
    public let state: GameState
    public let step: RecordStep?
    public let events: [ActionEvent]
}
public struct MatchRecord: Codable, Identifiable, Sendable {
    public var schema = 1
    public var engineVersion = "tacticalgo-actions-v1"
    public let id: UUID
    public let created: Date
    public var updated: Date
    public let size: Int
    public let one: HeroClass
    public let two: HeroClass
    public let computer: Player?
    public let rules: RecordRules
    public var difficulty: String
    public var steps: [RecordStep] = []
    public init(size: Int, one: HeroClass, two: HeroClass, computer: Player?, difficulty: String, rules: RecordRules = .original) {
        id = UUID(); created = Date(); updated = created
        self.size = size; self.one = one; self.two = two; self.computer = computer
        self.difficulty = difficulty; self.rules = rules
    }
    public func rebuild() throws -> (GameSession, [ReplayFrame]) {
        guard schema == 1, engineVersion == "tacticalgo-actions-v1" else { throw RecordError.unsupportedVersion }
        guard [7,9].contains(size), one != .none, two != .none, computer == nil || size == 7,
              ["easy","standard"].contains(difficulty), steps.count <= 300 else { throw RecordError.invalidSetup }
        var session = GameSession(try GameSetup.newGame(config: rules.config(size: size), classOne: one, classTwo: two))
        var frames = [ReplayFrame(state: session.state, step: nil, events: [])]
        for (i, step) in steps.enumerated() {
            guard step.actor == session.state.current, ["easy","standard"].contains(step.difficulty) else { throw RecordError.receiptMismatch(i) }
            let action = try step.action.action()
            let outcome = session.apply(action)
            guard outcome.success else { throw RecordError.invalidAction(i) }
            guard StateReceipt(outcome.state) == step.after, recordedEvents(outcome.events) == step.events else { throw RecordError.receiptMismatch(i) }
            frames.append(ReplayFrame(state: outcome.state, step: step, events: outcome.events))
        }
        return (session, frames)
    }
    public func encoded() throws -> Data {
        let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try e.encode(self)
    }
    /// Creates a separately identified candidate without mutating this value or writing to disk.
    /// Both replays verify the original receipts/events; incompatible R2 exchanges are rejected.
    /// Calling this on a redeployment record throws alreadyCandidate; it is not an idempotent copy.
    public func candidateCopy() throws -> MatchRecord {
        guard rules != .redeployment else { throw RecordError.alreadyCandidate }
        _ = try rebuild()
        var candidate = MatchRecord(size: size, one: one, two: two, computer: computer,
                                    difficulty: difficulty, rules: .redeployment)
        candidate.steps = steps
        _ = try candidate.rebuild()
        return candidate
    }
    public static func decode(_ data: Data) throws -> MatchRecord {
        guard data.count <= 2_000_000 else { throw RecordError.oversized }
        let record = try JSONDecoder().decode(Self.self, from: data)
        _ = try record.rebuild()
        return record
    }
}

/// Atomic per-game files. A failed write never truncates the previously saved game.
public struct RecordRepository: Sendable {
    public let directory: URL
    public init(directory: URL) { self.directory = directory }
    public func save(_ record: MatchRecord) throws {
        _ = try record.rebuild()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try record.encoded().write(to: url(record.id), options: .atomic)
    }
    public func url(_ id: UUID) -> URL { directory.appendingPathComponent(id.uuidString).appendingPathExtension("json") }
    public func list() throws -> (records: [MatchRecord], rejected: Int) {
        guard FileManager.default.fileExists(atPath: directory.path) else { return ([],0) }
        var records: [MatchRecord] = []; var rejected = 0
        for file in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) where file.pathExtension == "json" {
            do {
                let values = try file.resourceValues(forKeys: [.fileSizeKey])
                guard (values.fileSize ?? 0) <= 2_000_000 else { throw RecordError.oversized }
                let record = try MatchRecord.decode(Data(contentsOf: file))
                guard file.lastPathComponent == url(record.id).lastPathComponent else { throw RecordError.invalidSetup }
                records.append(record)
            } catch { rejected += 1 } // Preserve rejected bytes for diagnosis; never overwrite them on load.
        }
        return (records.sorted { $0.updated == $1.updated ? $0.id.uuidString < $1.id.uuidString : $0.updated > $1.updated }, rejected)
    }
}
