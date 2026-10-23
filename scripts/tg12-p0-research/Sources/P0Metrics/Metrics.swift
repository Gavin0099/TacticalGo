import TacticalGoCore

public enum P0Metrics {
    /// Current 1.1 UI/Bot policy; compatibility-only Core actions remain valid for old record replay.
    public static func isInCurrentMode(_ action: GameAction, config: RuleConfig) -> Bool {
        if config.expansionSkills && config.experimentalFriendlyRedeploy,
           case .castMagicHand = action { return false }
        return true
    }
    public static func isBasic(_ a: GameAction) -> Bool {
        switch a {
        case .castBastion, .castMagicHand, .castFriendlyRedeploy, .castSwap, .castOffering, .castSeal: true
        default: false
        }
    }
    public static func isAdvanced(_ a: GameAction) -> Bool {
        switch a {
        case .castSanctum, .castSanctuary, .castReformation, .castDoublePull, .castChainSwap: true
        default: false
        }
    }
    public static func isClassSkill(_ a: GameAction) -> Bool { isBasic(a) || isAdvanced(a) }
    public static func isPurePass(_ actions: [GameAction]) -> Bool {
        !actions.isEmpty && actions.allSatisfy { $0 == .endTurn }
    }
    public static func pattern(_ actions: [GameAction]) -> String {
        actions.map { a in
            if isClassSkill(a) { return "skill" }
            switch a {
            case .placeSoldier: return "soldier"
            case .summonHero: return "summon"
            case .endTurn: return "end"
            default: return "other"
            }
        }.joined(separator: "+")
    }
    public static func result(_ status: GameStatus) -> String {
        switch status { case .won: "won"; case .drawn: "drawn"; case .ongoing: "incomplete" }
    }
    public static func longestPassRun(_ flags: [Bool]) -> Int {
        var run = 0, best = 0
        for flag in flags { run = flag ? run + 1 : 0; best = max(best, run) }
        return best
    }
}
