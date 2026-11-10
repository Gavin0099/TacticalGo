import Foundation
import TacticalGoCore

/// Presentation-only haptic names. These do not place stones, capture, or score.
public enum HapticEvent: String, CaseIterable, Equatable, Sendable {
    case placement
    case contactHit
    case kill
    case chain
    case victory
    case defeat
}

/// Generator family the iOS service may play. Intensity is a separate 0...1 peak.
public enum HapticFeel: String, Equatable, Sendable {
    case soft
    case light
    case medium
    case heavy
    case success
    case error
}

public struct HapticImpulse: Equatable, Sendable {
    public let event: HapticEvent
    public let feel: HapticFeel
    public let intensity: Double
    public let at: Double
    public init(event: HapticEvent, feel: HapticFeel, intensity: Double, at: Double) {
        self.event = event
        self.feel = feel
        self.intensity = intensity
        self.at = at
    }
}

/// Persisted player toggle. Missing or non-bool storage stays on; the key is not written until the player changes it.
public struct HapticPreference: Equatable, Sendable {
    public static let storageKey = "combatHaptics.enabled"
    public var enabled: Bool
    public init(stored: Any?) {
        if let value = stored as? Bool { enabled = value }
        else { enabled = true }
    }
}

/// Playback permission. UIKit feedback generators also silence themselves when System Haptics is off;
/// `systemHapticsEnabled` lets tests and a caller that already knows the switch state fail closed.
public struct HapticGate: Equatable, Sendable {
    public var enabled: Bool
    public var hardwareSupported: Bool
    public var systemHapticsEnabled: Bool
    public init(enabled: Bool, hardwareSupported: Bool, systemHapticsEnabled: Bool) {
        self.enabled = enabled
        self.hardwareSupported = hardwareSupported
        self.systemHapticsEnabled = systemHapticsEnabled
    }
    public var allowsPlayback: Bool { enabled && hardwareSupported && systemHapticsEnabled }
}

/// Significance rises placement → contact → kill → chain → match end.
/// Match end is one tier: victory and defeat share the peak and differ by feel.
/// Reduce Motion keeps that order, softens the two motion-coupled taps, and collapses a chain rhythm to one tap.
public enum HapticVocabulary {
    public static func feel(for event: HapticEvent) -> HapticFeel {
        switch event {
        case .placement: .soft
        case .contactHit: .light
        case .kill: .medium
        case .chain: .heavy
        case .victory: .success
        case .defeat: .error
        }
    }

    public static func peak(for event: HapticEvent, reduceMotion: Bool) -> Double {
        switch event {
        case .placement: reduceMotion ? 0.375 : 0.5
        case .contactHit: reduceMotion ? 0.5 : 0.625
        case .kill: 0.75
        case .chain: 0.875
        case .victory, .defeat: 1
        }
    }

    public static func impulse(_ event: HapticEvent, at time: Double, reduceMotion: Bool) -> HapticImpulse {
        .init(event: event, feel: feel(for: event), intensity: peak(for: event, reduceMotion: reduceMotion), at: time)
    }

    /// Two exchanges become a lead-in then a peak. Reduce Motion, or a single timestamp, is one peak tap.
    public static func chainImpulses(at times: [Double], reduceMotion: Bool) -> [HapticImpulse] {
        let unique = Array(Set(times.filter { $0.isFinite && $0 >= 0 })).sorted()
        guard let last = unique.last else { return [] }
        if reduceMotion || unique.count < 2 {
            return [impulse(.chain, at: last, reduceMotion: reduceMotion)]
        }
        let lead = HapticImpulse(event: .chain, feel: .heavy, intensity: 0.75, at: unique[0])
        return [lead, impulse(.chain, at: last, reduceMotion: reduceMotion)]
    }
}

public enum HapticPlayback {
    /// Same-time taps keep the stronger one so a landing and a hit do not stack into one muddy buzz.
    public static func coalesce(_ impulses: [HapticImpulse]) -> [HapticImpulse] {
        let sorted = impulses.sorted { lhs, rhs in
            if lhs.at != rhs.at { return lhs.at < rhs.at }
            return lhs.intensity > rhs.intensity
        }
        var kept: [HapticImpulse] = []
        for impulse in sorted {
            if let last = kept.last, last.at == impulse.at { continue }
            kept.append(impulse)
        }
        return kept
    }

