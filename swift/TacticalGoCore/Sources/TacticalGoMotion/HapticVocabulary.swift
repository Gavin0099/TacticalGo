import Foundation
import TacticalGoCore

/// Semantic haptic meanings for a match. Names are events, not waveform shapes.
public enum GameHapticEvent: String, CaseIterable, Sendable {
    case placement
    case contactHit
    case kill
    case chain
    case victory
    case defeat
}

public struct HapticTransient: Equatable, Sendable {
    public var time: Double
    public var intensity: Float
    public var sharpness: Float
    public init(time: Double, intensity: Float, sharpness: Float) {
        self.time = time
        self.intensity = intensity
        self.sharpness = sharpness
    }
}

public struct HapticContinuous: Equatable, Sendable {
    public var time: Double
    public var duration: Double
    public var intensity: Float
    public var sharpness: Float
    public init(time: Double, duration: Double, intensity: Float, sharpness: Float) {
        self.time = time
        self.duration = duration
        self.intensity = intensity
        self.sharpness = sharpness
    }
}

/// A pattern the playback service renders. Intensity and sharpness stay in 0...1.
public struct HapticPattern: Equatable, Sendable {
    public var transients: [HapticTransient]
    public var continuous: [HapticContinuous]
    public init(transients: [HapticTransient], continuous: [HapticContinuous] = []) {
        self.transients = transients
        self.continuous = continuous
    }
    public var peakIntensity: Float {
        let transientPeak = transients.map(\.intensity).max() ?? 0
        let continuousPeak = continuous.map(\.intensity).max() ?? 0
        return max(transientPeak, continuousPeak)
    }
}

/// One playback moment on the presentation clock. `at` is seconds from the receipt start.
public struct HapticMoment: Equatable, Sendable {
    public let event: GameHapticEvent
    public let at: Double
    public init(_ event: GameHapticEvent, at: Double) {
        self.event = event
        self.at = at
    }
}

/// Persisted on/off switch. Missing storage means on, so a first launch still has feedback.
public struct HapticPreference: Equatable, Sendable {
    public static let defaultsKey = "haptics.enabled"
    public var enabled: Bool
    public init(storedFlag: Bool?) {
        enabled = storedFlag ?? true
    }
}

/// The user switch and Reduce Motion live here, not at each call site.
public struct HapticGate: Equatable, Sendable {
    public var enabled: Bool
    public var reduceMotion: Bool
    public init(enabled: Bool, reduceMotion: Bool) {
        self.enabled = enabled
        self.reduceMotion = reduceMotion
    }
    public func pattern(for event: GameHapticEvent) -> HapticPattern? {
        guard enabled else { return nil }
        return HapticVocabulary.pattern(for: event, reduceMotion: reduceMotion)
    }
}

/// Published intensity table, rarest last. Shapes follow the game-feel sketches:
/// instants are single transients, a chain is two hits, defeat is a dull tail,
/// victory is the only ascending swell.
///
/// Peak intensity: placement 0.32, contact 0.48, kill 0.64, chain 0.78, defeat 0.90, victory 1.00.
/// Defeat is heavier than a chain because a match ending is rarer, and duller than victory
/// so a loss does not reuse the win. Reduce Motion keeps that peak and drops the extra hits.
public enum HapticVocabulary {
    public static func pattern(for event: GameHapticEvent, reduceMotion: Bool) -> HapticPattern {
        let full = fullPattern(event)
        guard reduceMotion else { return full }
        let peak = full.transients.max { $0.intensity < $1.intensity } ?? HapticTransient(time: 0, intensity: full.peakIntensity, sharpness: 0.5)
        return HapticPattern(transients: [HapticTransient(time: 0, intensity: peak.intensity, sharpness: peak.sharpness)])
    }

    private static func fullPattern(_ event: GameHapticEvent) -> HapticPattern {
        switch event {
        case .placement:
            return HapticPattern(transients: [.init(time: 0, intensity: 0.32, sharpness: 0.25)])
        case .contactHit:
            return HapticPattern(transients: [.init(time: 0, intensity: 0.48, sharpness: 0.72)])
        case .kill:
            return HapticPattern(transients: [.init(time: 0, intensity: 0.64, sharpness: 0.80)])
        case .chain:
            return HapticPattern(transients: [
                .init(time: 0, intensity: 0.62, sharpness: 0.70),
                .init(time: 0.10, intensity: 0.78, sharpness: 0.84)
            ])
        case .defeat:
            return HapticPattern(
                transients: [.init(time: 0, intensity: 0.90, sharpness: 0.22)],
                continuous: [.init(time: 0.02, duration: 0.28, intensity: 0.40, sharpness: 0.12)]
            )
        case .victory:
            return HapticPattern(
                transients: [
                    .init(time: 0, intensity: 0.55, sharpness: 0.45),
                    .init(time: 0.12, intensity: 0.78, sharpness: 0.62),
                    .init(time: 0.24, intensity: 1.00, sharpness: 0.90)
                ],
                continuous: [.init(time: 0.24, duration: 0.40, intensity: 0.70, sharpness: 0.40)]
            )
        }
    }
}

/// Original-shell cues. A skill's `"place"` cue is the landing, not a soldier drop.
public enum LegacyHapticPlan {
    /// The original shell labels a lost match as `"victory"` until the human perspective is applied.
    public static func playbackKey(_ key: String, winnerIsComputer: Bool) -> String {
        key == "victory" && winnerIsComputer ? "defeat" : key
    }

    public static func event(forCue key: String, action: GameAction) -> GameHapticEvent? {
        switch key {
        case "place", "summon":
            switch action {
            case .placeSoldier, .summonHero: return .placement
            case .castChainSwap: return nil
            default: return .contactHit
            }
        case "capture": return .kill
        case "victory": return .victory
        case "defeat": return .defeat
        default: return nil
        }
    }
}

/// 1.1 receipt clock. One moment per meaning, aligned to the same timestamps as the sound cues.
/// A chain owns both exchanges, so the second land is not also a contact hit.
/// Draw, selection, and cast winds are not part of this vocabulary.
public enum ExpansionHapticPlan {
    public static func moments(_ presentation: ExpansionPresentation, computer: Player?) -> [HapticMoment] {
        var moments: [HapticMoment] = []
        switch presentation.action {
        case .placeSoldier, .summonHero:
            moments.append(.init(.placement, at: presentation.arrival))
        case .castMagicHand, .castFriendlyRedeploy, .castDoublePull,
             .castBastion, .castReformation, .castSwap,
             .castSanctuary, .castSanctum, .castOffering,
             .useStickyBounce, .useShadowStep, .huntMonster:
            moments.append(.init(.contactHit, at: presentation.arrival))
        case .castChainSwap:
            let firstContact = (presentation.moveStart + presentation.arrival) / 2
            moments.append(.init(.chain, at: firstContact))
        case .castSeal, .endTurn:
            break
        }
        if !presentation.captures.isEmpty {
            moments.append(.init(.kill, at: presentation.captureStart))
        }
        switch presentation.terminalCue(computer: computer) {
        case "victory": moments.append(.init(.victory, at: presentation.duration))
        case "defeat": moments.append(.init(.defeat, at: presentation.duration))
        default: break
        }
        return moments.sorted { $0.at < $1.at }
    }
}
