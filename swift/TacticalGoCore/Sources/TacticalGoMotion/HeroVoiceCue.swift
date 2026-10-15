import TacticalGoCore

/// Selects a voice from a committed receipt. Does not play, apply or infer rules.
public struct HeroVoiceCue: Equatable, Sendable {
    public enum Trigger: String, Sendable { case summon, skill }
    public let hero: HeroClass
    public let trigger: Trigger
    public var key: String { "voice-\(hero.rawValue.lowercased())-\(trigger.rawValue)" }
    public static func make(before: GameState, action: GameAction, outcome: ActionOutcome) -> Self? {
        guard outcome.success else { return nil }
        switch action {
        case .summonHero:
            guard outcome.events.contains(where: { event in
                if case .piecePlaced(let owner, _, .hero) = event { return owner == before.current }
                return false
            }) else { return nil }
            return Self(hero: before.heroClass(of: before.current), trigger: .summon)
        case .castBastion, .castMagicHand, .castFriendlyRedeploy, .castSwap, .castSeal:
            guard before.board.find(before.current, .hero) != nil else { return nil }
            return Self(hero: before.heroClass(of: before.current), trigger: .skill)
        default: return nil
        }
    }
}