    public static func audible(_ impulses: [HapticImpulse], gate: HapticGate) -> [HapticImpulse] {
        guard gate.allowsPlayback else { return [] }
        let finite = impulses.filter { impulse in
            impulse.at.isFinite && impulse.at >= 0 && impulse.intensity.isFinite
                && impulse.intensity > 0 && impulse.intensity <= 1
        }
        return coalesce(finite)
    }
}

/// Maps an already validated presentation or the legacy sound-cue list onto the vocabulary.
/// Callers must pass only a successful receipt. A nil presentation schedules nothing.
public enum HapticCuePlan {
    public static func impulses(presentation: ExpansionPresentation?, computer: Player?, reduceMotion: Bool) -> [HapticImpulse] {
        guard let presentation else { return [] }
        return presentation.hapticImpulses(computer: computer, reduceMotion: reduceMotion)
    }

    public static func impulses(legacyCues: [CombatSoundCue], action: GameAction, defeat: Bool, reduceMotion: Bool) -> [HapticImpulse] {
        let placementAction: Bool
        let contactAction: Bool
        switch action {
        case .placeSoldier, .summonHero:
            placementAction = true
            contactAction = false
        case .castMagicHand, .castFriendlyRedeploy, .castBastion, .castSwap, .castSeal,
             .castSanctuary, .castSanctum, .castOffering, .castDoublePull, .castReformation,
             .huntMonster, .useStickyBounce, .useShadowStep:
            placementAction = false
            contactAction = true
        default:
            placementAction = false
            contactAction = false
        }
        var items: [HapticImpulse] = []
        for cue in legacyCues {
            switch cue.key {
            case "place", "summon":
                if placementAction {
                    items.append(HapticVocabulary.impulse(.placement, at: cue.start, reduceMotion: reduceMotion))
                } else if contactAction {
                    items.append(HapticVocabulary.impulse(.contactHit, at: cue.start, reduceMotion: reduceMotion))
                }
            case "capture":
                items.append(HapticVocabulary.impulse(.kill, at: cue.start, reduceMotion: reduceMotion))
            case "victory":
                items.append(HapticVocabulary.impulse(defeat ? .defeat : .victory, at: cue.start, reduceMotion: reduceMotion))
            case "defeat":
                items.append(HapticVocabulary.impulse(.defeat, at: cue.start, reduceMotion: reduceMotion))
            default:
                break
            }
        }
        return items.sorted { $0.at < $1.at }
    }
}

extension ExpansionPresentation {
    /// Placement is a new piece. Contact is a skill or monster landing. Chain replaces contact on a chain swap.
    /// Kill follows captures. Victory and defeat follow the existing human-perspective terminal cue.
    public func hapticImpulses(computer: Player?, reduceMotion: Bool) -> [HapticImpulse] {
        var items: [HapticImpulse] = []
        if !placements.isEmpty {
            items.append(HapticVocabulary.impulse(.placement, at: arrival, reduceMotion: reduceMotion))
        }
        if isChainSwap {
            let times = contactBeats.map(\.start)
            items.append(contentsOf: HapticVocabulary.chainImpulses(at: times.isEmpty ? [arrival] : times, reduceMotion: reduceMotion))
        } else if let contact = contactMoment {
            items.append(HapticVocabulary.impulse(.contactHit, at: contact, reduceMotion: reduceMotion))
        }
        if !captures.isEmpty {
            items.append(HapticVocabulary.impulse(.kill, at: captureStart, reduceMotion: reduceMotion))
        }
        switch terminalCue(computer: computer) {
        case "victory":
            items.append(HapticVocabulary.impulse(.victory, at: duration, reduceMotion: reduceMotion))
        case "defeat":
            items.append(HapticVocabulary.impulse(.defeat, at: duration, reduceMotion: reduceMotion))
        default:
            break
        }
        return items.sorted { $0.at < $1.at }
    }

    private var contactMoment: Double? {
        if let first = contactBeats.map(\.start).min() { return first }
        switch action {
        case .huntMonster, .useStickyBounce, .useShadowStep: return arrival
        default: return nil
        }
    }
}
