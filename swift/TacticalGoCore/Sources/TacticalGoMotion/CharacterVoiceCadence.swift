import TacticalGoCore

/// Transient presentation history. Nothing here changes rules or saved games.
public struct CharacterVoiceCadence: Equatable, Sendable {
    public enum Profile: Sendable {
        /// `everyCast`: Owner decision 2026-10-17 (TestFlight 1114) — a skipped line read as missing sound.
        /// Only the 3 s global gap remains, so two heroes' lines never overlap.
        case balanced, calm, everyCast
        var castSpacing: Int { switch self { case .balanced: 3; case .calm: 4; case .everyCast: 1 } }
        var seconds: Double { switch self { case .balanced: 12; case .calm: 18; case .everyCast: 0 } }
    }
    private struct Identity: Hashable, Sendable { let player: Int; let hero: String }
    private struct History: Equatable, Sendable {
        var eligibleCasts = 0
        var nextCast = 1
        var spokenAt: Double?
    }
    public let profile: Profile
    private var histories: [Identity: History] = [:]
    private var lastGlobalVoice: Double?
    private var lastEligibleTime: Double?
    public init(profile: Profile = .balanced) { self.profile = profile }
    public mutating func reset() { histories = [:];lastGlobalVoice = nil;lastEligibleTime = nil }

    /// Evaluate on a copy; retain it only if the requested voice player accepts
    /// playback. Suppressed eligible casts can retain the copy immediately.
    public mutating func shouldSpeak(player: Player, hero: HeroClass, at time: Double, eligible: Bool) -> Bool {
        guard eligible, hero != .none, time.isFinite, time >= 0,
              lastEligibleTime.map({ time >= $0 }) ?? true else { return false }
        lastEligibleTime = time
        let identity = Identity(player: player.rawValue, hero: hero.rawValue)
        var history = histories[identity] ?? History()
        history.eligibleCasts += 1
        let due = history.eligibleCasts >= history.nextCast
        let classReady = history.spokenAt.map { time - $0 >= profile.seconds } ?? true
        let globalReady = lastGlobalVoice.map { time - $0 >= 3 } ?? true
        let speak = due && classReady && globalReady
        if speak {
            history.spokenAt = time
            history.nextCast = history.eligibleCasts + profile.castSpacing
            lastGlobalVoice = time
        }
        histories[identity] = history
        return speak
    }
}
