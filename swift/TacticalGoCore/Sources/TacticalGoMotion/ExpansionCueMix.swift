/// Presentation gain hierarchy. Assets, voice identity, cue times and input windows stay separate.
public struct ExpansionCueMix: Equatable, Sendable {
    public let preparation: Double
    public let motion: Double
    public let impact: Double
    public init(voiceEnabled: Bool) {
        preparation = voiceEnabled ? 0.20:0.42
        motion = voiceEnabled ? 0.26:0.58
        impact = voiceEnabled ? 0.30:0.65
    }
    public static let monsterPreparation = 0.48
    public static let monsterMotion = 0.58
    public static let monsterImpact = 0.65
}
