import TacticalGoCore

public enum ArcaneAudioRevision: Sendable { case soft, weighty }

/// Historical M3/B are preserved; phoneOriginal restores frozen phone1023.
public enum MagePresentationVariant: String, CaseIterable, Sendable {
    case original, rhythmic, phoneOriginal, phoneRefined, arcaneHand
    public var timing: MageTiming {
        switch self {
        case .phoneOriginal, .phoneRefined: MageTiming(anticipationEnd: 0.18, release: 0.26, moveStart: 0.38, arrival: 0.60, captureStart: 0.70, recoveryEnd: 0.95, summonEnd: 0.72)
        case .arcaneHand: MageTiming(anticipationEnd: 0.18, release: 0.30, moveStart: 0.46, arrival: 0.68, captureStart: 0.80, recoveryEnd: 1.08, summonEnd: 0.72)
        case .original: MageTempo.full.timing
        case .rhythmic: MageTiming(anticipationEnd: 0.10, release: 0.22, moveStart: 0.22,
            arrival: 0.52, captureStart: 0.52, recoveryEnd: 0.70, summonEnd: 0.60)
        }
    }
}

/// An immutable adapter for a confirmed Domain receipt. A preview, failed or
/// stale receipt cannot authorize motion or sound. Completion never writes Domain.
public struct MagePresentationPlan: Equatable, Sendable {
    public let variant: MagePresentationVariant
    public let before: GameState
    public let after: GameState
    public let clip: Anim01MagicHand
    public let sounds: [CombatSoundCue]
    public static func make(before: GameState, action: GameAction, outcome: ActionOutcome,
                            current: GameState, variant: MagePresentationVariant, arcaneAudio: ArcaneAudioRevision = .soft) -> Self? {
        guard current == outcome.state, before.heroClass(of: before.current) == .mage,
              case .castMagicHand(let from, let direction) = action,
              before.board.contains(from), direction != .invalid,
              let source = before.board[from], source.kind == .soldier,
              let old = Anim01MagicHand.make(before: before, action: action, outcome: outcome),
              old.caster == before.current, old.from == from,
              old.to == direction.destination(from: from), old.piece == source else { return nil }
        let clip = Anim01MagicHand(caster: old.caster, hero: old.hero, from: old.from,
            to: old.to, piece: old.piece, captures: old.captures, winner: old.winner, timing: variant.timing)
        var sounds: [CombatSoundCue] = variant != .rhythmic
            ? [.init("mage", at: clip.timing.release), .init("place", at: clip.timing.arrival)]
            : [.init("p-charge", at: 0), .init("p-release", at: clip.timing.release), .init("p-land", at: clip.timing.arrival)]
        if variant == .phoneRefined { sounds.insert(.init("p3-air", at: clip.timing.moveStart), at: 1) }
        if variant == .arcaneHand { sounds = [.init("p4-conjure", at: 0.08), .init("p4-push", at: clip.timing.moveStart), .init("p4-contact", at: clip.timing.arrival)] }
        if variant == .arcaneHand && arcaneAudio == .weighty { sounds = [.init("p5-conjure", at: 0.08), .init("p5-push", at: clip.timing.moveStart), .init("p5-contact", at: clip.timing.arrival)] }
        if !clip.captures.isEmpty {
            sounds.append(.init(variant != .rhythmic ? "capture" : "p-capture", at: clip.timing.captureStart))
        }
        if clip.winner != nil { sounds.append(.init("victory", at: clip.duration)) }
        return Self(variant: variant, before: before, after: outcome.state, clip: clip, sounds: sounds)
    }
    public func pose(at time: Double, reducedMotion: Bool = false) -> MageBodyPose {
        MageBodyPose.cast(at: time, timing: clip.timing, reduced: reducedMotion, revision: variant == .phoneRefined || variant == .arcaneHand ? .r2 : variant == .phoneOriginal ? .r1 : .m3)
    }
    /// Captured actors disappear at arrival; only receipt-listed capture ghosts
    /// may remain briefly. A captured mage is never recreated by the renderer.
    public func board(at time: Double, reducedMotion: Bool = false) -> Board {
        reducedMotion || time >= clip.timing.arrival ? after.board : before.board
    }
}
