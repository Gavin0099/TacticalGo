import TacticalGoCore

/// Candidate-only presentation contract. It describes a successful receipt;
/// neither its clock nor its completion can mutate the Domain.
public struct Anim01MagicHand: Equatable, Sendable {
    public static let charge = 0.080
    public static let move = 0.220
    public static let settle = 0.100
    public static let capture = 0.180
    public let caster: Player
    public let hero: Point
    public let from: Point
    public let to: Point
    public let piece: Piece
    public let captures: [CapturedPiece]
    public let winner: Player?
    public var duration: Double { 0.4 + (captures.isEmpty ? 0 : Self.capture) }
    /// A paused TimelineView can retain its last pre-completion frame date.
    /// Completion must display the committed board, never a frozen capture ghost.
    public func displayTime(elapsed: Double, animating: Bool, reducedMotion: Bool) -> Double {
        animating && !reducedMotion ? max(0, elapsed) : duration
    }
    public static func make(before: GameState, action: GameAction, outcome: ActionOutcome) -> Self? {
        guard outcome.success, case .castMagicHand = action,
              let hero = before.board.find(before.current, .hero) else { return nil }
        let pushes = outcome.events.compactMap { event -> (Player, Point, Point, Piece)? in
            if case .piecePushed(let caster, let from, let to, let piece) = event { return (caster, from, to, piece) }
            return nil
        }
        guard pushes.count == 1, let push = pushes.first else { return nil }
        let captures = outcome.events.flatMap { event -> [CapturedPiece] in
            if case .piecesCaptured(_, let pieces) = event { return pieces }; return []
        }
        let winner = outcome.events.compactMap { event -> Player? in
            if case .gameWon(let player) = event { return player }; return nil
        }.first
        return Self(caster: push.0, hero: hero, from: push.1, to: push.2, piece: push.3, captures: captures, winner: winner)
    }
    /// 80 ms anticipation, 220 ms straight movement, then 100 ms settling.
    public func progress(at elapsed: Double, reducedMotion: Bool = false) -> Double {
        guard !reducedMotion else { return 1 }
        let t = min(1, max(0, (elapsed - Self.charge) / Self.move))
        return t * t * (3 - 2 * t)
    }
}

extension CombatFeedbackPlan {
    public static func anim01(before: GameState, action: GameAction, outcome: ActionOutcome) -> Self {
        guard let clip = Anim01MagicHand.make(before: before, action: action, outcome: outcome) else {
            return Self(cues: [], duration: 0)
        }
        var cues: [CombatSoundCue] = [.init("mage", at: 0), .init("place", at: 0.3)]
        if !clip.captures.isEmpty { cues.append(.init("capture", at: 0.4)) }
        if clip.winner != nil { cues.append(.init("victory", at: clip.duration)) }
        return Self(cues: cues, duration: clip.duration)
    }
}

/// Sparse real-engine review positions, shared across board sizes. No rules are
/// altered; a capture fixture is only used with a friendly pushed soldier.
public enum Anim01Fixture {
    public static let action: GameAction = .castMagicHand(Point(4, 3), .up)
    public static func state(size: Int = 7, caster: Player = .one, pushedOwner: Player = .one,
                             capture: Bool = true, ap: Int = 2) throws -> GameState {
        precondition(size == 7 || size == 9)
        precondition(!capture || pushedOwner == caster)
        var rows = Array(repeating: Array(repeating: Character("."), count: size), count: size)
        let soldier: Character = caster == .one ? "x" : "o"
        let enemyCommander: Character = caster == .one ? "O" : "X"
        let ownCommander: Character = caster == .one ? "X" : "O"
        rows[3][3] = caster == .one ? "H" : "Q"
        rows[3][4] = pushedOwner == .one ? "x" : "o"
        rows[5][3] = ownCommander
        if capture {
            rows[1][3] = soldier; rows[2][2] = soldier; rows[2][3] = enemyCommander
        } else { rows[1][3] = enemyCommander }
        return try GameSetup.fromDiagram(config: .board(size: size), diagram: rows.map { String($0) }.joined(separator: "\n"),
            classOne: caster == .one ? .mage : .warrior, classTwo: caster == .two ? .mage : .warrior,
            current: caster, manaOne: 4, manaTwo: 4, ap: ap)
    }
}
