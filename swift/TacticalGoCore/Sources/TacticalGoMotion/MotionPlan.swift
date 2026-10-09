import TacticalGoCore

/// Presentation only. Plans explain committed events; they never resolve rules.
public struct MotionCue: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case drop(PieceKind), capture(Piece), swap, bastion, seal, sealExpired, win(Player), turn(Player), draw
    }
    public let kind: Kind
    public let points: [Point]
    public let start: Double
    public let duration: Double
    public init(_ kind: Kind, _ points: [Point] = [], start: Double, duration: Double) {
        self.kind = kind; self.points = points; self.start = start; self.duration = duration
    }
}
public struct MotionPlan: Equatable, Sendable {
    public let cues: [MotionCue]
    public let duration: Double
    public static let empty = MotionPlan(cues: [], duration: 0)
    /// Hand-authored timing contract, independent of renderer frame rate.
    public static func make(before: GameState, action: GameAction, outcome: ActionOutcome, reducedMotion: Bool = false) -> MotionPlan {
        guard outcome.success, !reducedMotion else { return .empty }
        var cues: [MotionCue] = []
        let skillDelay: Double
        switch action {
        case .castBastion(let a, let b):
            let hero = before.board.find(before.current, .hero)
            cues.append(MotionCue(.bastion, hero.map { [$0, a, b] } ?? [a, b], start: 0, duration: 0.48))
            skillDelay = 0.18
        case .castSeal(let at):
            let hero = before.board.find(before.current, .hero)
            cues.append(MotionCue(.seal, hero.map { [$0, at] } ?? [at], start: 0, duration: 0.60))
            skillDelay = 0
        case .castSwap: skillDelay = 0.10
        default: skillDelay = 0
        }
        // Captures follow the primary action's visual landing, including placed-and-captured units.
        let captureStart: Double
        switch action {
        case .castBastion: captureStart = 0.48
        case .castSeal: captureStart = 0.60
        case .castSwap: captureStart = 0.42
        case .summonHero: captureStart = 0.46
        case .placeSoldier: captureStart = 0.30
        case .castMagicHand: captureStart = 0 // A0 uses static committed state; no new motion production.
        case .castFriendlyRedeploy: captureStart = 0.62
        case .endTurn: captureStart = 0
        }
        for event in outcome.events {
            switch event {
            case .piecePlaced(_, let at, let kind):
                cues.append(MotionCue(.drop(kind), [at], start: skillDelay, duration: kind == .hero ? 0.46 : 0.30))
            case .piecesSwapped(_, let a, let b):
                cues.append(MotionCue(.swap, [a, b], start: skillDelay, duration: 0.32))
            case .piecesCaptured(_, let pieces):
                for p in pieces { cues.append(MotionCue(.capture(p.piece), [p.at], start: captureStart, duration: 0.28)) }
            case .sealExpired(let at): cues.append(MotionCue(.sealExpired, [at], start: 0, duration: 0.22))
            case .gameWon(let player): cues.append(MotionCue(.win(player), start: captureStart + 0.28, duration: 0.58))
            case .gameDrawn:
                let captures = outcome.events.contains { if case .piecesCaptured(_, let pieces) = $0 { return !pieces.isEmpty }; return false }
                cues.append(MotionCue(.draw, start: captureStart + (captures ? 0.28 : 0), duration: 0.28))
            case .turnStarted(let player, _, _, _): cues.append(MotionCue(.turn(player), start: 0, duration: 0.22))
            case .resourcesSpent, .sealPlaced, .turnEnded, .piecePushed: break
            }
        }
        return MotionPlan(cues: cues, duration: cues.map { $0.start + $0.duration }.max() ?? 0)
    }
    public init(cues: [MotionCue], duration: Double) { self.cues = cues; self.duration = duration }
}

/// Curves are reusable by native models and deterministic offline animation review.
public enum MotionCurves {
    /// A delayed, outward-only cloth response. Shoulders stay attached through
    /// skin weights; the hem peaks after the body gesture and returns to rest.
    public static func capeFollowThrough(_ t: Double, lateImpact: Bool = false) -> Double {
        // Warrior shield impact is at0.8125; shift the cloth peak to0.835.
        // Mage/rogue body gestures peak earlier and retain the0.70 cloth peak.
        let x = clamp(lateImpact ? (t - 0.45) / 0.55 : t)
        if x <= 0.25 { return 0 }
        if x < 0.70 { return ease((x - 0.25) / 0.45) }
        return 1 - ease((x - 0.70) / 0.30)
    }
    public static func clamp(_ value: Double) -> Double { min(1, max(0, value)) }
    public static func ease(_ t: Double) -> Double { let x = clamp(t); return x * x * (3 - 2 * x) }
    public static func dropHeight(_ t: Double) -> Double {
        let x = clamp(t)
        if x >= 1 { return 0 }
        if x < 0.70 { let fall = x / 0.70; return 1.2 * (1 - fall * fall) }
        let settle = (x - 0.70) / 0.30
        return 0.10 * 4 * settle * (1 - settle)
    }
    public static func squash(_ t: Double) -> Double {
        let x = clamp(t)
        if x < 0.70 { return 1 }
        let settle = (x - 0.70) / 0.30
        return 0.82 + 0.18 * ease(settle)
    }
    public static func swapProgress(_ t: Double) -> Double { ease(t) }
    public static func anticipation(_ t: Double) -> Double {
        let x = clamp(t)
        if x < 0.25 { return -0.16 * ease(x / 0.25) }
        if x < 0.55 { return -0.16 + 0.38 * ease((x - 0.25) / 0.30) }
        return 0.22 * (1 - ease((x - 0.55) / 0.45))
    }
    /// Shield impact coincides with both soldiers touching down at 0.39 seconds.
    public static func shieldStrike(_ t: Double) -> Double {
        let x = clamp(t), windup = 0.18 / 0.48, impact = 0.39 / 0.48
        if x < windup { return -0.16 * ease(x / windup) }
        if x < impact { return -0.16 + 0.40 * ease((x - windup) / (impact - windup)) }
        return 0.24 * (1 - ease((x - impact) / (1 - impact)))
    }
}
