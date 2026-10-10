import TacticalGoCore

/// Candidate-only presentation contract. It describes a successful receipt;
/// neither its clock nor its completion can mutate the Domain.
public struct Anim01MagicHand: Equatable, Sendable {
    public static let charge = MageTempo.full.timing.moveStart
    public static let move = MageTempo.full.timing.arrival - charge
    public static let settle = MageTempo.full.timing.captureStart - MageTempo.full.timing.arrival
    public static let capture = 0.180
    public let caster: Player
    public let hero: Point
    public let from: Point
    public let to: Point
    public let piece: Piece
    public let captures: [CapturedPiece]
    public let winner: Player?
    public let timing: MageTiming
    public var duration: Double { max(timing.recoveryEnd, captures.isEmpty ? 0 : timing.captureEnd) }
    /// A paused TimelineView can retain its last pre-completion frame date.
    /// Completion must display the committed board, never a frozen capture ghost.
    public func displayTime(elapsed: Double, animating: Bool, reducedMotion: Bool) -> Double {
        animating && !reducedMotion ? max(0, elapsed) : duration
    }
    public static func make(before: GameState, action: GameAction, outcome: ActionOutcome, tempo: MageTempo = .full) -> Self? {
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
        return Self(caster: push.0, hero: hero, from: push.1, to: push.2, piece: push.3, captures: captures, winner: winner, timing: tempo.timing)
    }
    /// Soldier movement starts after the visible casting pose has been reached.
    public func progress(at elapsed: Double, reducedMotion: Bool = false) -> Double {
        guard !reducedMotion else { return 1 }
        let t = min(1, max(0, (elapsed - timing.moveStart) / (timing.arrival - timing.moveStart)))
        return t * t * (3 - 2 * t)
    }
}

extension CombatFeedbackPlan {
    public static func anim01(before: GameState, action: GameAction, outcome: ActionOutcome, tempo: MageTempo = .full) -> Self {
        guard let clip = Anim01MagicHand.make(before: before, action: action, outcome: outcome, tempo: tempo) else {
            return Self(cues: [], duration: 0)
        }
        var cues: [CombatSoundCue] = [.init("mage", at: clip.timing.release), .init("place", at: clip.timing.arrival)]
        if !clip.captures.isEmpty { cues.append(.init("capture", at: clip.timing.captureStart)) }
        if clip.winner != nil { cues.append(.init("victory", at: clip.duration)) }
        return Self(cues: cues, duration: clip.duration)
    }
}

/// Sparse real-engine review positions, shared across board sizes. No rules are
/// altered; a capture fixture is only used with a friendly pushed soldier.
public enum Anim01Fixture {
    public static let action: GameAction = .castMagicHand(Point(4, 3), .up)
    /// Fixed legal stress fixture, not a claim of natural competitive reachability.
    public static func denseState(caster: Player = .one) throws -> GameState {
        let base = try state(size: 9, caster: caster, pushedOwner: caster, capture: false)
        var rows = base.board.diagram.split(separator: "\n").map { Array($0) }
        for y in [0,6,8] {
            for x in 0..<9 where rows[y][x] == "." { rows[y][x] = x % 2 == 0 ? "x" : "o" }
        }
        rows[0][3] = "." // Keep the isolated opposing-color top stone from starting with zero liberties.
        for y in [2,4] {
            for x in [0,1,6,7,8] where rows[y][x] == "." { rows[y][x] = x % 2 == 0 ? "x" : "o" }
        }
        return try GameSetup.fromDiagram(config: .board(size: 9), diagram: rows.map { String($0) }.joined(separator: "\n"),
            classOne: base.heroClass(of: .one), classTwo: base.heroClass(of: .two), current: caster, manaOne: 4, manaTwo: 4, ap: 2)
    }
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
